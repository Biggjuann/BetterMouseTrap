"""Add sessions table for save/history.

Revision ID: 002
Revises: 001
Create Date: 2026-02-08 00:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "sessions",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("product_text", sa.Text(), nullable=False),
        sa.Column("product_url", sa.Text(), nullable=True),
        sa.Column("variants_json", sa.JSON(), nullable=True),
        sa.Column("selected_variant_json", sa.JSON(), nullable=True),
        sa.Column("spec_json", sa.JSON(), nullable=True),
        sa.Column("patent_hits_json", sa.JSON(), nullable=True),
        sa.Column("patent_confidence", sa.String(10), nullable=True),
        sa.Column("export_markdown", sa.Text(), nullable=True),
        sa.Column("export_plain_text", sa.Text(), nullable=True),
        sa.Column("patent_draft_json", sa.JSON(), nullable=True),
        sa.Column("prototype_json", sa.JSON(), nullable=True),
        sa.Column("status", sa.String(30), nullable=False, server_default="started"),
        sa.Column("title", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
    )
    op.create_index("ix_sessions_user_id", "sessions", ["user_id"])
    op.create_index("ix_sessions_updated_at", "sessions", ["updated_at"])


def downgrade() -> None:
    op.drop_table("sessions")
