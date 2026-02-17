"""Encrypt existing session data in-place.

Revision ID: 007
Revises: 006
Create Date: 2026-02-16 00:00:01.000000

"""
import logging
import os
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "007"
down_revision: Union[str, None] = "006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

log = logging.getLogger("mousetrap.migration_007")

FERNET_PREFIX = "gAAAAA"

TEXT_FIELDS = ["product_text", "title", "export_markdown", "export_plain_text"]
JSON_FIELDS = [
    "variants_json",
    "selected_variant_json",
    "spec_json",
    "patent_hits_json",
    "patent_draft_json",
    "prototype_json",
]
ALL_FIELDS = TEXT_FIELDS + JSON_FIELDS


def _get_fernet():
    """Build MultiFernet from env var. Returns None if not set."""
    from cryptography.fernet import Fernet, MultiFernet

    raw = os.environ.get("ENCRYPTION_KEYS", "").strip()
    if not raw:
        return None
    keys = [k.strip().encode() for k in raw.split(",") if k.strip()]
    return MultiFernet([Fernet(k) for k in keys])


def _encrypt(fernet, value):
    if value is None:
        return None
    if value.startswith(FERNET_PREFIX):
        return value  # already encrypted
    return fernet.encrypt(value.encode("utf-8")).decode("ascii")


def _decrypt(fernet, value):
    if value is None:
        return None
    if not value.startswith(FERNET_PREFIX):
        return value  # not encrypted
    return fernet.decrypt(value.encode("ascii")).decode("utf-8")


def upgrade() -> None:
    fernet = _get_fernet()
    if fernet is None:
        log.info("ENCRYPTION_KEYS not set — skipping data encryption migration")
        return

    conn = op.get_bind()
    rows = conn.execute(sa.text("SELECT id FROM sessions")).fetchall()
    encrypted_count = 0

    for (row_id,) in rows:
        row = conn.execute(
            sa.text("SELECT " + ", ".join(ALL_FIELDS) + " FROM sessions WHERE id = :id"),
            {"id": row_id},
        ).fetchone()

        updates = {}
        for i, field in enumerate(ALL_FIELDS):
            val = row[i]
            if val is not None and not val.startswith(FERNET_PREFIX):
                updates[field] = _encrypt(fernet, val)

        if updates:
            set_clause = ", ".join(f'"{k}" = :{k}' for k in updates)
            updates["id"] = row_id
            conn.execute(
                sa.text(f"UPDATE sessions SET {set_clause} WHERE id = :id"),
                updates,
            )
            encrypted_count += 1

    log.info("Encrypted %d session(s)", encrypted_count)


def downgrade() -> None:
    fernet = _get_fernet()
    if fernet is None:
        log.info("ENCRYPTION_KEYS not set — skipping data decryption migration")
        return

    conn = op.get_bind()
    rows = conn.execute(sa.text("SELECT id FROM sessions")).fetchall()
    decrypted_count = 0

    for (row_id,) in rows:
        row = conn.execute(
            sa.text("SELECT " + ", ".join(ALL_FIELDS) + " FROM sessions WHERE id = :id"),
            {"id": row_id},
        ).fetchone()

        updates = {}
        for i, field in enumerate(ALL_FIELDS):
            val = row[i]
            if val is not None and val.startswith(FERNET_PREFIX):
                updates[field] = _decrypt(fernet, val)

        if updates:
            set_clause = ", ".join(f'"{k}" = :{k}' for k in updates)
            updates["id"] = row_id
            conn.execute(
                sa.text(f"UPDATE sessions SET {set_clause} WHERE id = :id"),
                updates,
            )
            decrypted_count += 1

    log.info("Decrypted %d session(s)", decrypted_count)
