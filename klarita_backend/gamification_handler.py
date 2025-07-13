"""
Handles the gamification logic for Klarita.
"""
from sqlalchemy.orm import Session
from . import models

POINTS_PER_TASK = 10
LEVEL_THRESHOLD = 100  # Points needed to level up

def on_task_completed(db: Session, user: models.User, task: models.Task):
    """
    This function is called when a task is marked as complete.
    It awards points to the user and handles leveling up.
    """
    gamification_profile = user.gamification
    if not gamification_profile:
        # Should not happen if profile is created on user creation/first access
        gamification_profile = models.UserGamification(user_id=user.id)
        db.add(gamification_profile)

    # 1. Award points
    gamification_profile.points += POINTS_PER_TASK

    # 2. Check for level up
    if gamification_profile.points >= LEVEL_THRESHOLD:
        gamification_profile.level += 1
        gamification_profile.points -= LEVEL_THRESHOLD  # Reset points for the new level

    print(f"User {user.email} completed task '{task.title}'. Awarded {POINTS_PER_TASK} points. New level: {gamification_profile.level}, New points: {gamification_profile.points}")
    
    db.commit() 