import logging

from fastapi import APIRouter, Depends, HTTPException

from app.auth.dependencies import get_current_user
from app.core.config import settings
from app.schemas.build_this import (
    Background,
    CoverSheet,
    ProvisionalPatentRequest,
    ProvisionalPatentResponse,
    Specification,
)
from app.services.llm import LLMError, call_llm_async
from app.services.prompts import (
    PROVISIONAL_PATENT_SCHEMA,
    PROVISIONAL_PATENT_SYSTEM,
    build_provisional_patent_prompt,
)

log = logging.getLogger("mousetrap.routes_build_this")

router = APIRouter(prefix="/build", tags=["build"], dependencies=[Depends(get_current_user)])


def _has_llm_key() -> bool:
    if settings.llm_provider == "anthropic":
        return bool(settings.anthropic_api_key)
    return bool(settings.openai_api_key)


def _format_patent_markdown(data: dict) -> str:
    cover = data.get("cover_sheet", {})
    spec = data.get("specification", {})
    bg = spec.get("background", {})
    claims = data.get("claims", {})

    lines = [
        f"# {cover.get('invention_title', 'Untitled Invention')}",
        "",
        f"*{cover.get('filing_date_note', '')}*",
        "",
        "---",
        "",
        "## SPECIFICATION",
        "",
        f"### Title of Invention",
        "",
        spec.get("title_of_invention", ""),
        "",
    ]

    cross_ref = spec.get("cross_reference")
    if cross_ref:
        lines += [
            "### Cross-Reference to Related Applications",
            "",
            cross_ref,
            "",
        ]

    lines += [
        "### Background of the Invention",
        "",
        "#### Field of the Invention",
        "",
        bg.get("field_of_invention", ""),
        "",
        "#### Description of the Prior Art",
        "",
        bg.get("description_of_prior_art", ""),
        "",
        "### Summary of the Invention",
        "",
        spec.get("summary", ""),
        "",
    ]

    drawings_desc = spec.get("brief_description_of_drawings")
    if drawings_desc:
        lines += [
            "### Brief Description of the Drawings",
            "",
            drawings_desc,
            "",
        ]

    lines += [
        "### Detailed Description of Preferred Embodiments",
        "",
        spec.get("detailed_description", ""),
        "",
        "---",
        "",
        "## ABSTRACT",
        "",
        data.get("abstract", ""),
        "",
        "---",
        "",
        "## CLAIMS",
        "",
    ]

    for i, c in enumerate(claims.get("independent", []), 1):
        lines.append(f"**{i}.** {c}")
        lines.append("")
    dep_start = len(claims.get("independent", [])) + 1
    for i, c in enumerate(claims.get("dependent", []), dep_start):
        lines.append(f"**{i}.** {c}")
        lines.append("")

    lines += [
        "---",
        "",
        "## DRAWINGS RECOMMENDATION",
        "",
        data.get("drawings_note", ""),
        "",
        "---",
        "",
        "*Disclaimer: This is an AI-generated draft for informational purposes only. "
        "It does not constitute legal advice. Have a registered patent attorney or agent "
        "review this document before filing with the USPTO.*",
    ]
    return "\n".join(lines)


# ── Mock fallback ────────────────────────────────────────────────────

def _mock_patent_draft(req: ProvisionalPatentRequest) -> ProvisionalPatentResponse:
    data = {
        "cover_sheet": {
            "invention_title": f"Improved {req.variant.title}",
            "filing_date_note": "Filing establishes a priority date. You have 12 months to file a non-provisional application.",
        },
        "specification": {
            "title_of_invention": f"Improved {req.variant.title}",
            "cross_reference": None,
            "background": {
                "field_of_invention": (
                    f"This invention relates generally to improvements in {req.product_text}, "
                    f"and more particularly to {req.variant.title.lower()}."
                ),
                "description_of_prior_art": (
                    f"Existing solutions in the {req.product_text} space suffer from several limitations. "
                    f"{req.spec.baseline} "
                    f"There remains a need for an approach that addresses these shortcomings."
                ),
            },
            "summary": (
                f"{req.variant.summary} "
                f"The present invention provides {req.spec.novelty}"
            ),
            "brief_description_of_drawings": None,
            "detailed_description": (
                f"In accordance with the present invention, {req.spec.mechanism}\n\n"
                f"The invention differentiates from prior art in the following ways: "
                f"{', '.join(req.spec.differentiators) if req.spec.differentiators else 'novel mechanism and approach'}.\n\n"
                f"In one preferred embodiment, the system implements the core mechanism described above "
                f"to achieve measurable improvements over existing solutions."
            ),
        },
        "abstract": (
            f"An improved {req.product_text} comprising {req.spec.mechanism} "
            f"The invention addresses limitations in existing products by providing "
            f"{req.spec.novelty}"
        ),
        "claims": {
            "independent": [
                f"A method for improving {req.product_text} comprising: {req.spec.mechanism}",
                f"An apparatus for {req.variant.title.lower()} comprising the elements described herein.",
            ],
            "dependent": [
                "The method of claim 1, wherein the improvement further comprises enhanced durability.",
                "The method of claim 1, wherein the cost is reduced by at least 20%.",
                "The apparatus of claim 2, further comprising a modular design.",
            ],
        },
        "drawings_note": (
            "It is recommended to include the following drawings:\n"
            "- Figure 1: System overview diagram showing key components\n"
            "- Figure 2: Flowchart of the core method steps\n"
            "- Figure 3: Detailed view of the primary mechanism"
        ),
    }
    data["markdown"] = _format_patent_markdown(data)

    bg = data["specification"]["background"]
    spec_data = data["specification"]

    return ProvisionalPatentResponse(
        cover_sheet=CoverSheet(**data["cover_sheet"]),
        specification=Specification(
            title_of_invention=spec_data["title_of_invention"],
            cross_reference=spec_data["cross_reference"],
            background=Background(**bg),
            summary=spec_data["summary"],
            brief_description_of_drawings=spec_data["brief_description_of_drawings"],
            detailed_description=spec_data["detailed_description"],
        ),
        abstract=data["abstract"],
        claims=data["claims"],
        drawings_note=data["drawings_note"],
        markdown=data["markdown"],
    )


# ── Endpoint ─────────────────────────────────────────────────────────

@router.post("/patent-draft", response_model=ProvisionalPatentResponse)
async def generate_patent_draft(req: ProvisionalPatentRequest):
    """Generate a USPTO-format provisional patent application draft."""
    if not _has_llm_key():
        log.warning("No LLM API key — returning mock patent draft")
        return _mock_patent_draft(req)

    hits_data = [h.model_dump() for h in req.hits] if req.hits else []
    prompt = build_provisional_patent_prompt(
        product_text=req.product_text,
        variant_title=req.variant.title,
        variant_summary=req.variant.summary,
        spec_novelty=req.spec.novelty,
        spec_mechanism=req.spec.mechanism,
        spec_baseline=req.spec.baseline,
        spec_differentiators=req.spec.differentiators,
        patent_hits=hits_data,
    )
    try:
        data = await call_llm_async(
            prompt,
            json_schema_hint=PROVISIONAL_PATENT_SCHEMA,
            system=PROVISIONAL_PATENT_SYSTEM,
            max_tokens=32000,
        )
    except LLMError as exc:
        log.error("LLM call failed: %s", exc)
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    claims = data.get("claims", {})
    if isinstance(claims, list):
        claims = {"independent": claims, "dependent": []}

    # If abstract, claims, or drawings_note are missing, make a focused follow-up call
    missing_abstract = not data.get("abstract")
    missing_claims = not claims or not claims.get("independent")
    missing_drawings = not data.get("drawings_note")

    if missing_abstract or missing_claims or missing_drawings:
        log.warning(
            "Patent draft missing sections (abstract=%s, claims=%s, drawings=%s) — making follow-up call",
            missing_abstract, missing_claims, missing_drawings,
        )
        spec_data_for_followup = data.get("specification", {})
        title = data.get("cover_sheet", {}).get("invention_title", req.variant.title)
        summary = spec_data_for_followup.get("summary", req.variant.summary)

        followup_prompt = f"""Given this patent invention, generate ONLY the missing sections.

Invention: {title}
Summary: {summary}
Product: {req.product_text}
Novelty: {req.spec.novelty}
Mechanism: {req.spec.mechanism}

Generate a JSON object with these fields:
- "abstract": Exactly 150 words. Technical summary stating the field, problem, and solution.
- "claims": Object with "independent" (2-3 claims) and "dependent" (4-6 claims) arrays in patent language.
- "drawings_note": Recommend specific figures (perspective view, block diagram, flowchart) the inventor should prepare.

Respond with ONLY valid JSON, no markdown fences."""

        try:
            followup = await call_llm_async(followup_prompt, system=PROVISIONAL_PATENT_SYSTEM, max_tokens=4096)
            if missing_abstract and followup.get("abstract"):
                data["abstract"] = followup["abstract"]
            if missing_claims:
                fc = followup.get("claims", {})
                if isinstance(fc, list):
                    fc = {"independent": fc, "dependent": []}
                if fc.get("independent"):
                    claims = fc
            if missing_drawings and followup.get("drawings_note"):
                data["drawings_note"] = followup["drawings_note"]
        except Exception as exc:
            log.error("Follow-up LLM call failed: %s", exc)

    cover_data = data.get("cover_sheet", {})
    spec_data = data.get("specification", {})
    bg_data = spec_data.get("background", {})

    full_data = {**data, "claims": claims}
    markdown = _format_patent_markdown(full_data)

    return ProvisionalPatentResponse(
        cover_sheet=CoverSheet(
            invention_title=cover_data.get("invention_title", "Untitled"),
            filing_date_note=cover_data.get("filing_date_note", ""),
        ),
        specification=Specification(
            title_of_invention=spec_data.get("title_of_invention", ""),
            cross_reference=spec_data.get("cross_reference"),
            background=Background(
                field_of_invention=bg_data.get("field_of_invention", ""),
                description_of_prior_art=bg_data.get("description_of_prior_art", ""),
            ),
            summary=spec_data.get("summary", ""),
            brief_description_of_drawings=spec_data.get("brief_description_of_drawings"),
            detailed_description=spec_data.get("detailed_description", ""),
        ),
        abstract=data.get("abstract", ""),
        claims=claims,
        drawings_note=data.get("drawings_note", ""),
        markdown=markdown,
    )
