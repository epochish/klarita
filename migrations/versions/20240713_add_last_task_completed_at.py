"""add last_task_completed_at column to user_gamification

Revision ID: 20240713_add_last_task_completed_at
Revises: 
Create Date: 2025-07-13

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '8f1a20250713'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('user_gamification', sa.Column('last_task_completed_at', sa.DateTime(timezone=True), nullable=True))


def downgrade():
    op.drop_column('user_gamification', 'last_task_completed_at') 