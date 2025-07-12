"""
Main FastAPI Application for Klarita (Revamped)
"""

import uvicorn
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm
from typing import List
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Import local modules
from . import models, schemas, auth, rag_handler, rl_handler
from .database import SessionLocal, engine, get_db

# Create all database tables
models.Base.metadata.create_all(bind=engine)

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

    # Trigger RL preference update (simple heuristic)
    try:
        rl_handler.process_feedback(db, current_user.id)
    except Exception as e:
        print(f"RL processing error: {e}")

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
    POINTS_PER_TASK = 10
    LEVEL_THRESHOLD = 100
    
    gamification_profile = current_user.gamification
    if not gamification_profile:
        gamification_profile = models.UserGamification(user_id=current_user.id)
        db.add(gamification_profile)

    gamification_profile.points += POINTS_PER_TASK

    if gamification_profile.points >= LEVEL_THRESHOLD:
        gamification_profile.level += 1
        gamification_profile.points -= LEVEL_THRESHOLD

    db.commit()
    db.refresh(task)
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
    Provides a Socratic dialogue to help users overcome feelings of being stuck.
    """
    ai_response = rag_handler.get_stuck_coach_response(
        message=request.message, 
        user_id=current_user.id
    )
    
    return schemas.StuckCoachResponse(
        session_id=0, # This will be implemented later
        ai_response=ai_response,
        suggested_actions=[] # This will be implemented later
    )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000) 