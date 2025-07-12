from sqlalchemy.orm import Session
from sqlalchemy.sql import func
from . import models

"""Simple reinforcement-learning heuristic that updates a user's stored preferences
based on accumulated SessionFeedback ratings and associated task statistics.
This is a lightweight placeholder until we swap in a more sophisticated RL model.
"""

AVG_SAMPLE_SIZE = 10  # number of latest feedback records to consider


def process_feedback(db: Session, user_id: int):
    """Aggregate recent feedback and update UserPreference rows.

    Heuristic rules:
    • preferred_task_duration becomes the median estimated_duration of tasks in
      sessions with rating ≥4 (success) among last AVG_SAMPLE_SIZE feedbacks.
    • breakdown_style toggles to "simple" if average task count > 10 and rating ≤3,
      else stays/sets to "detailed".
    """

    # Ensure preference row exists
    pref = db.query(models.UserPreference).filter(models.UserPreference.user_id == user_id).first()
    if not pref:
        pref = models.UserPreference(user_id=user_id)
        db.add(pref)
        db.commit()
        db.refresh(pref)

    # Get recent feedbacks
    feedbacks = (
        db.query(models.SessionFeedback)
        .filter(models.SessionFeedback.user_id == user_id)
        .order_by(models.SessionFeedback.created_at.desc())
        .limit(AVG_SAMPLE_SIZE)
        .all()
    )

    if not feedbacks:
        return  # nothing to learn yet

    # Collect successful session ids & ratings
    successful_session_ids = [fb.session_id for fb in feedbacks if fb.rating >= 4]

    if successful_session_ids:
        # Compute median task duration across successful sessions
        durations = (
            db.query(models.Task.estimated_duration)
            .join(models.TaskSession)
            .filter(models.Task.session_id.in_(successful_session_ids))
            .filter(models.Task.estimated_duration.isnot(None))
            .all()
        )
        duration_values = [d[0] for d in durations if d[0] is not None]
        if duration_values:
            duration_values.sort()
            median = duration_values[len(duration_values)//2]
            pref.preferred_task_duration = median

    # Evaluate breakdown style heuristic
    avg_rating = sum(fb.rating for fb in feedbacks) / len(feedbacks)
    # Average task count in recent sessions
    task_counts = (
        db.query(func.count(models.Task.id))
        .join(models.TaskSession)
        .filter(models.TaskSession.user_id == user_id)
        .group_by(models.Task.session_id)
        .order_by(models.Task.session_id.desc())
        .limit(len(feedbacks))
        .all()
    )
    avg_task_count = sum(tc[0] for tc in task_counts) / len(task_counts) if task_counts else 0

    if avg_rating <= 3 and avg_task_count > 10:
        pref.breakdown_style = "simple"
    else:
        pref.breakdown_style = "detailed"

    db.commit() 