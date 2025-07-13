"""
Analytics Handler for Klarita
Provides comprehensive analytics computation for user productivity data.
"""

import json
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import func, desc, asc, extract
from collections import defaultdict, Counter
import statistics

from . import models, schemas
try:
    from . import enhanced_rl_handler
    HAS_ENHANCED_RL = True
except ImportError:
    HAS_ENHANCED_RL = False

def categorize_task(task_title: str) -> str:
    """
    Categorize a task based on its title using simple keyword matching.
    In the future, this could be enhanced with ML classification.
    """
    title_lower = task_title.lower()
    
    # Work-related keywords
    work_keywords = ['work', 'job', 'meeting', 'email', 'project', 'deadline', 'client', 'report', 'presentation']
    # Health-related keywords
    health_keywords = ['gym', 'exercise', 'workout', 'doctor', 'health', 'medicine', 'vitamins', 'walk', 'run']
    # Life/Personal keywords
    life_keywords = ['home', 'family', 'grocery', 'shopping', 'clean', 'cook', 'laundry', 'bills', 'personal']
    # Study/Learning keywords
    study_keywords = ['study', 'learn', 'read', 'book', 'course', 'homework', 'research', 'practice']
    
    for keyword in work_keywords:
        if keyword in title_lower:
            return "Work"
    
    for keyword in health_keywords:
        if keyword in title_lower:
            return "Health"
    
    for keyword in life_keywords:
        if keyword in title_lower:
            return "Life"
    
    for keyword in study_keywords:
        if keyword in title_lower:
            return "Study"
    
    return "Other"

def get_quick_stats(db: Session, user_id: int) -> schemas.QuickStats:
    """Get quick overview statistics for a user."""
    
    # Get gamification data
    gamification = db.query(models.UserGamification).filter(
        models.UserGamification.user_id == user_id
    ).first()
    
    if not gamification:
        # Create default gamification profile if it doesn't exist
        gamification = models.UserGamification(user_id=user_id)
        db.add(gamification)
        db.commit()
        db.refresh(gamification)
    
    # Get all user tasks
    tasks = db.query(models.Task).join(models.TaskSession).filter(
        models.TaskSession.user_id == user_id
    ).all()
    
    total_tasks_created = len(tasks)
    completed_tasks = [task for task in tasks if task.status == "completed"]
    total_tasks_completed = len(completed_tasks)
    
    # Calculate completion rate
    overall_completion_rate = (total_tasks_completed / total_tasks_created * 100) if total_tasks_created > 0 else 0
    
    # Calculate average task duration
    durations = [task.estimated_duration for task in completed_tasks if task.estimated_duration]
    average_task_duration = statistics.mean(durations) if durations else None
    
    return schemas.QuickStats(
        total_tasks_completed=total_tasks_completed,
        total_tasks_created=total_tasks_created,
        overall_completion_rate=round(overall_completion_rate, 1),
        average_task_duration=round(average_task_duration, 1) if average_task_duration else None,
        current_streak=gamification.current_streak,
        longest_streak=gamification.longest_streak,
        total_xp=gamification.points,
        current_level=gamification.level
    )

def get_category_stats(db: Session, user_id: int) -> List[schemas.CategoryStats]:
    """Get task completion statistics by category."""
    
    # Get all user tasks
    tasks = db.query(models.Task).join(models.TaskSession).filter(
        models.TaskSession.user_id == user_id
    ).all()
    
    # Categorize tasks
    category_data: Dict[str, Dict[str, Any]] = defaultdict(lambda: {"completed": 0, "total": 0, "durations": []})
    
    for task in tasks:
        category = categorize_task(task.title)
        category_data[category]["total"] += 1
        
        if task.status == "completed":
            category_data[category]["completed"] += 1
            if task.estimated_duration:
                category_data[category]["durations"].append(task.estimated_duration)
    
    # Convert to schema format
    category_stats = []
    for category, data in category_data.items():
        completion_rate = (data["completed"] / data["total"] * 100) if data["total"] > 0 else 0
        average_duration = statistics.mean(data["durations"]) if data["durations"] else None
        
        category_stats.append(schemas.CategoryStats(
            category=category,
            completed_tasks=data["completed"],
            total_tasks=data["total"],
            completion_rate=round(completion_rate, 1),
            average_duration=round(average_duration, 1) if average_duration else None
        ))
    
    return sorted(category_stats, key=lambda x: x.completion_rate, reverse=True)

def get_time_of_day_stats(db: Session, user_id: int) -> List[schemas.TimeOfDayStats]:
    """Get task completion statistics by time of day."""
    
    # Get all user sessions with their tasks
    sessions = db.query(models.TaskSession).filter(
        models.TaskSession.user_id == user_id
    ).all()
    
    # Group by hour of day
    hour_data: Dict[int, Dict[str, Any]] = defaultdict(lambda: {"completed": 0, "total": 0, "durations": []})
    
    for session in sessions:
        hour = session.created_at.hour
        
        for task in session.tasks:
            hour_data[hour]["total"] += 1
            
            if task.status == "completed":
                hour_data[hour]["completed"] += 1
                if task.estimated_duration:
                    hour_data[hour]["durations"].append(task.estimated_duration)
    
    # Convert to schema format
    time_stats = []
    for hour in range(24):
        if hour in hour_data:
            data = hour_data[hour]
            completion_rate = (data["completed"] / data["total"] * 100) if data["total"] > 0 else 0
            average_duration = statistics.mean(data["durations"]) if data["durations"] else None
            
            time_stats.append(schemas.TimeOfDayStats(
                hour=hour,
                completed_tasks=data["completed"],
                total_tasks=data["total"],
                completion_rate=round(completion_rate, 1),
                average_duration=round(average_duration, 1) if average_duration else None
            ))
    
    return sorted(time_stats, key=lambda x: x.completion_rate, reverse=True)

def get_stuck_stats(db: Session, user_id: int) -> List[schemas.StuckStats]:
    """Get statistics about where users get stuck by category."""
    
    # This would need to be enhanced once we have stuck coach session tracking
    # For now, we'll use session feedback as a proxy
    sessions = db.query(models.TaskSession).filter(
        models.TaskSession.user_id == user_id
    ).all()
    
    category_sessions = defaultdict(lambda: {"stuck": 0, "total": 0})
    
    for session in sessions:
        # Categorize the session based on the original goal
        category = categorize_task(session.original_goal)
        category_sessions[category]["total"] += 1
        
        # Check if user provided negative feedback (proxy for being stuck)
        feedback = db.query(models.SessionFeedback).filter(
            models.SessionFeedback.session_id == session.id,
            models.SessionFeedback.rating <= 2
        ).first()
        
        if feedback:
            category_sessions[category]["stuck"] += 1
    
    # Convert to schema format
    stuck_stats = []
    for category, data in category_sessions.items():
        stuck_percentage = (data["stuck"] / data["total"] * 100) if data["total"] > 0 else 0
        
        stuck_stats.append(schemas.StuckStats(
            category=category,
            stuck_count=data["stuck"],
            total_sessions=data["total"],
            stuck_percentage=round(stuck_percentage, 1)
        ))
    
    return sorted(stuck_stats, key=lambda x: x.stuck_percentage, reverse=True)

def get_completion_trends(db: Session, user_id: int, days: int = 30) -> List[schemas.CompletionTrend]:
    """Get completion trends over the last N days."""
    
    end_date = datetime.now().date()
    start_date = end_date - timedelta(days=days)
    
    # Get all tasks within the date range
    tasks = db.query(models.Task).join(models.TaskSession).filter(
        models.TaskSession.user_id == user_id,
        func.date(models.TaskSession.created_at) >= start_date,
        func.date(models.TaskSession.created_at) <= end_date
    ).all()
    
    # Group by date
    date_data = defaultdict(lambda: {"completed": 0, "total": 0})
    
    for task in tasks:
        date_str = task.session.created_at.strftime("%Y-%m-%d")
        date_data[date_str]["total"] += 1
        
        if task.status == "completed":
            date_data[date_str]["completed"] += 1
    
    # Convert to schema format
    trends = []
    current_date = start_date
    
    while current_date <= end_date:
        date_str = current_date.strftime("%Y-%m-%d")
        data = date_data[date_str]
        completion_rate = (data["completed"] / data["total"] * 100) if data["total"] > 0 else 0
        
        trends.append(schemas.CompletionTrend(
            date=date_str,
            completed_tasks=data["completed"],
            total_tasks=data["total"],
            completion_rate=round(completion_rate, 1)
        ))
        
        current_date += timedelta(days=1)
    
    return trends

def generate_personalized_insights(db: Session, user_id: int) -> List[schemas.PersonalizedInsight]:
    """Generate personalized insights based on user data and RL learning."""
    
    insights = []
    
    # Get user data
    quick_stats = get_quick_stats(db, user_id)
    category_stats = get_category_stats(db, user_id)
    time_stats = get_time_of_day_stats(db, user_id)
    
    # Add RL-based insights if available
    if HAS_ENHANCED_RL:
        try:
            rl_insights = enhanced_rl_handler.get_rl_insights(db, user_id)
            insights.extend(rl_insights)
        except Exception as e:
            print(f"Error getting RL insights: {e}")
    
    # Best performing category
    if category_stats:
        best_category = max(category_stats, key=lambda x: x.completion_rate)
        if best_category.completion_rate > 80:
            insights.append(schemas.PersonalizedInsight(
                type="pattern_recognition",
                title=f"You excel at {best_category.category} tasks!",
                description=f"You have a {best_category.completion_rate}% completion rate for {best_category.category} tasks. Consider scheduling more challenging tasks in this category.",
                confidence=0.9,
                category=best_category.category
            ))
    
    # Best time of day
    if time_stats:
        best_time = max(time_stats, key=lambda x: x.completion_rate)
        if best_time.completion_rate > 70:
            hour_str = f"{best_time.hour:02d}:00"
            insights.append(schemas.PersonalizedInsight(
                type="productivity_tip",
                title=f"Your peak productivity is at {hour_str}",
                description=f"You complete {best_time.completion_rate}% of tasks started at {hour_str}. Try scheduling important tasks during this time.",
                confidence=0.8,
                category="time_management"
            ))
    
    # Task duration preference
    if quick_stats.average_task_duration:
        if quick_stats.average_task_duration < 15:
            insights.append(schemas.PersonalizedInsight(
                type="recommendation",
                title="You prefer short, focused tasks",
                description="Your average task duration is under 15 minutes. Consider breaking larger goals into smaller, bite-sized tasks.",
                confidence=0.7,
                category="task_management"
            ))
        elif quick_stats.average_task_duration > 45:
            insights.append(schemas.PersonalizedInsight(
                type="recommendation",
                title="You work well with longer tasks",
                description="Your average task duration is over 45 minutes. You might benefit from deep work sessions and fewer task switches.",
                confidence=0.7,
                category="task_management"
            ))
    
    # Streak encouragement
    if quick_stats.current_streak > 5:
        insights.append(schemas.PersonalizedInsight(
            type="productivity_tip",
            title=f"Amazing streak! You're on day {quick_stats.current_streak}",
            description="Keep up the momentum! Research shows that consistency is key to building lasting habits.",
            confidence=0.95,
            category="motivation"
        ))
    
    # RL-based adaptive recommendations
    if HAS_ENHANCED_RL:
        try:
            # Check if RL handler has learned preferences
            rl_insights = enhanced_rl_handler.get_rl_insights(db, user_id)
            if rl_insights and isinstance(rl_insights, list) and len(rl_insights) > 0:
                insights.append(schemas.PersonalizedInsight(
                    type="recommendation",
                    title="AI-optimized task settings available",
                    description=f"Based on your success patterns, I've learned optimal settings for {len(rl_insights)} different contexts. These will be automatically applied to future breakdowns.",
                    confidence=0.85,
                    category="ai_learning"
                ))
        except Exception as e:
            print(f"Error getting adaptive preferences: {e}")
    
    # Enhanced hyper-personalization insights
    _add_advanced_behavioral_insights(db, user_id, insights)
    _add_completion_pattern_insights(db, user_id, insights)
    _add_momentum_insights(db, user_id, insights)
    _add_difficulty_adaptation_insights(db, user_id, insights)
    
    return insights

def _add_advanced_behavioral_insights(db: Session, user_id: int, insights: List[schemas.PersonalizedInsight]):
    """Add advanced behavioral pattern insights."""
    
    # Analyze task completion patterns by day of week
    sessions = db.query(models.TaskSession).filter(
        models.TaskSession.user_id == user_id
    ).all()
    
    if not sessions:
        return
    
    # Day-of-week completion patterns
    day_patterns = {}
    
    for session in sessions:
        day_name = session.created_at.strftime("%A")
        if day_name not in day_patterns:
            day_patterns[day_name] = {"completed": 0, "total": 0, "avg_duration": []}
        
        for task in session.tasks:
            day_patterns[day_name]["total"] += 1
            if task.status == "completed":
                day_patterns[day_name]["completed"] += 1
                if task.estimated_duration:
                    day_patterns[day_name]["avg_duration"].append(task.estimated_duration)
    
    # Find patterns
    best_days = sorted(day_patterns.keys(), 
                      key=lambda d: day_patterns[d]["completed"] / day_patterns[d]["total"] 
                      if day_patterns[d]["total"] > 0 else 0, reverse=True)
    
    if len(best_days) >= 2:
        best_day = best_days[0]
        best_rate = day_patterns[best_day]["completed"] / day_patterns[best_day]["total"]
        worst_day = best_days[-1]
        worst_rate = day_patterns[worst_day]["completed"] / day_patterns[worst_day]["total"]
        
        if best_rate - worst_rate > 0.3:  # Significant difference
            insights.append(schemas.PersonalizedInsight(
                type="pattern_recognition",
                title=f"Strong weekly productivity pattern detected",
                description=f"You're {((best_rate - worst_rate) * 100):.0f}% more productive on {best_day}s than {worst_day}s. Consider scheduling important tasks on {best_day}s.",
                confidence=0.8,
                category="weekly_patterns"
            ))

def _add_completion_pattern_insights(db: Session, user_id: int, insights: List[schemas.PersonalizedInsight]):
    """Add insights based on task completion patterns."""
    
    # Analyze task completion sequences
    sessions = db.query(models.TaskSession).filter(
        models.TaskSession.user_id == user_id
    ).order_by(models.TaskSession.created_at.desc()).limit(10).all()
    
    if not sessions:
        return
    
    # Analyze completion momentum
    incomplete_starts = 0
    complete_sessions = 0
    
    for session in sessions:
        completed_tasks = sum(1 for task in session.tasks if task.status == "completed")
        total_tasks = len(session.tasks)
        
        if completed_tasks == total_tasks and total_tasks > 0:
            complete_sessions += 1
        elif completed_tasks < total_tasks / 2:
            incomplete_starts += 1
    
    if incomplete_starts > 5:
        insights.append(schemas.PersonalizedInsight(
            type="recommendation",
            title="Consider smaller task sets",
            description="You've left several recent sessions incomplete. Try breaking goals into smaller, more manageable sets of 2-3 tasks.",
            confidence=0.75,
            category="task_sizing"
        ))
    elif complete_sessions > 7:
        insights.append(schemas.PersonalizedInsight(
            type="productivity_tip",
            title="Excellent completion consistency!",
            description="You've completed most of your recent sessions fully. You might be ready for slightly more challenging goals.",
            confidence=0.9,
            category="achievement"
        ))

def _add_momentum_insights(db: Session, user_id: int, insights: List[schemas.PersonalizedInsight]):
    """Add insights about user momentum and energy patterns."""
    
    # Get recent task completion times
    recent_tasks = db.query(models.Task).join(models.TaskSession).filter(
        models.TaskSession.user_id == user_id,
        models.Task.status == "completed"
    ).order_by(models.Task.id.desc()).limit(20).all()
    
    if len(recent_tasks) < 5:
        return
    
    # Analyze task completion speed vs estimated duration
    speed_ratios = []
    for task in recent_tasks:
        if task.estimated_duration and task.estimated_duration > 0:
            # This is a placeholder - in a real system, you'd track actual completion time
            # For now, we'll use a heuristic based on task characteristics
            speed_ratios.append(1.0)  # placeholder
    
    if len(speed_ratios) >= 5:
        avg_speed = sum(speed_ratios) / len(speed_ratios)
        if avg_speed < 0.8:  # Consistently faster than estimated
            insights.append(schemas.PersonalizedInsight(
                type="recommendation",
                title="You're faster than expected!",
                description="You consistently complete tasks quicker than estimated. Consider taking on more challenging tasks or increasing your daily goals.",
                confidence=0.7,
                category="performance_optimization"
            ))

def _add_difficulty_adaptation_insights(db: Session, user_id: int, insights: List[schemas.PersonalizedInsight]):
    """Add insights about task difficulty adaptation."""
    
    # Analyze feedback patterns
    recent_feedback = db.query(models.SessionFeedback).filter(
        models.SessionFeedback.user_id == user_id
    ).order_by(models.SessionFeedback.created_at.desc()).limit(10).all()
    
    if len(recent_feedback) < 3:
        return
    
    # Analyze feedback trends
    ratings = [feedback.rating for feedback in recent_feedback]
    avg_rating = sum(ratings) / len(ratings)
    
    if avg_rating > 4.5:
        insights.append(schemas.PersonalizedInsight(
            type="ai_learning",
            title="AI suggests increasing challenge level",
            description="Your consistently high session ratings suggest you're ready for more complex tasks. The AI will gradually increase task complexity in future breakdowns.",
            confidence=0.8,
            category="difficulty_adaptation"
        ))
    elif avg_rating < 2.5:
        insights.append(schemas.PersonalizedInsight(
            type="ai_learning",
            title="AI adjusting for better balance",
            description="Recent ratings suggest tasks may be too challenging. The AI will focus on simpler, more manageable breakdowns to rebuild confidence.",
            confidence=0.8,
            category="difficulty_adaptation"
        ))

def get_analytics_summary(db: Session, user_id: int) -> schemas.AnalyticsSummary:
    """Get comprehensive analytics summary for a user."""
    
    return schemas.AnalyticsSummary(
        quick_stats=get_quick_stats(db, user_id),
        category_stats=get_category_stats(db, user_id),
        time_of_day_stats=get_time_of_day_stats(db, user_id),
        stuck_stats=get_stuck_stats(db, user_id),
        completion_trends=get_completion_trends(db, user_id),
        personalized_insights=generate_personalized_insights(db, user_id)
    )

def get_analytics_performance(db: Session, user_id: int) -> schemas.AnalyticsPerformance:
    """Get performance analytics for a user."""
    
    time_stats = get_time_of_day_stats(db, user_id)
    category_stats = get_category_stats(db, user_id)
    quick_stats = get_quick_stats(db, user_id)
    
    # Find best time of day
    best_time = max(time_stats, key=lambda x: x.completion_rate) if time_stats else None
    
    # Get day of week performance (simplified for now)
    sessions = db.query(models.TaskSession).filter(
        models.TaskSession.user_id == user_id
    ).all()
    
    day_performance = defaultdict(lambda: {"completed": 0, "total": 0})
    
    for session in sessions:
        day_name = session.created_at.strftime("%A")
        for task in session.tasks:
            day_performance[day_name]["total"] += 1
            if task.status == "completed":
                day_performance[day_name]["completed"] += 1
    
    best_day = max(day_performance.keys(), 
                   key=lambda d: day_performance[d]["completed"] / day_performance[d]["total"] 
                   if day_performance[d]["total"] > 0 else 0) if day_performance else "Monday"
    
    # Determine preferred task size
    avg_duration = quick_stats.average_task_duration or 25
    if avg_duration < 20:
        preferred_size = "small"
    elif avg_duration < 45:
        preferred_size = "medium"
    else:
        preferred_size = "large"
    
    return schemas.AnalyticsPerformance(
        best_day_of_week=best_day,
        best_time_of_day=best_time.hour if best_time else 9,
        most_productive_duration=int(avg_duration),
        preferred_task_size=preferred_size,
        focus_patterns={
            "average_session_length": avg_duration,
            "completion_rate": quick_stats.overall_completion_rate,
            "streak_consistency": quick_stats.current_streak / max(quick_stats.longest_streak, 1)
        }
    ) 