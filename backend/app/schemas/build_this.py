from pydantic import BaseModel

from app.schemas.idea import IdeaSpec, IdeaVariant
from app.schemas.patent import PatentHit


class ProvisionalPatentRequest(BaseModel):
    product_text: str
    variant: IdeaVariant
    spec: IdeaSpec
    hits: list[PatentHit]


# ── USPTO Provisional Patent Response Models ──────────────────────────

class CoverSheet(BaseModel):
    invention_title: str
    filing_date_note: str


class Background(BaseModel):
    field_of_invention: str
    description_of_prior_art: str


class Specification(BaseModel):
    title_of_invention: str
    cross_reference: str | None = None
    background: Background
    summary: str
    brief_description_of_drawings: str | None = None
    detailed_description: str


class ProvisionalPatentResponse(BaseModel):
    cover_sheet: CoverSheet
    specification: Specification
    abstract: str
    claims: dict  # {independent: [...], dependent: [...]}
    drawings_note: str
    markdown: str
