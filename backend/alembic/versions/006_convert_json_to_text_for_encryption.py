"""Convert JSON columns to Text for field encryption support.

Revision ID: 006
Revises: 005
Create Date: 2026-02-16 00:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "006"
down_revision: Union[str, None] = "005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

JSON_COLUMNS = [
    "variants_json",
    "selected_variant_json",
    "spec_json",
    "patent_hits_json",
    "patent_draft_json",
    "prototype_json",
]


def upgrade() -> None:
    for col in JSON_COLUMNS:
        op.execute(
            sa.text(f'ALTER TABLE sessions ALTER COLUMN "{col}" TYPE TEXT USING "{col}"::text')
        )


def downgrade() -> None:
    for col in JSON_COLUMNS:
        op.execute(
            sa.text(f'ALTER TABLE sessions ALTER COLUMN "{col}" TYPE JSON USING "{col}"::json')
        )
