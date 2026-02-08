import logging
import uuid

from fastapi import APIRouter, Depends, HTTPException

from app.auth.dependencies import get_current_user

from app.core.config import settings
from app.schemas.idea import (
    GenerateIdeasRequest,
    GenerateIdeasResponse,
    GenerateSpecRequest,
    GenerateSpecResponse,
    IdeaSpec,
    IdeaVariant,
)
from app.services.llm import LLMError, call_llm
from app.services.prompts import (
    GENERATE_SPEC_SCHEMA,
    GENERATE_SPEC_SYSTEM,
    GENERATE_VARIANTS_SCHEMA,
    GENERATE_VARIANTS_SYSTEM,
    build_generate_spec_prompt,
    build_generate_variants_prompt,
)

log = logging.getLogger("better_mousetrap.routes_ideas")

router = APIRouter(prefix="/ideas", tags=["ideas"], dependencies=[Depends(get_current_user)])

IMPROVEMENT_MODES = [
    "cost_down",
    "durability",
    "safety",
    "convenience",
    "sustainability",
    "performance",
    "mashup",
]


def _has_llm_key() -> bool:
    if settings.llm_provider == "anthropic":
        return bool(settings.anthropic_api_key)
    return bool(settings.openai_api_key)


# ── Mock fallbacks ───────────────────────────────────────────────────

def _mock_variants(product: str) -> list[IdeaVariant]:
    variants = [
        IdeaVariant(
            id=str(uuid.uuid4()),
            title=f"{product} — {mode} improvement",
            summary=f"A version of {product} optimized for {mode.replace('_', ' ')}.",
            improvement_mode=mode,
            keywords=[product, mode.replace("_", " "), "improved"],
        )
        for mode in IMPROVEMENT_MODES
    ]
    for extra in ["smart", "modular", "eco"]:
        variants.append(
            IdeaVariant(
                id=str(uuid.uuid4()),
                title=f"{product} — {extra} edition",
                summary=f"A {extra} take on {product} with novel features.",
                improvement_mode="mashup",
                keywords=[product, extra, "novel"],
            )
        )
    return variants


def _mock_spec(product_text: str, v: IdeaVariant) -> IdeaSpec:
    return IdeaSpec(
        novelty=f"Novel approach to {v.title} using {v.improvement_mode} principles.",
        mechanism=f"Mechanism leverages improved {v.improvement_mode.replace('_', ' ')} design.",
        baseline=f"Current {product_text} products on the market.",
        differentiators=[
            f"Improved {v.improvement_mode.replace('_', ' ')}",
            "Lower manufacturing complexity",
            "User-centric ergonomic design",
        ],
        keywords=v.keywords + ["invention", "improvement"],
        search_queries=[
            f"{product_text} {v.improvement_mode.replace('_', ' ')} improvement",
            f"{product_text} novel design",
            f"{product_text} patent prior art",
        ],
        disclaimer="This is not legal advice. This analysis is not exhaustive and should not be used as a substitute for professional patent counsel.",
    )


# ── Endpoints ────────────────────────────────────────────────────────

@router.post("/generate", response_model=GenerateIdeasResponse)
async def generate_ideas(req: GenerateIdeasRequest):
    """Generate idea variants for a product."""
    product = req.text or "generic product"

    if not _has_llm_key():
        log.warning("No LLM API key configured — returning mock variants")
        return GenerateIdeasResponse(variants=_mock_variants(product))

    prompt = build_generate_variants_prompt(product, req.category)
    try:
        data = call_llm(
            prompt,
            json_schema_hint=GENERATE_VARIANTS_SCHEMA,
            system=GENERATE_VARIANTS_SYSTEM,
        )
    except LLMError as exc:
        log.error("LLM call failed: %s", exc)
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    # Parse variants — the LLM may use camelCase keys
    raw_variants = data.get("variants", [])
    variants = []
    for rv in raw_variants:
        variants.append(
            IdeaVariant(
                id=rv.get("id", str(uuid.uuid4())),
                title=rv.get("title", "Untitled"),
                summary=rv.get("summary", ""),
                improvement_mode=rv.get("improvementMode", rv.get("improvement_mode", "mashup")),
                keywords=rv.get("keywords", []),
            )
        )

    return GenerateIdeasResponse(variants=variants)


@router.post("/spec", response_model=GenerateSpecResponse)
async def generate_spec(req: GenerateSpecRequest):
    """Generate a claim-like structured spec for a selected variant."""
    v = req.variant

    if not _has_llm_key():
        log.warning("No LLM API key configured — returning mock spec")
        return GenerateSpecResponse(spec=_mock_spec(req.product_text, v))

    prompt = build_generate_spec_prompt(
        product_text=req.product_text,
        variant_title=v.title,
        variant_summary=v.summary,
        variant_keywords=v.keywords,
    )
    try:
        data = call_llm(
            prompt,
            json_schema_hint=GENERATE_SPEC_SCHEMA,
            system=GENERATE_SPEC_SYSTEM,
        )
    except LLMError as exc:
        log.error("LLM call failed: %s", exc)
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    raw = data.get("spec", data)
    return GenerateSpecResponse(
        spec=IdeaSpec(
            novelty=raw.get("novelty", ""),
            mechanism=raw.get("mechanism", ""),
            baseline=raw.get("baseline", ""),
            differentiators=raw.get("differentiators", []),
            keywords=raw.get("keywords", []),
            search_queries=raw.get("searchQueries", raw.get("search_queries", [])),
            disclaimer=raw.get("disclaimer", "This is not legal advice."),
        )
    )
