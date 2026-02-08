from pydantic import BaseModel, Field


class GenerateIdeasRequest(BaseModel):
    text: str = Field(max_length=5000)
    category: str | None = Field(default=None, max_length=100)
    random: bool = False


class IdeaVariant(BaseModel):
    id: str
    title: str
    summary: str
    improvement_mode: str  # cost_down, durability, safety, convenience, sustainability, performance, mashup
    keywords: list[str]


class GenerateIdeasResponse(BaseModel):
    variants: list[IdeaVariant]


class GenerateSpecRequest(BaseModel):
    product_text: str = Field(max_length=5000)
    variant_id: str = Field(max_length=100)
    variant: IdeaVariant


class IdeaSpec(BaseModel):
    novelty: str
    mechanism: str
    baseline: str
    differentiators: list[str]
    keywords: list[str]
    search_queries: list[str]
    disclaimer: str


class GenerateSpecResponse(BaseModel):
    spec: IdeaSpec
