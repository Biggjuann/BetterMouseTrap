"""PatentsView PatentSearch API client."""

import asyncio
import logging

import httpx

from app.core.config import settings

log = logging.getLogger("mousetrap.patentsview")

PATENT_FIELDS = [
    "patent_id",
    "patent_title",
    "patent_abstract",
    "patent_date",
    "assignees.assignee_organization",
]

ENHANCED_PATENT_FIELDS = [
    "patent_id",
    "patent_title",
    "patent_abstract",
    "patent_date",
    "assignees.assignee_organization",
    "cpc_current.cpc_section",
    "cpc_current.cpc_subclass",
    "cpc_current.cpc_group",
]


def build_query_payload(
    queries: list[str],
    keywords: list[str],
    limit: int = 25,
) -> dict:
    """Build a PatentsView API query payload.

    Uses _text_any on title+abstract for recall, plus _text_all on
    keywords for precision. Results matching any clause are returned.
    """
    clauses = []

    # Each search query: broad _text_any on title + abstract
    for q in queries:
        q = q.strip()
        if q:
            clauses.append({"_text_any": {"patent_title": q}})
            clauses.append({"_text_any": {"patent_abstract": q}})

    # Keywords: use _text_any (any keyword match) for broad recall
    if keywords:
        kw_string = " ".join(k.lower().strip() for k in keywords if len(k.strip()) > 2)
        if kw_string:
            clauses.append({"_text_any": {"patent_abstract": kw_string}})

    if not clauses:
        fallback = queries[0] if queries else " ".join(keywords[:5])
        clauses.append({"_text_any": {"patent_abstract": fallback}})

    query = {"_or": clauses}

    return {
        "q": query,
        "f": PATENT_FIELDS,
        "o": {"size": min(limit, 100)},
    }


def search_patents(payload: dict) -> list[dict]:
    """Call the PatentsView API and return raw patent results."""
    url = f"{settings.patentsview_base_url}/patent/"
    headers = {}
    if settings.patentsview_api_key:
        headers["X-Api-Key"] = settings.patentsview_api_key

    log.info("Querying PatentsView: %s", url)
    log.debug("Payload: %s", payload)

    resp = httpx.get(
        url,
        params={
            "q": _json_param(payload["q"]),
            "f": _json_param(payload["f"]),
            "o": _json_param(payload["o"]),
        },
        headers=headers,
        timeout=30,
    )

    if resp.status_code != 200:
        log.error("PatentsView returned %s: %s", resp.status_code, resp.text[:500])
        return []

    data = resp.json()
    patents = data.get("patents", [])
    log.info("PatentsView returned %d patents (total_hits=%s)", len(patents), data.get("total_hits"))
    return patents


def _json_param(obj) -> str:
    """Serialize a Python object to a JSON string for query params."""
    import json
    return json.dumps(obj, separators=(",", ":"))


def normalize_hits(raw_patents: list[dict]) -> list[dict]:
    """Normalize raw PatentsView results into a standard dict format.

    Returns dicts with keys: patent_id, title, abstract, assignee, date.
    Score and why_similar are added later by the scoring service.
    """
    hits = []
    for p in raw_patents:
        assignees = p.get("assignees", [])
        assignee_name = None
        if assignees and isinstance(assignees, list) and len(assignees) > 0:
            assignee_name = assignees[0].get("assignee_organization")

        hits.append({
            "patent_id": p.get("patent_id", ""),
            "title": p.get("patent_title", ""),
            "abstract": p.get("patent_abstract", ""),
            "assignee": assignee_name,
            "date": p.get("patent_date"),
        })
    return hits


def normalize_enhanced_hits(raw_patents: list[dict], source_phase: str) -> list[dict]:
    """Normalize raw PatentsView results with CPC codes and source phase."""
    hits = []
    for p in raw_patents:
        assignees = p.get("assignees", [])
        assignee_name = None
        if assignees and isinstance(assignees, list) and len(assignees) > 0:
            assignee_name = assignees[0].get("assignee_organization")

        cpc_codes = []
        cpc_current = p.get("cpc_current", [])
        if isinstance(cpc_current, list):
            for cpc in cpc_current:
                group = cpc.get("cpc_group", "")
                subclass = cpc.get("cpc_subclass", "")
                if group:
                    cpc_codes.append(group)
                elif subclass:
                    cpc_codes.append(subclass)
            cpc_codes = list(dict.fromkeys(cpc_codes))[:10]  # dedup, limit

        hits.append({
            "patent_id": p.get("patent_id", ""),
            "title": p.get("patent_title", ""),
            "abstract": p.get("patent_abstract", ""),
            "assignee": assignee_name,
            "date": p.get("patent_date"),
            "cpc_codes": cpc_codes,
            "source_phase": source_phase,
        })
    return hits


# ── CPC-based search ────────────────────────────────────────────────

def build_cpc_query(cpc_code: str, limit: int = 25) -> dict:
    """Build a PatentsView query to search by CPC classification code.

    Uses _begins for prefix matching — e.g. "A47J36" finds A47J36/02, /04, etc.
    Searches both cpc_current.cpc_group (specific) and cpc_subclass (broad).
    """
    code = cpc_code.strip().rstrip("/")
    # If it looks like a full group code (has /), search group; otherwise search subclass
    if "/" in code:
        return {
            "q": {"_begins": {"cpc_current.cpc_group": code}},
            "f": ENHANCED_PATENT_FIELDS,
            "o": {"size": min(limit, 100)},
        }
    return {
        "q": {"_begins": {"cpc_current.cpc_subclass": code}},
        "f": ENHANCED_PATENT_FIELDS,
        "o": {"size": min(limit, 100)},
    }


# ── Async search ─────────────────────────────────────────────────────

async def search_patents_async(payload: dict) -> list[dict]:
    """Async version of search_patents using httpx.AsyncClient."""
    url = f"{settings.patentsview_base_url}/patent/"
    headers = {}
    if settings.patentsview_api_key:
        headers["X-Api-Key"] = settings.patentsview_api_key

    q_str = _json_param(payload["q"])
    log.info("Async querying PatentsView — q=%s", q_str[:200])

    async with httpx.AsyncClient() as client:
        resp = await client.get(
            url,
            params={
                "q": q_str,
                "f": _json_param(payload["f"]),
                "o": _json_param(payload["o"]),
            },
            headers=headers,
            timeout=30,
        )

    if resp.status_code != 200:
        log.error("PatentsView %s for q=%s: %s", resp.status_code, q_str[:150], resp.text[:300])
        return []

    data = resp.json()
    patents = data.get("patents", [])
    log.info("PatentsView returned %d patents (total_hits=%s)", len(patents), data.get("total_hits"))
    return patents


async def search_keyword_async(query: str, target_field: str, limit: int = 25) -> list[dict]:
    """Run a keyword query using _text_any on both title AND abstract.

    Casts a wide net — any word from the query matching in either field.
    """
    payload = {
        "q": {"_or": [
            {"_text_any": {"patent_title": query}},
            {"_text_any": {"patent_abstract": query}},
        ]},
        "f": ENHANCED_PATENT_FIELDS,
        "o": {"size": min(limit, 50)},
    }
    raw = await search_patents_async(payload)
    return normalize_enhanced_hits(raw, "keyword")


async def search_keyword_focused_async(query: str, limit: int = 25) -> list[dict]:
    """Run a focused query requiring all words to appear in the abstract."""
    payload = {
        "q": {"_text_all": {"patent_abstract": query}},
        "f": ENHANCED_PATENT_FIELDS,
        "o": {"size": min(limit, 50)},
    }
    raw = await search_patents_async(payload)
    return normalize_enhanced_hits(raw, "keyword")


async def search_cpc_async(cpc_code: str, limit: int = 20) -> list[dict]:
    """Search PatentsView by CPC code asynchronously."""
    payload = build_cpc_query(cpc_code, limit)
    raw = await search_patents_async(payload)
    return normalize_enhanced_hits(raw, "cpc")


# ── Deduplication ────────────────────────────────────────────────────

def deduplicate_hits(all_hits: list[dict]) -> tuple[list[dict], int]:
    """Deduplicate patent hits by patent_id, keeping richest version.

    Prefers hits that have CPC codes and more metadata.
    Returns (deduplicated_list, num_duplicates_removed).
    """
    best: dict[str, dict] = {}
    for hit in all_hits:
        pid = hit.get("patent_id", "")
        if not pid:
            continue
        if pid not in best:
            best[pid] = hit
        else:
            # Keep the version with more CPC codes
            existing_cpcs = len(best[pid].get("cpc_codes", []))
            new_cpcs = len(hit.get("cpc_codes", []))
            if new_cpcs > existing_cpcs:
                best[pid] = hit
    unique = list(best.values())
    return unique, len(all_hits) - len(unique)
