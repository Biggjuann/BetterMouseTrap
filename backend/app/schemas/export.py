from pydantic import BaseModel, Field

from app.schemas.idea import IdeaSpec, IdeaVariant
from app.schemas.patent import PatentHit


class ProductInput(BaseModel):
    text: str = Field(max_length=5000)
    url: str | None = Field(default=None, max_length=2000)
    category: str | None = Field(default=None, max_length=100)


class ExportRequest(BaseModel):
    product: ProductInput
    variant: IdeaVariant
    spec: IdeaSpec
    hits: list[PatentHit]


class ExportResponse(BaseModel):
    markdown: str
    plain_text: str
