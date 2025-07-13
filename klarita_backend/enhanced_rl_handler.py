"""
Enhanced Reinforcement Learning Handler for Klarita
"""

import json
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional, Any
from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from collections import defaultdict, deque
import pickle
import os

from . import models, schemas

# RL Configuration
LEARNING_RATE = 0.1
DISCOUNT_FACTOR = 0.95
EPSILON = 0.1
REWARD_THRESHOLD = 4
STATE_HISTORY_SIZE = 50
ACTION_REWARD_DECAY = 0.95

class RLState:
    def __init__(self, user_id, time_of_day, task_category, session_complexity, user_mood="neutral"):
        self.user_id = user_id
        self.time_of_day = time_of_day
        self.task_category = task_category
        self.session_complexity = session_complexity
        self.user_mood = user_mood

    def to_key(self):
        return f"{self.user_id}_{self.time_of_day}_{self.task_category}_{self.session_complexity}_{self.user_mood}"

    def to_dict(self):
        return {
            "user_id": self.user_id,
            "time_of_day": self.time_of_day,
            "task_category": self.task_category,
            "session_complexity": self.session_complexity,
            "user_mood": self.user_mood
        }

class RLAction:
    def __init__(self, breakdown_style, task_duration, communication_style, task_count):
        self.breakdown_style = breakdown_style
        self.task_duration = task_duration
        self.communication_style = communication_style
        self.task_count = task_count

    def to_key(self):
        return f"{self.breakdown_style}_{self.task_duration}_{self.communication_style}_{self.task_count}"

    def to_dict(self):
        return {
            "breakdown_style": self.breakdown_style,
            "task_duration": self.task_duration,
            "communication_style": self.communication_style,
            "task_count": self.task_count
        }

class QTable:
    def __init__(self):
        self.q_values = defaultdict(lambda: defaultdict(float))
        self.state_visits = defaultdict(int)
        self.action_history = deque(maxlen=STATE_HISTORY_SIZE)

    def get_q_value(self, state, action):
        return self.q_values[state.to_key()][action.to_key()]

    def update_q_value(self, state, action, reward, next_state=None):
        state_key = state.to_key()
        action_key = action.to_key()
        
        current_q = self.q_values[state_key][action_key]
        
        if next_state:
            next_state_key = next_state.to_key()
            max_next_q = max(self.q_values[next_state_key].values()) if self.q_values[next_state_key] else 0
            new_q = current_q + LEARNING_RATE * (reward + DISCOUNT_FACTOR * max_next_q - current_q)
        else:
            new_q = current_q + LEARNING_RATE * (reward - current_q)
        
        self.q_values[state_key][action_key] = new_q
        self.state_visits[state_key] += 1
        
        self.action_history.append({
            "state": state_key,
            "action": action_key,
            "reward": reward,
            "timestamp": datetime.now()
        })

    def get_best_action(self, state, possible_actions):
        state_key = state.to_key()
        
        if np.random.random() < EPSILON:
            return np.random.choice(possible_actions)
        
        if state_key in self.q_values and self.q_values[state_key]:
            best_action_key = max(self.q_values[state_key].keys(), 
                                key=lambda k: self.q_values[state_key][k])
            
            for action in possible_actions:
                if action.to_key() == best_action_key:
                    return action
        
        return np.random.choice(possible_actions)

class EnhancedRLHandler:
    def __init__(self):
        self.q_table = QTable()
        self.load_q_table()

    def save_q_table(self):
        try:
            with open('q_table.pkl', 'wb') as f:
                pickle.dump(self.q_table, f)
        except Exception as e:
            print(f"Error saving Q-table: {e}")

    def load_q_table(self):
        try:
            if os.path.exists('q_table.pkl'):
                with open('q_table.pkl', 'rb') as f:
                    self.q_table = pickle.load(f)
        except Exception as e:
            print(f"Error loading Q-table: {e}")
            self.q_table = QTable()

    def get_current_state(self, db, user_id, goal):
        current_hour = datetime.now().hour
        
        task_category = "general"
        if "work" in goal.lower():
            task_category = "work"
        elif "study" in goal.lower():
            task_category = "study"
        elif "personal" in goal.lower():
            task_category = "personal"
        elif "exercise" in goal.lower():
            task_category = "health"
        
        recent_tasks = db.query(models.Task).filter(
            models.Task.user_id == user_id,
            models.Task.created_at > datetime.now() - timedelta(days=7)
        ).all()
        
        avg_completion_rate = 0.7
        if recent_tasks:
            completed_tasks = [t for t in recent_tasks if t.completed]
            avg_completion_rate = len(completed_tasks) / len(recent_tasks)
        
        session_complexity = "medium"
        if avg_completion_rate > 0.8:
            session_complexity = "high"
        elif avg_completion_rate < 0.5:
            session_complexity = "low"
        
        return RLState(user_id, current_hour, task_category, session_complexity)

    def get_possible_actions(self, db, user_id):
        breakdown_styles = ["detailed", "concise", "visual", "step-by-step"]
        durations = [15, 25, 45, 60]
        communication_styles = ["encouraging", "direct", "gentle", "motivational"]
        task_counts = [3, 5, 7, 10]
        
        actions = []
        for style in breakdown_styles:
            for duration in durations:
                for comm_style in communication_styles:
                    for count in task_counts:
                        actions.append(RLAction(style, duration, comm_style, count))
        
        return actions

    def recommend_action(self, db, user_id, goal):
        current_state = self.get_current_state(db, user_id, goal)
        possible_actions = self.get_possible_actions(db, user_id)
        
        best_action = self.q_table.get_best_action(current_state, possible_actions)
        
        self.last_state = current_state
        self.last_action = best_action
        
        return best_action

    def calculate_reward(self, db, session_id, rating):
        session = db.query(models.Task).filter(models.Task.id == session_id).first()
        
        if not session:
            return 0.0
        
        base_reward = (rating - 3) * 0.5
        
        completion_bonus = 0.0
        if hasattr(session, 'completed') and session.completed:
            completion_bonus = 0.5
        
        time_bonus = 0.0
        
        streak_bonus = 0.0
        user = db.query(models.User).filter(models.User.id == session.user_id).first()
        if user and hasattr(user, 'streak_days') and user.streak_days > 0:
            streak_bonus = min(user.streak_days * 0.1, 0.5)
        
        penalty = 0.0
        if rating <= 2:
            penalty = -0.5
        
        total_reward = base_reward + completion_bonus + time_bonus + streak_bonus + penalty
        
        return max(-1.0, min(1.0, total_reward))

    def process_feedback(self, db, user_id, session_id, rating):
        if not hasattr(self, 'last_state') or not hasattr(self, 'last_action'):
            return
        
        reward = self.calculate_reward(db, session_id, rating)
        
        current_state = self.get_current_state(db, user_id, "general")
        
        self.q_table.update_q_value(
            self.last_state,
            self.last_action,
            reward,
            current_state
        )
        
        self.save_q_table()
        
        if hasattr(self, 'last_state'):
            delattr(self, 'last_state')
        if hasattr(self, 'last_action'):
            delattr(self, 'last_action')

    def generate_rl_insights(self, db, user_id):
        insights = []
        
        user_states = [key for key in self.q_table.q_values.keys() if key.startswith(f"{user_id}_")]
        
        if not user_states:
            return insights
        
        best_patterns = {}
        for state_key in user_states:
            if self.q_table.q_values[state_key]:
                q_values_dict = self.q_table.q_values[state_key]
                best_action_key = max(q_values_dict.keys(), key=lambda k: q_values_dict[k])
                best_patterns[state_key] = {
                    "action": best_action_key,
                    "q_value": q_values_dict[best_action_key],
                    "visits": self.q_table.state_visits[state_key]
                }
        
        if best_patterns:
            best_overall = max(best_patterns.values(), key=lambda x: x["q_value"])
            action_parts = best_overall["action"].split('_')
            
            if len(action_parts) >= 4:
                insights.append(schemas.PersonalizedInsight(
                    id=f"rl_best_pattern_{user_id}",
                    insight_type="pattern",
                    title="Your Most Successful Pattern",
                    description=f"You perform best with {action_parts[0]} breakdowns, {action_parts[1]}-minute tasks, and {action_parts[2]} communication style.",
                    confidence=min(best_overall["q_value"] * 100, 95),
                    actionable_tip=f"Try using {action_parts[0]} breakdowns for your next session.",
                    data_source="reinforcement_learning"
                ))
        
        return insights

# Global RL handler instance
rl_handler = EnhancedRLHandler()

def process_feedback(db, user_id, session_id=None, rating=None):
    if session_id and rating:
        rl_handler.process_feedback(db, user_id, session_id, rating)

def get_rl_recommendations(db, user_id, goal):
    action = rl_handler.recommend_action(db, user_id, goal)
    return action.to_dict()

def get_rl_insights(db, user_id):
    return rl_handler.generate_rl_insights(db, user_id) 