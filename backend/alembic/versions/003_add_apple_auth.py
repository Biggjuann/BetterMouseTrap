"""Add Apple Sign-In support: nullable password_hash, apple_user_id column.

Revision ID: 003
Revises: 002
Create Date: 2026-02-11 00:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Apple users won't have a password
    op.alter_column("users", "password_hash", existing_type=sa.String(255), nullable=True)

    # Store Apple's stable user identifier (the 'sub' claim)
    op.add_column("users", sa.Column("apple_user_id", sa.String(255), nullable=True))
    op.create_index("ix_users_apple_user_id", "users", ["apple_user_id"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_users_apple_user_id", table_name="users")
    op.drop_column("users", "apple_user_id")
    op.alter_column("users", "password_hash", existing_type=sa.String(255), nullable=False)
