from pydantic import BaseModel, Field


# ── Legacy schemas (kept for backward compatibility) ──────────────────

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


# ── New: Professional patent analysis schemas ─────────────────────────

# -- Request --

class VariantRef(BaseModel):
    """Lightweight variant reference for analysis request."""
    title: str
    summary: str
    improvement_mode: str
    keywords: list[str]


class SpecRef(BaseModel):
    """Lightweight spec reference for analysis request."""
    novelty: str
    mechanism: str
    baseline: str
    differentiators: list[str]
    keywords: list[str]
    search_queries: list[str]


class PatentAnalysisRequest(BaseModel):
    product_text: str = Field(max_length=5000)
    variant: VariantRef
    spec: SpecRef
    limit: int = Field(default=15, ge=1, le=30)


# -- Step 1: Invention Analysis (LLM pre-search) --

class CpcSuggestion(BaseModel):
    code: str
    description: str
    rationale: str


class SearchStrategy(BaseModel):
    query: str
    approach: str  # function_words, technical_structure, use_case, synonyms
    target_field: str  # title, abstract


class InventionAnalysis(BaseModel):
    core_concept: str
    essential_elements: list[str]
    alternative_implementations: list[str]
    cpc_codes: list[CpcSuggestion]
    search_strategies: list[SearchStrategy]


# -- Step 2: Enhanced patent hits --

class EnhancedPatentHit(BaseModel):
    patent_id: str
    title: str
    abstract: str
    assignee: str | None = None
    date: str | None = None
    cpc_codes: list[str] = []
    score: float
    why_similar: str
    source_phase: str  # keyword, cpc, citation


class SearchMetadata(BaseModel):
    total_queries_run: int
    keyword_hits: int
    cpc_hits: int
    citation_hits: int
    duplicates_removed: int
    phases_completed: list[str]


# -- Step 3: Professional analysis (LLM post-search) --

class NoveltyAssessment(BaseModel):
    risk_level: str  # low, medium, high
    summary: str
    closest_reference: str | None = None
    missing_elements: list[str] = []


class ObviousnessAssessment(BaseModel):
    risk_level: str  # low, medium, high
    summary: str
    combination_refs: list[str] = []


class EligibilityNote(BaseModel):
    applies: bool
    summary: str


class PriorArtSummary(BaseModel):
    overall_risk: str  # low, medium, high
    narrative: str
    key_findings: list[str]


class ClaimStrategy(BaseModel):
    recommended_filing: str  # provisional, non_provisional, design_patent, defer, abandon
    rationale: str
    suggested_independent_claims: list[str] = []
    risk_areas: list[str] = []


# -- Full analysis response --

class PatentAnalysisResponse(BaseModel):
    invention_analysis: InventionAnalysis
    hits: list[EnhancedPatentHit]
    search_metadata: SearchMetadata
    novelty_assessment: NoveltyAssessment
    obviousness_assessment: ObviousnessAssessment
    eligibility_note: EligibilityNote
    prior_art_summary: PriorArtSummary
    claim_strategy: ClaimStrategy
    confidence: str  # low, med, high
    disclaimer: str
