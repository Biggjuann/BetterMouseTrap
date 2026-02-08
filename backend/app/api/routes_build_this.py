import logging

from fastapi import APIRouter, Depends, HTTPException

from app.auth.dependencies import get_current_user
from app.core.config import settings
from app.schemas.build_this import (
    BomItem,
    ProvisionalPatentRequest,
    ProvisionalPatentResponse,
    PrototypingApproach,
    PrototypingRequest,
    PrototypingResponse,
)
from app.services.llm import LLMError, call_llm
from app.services.prompts import (
    PROVISIONAL_PATENT_SCHEMA,
    PROVISIONAL_PATENT_SYSTEM,
    PROTOTYPING_SCHEMA,
    PROTOTYPING_SYSTEM,
    build_provisional_patent_prompt,
    build_prototyping_prompt,
)

log = logging.getLogger("better_mousetrap.routes_build_this")

router = APIRouter(prefix="/build", tags=["build"], dependencies=[Depends(get_current_user)])


def _has_llm_key() -> bool:
    if settings.llm_provider == "anthropic":
        return bool(settings.anthropic_api_key)
    return bool(settings.openai_api_key)


def _format_patent_markdown(data: dict) -> str:
    lines = [
        f"# Provisional Patent Application: {data.get('title', 'Untitled')}",
        "",
        "## Abstract",
        data.get("abstract", ""),
        "",
        "## Claims",
        "",
    ]
    claims = data.get("claims", {})
    for i, c in enumerate(claims.get("independent", []), 1):
        lines.append(f"**{i}.** {c}")
        lines.append("")
    dep_start = len(claims.get("independent", [])) + 1
    for i, c in enumerate(claims.get("dependent", []), dep_start):
        lines.append(f"**{i}.** {c}")
        lines.append("")

    lines += [
        "## Detailed Description",
        data.get("detailed_description", ""),
        "",
        "## Prior Art Discussion",
        data.get("prior_art_discussion", ""),
        "",
        "---",
        "**Disclaimer:** This is not legal advice. This draft is for informational purposes only "
        "and should be reviewed by a registered patent attorney before filing.",
    ]
    return "\n".join(lines)


def _format_prototype_markdown(approaches: list[dict]) -> str:
    lines = ["# Prototyping Package", ""]
    for i, a in enumerate(approaches, 1):
        lines.append(f"## Approach {i}: {a.get('method', 'Unknown')}")
        lines.append("")
        lines.append(f"**Rationale:** {a.get('rationale', '')}")
        lines.append("")

        specs = a.get("specs", {})
        if specs:
            lines.append("### Specifications")
            for k, v in specs.items():
                lines.append(f"- **{k.replace('_', ' ').title()}:** {v}")
            lines.append("")

        bom = a.get("bill_of_materials", [])
        if bom:
            lines.append("### Bill of Materials")
            lines.append("| Item | Qty | Est. Cost | Source |")
            lines.append("|------|-----|-----------|--------|")
            for item in bom:
                lines.append(
                    f"| {item.get('item', '')} | {item.get('quantity', '')} "
                    f"| {item.get('estimated_cost', '')} | {item.get('source', '')} |"
                )
            lines.append("")

        steps = a.get("assembly_instructions", [])
        if steps:
            lines.append("### Assembly Instructions")
            for j, step in enumerate(steps, 1):
                lines.append(f"{j}. {step}")
            lines.append("")

    return "\n".join(lines)


# ── Mock fallbacks ───────────────────────────────────────────────────

def _mock_patent_draft(req: ProvisionalPatentRequest) -> ProvisionalPatentResponse:
    data = {
        "title": f"Improved {req.variant.title}",
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
        "detailed_description": (
            f"Field of Invention: This invention relates to improvements in {req.product_text}.\n\n"
            f"Background: {req.spec.baseline}\n\n"
            f"Summary: {req.variant.summary}\n\n"
            f"Detailed Description: {req.spec.mechanism}"
        ),
        "prior_art_discussion": (
            "A search of existing patents revealed limited overlap with the proposed invention. "
            "The closest prior art differs in its approach to the core mechanism described herein."
        ),
    }
    return ProvisionalPatentResponse(
        **data,
        markdown=_format_patent_markdown(data),
    )


def _mock_prototype(req: PrototypingRequest) -> PrototypingResponse:
    approaches = [
        {
            "method": "3D Printing (FDM)",
            "rationale": f"3D printing allows rapid iteration on the {req.variant.title} design with minimal tooling costs.",
            "specs": {
                "dimensions": "150mm x 100mm x 50mm (estimated)",
                "materials": "PLA or PETG filament",
                "tolerances": "+/- 0.2mm",
                "finish": "Light sanding + spray paint",
            },
            "bill_of_materials": [
                {"item": "PLA Filament (1kg)", "quantity": "1", "estimated_cost": "$20", "source": "Amazon"},
                {"item": "Sandpaper (assorted)", "quantity": "1 pack", "estimated_cost": "$8", "source": "Hardware store"},
            ],
            "assembly_instructions": [
                "Download or create the 3D model based on the specifications above.",
                "Slice the model using recommended settings (0.2mm layer height, 20% infill).",
                "Print all components.",
                "Sand surfaces for smooth finish.",
                "Assemble components and test functionality.",
            ],
        }
    ]
    return PrototypingResponse(
        approaches=[PrototypingApproach(**a) for a in approaches],
        markdown=_format_prototype_markdown(approaches),
    )


# ── Endpoints ────────────────────────────────────────────────────────

@router.post("/patent-draft", response_model=ProvisionalPatentResponse)
async def generate_patent_draft(req: ProvisionalPatentRequest):
    """Generate a provisional patent application draft."""
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
        data = call_llm(
            prompt,
            json_schema_hint=PROVISIONAL_PATENT_SCHEMA,
            system=PROVISIONAL_PATENT_SYSTEM,
        )
    except LLMError as exc:
        log.error("LLM call failed: %s", exc)
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    claims = data.get("claims", {})
    if isinstance(claims, list):
        claims = {"independent": claims, "dependent": []}

    return ProvisionalPatentResponse(
        title=data.get("title", "Untitled"),
        abstract=data.get("abstract", ""),
        claims=claims,
        detailed_description=data.get("detailed_description", ""),
        prior_art_discussion=data.get("prior_art_discussion", ""),
        markdown=_format_patent_markdown(data),
    )


@router.post("/prototype", response_model=PrototypingResponse)
async def generate_prototype(req: PrototypingRequest):
    """Generate a prototyping package with fabrication approaches."""
    if not _has_llm_key():
        log.warning("No LLM API key — returning mock prototype")
        return _mock_prototype(req)

    prompt = build_prototyping_prompt(
        product_text=req.product_text,
        variant_title=req.variant.title,
        variant_summary=req.variant.summary,
        spec_mechanism=req.spec.mechanism,
        spec_differentiators=req.spec.differentiators,
    )
    try:
        data = call_llm(
            prompt,
            json_schema_hint=PROTOTYPING_SCHEMA,
            system=PROTOTYPING_SYSTEM,
        )
    except LLMError as exc:
        log.error("LLM call failed: %s", exc)
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    raw_approaches = data.get("approaches", [])
    approaches = []
    for ra in raw_approaches:
        bom_items = []
        for item in ra.get("bill_of_materials", []):
            bom_items.append(BomItem(
                item=item.get("item", ""),
                quantity=item.get("quantity", ""),
                estimated_cost=item.get("estimated_cost", ""),
                source=item.get("source", ""),
            ))
        approaches.append(PrototypingApproach(
            method=ra.get("method", "Unknown"),
            rationale=ra.get("rationale", ""),
            specs=ra.get("specs", {}),
            bill_of_materials=bom_items,
            assembly_instructions=ra.get("assembly_instructions", []),
        ))

    return PrototypingResponse(
        approaches=approaches,
        markdown=_format_prototype_markdown([a.model_dump() for a in approaches]),
    )
