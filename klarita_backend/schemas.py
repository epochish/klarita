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

class TaskReorderRequest(BaseModel):
    ordered_task_ids: List[int]

class TaskMergeRequest(BaseModel):
    task_ids: List[int] = Field(..., min_items=2, description="IDs of tasks to merge")

# ==================================
# Analytics Schemas
# ==================================

class CategoryStats(BaseModel):
    category: str
    completed_tasks: int
    total_tasks: int
    completion_rate: float
    average_duration: Optional[float] = None

class TimeOfDayStats(BaseModel):
    hour: int
    completed_tasks: int
    total_tasks: int
    completion_rate: float
    average_duration: Optional[float] = None

class CompletionTrend(BaseModel):
    date: str
    completed_tasks: int
    total_tasks: int
    completion_rate: float

class StuckStats(BaseModel):
    category: str
    stuck_count: int
    total_sessions: int
    stuck_percentage: float

class QuickStats(BaseModel):
    total_tasks_completed: int
    total_tasks_created: int
    overall_completion_rate: float
    average_task_duration: Optional[float] = None
    current_streak: int
    longest_streak: int
    total_xp: int
    current_level: int

class PersonalizedInsight(BaseModel):
    type: str  # "productivity_tip", "pattern_recognition", "recommendation"
    title: str
    description: str
    confidence: float = Field(..., ge=0.0, le=1.0)
    category: Optional[str] = None

class AnalyticsSummary(BaseModel):
    quick_stats: QuickStats
    category_stats: List[CategoryStats]
    time_of_day_stats: List[TimeOfDayStats]
    stuck_stats: List[StuckStats]
    completion_trends: List[CompletionTrend]
    personalized_insights: List[PersonalizedInsight]

class AnalyticsTrends(BaseModel):
    period: str  # "week", "month", "quarter"
    trends: List[CompletionTrend]
    streak_history: List[Dict[str, Any]]

class AnalyticsPerformance(BaseModel):
    best_day_of_week: str
    best_time_of_day: int
    most_productive_duration: int
    preferred_task_size: str  # "small", "medium", "large"
    focus_patterns: Dict[str, Any]
