from pydantic import BaseModel, Field


class GenerateIdeasRequest(BaseModel):
    text: str = Field(max_length=5000)
    category: str | None = Field(default=None, max_length=100)
    random: bool = False
    guided_context: dict | None = None


class IdeaScores(BaseModel):
    urgency: int = 0
    differentiation: int = 0
    speed_to_revenue: int = 0
    margin: int = 0
    defensibility: int = 0
    distribution: int = 0


class CustomerTruth(BaseModel):
    buyer: str = ""
    job_to_be_done: str = ""
    purchase_drivers: list[str] = []
    complaints: list[str] = []


class IdeaVariant(BaseModel):
    id: str
    title: str
    summary: str
    improvement_mode: str = "mashup"
    keywords: list[str] = []
    # Sellable Ideas Engine fields
    tier: str = "upgrade"  # top, moonshot, upgrade, adjacent, recurring
    one_line_pitch: str | None = None
    target_customer: str | None = None
    core_problem: str | None = None
    solution: str | None = None
    why_it_wins: list[str] = []
    monetization: str | None = None
    unit_economics: str | None = None
    defensibility_note: str | None = None
    mvp_90_days: str | None = None
    go_to_market: list[str] = []
    risks: list[str] = []
    scores: IdeaScores | None = None


class GenerateIdeasResponse(BaseModel):
    variants: list[IdeaVariant]
    customer_truth: CustomerTruth | None = None


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
