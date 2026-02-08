"""Scoring service — keyword overlap heuristic + optional LLM rerank."""

import logging
from datetime import datetime

from app.services.llm import LLMError, call_llm
from app.services.prompts import RERANK_SCHEMA, RERANK_SYSTEM, build_rerank_prompt

log = logging.getLogger("mousetrap.scoring")


def _keyword_overlap_score(keywords: list[str], title: str, abstract: str) -> float:
    """Score 0-1 based on fraction of keywords found in title + abstract."""
    if not keywords:
        return 0.0
    text = (title + " " + abstract).lower()
    matches = sum(1 for kw in keywords if kw.lower() in text)
    return min(matches / max(len(keywords), 1), 1.0)


def _recency_bonus(date_str: str | None) -> float:
    """Small bonus for more recent patents (0.0 to 0.1)."""
    if not date_str:
        return 0.0
    try:
        patent_date = datetime.strptime(date_str[:10], "%Y-%m-%d")
        years_old = (datetime.now() - patent_date).days / 365.25
        if years_old < 3:
            return 0.10
        elif years_old < 7:
            return 0.05
        return 0.0
    except (ValueError, TypeError):
        return 0.0


def score_hits_heuristic(
    hits: list[dict],
    keywords: list[str],
) -> list[dict]:
    """Apply keyword-overlap + recency scoring to normalized patent hits.

    Mutates each hit dict in-place, adding 'score' and 'why_similar' keys.
    Returns hits sorted by score descending.
    """
    for h in hits:
        kw_score = _keyword_overlap_score(keywords, h.get("title", ""), h.get("abstract", ""))
        recency = _recency_bonus(h.get("date"))
        h["score"] = round(min(kw_score + recency, 1.0), 3)

        matched = [kw for kw in keywords if kw.lower() in (h.get("title", "") + " " + h.get("abstract", "")).lower()]
        if matched:
            h["why_similar"] = f"Shares keywords: {', '.join(matched[:4])}. Addresses a related problem domain."
        else:
            h["why_similar"] = "Low keyword overlap. May be tangentially related."

    hits.sort(key=lambda x: x["score"], reverse=True)
    return hits


def compute_confidence(hits: list[dict]) -> str:
    """Estimate search confidence based on score distribution."""
    if not hits:
        return "low"
    top_scores = [h["score"] for h in hits[:5]]
    avg = sum(top_scores) / len(top_scores)
    if avg >= 0.6:
        return "high"
    elif avg >= 0.35:
        return "med"
    return "low"


def rerank_with_llm(
    hits: list[dict],
    spec_novelty: str,
    spec_mechanism: str,
    spec_differentiators: list[str],
    top_n: int = 10,
) -> list[dict]:
    """Use the LLM to rerank and explain similarity for the top N hits.

    Falls back to heuristic scores if the LLM call fails.
    """
    candidates = hits[:top_n]
    if not candidates:
        return hits

    prompt = build_rerank_prompt(
        spec_novelty=spec_novelty,
        spec_mechanism=spec_mechanism,
        spec_differentiators=spec_differentiators,
        patents=candidates,
    )

    try:
        data = call_llm(prompt, json_schema_hint=RERANK_SCHEMA, system=RERANK_SYSTEM)
    except LLMError as exc:
        log.warning("LLM rerank failed, keeping heuristic scores: %s", exc)
        return hits

    results = data.get("results", [])
    rerank_map = {r["patentId"]: r for r in results if "patentId" in r}

    for h in candidates:
        pid = h["patent_id"]
        if pid in rerank_map:
            r = rerank_map[pid]
            h["score"] = round(float(r.get("score", h["score"])), 3)
            h["why_similar"] = r.get("whySimilar", h["why_similar"])

    # Re-sort all hits by updated scores
    hits.sort(key=lambda x: x["score"], reverse=True)
    return hits
