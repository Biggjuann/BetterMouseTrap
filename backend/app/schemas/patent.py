from pydantic import BaseModel, Field


class PatentSearchRequest(BaseModel):
    queries: list[str] = Field(max_length=20)
    keywords: list[str] = Field(max_length=50)
    limit: int = Field(default=10, ge=1, le=50)


class PatentHit(BaseModel):
    patent_id: str
    title: str
    abstract: str
    assignee: str | None = None
    date: str | None = None
    score: float
    why_similar: str


class PatentSearchResponse(BaseModel):
    hits: list[PatentHit]
    confidence: str  # low, med, high
