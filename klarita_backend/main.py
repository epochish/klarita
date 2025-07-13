"""
Main FastAPI Application for Klarita (Revamped)
"""

import uvicorn
from fastapi import FastAPI, Depends, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm
from typing import List, Optional
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Import local modules
from . import models, schemas, auth, rag_handler, rl_handler, analytics_handler
from .database import SessionLocal, engine, get_db

# Create all database tables
models.Base.metadata.create_all(bind=engine)

# --- Badge Seeding ---
def seed_badges(db: Session):
    badges = [
        {
            "name": "First Task",
            "description": "Completed your first task!",
            "icon": "first_task.png",
            "criteria": {"type": "tasks_completed", "value": 1},
        },
        {
            "name": "Streak 3",
            "description": "Maintain a 3-day streak of task completions.",
            "icon": "streak3.png",
            "criteria": {"type": "streak", "value": 3},
        },
        {
            "name": "Level 5",
            "description": "Reach level 5.",
            "icon": "level5.png",
            "criteria": {"type": "level", "value": 5},
        },
    ]
    for badge in badges:
        if not db.query(models.Badge).filter(models.Badge.name == badge["name"]).first():
            db.add(models.Badge(**badge))
    db.commit()

# Seed badges once at startup
with SessionLocal() as seed_db:
    seed_badges(seed_db)

# --- FastAPI App Initialization ---
app = FastAPI(
    title="Klarita API",
    description="Backend services for the Klarita ADHD support application.",
    version="2.0.0",
)

# --- CORS Middleware ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this to your Flutter app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================================
# Authentication Endpoints
# ==================================

@app.post("/token", response_model=schemas.Token, tags=["Users"])
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    # OAuth2PasswordRequestForm uses "username" as the field for the email
    user = auth.authenticate_user(db, email=form_data.username, password=form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = auth.create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/users/", response_model=schemas.User, tags=["Users"])
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = auth.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return auth.create_user(db=db, user=user)

@app.get("/users/me/", response_model=schemas.User, tags=["Users"])
async def read_users_me(current_user: models.User = Depends(auth.get_current_active_user)):
    return current_user

# ==================================
# AI Task Breakdown Engine
# ==================================
@app.post("/breakdown/initiate", response_model=schemas.TaskSession, tags=["AI Engine"])
async def initiate_breakdown(
    request: schemas.BreakdownInitiateRequest, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """
    Takes a user's goal and returns an AI-generated task breakdown.
    """
    # Get the AI-generated breakdown
    task_list = rag_handler.get_initial_breakdown(
        db=db,
        goal=request.goal, 
        user_id=current_user.id
    )

    # Create a new TaskSession in the database
    new_session = models.TaskSession(
        user_id=current_user.id,
        original_goal=request.goal,
        status="pending"
    )
    db.add(new_session)
    db.commit()
    db.refresh(new_session)

    # Create the individual tasks and link them to the session
    for task_data in task_list:
        new_task = models.Task(
            session_id=new_session.id,
            title=task_data.get("title", "Untitled Task"),
            description=task_data.get("description"),
            estimated_duration=task_data.get("estimated_duration"),
            status="pending"
        )
        db.add(new_task)
    
    db.commit()
    db.refresh(new_session) # Refresh to load the tasks relationship

    return new_session

@app.post("/sessions/{session_id}/save_as_memory", response_model=schemas.TaskMemory, tags=["Memories"])
def save_session_as_memory(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """
    Saves a completed and successful task session as a memory for the RAG model.
    """
    db_session = db.query(models.TaskSession).filter(models.TaskSession.id == session_id).first()

    if not db_session:
        raise HTTPException(status_code=404, detail="Session not found")

    if db_session.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to access this session")

    # Convert the tasks to a JSON serializable format.
    # Pydantic models can handle the serialization of the task objects.
    tasks_for_memory = [schemas.Task.from_orm(task).dict() for task in db_session.tasks]

    new_memory = models.TaskMemory(
        user_id=current_user.id,
        original_goal=db_session.original_goal,
        task_breakdown=tasks_for_memory
    )
    
    db.add(new_memory)
    db.commit()
    db.refresh(new_memory)

    # Add the new memory to the vector store for RAG
    try:
        rag_handler.add_memory_to_vector_store(current_user.id, new_memory)
    except Exception as e:
        # Log the error, but don't fail the request if the vector store fails.
        # The memory is still saved in the primary DB.
        print(f"ERROR: Could not add memory {new_memory.id} to vector store: {e}")

    return new_memory

# ==================================
# Feedback / RL Endpoints
# ==================================


@app.post("/sessions/{session_id}/feedback", response_model=schemas.SessionFeedback, tags=["Feedback"])
async def submit_session_feedback(
    session_id: int,
    feedback: schemas.SessionFeedbackCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Logs a user's rating/comments for a task session (reward signal for RL)."""

    db_session = db.query(models.TaskSession).filter(models.TaskSession.id == session_id).first()

    if not db_session:
        raise HTTPException(status_code=404, detail="Session not found")

    if db_session.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to provide feedback on this session")

    # Persist feedback
    new_feedback = models.SessionFeedback(
        session_id=session_id,
        user_id=current_user.id,
        rating=feedback.rating,
        comments=feedback.comments,
    )
    db.add(new_feedback)

    # Update session success_rating field as quick aggregate signal
    db_session.success_rating = feedback.rating

    db.commit()
    db.refresh(new_feedback)

    # Trigger enhanced RL learning with session and rating
    try:
        from . import enhanced_rl_handler
        enhanced_rl_handler.process_feedback(db, current_user.id, session_id, feedback.rating)
        print(f"Enhanced RL processing completed for user {current_user.id}")
    except Exception as e:
        print(f"Enhanced RL processing error: {e}")
        # Fallback to simple RL handler
        try:
            rl_handler.process_feedback(db, current_user.id)
        except Exception as fallback_e:
            print(f"Fallback RL processing error: {fallback_e}")

    return new_feedback

# ==================================
# Task Update Endpoints
# ==================================


@app.patch("/tasks/{task_id}", response_model=schemas.Task, tags=["Tasks"])
async def update_task(
    task_id: int,
    update: schemas.TaskUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Partially updates a task's fields (title, description, duration, priority)."""
    task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Ensure ownership
    if task.session.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this task")

    # Apply updates if provided
    if update.title is not None:
        task.title = update.title
    if update.description is not None:
        task.description = update.description
    if update.estimated_duration is not None:
        task.estimated_duration = update.estimated_duration
    if update.priority is not None:
        task.priority = update.priority

    db.commit()
    db.refresh(task)

    return task

# ==================================
# Task Reorder Endpoint
# ==================================


@app.patch("/sessions/{session_id}/reorder", tags=["Tasks"])
async def reorder_tasks(
    session_id: int,
    payload: schemas.TaskReorderRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user),
):
    """Reorders tasks within a session based on the list of IDs provided."""
    session_obj = db.query(models.TaskSession).filter(models.TaskSession.id == session_id).first()
    if not session_obj:
        raise HTTPException(status_code=404, detail="Session not found")
    if session_obj.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to reorder tasks for this session")

    id_list = payload.ordered_task_ids
    # Validate that provided IDs belong to this session
    tasks = db.query(models.Task).filter(models.Task.session_id == session_id).all()
    task_ids_set = {t.id for t in tasks}
    if set(id_list) != task_ids_set:
        raise HTTPException(status_code=400, detail="Provided task IDs do not match session tasks")

    # Update position values
    for position, task_id in enumerate(id_list):
        db.query(models.Task).filter(models.Task.id == task_id).update({"position": position})

    db.commit()
    return {"status": "success"}

# ==================================
# Task Merge Endpoint
# ==================================


@app.post("/tasks/merge", response_model=schemas.Task, tags=["Tasks"])
async def merge_tasks(
    payload: schemas.TaskMergeRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user),
):
    """Merge multiple tasks into one consolidated task."""

    ids = payload.task_ids
    tasks = db.query(models.Task).filter(models.Task.id.in_(ids)).all()

    if len(tasks) != len(ids):
        raise HTTPException(status_code=404, detail="One or more tasks not found")

    # Ensure all belong to same session and user
    first_session = tasks[0].session
    if any(t.session_id != first_session.id for t in tasks):
        raise HTTPException(status_code=400, detail="Tasks must belong to the same session to merge")
    if first_session.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to merge these tasks")

    # Compute merged properties
    merged_title = f"{tasks[0].title} (merged)"
    merged_description = "\n\n".join([t.description or "" for t in tasks]).strip()
    merged_duration = sum([t.estimated_duration or 0 for t in tasks]) or None

    # Highest priority (high > medium > low)
    priority_order = {models.TaskPriority.low: 0, models.TaskPriority.medium: 1, models.TaskPriority.high: 2}
    highest_priority = max(tasks, key=lambda t: priority_order[t.priority]).priority

    merged_task = models.Task(
        session_id=first_session.id,
        title=merged_title,
        description=merged_description,
        estimated_duration=merged_duration,
        priority=highest_priority,
        position=min([t.position or 0 for t in tasks]),
        status="pending",
    )
    db.add(merged_task)

    # Delete originals
    for t in tasks:
        db.delete(t)

    db.commit()
    db.refresh(merged_task)

    return merged_task

# ==================================
# Gamification Endpoints
# ==================================

@app.get("/gamification/status", response_model=schemas.UserGamification, tags=["Gamification"])
async def get_gamification_status(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """
    Returns the current user's gamification profile.
    """
    if not current_user.gamification:
        # Create a default gamification profile if one doesn't exist
        new_profile = models.UserGamification(user_id=current_user.id)
        db.add(new_profile)
        db.commit()
        db.refresh(new_profile)
        return new_profile
    return current_user.gamification

@app.post("/tasks/{task_id}/complete", response_model=schemas.Task, tags=["Gamification"])
async def complete_task(
    task_id: int,
    actual_minutes: Optional[int] = Query(None, ge=1, description="Actual minutes taken to finish task"),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """
    Marks a task as complete and triggers gamification logic.
    """
    task = db.query(models.Task).filter(models.Task.id == task_id).first()

    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Ensure the user owns the task
    if task.session.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to complete this task")

    if task.status == "completed":
        raise HTTPException(status_code=400, detail="Task is already completed")

    task.status = "completed"

    # --- Gamification Logic ---
    BASE_POINTS = 10
    BONUS_POINTS = 5
    LEVEL_THRESHOLD = 100

    points_earned = BASE_POINTS

    # Bonus if user finished quicker than estimate
    if actual_minutes is not None and task.estimated_duration and actual_minutes < task.estimated_duration:
        points_earned += BONUS_POINTS

    gamification_profile = current_user.gamification
    if not gamification_profile:
        gamification_profile = models.UserGamification(user_id=current_user.id)
        db.add(gamification_profile)

    gamification_profile.points += points_earned

    if gamification_profile.points >= LEVEL_THRESHOLD:
        gamification_profile.level += 1
        gamification_profile.points -= LEVEL_THRESHOLD

    # --- Streak logic ---
    from datetime import datetime, timezone, timedelta

    today = datetime.now(timezone.utc).date()
    last_date = (
        gamification_profile.last_task_completed_at.date()
        if gamification_profile.last_task_completed_at
        else None
    )

    if last_date is None:
        # First ever completion
        gamification_profile.current_streak = 1
    else:
        delta_days = (today - last_date).days
        if delta_days == 0:
            # Same day – keep streak as-is
            pass
        elif delta_days == 1:
            gamification_profile.current_streak += 1
        else:
            gamification_profile.current_streak = 1

    # Update longest_streak
    if gamification_profile.current_streak > gamification_profile.longest_streak:
        gamification_profile.longest_streak = gamification_profile.current_streak

    # Save last completion timestamp
    gamification_profile.last_task_completed_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(gamification_profile)

    # --- Badge awarding ---
    def try_award_badge(badge_name: str):
        badge = db.query(models.Badge).filter(models.Badge.name == badge_name).first()
        if badge and not any(eb.badge_id == badge.id for eb in gamification_profile.badges):
            db.add(models.EarnedBadge(gamification_profile_id=gamification_profile.id, badge_id=badge.id))

    # First Task badge
    total_completed = (
        db.query(models.Task)
        .join(models.TaskSession)
        .filter(models.Task.status == "completed", models.TaskSession.user_id == current_user.id)
        .count()
    )
    if total_completed == 1:
        try_award_badge("First Task")

    # --- Enhanced RL Integration ---
    # Notify the enhanced RL handler about task completion for learning
    try:
        from . import enhanced_rl_handler
        # Use task completion as positive feedback for RL learning
        # If task was completed faster than estimated, give higher "rating"
        implied_rating = 4  # Base positive rating for task completion
        if actual_minutes is not None and task.estimated_duration and actual_minutes < task.estimated_duration:
            implied_rating = 5  # Higher rating for faster completion
        
        enhanced_rl_handler.process_feedback(
            db, current_user.id, task.session_id, implied_rating
        )
        print(f"Enhanced RL task completion processed for user {current_user.id}")
    except Exception as e:
        print(f"Enhanced RL task completion processing error: {e}")

    return task

# ==================================
# "Feeling Stuck" AI Coach
# ==================================

@app.post("/stuck_coach", response_model=schemas.StuckCoachResponse, tags=["AI Coach"])
async def stuck_coach(
    request: schemas.StuckCoachRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """
    Provides a personalized Socratic dialogue to help users overcome feelings of being stuck.
    """
    ai_response = rag_handler.get_stuck_coach_response(
        message=request.message, 
        user_id=current_user.id,
        db=db
    )
    
    return schemas.StuckCoachResponse(
        session_id=0, # This will be implemented later
        ai_response=ai_response,
        suggested_actions=[] # This will be implemented later
    )

# ==================================
# Leaderboard Endpoint
# ==================================


@app.get("/gamification/leaderboard", response_model=List[schemas.UserGamification], tags=["Gamification"])
async def leaderboard(db: Session = Depends(get_db)):
    top = (
        db.query(models.UserGamification)
        .order_by(models.UserGamification.points.desc())
        .limit(10)
        .all()
    )
    return top

# ==================================
# Advanced Analytics Endpoints
# ==================================

@app.get("/analytics/summary", response_model=schemas.AnalyticsSummary, tags=["Analytics"])
async def get_analytics_summary(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Get comprehensive analytics summary for the current user."""
    try:
        return analytics_handler.get_analytics_summary(db, current_user.id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating analytics summary: {str(e)}")

@app.get("/analytics/trends", response_model=schemas.AnalyticsTrends, tags=["Analytics"])
async def get_analytics_trends(
    period: str = Query("week", regex="^(week|month|quarter)$"),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Get analytics trends for a specific period."""
    try:
        days_map = {"week": 7, "month": 30, "quarter": 90}
        days = days_map[period]
        
        trends = analytics_handler.get_completion_trends(db, current_user.id, days)
        
        # For now, return basic trends structure
        return schemas.AnalyticsTrends(
            period=period,
            trends=trends,
            streak_history=[]  # Could be enhanced with actual streak history
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating analytics trends: {str(e)}")

@app.get("/analytics/categories", response_model=List[schemas.CategoryStats], tags=["Analytics"])
async def get_category_analytics(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Get task completion statistics by category."""
    try:
        return analytics_handler.get_category_stats(db, current_user.id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating category analytics: {str(e)}")

@app.get("/analytics/performance", response_model=schemas.AnalyticsPerformance, tags=["Analytics"])
async def get_performance_analytics(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Get performance analytics including best times and patterns."""
    try:
        return analytics_handler.get_analytics_performance(db, current_user.id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating performance analytics: {str(e)}")

@app.get("/analytics/insights", response_model=List[schemas.PersonalizedInsight], tags=["Analytics"])
async def get_personalized_insights(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Get personalized insights based on user behavior patterns."""
    try:
        return analytics_handler.generate_personalized_insights(db, current_user.id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating personalized insights: {str(e)}")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000) 