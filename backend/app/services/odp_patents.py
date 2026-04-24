"""USPTO Open Data Portal (ODP) patent search client.

Replaces PatentsView (search.patentsview.org), which shut down March 2026.
Endpoint: POST https://api.uspto.gov/api/v1/patent/applications/search
Auth: X-API-KEY header
Query: Lucene syntax (field:value, AND/OR/NOT, wildcards, phrases)

Key difference from PatentsView: no abstract text search. Title + applicant
text fields are indexed. CPC codes not exposed via this API; CPC phase is
skipped (returns empty list) so keyword phases carry the full load.
"""

import logging

import httpx

from app.core.config import settings

log = logging.getLogger("mousetrap.odp_patents")

ODP_SEARCH_URL = "https://api.uspto.gov/api/v1/patent/applications/search"

# Fields to request back in every response
_RESPONSE_FIELDS = [
    "applicationNumberText",
    "applicationMetaData.inventionTitle",
    "applicationMetaData.patentNumber",
    "applicationMetaData.firstApplicantName",
    "applicationMetaData.filingDate",
    "applicationMetaData.grantDate",
    "applicationMetaData.applicationStatusDescriptionText",
    "applicationMetaData.applicationTypeLabelName",
]

# ── Shared async client ────────────────────────────────────────────────
_async_client: httpx.AsyncClient | None = None


def _get_async_client() -> httpx.AsyncClient:
    global _async_client
    if _async_client is None or _async_client.is_closed:
        _async_client = httpx.AsyncClient(
            timeout=30,
            limits=httpx.Limits(max_connections=20, max_keepalive_connections=10),
        )
    return _async_client


async def close_async_client():
    global _async_client
    if _async_client is not None and not _async_client.is_closed:
        await _async_client.aclose()
        _async_client = None


def _headers() -> dict:
    return {
        "X-API-KEY": settings.odp_api_key,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }


async def _search_raw(q: str, limit: int = 25) -> list[dict]:
    """POST to ODP search and return raw patentFileWrapperDataBag items."""
    body = {
        "q": q,
        "fields": _RESPONSE_FIELDS,
        "pagination": {"offset": 0, "limit": min(limit, 100)},
    }
    log.info("ODP search: q=%s", q[:200])

    client = _get_async_client()
    try:
        resp = await client.post(ODP_SEARCH_URL, headers=_headers(), json=body)
    except Exception as exc:
        log.error("ODP request failed: %s", exc)
        return []

    if resp.status_code == 404:
        return []
    if resp.status_code != 200:
        log.error("ODP returned %s: %s", resp.status_code, resp.text[:400])
        return []

    data = resp.json()
    results = data.get("patentFileWrapperDataBag", [])
    log.info("ODP returned %d results (q=%s)", len(results), q[:100])
    return results


def _normalize(raw: list[dict], source_phase: str) -> list[dict]:
    hits = []
    for item in raw:
        meta = item.get("applicationMetaData") or {}
        patent_num = meta.get("patentNumber") or item.get("applicationNumberText") or ""
        title = meta.get("inventionTitle") or ""
        assignee = meta.get("firstApplicantName")
        date = meta.get("grantDate") or meta.get("filingDate")

        if not title:
            continue

        hits.append({
            "patent_id": patent_num,
            "title": title,
            "abstract": "",   # ODP file-wrapper API does not return abstract text
            "assignee": assignee,
            "date": date,
            "cpc_codes": [],
            "source_phase": source_phase,
        })
    return hits


# ── Public search functions (same signatures as patentsview equivalents) ──

async def search_keyword_async(query: str, target_field: str, limit: int = 25) -> list[dict]:
    """Title keyword search. target_field is ignored (ODP has no abstract search)."""
    words = query.strip().split()
    # Lucene phrase for multi-word; single word as-is
    phrase = f'"{query}"' if len(words) > 1 else query
    q = (
        f"applicationMetaData.inventionTitle:{phrase}"
        " AND applicationMetaData.applicationTypeLabelName:Utility"
    )
    # For long queries also try first 3 words for broader recall
    if len(words) > 3:
        short = " ".join(words[:3])
        short_phrase = f'"{short}"'
        q = (
            f"(applicationMetaData.inventionTitle:{phrase}"
            f" OR applicationMetaData.inventionTitle:{short_phrase})"
            " AND applicationMetaData.applicationTypeLabelName:Utility"
        )
    raw = await _search_raw(q, limit)
    return _normalize(raw, "keyword")


async def search_keyword_broad_async(query: str, limit: int = 25) -> list[dict]:
    """Free-text search across all indexed fields (includes title)."""
    words = query.strip().split()
    phrase = f'"{query}"' if len(words) > 1 else query
    q = f"{phrase} AND applicationMetaData.applicationTypeLabelName:Utility"
    raw = await _search_raw(q, limit)
    return _normalize(raw, "keyword")


async def search_keyword_focused_async(query: str, limit: int = 25) -> list[dict]:
    """Focused title search (maps old abstract-focused search to title)."""
    return await search_keyword_async(query, "abstract", limit)


async def search_cpc_async(cpc_code: str, limit: int = 20) -> list[dict]:
    """CPC search — ODP doesn't expose CPC fields, so returns empty."""
    log.debug("CPC search skipped (ODP API does not support CPC queries): %s", cpc_code)
    return []


# ── Deduplication (same as patentsview.py) ────────────────────────────

def deduplicate_hits(all_hits: list[dict]) -> tuple[list[dict], int]:
    """Deduplicate patent hits by patent_id, keeping richest version."""
    best: dict[str, dict] = {}
    for hit in all_hits:
        pid = hit.get("patent_id", "")
        if not pid:
            continue
        if pid not in best:
            best[pid] = hit
        else:
            existing_cpcs = len(best[pid].get("cpc_codes", []))
            new_cpcs = len(hit.get("cpc_codes", []))
            if new_cpcs > existing_cpcs:
                best[pid] = hit
    unique = list(best.values())
    return unique, len(all_hits) - len(unique)
