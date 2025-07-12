"""
Pydantic Schemas for Klarita API (Revamped)
Defines the data shapes for API requests and responses.
"""

from pydantic import BaseModel, Field, EmailStr
from typing import List, Optional, Dict, Any
from datetime import datetime
from .models import TaskPriority

# ==================================
# Base & Shared Schemas
# ==================================

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

# ==================================
# User & Preferences Schemas
# ==================================

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class UserPreference(BaseModel):
    breakdown_style: str = "detailed"
    preferred_task_duration: int = 25
    communication_style: str = "encouraging"

    class Config:
        from_attributes = True

# ==================================
# Task & Session Schemas
# ==================================

class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    estimated_duration: Optional[int] = None
    priority: TaskPriority = TaskPriority.medium

class Task(TaskBase):
    id: int
    status: str

    class Config:
        from_attributes = True

class TaskSessionBase(BaseModel):
    original_goal: str

class TaskSession(TaskSessionBase):
    id: int
    status: str
    created_at: datetime
    tasks: List[Task] = []

    class Config:
        from_attributes = True

# Request model for starting a new breakdown
class BreakdownInitiateRequest(BaseModel):
    goal: str

# New schema for RAG memory
class TaskMemory(BaseModel):
    id: int
    original_goal: str
    task_breakdown: List[Task]

    class Config:
        from_attributes = True

# ==================================
# Gamification Schemas
# ==================================

class Badge(BaseModel):
    name: str
    description: str
    icon: str

    class Config:
        from_attributes = True

class UserGamification(BaseModel):
    points: int
    level: int
    current_streak: int
    longest_streak: int
    badges: List[Badge] = []

    class Config:
        from_attributes = True

# ==================================
# "Feeling Stuck" Coach Schemas
# ==================================

class StuckCoachRequest(BaseModel):
    session_id: Optional[int] = None # Optional existing session
    message: str

class StuckCoachResponse(BaseModel):
    session_id: int
    ai_response: str
    suggested_actions: List[str] = []

# ==================================
# Feedback / RL Schemas
# ==================================

class SessionFeedbackCreate(BaseModel):
    rating: int = Field(..., ge=1, le=5)
    comments: Optional[str] = None

class SessionFeedback(SessionFeedbackCreate):
    id: int
    session_id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    estimated_duration: Optional[int] = Field(None, ge=1)
    priority: Optional[TaskPriority] = None

    class Config:
        from_attributes = True
