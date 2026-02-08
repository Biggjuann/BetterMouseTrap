"""PatentsView PatentSearch API client."""

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


def build_query_payload(
    queries: list[str],
    keywords: list[str],
    limit: int = 20,
) -> dict:
    """Build a PatentsView API query payload.

    Uses _text_any on patent_title and patent_abstract to find patents
    matching the provided queries and keywords.
    """
    # Combine all query terms and keywords into a single token list
    all_terms = []
    for q in queries:
        all_terms.extend(q.split())
    all_terms.extend(keywords)

    # Deduplicate while preserving order, lowercase
    seen = set()
    unique_terms = []
    for t in all_terms:
        t_lower = t.lower().strip()
        if t_lower and t_lower not in seen and len(t_lower) > 2:
            seen.add(t_lower)
            unique_terms.append(t_lower)

    search_string = " ".join(unique_terms[:30])  # cap to avoid overly long queries

    query = {
        "_or": [
            {"_text_any": {"patent_title": search_string}},
            {"_text_any": {"patent_abstract": search_string}},
        ]
    }

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
