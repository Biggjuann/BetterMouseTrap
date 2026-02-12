"""Patent analysis orchestrator — professional 4-step workflow.

Step 1: LLM invention analysis (understand before searching)
Step 2: Multi-phase PatentsView search (keyword + CPC + broad)
Step 3: Heuristic scoring + deduplication
Step 4: LLM professional analysis (novelty, obviousness, claim strategy)
"""

import asyncio
import logging

from app.schemas.patent import (
    ClaimStrategy,
    CpcSuggestion,
    EligibilityNote,
    EnhancedPatentHit,
    InventionAnalysis,
    NoveltyAssessment,
    ObviousnessAssessment,
    PatentAnalysisRequest,
    PatentAnalysisResponse,
    PriorArtSummary,
    SearchMetadata,
    SearchStrategy,
)
from app.services.llm import LLMError, call_llm_async
from app.services.patentsview import (
    deduplicate_hits,
    search_cpc_async,
    search_keyword_async,
    search_keyword_broad_async,
    search_keyword_focused_async,
)
from app.services.prompts import (
    INVENTION_ANALYSIS_SCHEMA,
    INVENTION_ANALYSIS_SYSTEM,
    PROFESSIONAL_ANALYSIS_SCHEMA,
    PROFESSIONAL_ANALYSIS_SYSTEM,
    build_invention_analysis_prompt,
    build_professional_analysis_prompt,
)
from app.services.scoring import score_hits_heuristic

log = logging.getLogger("mousetrap.patent_analysis")


async def run_patent_analysis(req: PatentAnalysisRequest) -> PatentAnalysisResponse:
    """Execute the full 4-step patent analysis workflow."""

    # ── Step 1: LLM Invention Analysis ───────────────────────────────
    log.info("Step 1: Running invention analysis via LLM")
    invention = await _step1_invention_analysis(req)

    # ── Step 2: Multi-phase patent search ────────────────────────────
    log.info("Step 2: Running multi-phase patent search")
    all_hits, metadata = await _step2_multi_phase_search(req, invention)

    # ── Step 3: Heuristic scoring + dedup ────────────────────────────
    log.info("Step 3: Scoring and deduplicating %d hits", len(all_hits))
    all_hits, dups_removed = deduplicate_hits(all_hits)
    metadata_dict = {
        "total_queries_run": metadata["total_queries"],
        "keyword_hits": metadata["keyword_hits"],
        "cpc_hits": metadata["cpc_hits"],
        "citation_hits": 0,
        "duplicates_removed": dups_removed,
        "phases_completed": metadata["phases"],
    }

    # Combine all keywords for scoring — include product text, essential elements,
    # and baseline product terms so existing products score properly
    extra_kw = invention.get("essential_elements", [])
    # Split product_text into individual words for keyword matching
    product_words = [w for w in req.product_text.split() if len(w) > 2]
    all_keywords = list(dict.fromkeys(
        product_words + req.variant.keywords + req.spec.keywords + extra_kw
    ))
    scored = score_hits_heuristic(all_hits, all_keywords)
    scored = scored[: max(req.limit, 25)]

    # ── Step 4: LLM Professional Analysis ────────────────────────────
    log.info("Step 4: Running professional analysis via LLM on %d hits", len(scored))
    analysis = await _step4_professional_analysis(req, invention, scored)

    # ── Build response ───────────────────────────────────────────────
    inv_analysis = _parse_invention_analysis(invention)
    enhanced_hits = _build_enhanced_hits(scored, analysis)
    search_meta = SearchMetadata(**metadata_dict)

    return PatentAnalysisResponse(
        invention_analysis=inv_analysis,
        hits=enhanced_hits,
        search_metadata=search_meta,
        novelty_assessment=_parse_novelty(analysis),
        obviousness_assessment=_parse_obviousness(analysis),
        eligibility_note=_parse_eligibility(analysis),
        prior_art_summary=_parse_prior_art_summary(analysis),
        claim_strategy=_parse_claim_strategy(analysis),
        confidence=_compute_confidence(scored),
        disclaimer=analysis.get(
            "disclaimer",
            "This is an automated preliminary analysis and does not constitute legal advice. "
            "This search is not exhaustive. Consult a registered patent attorney for a "
            "professional patentability opinion.",
        ),
    )


# ── Step 1: Invention Analysis ───────────────────────────────────────

async def _step1_invention_analysis(req: PatentAnalysisRequest) -> dict:
    """Ask the LLM to analyze the invention before searching."""
    prompt = build_invention_analysis_prompt(
        product_text=req.product_text,
        variant_title=req.variant.title,
        variant_summary=req.variant.summary,
        variant_keywords=req.variant.keywords,
        spec_novelty=req.spec.novelty,
        spec_mechanism=req.spec.mechanism,
        spec_baseline=req.spec.baseline,
        spec_differentiators=req.spec.differentiators,
        spec_keywords=req.spec.keywords,
    )
    try:
        return await call_llm_async(
            prompt, json_schema_hint=INVENTION_ANALYSIS_SCHEMA, system=INVENTION_ANALYSIS_SYSTEM
        )
    except LLMError as exc:
        log.warning("Invention analysis LLM call failed: %s. Using fallback.", exc)
        return _fallback_invention_analysis(req)


def _fallback_invention_analysis(req: PatentAnalysisRequest) -> dict:
    """Fallback when LLM is unavailable — use spec data directly."""
    strategies = [
        # Always include baseline product search
        {"query": req.product_text, "approach": "baseline_product", "target_field": "title"},
        {"query": req.variant.title, "approach": "baseline_product", "target_field": "title"},
    ]
    strategies.extend([
        {"query": q, "approach": "use_case", "target_field": "abstract"}
        for q in req.spec.search_queries[:6]
    ])
    return {
        "core_concept": req.spec.novelty,
        "essential_elements": req.spec.differentiators,
        "alternative_implementations": [],
        "cpc_codes": [],
        "search_strategies": strategies,
    }


# ── Step 2: Multi-phase search ───────────────────────────────────────

async def _step2_multi_phase_search(
    req: PatentAnalysisRequest, invention: dict
) -> tuple[list[dict], dict]:
    """Run broad keyword + focused keyword + CPC searches in parallel."""
    metadata = {
        "total_queries": 0,
        "keyword_hits": 0,
        "cpc_hits": 0,
        "phases": [],
    }
    all_hits: list[dict] = []

    # Phase A: Baseline product search (MOST IMPORTANT — finds existing products)
    # Search for the base product category using simple consumer terms
    strategies = invention.get("search_strategies", [])
    keyword_tasks = []

    # A1: Direct product text search — the most obvious thing to search
    product_text = req.product_text.strip()
    if product_text and len(product_text) > 2:
        keyword_tasks.append(search_keyword_broad_async(product_text, limit=30))
        # Also search title specifically for the product category
        keyword_tasks.append(search_keyword_async(product_text, "title", limit=30))

    # A2: Baseline product queries from LLM strategies
    baseline_queries = [
        s.get("query", "") for s in strategies
        if s.get("approach") == "baseline_product" and s.get("query", "")
    ]
    for q in baseline_queries[:4]:
        keyword_tasks.append(search_keyword_async(q, "title", limit=25))

    # Phase B: Novelty-focused searches (LLM strategies)
    non_baseline = [
        s for s in strategies
        if s.get("approach") != "baseline_product"
    ]
    for s in non_baseline[:8]:
        query = s.get("query", "")
        target = s.get("target_field", "abstract")
        if query:
            keyword_tasks.append(search_keyword_async(query, target, limit=25))

    # Phase C: Focused keyword searches (precision, _text_all)
    # Uses spec search queries — require all words to appear
    spec_queries = req.spec.search_queries
    for q in spec_queries[:4]:
        if q:
            keyword_tasks.append(search_keyword_focused_async(q, limit=25))

    # Phase D: Broad keyword sweep using specific terms
    _generic = {"system", "method", "device", "apparatus", "process", "tool",
                "machine", "unit", "module", "assembly", "platform", "product",
                "application", "interface", "mechanism", "component", "element"}
    specific_kw = [
        kw for kw in dict.fromkeys(req.variant.keywords + req.spec.keywords)
        if kw.lower() not in _generic and len(kw) > 3
    ][:6]
    if specific_kw:
        broad_query = " ".join(specific_kw)
        keyword_tasks.append(search_keyword_broad_async(broad_query, limit=25))

    if keyword_tasks:
        metadata["total_queries"] += len(keyword_tasks)
        keyword_results = await asyncio.gather(*keyword_tasks, return_exceptions=True)
        for result in keyword_results:
            if isinstance(result, list):
                all_hits.extend(result)
                metadata["keyword_hits"] += len(result)
            elif isinstance(result, Exception):
                log.warning("Keyword search failed: %s", result)
        metadata["phases"].append("keyword")

    # Phase C: CPC classification searches (up to 5 codes)
    cpc_codes = invention.get("cpc_codes", [])
    cpc_tasks = []
    for cpc in cpc_codes[:5]:
        code = cpc.get("code", "") if isinstance(cpc, dict) else str(cpc)
        if code:
            cpc_tasks.append(search_cpc_async(code, limit=25))

    if cpc_tasks:
        metadata["total_queries"] += len(cpc_tasks)
        cpc_results = await asyncio.gather(*cpc_tasks, return_exceptions=True)
        for result in cpc_results:
            if isinstance(result, list):
                all_hits.extend(result)
                metadata["cpc_hits"] += len(result)
            elif isinstance(result, Exception):
                log.warning("CPC search failed: %s", result)
        metadata["phases"].append("cpc")

    log.info("Search complete: %d total hits from %d queries", len(all_hits), metadata["total_queries"])
    return all_hits, metadata


# ── Step 4: Professional Analysis ────────────────────────────────────

async def _step4_professional_analysis(
    req: PatentAnalysisRequest, invention: dict, scored_hits: list[dict]
) -> dict:
    """Ask the LLM to produce a professional analysis of the results."""
    essential = invention.get("essential_elements", req.spec.differentiators)
    prompt = build_professional_analysis_prompt(
        product_text=req.product_text,
        variant_title=req.variant.title,
        variant_summary=req.variant.summary,
        spec_novelty=req.spec.novelty,
        spec_mechanism=req.spec.mechanism,
        spec_baseline=req.spec.baseline,
        spec_differentiators=req.spec.differentiators,
        essential_elements=essential,
        patents=scored_hits,
    )
    try:
        return await call_llm_async(
            prompt,
            json_schema_hint=PROFESSIONAL_ANALYSIS_SCHEMA,
            system=PROFESSIONAL_ANALYSIS_SYSTEM,
        )
    except LLMError as exc:
        log.warning("Professional analysis LLM call failed: %s. Using fallback.", exc)
        return _fallback_professional_analysis(scored_hits)


def _fallback_professional_analysis(scored_hits: list[dict]) -> dict:
    """Fallback analysis when LLM is unavailable."""
    has_high = any(h.get("score", 0) >= 0.7 for h in scored_hits)
    has_medium = any(h.get("score", 0) >= 0.4 for h in scored_hits)

    if has_high:
        risk = "high"
    elif has_medium:
        risk = "medium"
    else:
        risk = "low"

    return {
        "novelty_assessment": {
            "risk_level": risk,
            "summary": "Automated heuristic assessment based on keyword overlap scores.",
            "closest_reference": scored_hits[0]["patent_id"] if scored_hits else None,
            "missing_elements": [],
        },
        "obviousness_assessment": {
            "risk_level": risk,
            "summary": "Unable to perform detailed obviousness analysis without LLM.",
            "combination_refs": [],
        },
        "eligibility_note": {
            "applies": False,
            "summary": "No §101 concerns identified for this type of consumer product.",
        },
        "prior_art_summary": {
            "overall_risk": risk,
            "narrative": f"Found {len(scored_hits)} potentially related patents. "
            "A detailed LLM analysis was not available.",
            "key_findings": [
                f"Found {len(scored_hits)} related patents",
                f"Highest similarity score: {scored_hits[0]['score']:.2f}" if scored_hits else "No patents found",
            ],
        },
        "claim_strategy": {
            "recommended_filing": "provisional" if risk != "high" else "defer",
            "rationale": "Preliminary assessment based on keyword overlap scoring only.",
            "suggested_independent_claims": [],
            "risk_areas": [],
        },
        "scored_hits": [
            {
                "patent_id": h["patent_id"],
                "score": h.get("score", 0),
                "why_similar": h.get("why_similar", ""),
            }
            for h in scored_hits
        ],
        "disclaimer": (
            "This is an automated preliminary analysis and does not constitute legal advice. "
            "This search is not exhaustive. Consult a registered patent attorney for a "
            "professional patentability opinion."
        ),
    }


# ── Response parsers ─────────────────────────────────────────────────

def _parse_invention_analysis(data: dict) -> InventionAnalysis:
    cpc_raw = data.get("cpc_codes", [])
    cpc_codes = []
    for c in cpc_raw:
        if isinstance(c, dict):
            cpc_codes.append(CpcSuggestion(
                code=c.get("code", ""),
                description=c.get("description", ""),
                rationale=c.get("rationale", ""),
            ))

    strat_raw = data.get("search_strategies", [])
    strategies = []
    for s in strat_raw:
        if isinstance(s, dict):
            strategies.append(SearchStrategy(
                query=s.get("query", ""),
                approach=s.get("approach", "use_case"),
                target_field=s.get("target_field", "abstract"),
            ))

    return InventionAnalysis(
        core_concept=data.get("core_concept", ""),
        essential_elements=data.get("essential_elements", []),
        alternative_implementations=data.get("alternative_implementations", []),
        cpc_codes=cpc_codes,
        search_strategies=strategies,
    )


def _build_enhanced_hits(scored: list[dict], analysis: dict) -> list[EnhancedPatentHit]:
    """Merge scored hits with LLM analysis scores."""
    llm_scores = {}
    for sh in analysis.get("scored_hits", []):
        if isinstance(sh, dict) and "patent_id" in sh:
            llm_scores[sh["patent_id"]] = sh

    hits = []
    for h in scored:
        pid = h.get("patent_id") or ""
        llm = llm_scores.get(pid, {})
        hits.append(EnhancedPatentHit(
            patent_id=pid,
            title=h.get("title") or "",
            abstract=h.get("abstract") or "",
            assignee=h.get("assignee"),
            date=h.get("date"),
            cpc_codes=h.get("cpc_codes") or [],
            score=round(float(llm.get("score", h.get("score", 0)) or 0), 3),
            why_similar=llm.get("why_similar") or h.get("why_similar") or "",
            source_phase=h.get("source_phase") or "keyword",
        ))

    hits.sort(key=lambda x: x.score, reverse=True)
    return hits


def _parse_novelty(data: dict) -> NoveltyAssessment:
    n = data.get("novelty_assessment", {})
    return NoveltyAssessment(
        risk_level=n.get("risk_level", "medium"),
        summary=n.get("summary", "Analysis unavailable."),
        closest_reference=n.get("closest_reference"),
        missing_elements=n.get("missing_elements", []),
    )


def _parse_obviousness(data: dict) -> ObviousnessAssessment:
    o = data.get("obviousness_assessment", {})
    return ObviousnessAssessment(
        risk_level=o.get("risk_level", "medium"),
        summary=o.get("summary", "Analysis unavailable."),
        combination_refs=o.get("combination_refs", []),
    )


def _parse_eligibility(data: dict) -> EligibilityNote:
    e = data.get("eligibility_note", {})
    return EligibilityNote(
        applies=e.get("applies", False),
        summary=e.get("summary", "No concerns identified."),
    )


def _parse_prior_art_summary(data: dict) -> PriorArtSummary:
    p = data.get("prior_art_summary", {})
    return PriorArtSummary(
        overall_risk=p.get("overall_risk", "medium"),
        narrative=p.get("narrative", "Analysis unavailable."),
        key_findings=p.get("key_findings", []),
    )


def _parse_claim_strategy(data: dict) -> ClaimStrategy:
    c = data.get("claim_strategy", {})
    return ClaimStrategy(
        recommended_filing=c.get("recommended_filing", "provisional"),
        rationale=c.get("rationale", "Analysis unavailable."),
        suggested_independent_claims=c.get("suggested_independent_claims", []),
        risk_areas=c.get("risk_areas", []),
    )


def _compute_confidence(scored: list[dict]) -> str:
    """Compute search confidence from scored hits."""
    if not scored:
        return "low"
    top = [h.get("score", 0) for h in scored[:5]]
    avg = sum(top) / len(top)
    if avg >= 0.6:
        return "high"
    elif avg >= 0.35:
        return "med"
    return "low"
