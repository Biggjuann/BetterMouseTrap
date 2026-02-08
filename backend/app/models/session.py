import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.user import Base


class Session(Base):
    __tablename__ = "sessions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    product_text: Mapped[str] = mapped_column(Text, nullable=False)
    product_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    variants_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    selected_variant_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    spec_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    patent_hits_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    patent_confidence: Mapped[str | None] = mapped_column(String(10), nullable=True)
    export_markdown: Mapped[str | None] = mapped_column(Text, nullable=True)
    export_plain_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    patent_draft_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    prototype_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    status: Mapped[str] = mapped_column(String(30), nullable=False, server_default="started")
    title: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
