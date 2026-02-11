import logging

from fastapi import APIRouter, Depends

from app.auth.dependencies import get_current_user

from app.core.config import settings
from app.schemas.patent import (
    EnhancedPatentHit,
    PatentAnalysisRequest,
    PatentAnalysisResponse,
    PatentHit,
    PatentSearchRequest,
    PatentSearchResponse,
)
from app.services.patent_analysis import run_patent_analysis
from app.services.patentsview import (
    build_query_payload,
    normalize_hits,
    search_patents as pv_search,
)
from app.services.scoring import compute_confidence, rerank_with_llm, score_hits_heuristic

log = logging.getLogger("mousetrap.routes_patents")

router = APIRouter(prefix="/patents", tags=["patents"], dependencies=[Depends(get_current_user)])


def _mock_hits(req: PatentSearchRequest) -> list[PatentHit]:
    return [
        PatentHit(
            patent_id=f"US{10000000 + i}",
            title=f"Mock Patent {i + 1}: {req.queries[0] if req.queries else 'device'} apparatus",
            abstract=f"An apparatus and method relating to {', '.join(req.keywords[:3])}. "
            f"This invention describes improvements in the field.",
            assignee="Example Corp",
            date="2023-01-15",
            score=round(0.55 - i * 0.08, 2),
            why_similar=f"Shares keywords: {', '.join(req.keywords[:2])}. "
            f"Addresses similar problem domain.",
        )
        for i in range(min(req.limit, 5))
    ]


@router.post("/search", response_model=PatentSearchResponse)
async def search_patents(req: PatentSearchRequest):
    """Search for prior-art patents via PatentsView, score, and optionally LLM-rerank."""

    # Fall back to mocks if no PatentsView API key
    if not settings.patentsview_api_key:
        log.warning("No PATENTSVIEW_API_KEY configured — returning mock hits")
        return PatentSearchResponse(hits=_mock_hits(req), confidence="low")

    # 1. Build query and call PatentsView
    payload = build_query_payload(
        queries=req.queries,
        keywords=req.keywords,
        limit=min(req.limit * 2, 50),  # fetch extra for reranking
    )
    raw = pv_search(payload)

    if not raw:
        log.warning("PatentsView returned no results")
        return PatentSearchResponse(hits=[], confidence="low")

    # 2. Normalize
    hits = normalize_hits(raw)

    # 3. Heuristic scoring
    hits = score_hits_heuristic(hits, req.keywords)

    # 4. Optional LLM rerank (only if we have an LLM key)
    has_llm_key = (
        (settings.llm_provider == "anthropic" and settings.anthropic_api_key)
        or (settings.llm_provider == "openai" and settings.openai_api_key)
    )
    if has_llm_key and len(hits) > 0:
        # We don't have the full spec here, so use queries + keywords as proxy
        hits = rerank_with_llm(
            hits=hits,
            spec_novelty=" ".join(req.queries),
            spec_mechanism="",
            spec_differentiators=req.keywords,
            top_n=min(10, len(hits)),
        )

    # 5. Trim to requested limit and compute confidence
    hits = hits[: req.limit]
    confidence = compute_confidence(hits)

    patent_hits = [
        PatentHit(
            patent_id=h["patent_id"],
            title=h["title"],
            abstract=h["abstract"],
            assignee=h.get("assignee"),
            date=h.get("date"),
            score=h["score"],
            why_similar=h["why_similar"],
        )
        for h in hits
    ]

    return PatentSearchResponse(hits=patent_hits, confidence=confidence)


# ── New: Professional Patent Analysis ────────────────────────────────

def _mock_analysis_response(req: PatentAnalysisRequest) -> PatentAnalysisResponse:
    """Return a mock analysis when no API keys are configured."""
    from app.schemas.patent import (
        ClaimStrategy,
        CpcSuggestion,
        EligibilityNote,
        InventionAnalysis,
        NoveltyAssessment,
        ObviousnessAssessment,
        PriorArtSummary,
        SearchMetadata,
        SearchStrategy,
    )

    mock_hits = [
        EnhancedPatentHit(
            patent_id=f"US{10000000 + i}",
            title=f"Mock Patent {i + 1}: {req.variant.title} related apparatus",
            abstract=f"An apparatus and method relating to {', '.join(req.variant.keywords[:3])}.",
            assignee="Example Corp",
            date="2023-06-15",
            cpc_codes=["A47J36/00"],
            score=round(0.55 - i * 0.08, 2),
            why_similar=f"Shares keywords: {', '.join(req.variant.keywords[:2])}. "
            "Addresses a similar problem domain.",
            source_phase="keyword" if i < 3 else "cpc",
        )
        for i in range(min(req.limit, 5))
    ]

    return PatentAnalysisResponse(
        invention_analysis=InventionAnalysis(
            core_concept=req.spec.novelty,
            essential_elements=req.spec.differentiators[:4],
            alternative_implementations=["Alternative approach using different materials"],
            cpc_codes=[CpcSuggestion(
                code="A47J36/02",
                description="Cooking vessels with integrated features",
                rationale="Relevant to the product category",
            )],
            search_strategies=[SearchStrategy(
                query=q,
                approach="use_case",
                target_field="abstract",
            ) for q in req.spec.search_queries[:3]],
        ),
        hits=mock_hits,
        search_metadata=SearchMetadata(
            total_queries_run=6,
            keyword_hits=3,
            cpc_hits=2,
            citation_hits=0,
            duplicates_removed=1,
            phases_completed=["keyword", "cpc"],
        ),
        novelty_assessment=NoveltyAssessment(
            risk_level="low",
            summary="Mock analysis — no real patents were searched. "
            "Configure API keys for real results.",
            closest_reference=None,
            missing_elements=req.spec.differentiators[:2],
        ),
        obviousness_assessment=ObviousnessAssessment(
            risk_level="low",
            summary="Mock analysis — configure API keys for real results.",
            combination_refs=[],
        ),
        eligibility_note=EligibilityNote(
            applies=False,
            summary="No §101 concerns for this type of consumer product.",
        ),
        prior_art_summary=PriorArtSummary(
            overall_risk="low",
            narrative="This is a mock analysis. Configure your PATENTSVIEW_API_KEY "
            "and LLM API key to get real patent search results and professional analysis.",
            key_findings=["Mock data — no real search performed"],
        ),
        claim_strategy=ClaimStrategy(
            recommended_filing="provisional",
            rationale="Mock recommendation. Real analysis requires API keys.",
            suggested_independent_claims=[],
            risk_areas=[],
        ),
        confidence="low",
        disclaimer="This is mock data. Configure API keys for real analysis. "
        "This does not constitute legal advice.",
    )


@router.post("/analyze", response_model=PatentAnalysisResponse)
async def analyze_patents(req: PatentAnalysisRequest):
    """Professional patent analysis: invention analysis → multi-phase search → assessment."""

    # Fall back to mocks if no API keys
    has_pv_key = bool(settings.patentsview_api_key)
    has_llm_key = (
        (settings.llm_provider == "anthropic" and settings.anthropic_api_key)
        or (settings.llm_provider == "openai" and settings.openai_api_key)
    )

    if not has_pv_key and not has_llm_key:
        log.warning("No API keys configured — returning mock analysis")
        return _mock_analysis_response(req)

    return await run_patent_analysis(req)
