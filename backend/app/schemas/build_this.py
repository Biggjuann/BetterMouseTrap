from pydantic import BaseModel

from app.schemas.idea import IdeaSpec, IdeaVariant
from app.schemas.patent import PatentHit


class ProvisionalPatentRequest(BaseModel):
    product_text: str
    variant: IdeaVariant
    spec: IdeaSpec
    hits: list[PatentHit]


class ProvisionalPatentResponse(BaseModel):
    title: str
    abstract: str
    claims: dict  # {independent: [...], dependent: [...]}
    detailed_description: str
    prior_art_discussion: str
    markdown: str


class BomItem(BaseModel):
    item: str
    quantity: str
    estimated_cost: str
    source: str


class PrototypingApproach(BaseModel):
    method: str
    rationale: str
    specs: dict
    bill_of_materials: list[BomItem]
    assembly_instructions: list[str]


class PrototypingRequest(BaseModel):
    product_text: str
    variant: IdeaVariant
    spec: IdeaSpec


class PrototypingResponse(BaseModel):
    approaches: list[PrototypingApproach]
    markdown: str
