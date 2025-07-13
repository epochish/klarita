"""
Nightly RL Training Script for Klarita
Performs automated reinforcement learning model fine-tuning based on accumulated user data.
"""

import os
import sys
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import desc

# Add the parent directory to the Python path to import our modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from klarita_backend import models, enhanced_rl_handler, analytics_handler
from klarita_backend.database import SessionLocal, engine

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('klarita_backend/logs/nightly_rl_training.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def get_users_for_training(db: Session, min_interactions: int = 5) -> List[int]:
    """Get users who have enough interactions for meaningful RL training."""
    
    # Get users with sufficient feedback data
    users_with_feedback = (
        db.query(models.SessionFeedback.user_id)
        .group_by(models.SessionFeedback.user_id)
        .having(db.func.count(models.SessionFeedback.id) >= min_interactions)
        .all()
    )
    
    return [user_id[0] for user_id in users_with_feedback]

def analyze_user_patterns(db: Session, user_id: int) -> Dict[str, Any]:
    """Analyze user patterns for RL training insights."""
    
    # Get recent session feedback
    recent_feedback = (
        db.query(models.SessionFeedback)
        .filter(models.SessionFeedback.user_id == user_id)
        .filter(models.SessionFeedback.created_at >= datetime.now() - timedelta(days=30))
        .order_by(desc(models.SessionFeedback.created_at))
        .all()
    )
    
    if not recent_feedback:
        return {}
    
    # Calculate key metrics
    total_sessions = len(recent_feedback)
    positive_feedback = len([fb for fb in recent_feedback if fb.rating >= 4])
    negative_feedback = len([fb for fb in recent_feedback if fb.rating <= 2])
    
    # Get user's task completion stats
    user_stats = analytics_handler.get_quick_stats(db, user_id)
    
    return {
        "user_id": user_id,
        "total_sessions": total_sessions,
        "positive_feedback": positive_feedback,
        "negative_feedback": negative_feedback,
        "success_rate": positive_feedback / total_sessions if total_sessions > 0 else 0,
        "completion_rate": user_stats.overall_completion_rate,
        "current_streak": user_stats.current_streak,
        "total_xp": user_stats.total_xp
    }

def train_user_rl_model(db: Session, user_id: int) -> Dict[str, Any]:
    """Perform RL training for a specific user."""
    
    logger.info(f"Training RL model for user {user_id}")
    
    # Get recent feedback to process
    recent_feedback = (
        db.query(models.SessionFeedback)
        .filter(models.SessionFeedback.user_id == user_id)
        .filter(models.SessionFeedback.created_at >= datetime.now() - timedelta(days=1))
        .all()
    )
    
    training_stats = {
        "user_id": user_id,
        "feedback_processed": 0,
        "q_value_updates": 0,
        "average_reward": 0.0,
        "errors": 0
    }
    
    total_reward = 0
    
    for feedback in recent_feedback:
        try:
            # Process feedback through enhanced RL system
            enhanced_rl_handler.rl_handler.process_feedback(
                db, user_id, feedback.session_id, feedback.rating
            )
            
            # Calculate reward for stats
            reward = enhanced_rl_handler.rl_handler.calculate_reward(
                db, feedback.session_id, feedback.rating
            )
            
            training_stats["feedback_processed"] += 1
            training_stats["q_value_updates"] += 1
            total_reward += reward
            
        except Exception as e:
            logger.error(f"Error processing feedback {feedback.id} for user {user_id}: {e}")
            training_stats["errors"] += 1
    
    # Calculate average reward
    if training_stats["feedback_processed"] > 0:
        training_stats["average_reward"] = total_reward / training_stats["feedback_processed"]
    
    # Save updated Q-table
    try:
        enhanced_rl_handler.rl_handler.save_q_table()
        logger.info(f"Q-table saved for user {user_id}")
    except Exception as e:
        logger.error(f"Error saving Q-table for user {user_id}: {e}")
        training_stats["errors"] += 1
    
    return training_stats

def generate_training_report(db: Session, training_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Generate a comprehensive training report."""
    
    if not training_results:
        return {"error": "No training results to report"}
    
    total_users = len(training_results)
    total_feedback = sum(result["feedback_processed"] for result in training_results)
    total_updates = sum(result["q_value_updates"] for result in training_results)
    total_errors = sum(result["errors"] for result in training_results)
    
    successful_users = [result for result in training_results if result["errors"] == 0]
    average_reward = sum(result["average_reward"] for result in training_results) / total_users
    
    # Get system-wide stats
    all_users = db.query(models.User).count()
    active_users = len(get_users_for_training(db, min_interactions=1))
    
    return {
        "timestamp": datetime.now().isoformat(),
        "total_users_trained": total_users,
        "total_feedback_processed": total_feedback,
        "total_q_value_updates": total_updates,
        "total_errors": total_errors,
        "successful_users": len(successful_users),
        "success_rate": len(successful_users) / total_users if total_users > 0 else 0,
        "average_reward": average_reward,
        "system_stats": {
            "total_users": all_users,
            "active_users": active_users,
            "training_coverage": total_users / active_users if active_users > 0 else 0
        },
        "user_results": training_results
    }

def optimize_rl_parameters(training_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Optimize RL parameters based on training results."""
    
    if not training_results:
        return {}
    
    # Calculate performance metrics
    avg_success_rate = sum(result.get("success_rate", 0) for result in training_results) / len(training_results)
    avg_reward = sum(result.get("average_reward", 0) for result in training_results) / len(training_results)
    
    # Basic parameter optimization heuristics
    optimizations = {}
    
    # Adjust learning rate based on convergence
    if avg_reward > 0.7:
        optimizations["learning_rate"] = "decrease"  # Stable learning, reduce learning rate
    elif avg_reward < 0.3:
        optimizations["learning_rate"] = "increase"  # Poor performance, increase learning rate
    
    # Adjust exploration rate based on success
    if avg_success_rate > 0.8:
        optimizations["epsilon"] = "decrease"  # Good performance, reduce exploration
    elif avg_success_rate < 0.4:
        optimizations["epsilon"] = "increase"  # Poor performance, increase exploration
    
    return optimizations

def main():
    """Main training function."""
    
    logger.info("Starting nightly RL training process")
    
    # Create database session
    db = SessionLocal()
    
    try:
        # Get users eligible for training
        users_for_training = get_users_for_training(db)
        logger.info(f"Found {len(users_for_training)} users eligible for training")
        
        if not users_for_training:
            logger.info("No users with sufficient data for training")
            return
        
        # Train each user's RL model
        training_results = []
        
        for user_id in users_for_training:
            try:
                # Analyze user patterns
                user_patterns = analyze_user_patterns(db, user_id)
                logger.info(f"User {user_id} patterns: {user_patterns}")
                
                # Train RL model
                training_stats = train_user_rl_model(db, user_id)
                training_results.append(training_stats)
                
                logger.info(f"Training completed for user {user_id}: {training_stats}")
                
            except Exception as e:
                logger.error(f"Error training user {user_id}: {e}")
                training_results.append({
                    "user_id": user_id,
                    "error": str(e),
                    "feedback_processed": 0,
                    "q_value_updates": 0,
                    "average_reward": 0.0,
                    "errors": 1
                })
        
        # Generate training report
        report = generate_training_report(db, training_results)
        logger.info(f"Training report: {report}")
        
        # Optimize RL parameters
        optimizations = optimize_rl_parameters(training_results)
        if optimizations:
            logger.info(f"Recommended optimizations: {optimizations}")
        
        # Save training report
        os.makedirs("klarita_backend/reports", exist_ok=True)
        report_filename = f"klarita_backend/reports/rl_training_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        import json
        with open(report_filename, 'w') as f:
            json.dump(report, f, indent=2)
        
        logger.info(f"Training report saved to {report_filename}")
        logger.info("Nightly RL training process completed successfully")
        
    except Exception as e:
        logger.error(f"Error in nightly RL training: {e}")
        raise
    
    finally:
        db.close()

if __name__ == "__main__":
    main() 