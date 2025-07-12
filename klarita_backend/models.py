"""
Database Models for Klarita (Revamped)
Defines the SQLAlchemy models that represent the database structure.
"""

import enum
from sqlalchemy import (
    create_engine, Column, Integer, String, Text, Boolean, DateTime,
    ForeignKey, Enum, Float, JSON
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base

# Enum for task priority
class TaskPriority(enum.Enum):
    low = "low"
    medium = "medium"
    high = "high"

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    preferences = relationship("UserPreference", back_populates="user", uselist=False)
    sessions = relationship("TaskSession", back_populates="user")
    gamification = relationship("UserGamification", back_populates="user", uselist=False)
    memories = relationship("TaskMemory", back_populates="user")

class UserPreference(Base):
    __tablename__ = "user_preferences"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True)
    
    # Task Breakdown Preferences
    breakdown_style = Column(String, default="detailed") # e.g., "detailed", "simple", "step-by-step"
    preferred_task_duration = Column(Integer, default=25) # in minutes
    
    # Communication Style
    communication_style = Column(String, default="encouraging") # e.g., "direct", "gentle"
    
    # Relationships
    user = relationship("User", back_populates="preferences")

class TaskSession(Base):
    __tablename__ = "task_sessions"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    original_goal = Column(Text, nullable=False)
    
    # Status
    status = Column(String, default="pending") # pending, active, completed, archived
    
    # Context
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Feedback
    success_rating = Column(Integer) # 1-5 rating from user
    
    # Relationships
    user = relationship("User", back_populates="sessions")
    tasks = relationship("Task", back_populates="session", cascade="all, delete-orphan")

class Task(Base):
    __tablename__ = "tasks"
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("task_sessions.id"), nullable=False)
    
    title = Column(String, nullable=False)
    description = Column(Text)
    
    # AI-Generated Data
    estimated_duration = Column(Integer) # in minutes
    
    # User-Modified Data
    user_modified_duration = Column(Integer)
    
    # Status & Priority
    status = Column(String, default="pending") # pending, active, completed
    priority = Column(Enum(TaskPriority), default=TaskPriority.medium)
    
    # Relationships
    session = relationship("TaskSession", back_populates="tasks")

class UserGamification(Base):
    __tablename__ = "user_gamification"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True)
    
    points = Column(Integer, default=0)
    level = Column(Integer, default=1)
    current_streak = Column(Integer, default=0)
    longest_streak = Column(Integer, default=0)
    
    # Relationships
    user = relationship("User", back_populates="gamification")
    badges = relationship("EarnedBadge", back_populates="gamification_profile")

class Badge(Base):
    __tablename__ = "badges"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False)
    description = Column(Text)
    icon = Column(String)
    criteria = Column(JSON) # e.g., {"type": "streak", "value": 5}

class EarnedBadge(Base):
    __tablename__ = "earned_badges"
    id = Column(Integer, primary_key=True, index=True)
    gamification_profile_id = Column(Integer, ForeignKey("user_gamification.id"), nullable=False)
    badge_id = Column(Integer, ForeignKey("badges.id"), nullable=False)
    earned_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    badge = relationship("Badge")
    gamification_profile = relationship("UserGamification", back_populates="badges")

# New table for RAG memory
class TaskMemory(Base):
    __tablename__ = "task_memories"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    original_goal = Column(Text, nullable=False)
    task_breakdown = Column(JSON, nullable=False) # Stores the list of tasks as JSON
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationship
    user = relationship("User", back_populates="memories")

class SessionFeedback(Base):
    __tablename__ = "session_feedback"
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("task_sessions.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    # Reward signal – 1-5 rating (5 = highly successful)
    rating = Column(Integer, nullable=False)
    comments = Column(Text)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    session = relationship("TaskSession")
    user = relationship("User")
