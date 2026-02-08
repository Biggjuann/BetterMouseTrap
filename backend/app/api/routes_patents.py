import logging

from fastapi import APIRouter, Depends

from app.auth.dependencies import get_current_user

from app.core.config import settings
from app.schemas.patent import PatentHit, PatentSearchRequest, PatentSearchResponse
from app.services.patentsview import (
    build_query_payload,
    normalize_hits,
    search_patents as pv_search,
)
from app.services.scoring import compute_confidence, rerank_with_llm, score_hits_heuristic

log = logging.getLogger("better_mousetrap.routes_patents")

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
