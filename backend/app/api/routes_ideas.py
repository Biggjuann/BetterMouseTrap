import logging
import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.credit_guard import require_credits
from app.auth.dependencies import get_current_user
from app.models.database import get_session
from app.models.user import User

from app.core.config import settings
from app.schemas.idea import (
    CustomerTruth,
    GenerateIdeasRequest,
    GenerateIdeasResponse,
    GenerateSpecRequest,
    GenerateSpecResponse,
    IdeaScores,
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

log = logging.getLogger("mousetrap.routes_ideas")

router = APIRouter(prefix="/ideas", tags=["ideas"], dependencies=[Depends(get_current_user)])

def _has_llm_key() -> bool:
    if settings.llm_provider == "anthropic":
        return bool(settings.anthropic_api_key)
    return bool(settings.openai_api_key)


# ── Mock fallbacks ───────────────────────────────────────────────────

def _mock_customer_truth(product: str) -> CustomerTruth:
    return CustomerTruth(
        buyer=f"Everyday consumers who use {product}",
        job_to_be_done=f"Get more value and convenience from their {product}",
        purchase_drivers=["Price", "Quality", "Convenience", "Durability", "Brand trust"],
        complaints=["Too expensive", "Breaks too easily", "Hard to clean", "Outdated design", "Missing features"],
    )


def _mock_variants(product: str) -> list[IdeaVariant]:
    top_ideas = [
        IdeaVariant(
            id=str(uuid.uuid4()),
            title=f"Smart{product.title().replace(' ', '')}",
            summary=f"IoT-enabled {product} with app control and usage tracking.",
            tier="top",
            one_line_pitch=f"The world's first smart {product} that tracks usage and optimizes performance.",
            target_customer=f"Tech-savvy {product} users aged 25-45",
            core_problem=f"No visibility into how you use your {product} or when it needs maintenance.",
            solution=f"Embedded sensors + companion app that tracks usage patterns and sends maintenance alerts.",
            why_it_wins=["First-mover in smart category", "Recurring revenue via premium app", "Patent-eligible sensor integration"],
            monetization=f"$49.99 device + $4.99/mo premium app",
            unit_economics="COGS ~$18, 64% gross margin on hardware, 90% on subscription",
            defensibility_note="Patentable sensor integration + growing data moat from usage patterns",
            mvp_90_days="Basic sensor + BLE connection + simple mobile dashboard",
            go_to_market=["Kickstarter launch", "Amazon listing with A+ content", "Instagram/TikTok demos"],
            risks=["Sensor reliability in early batches — mitigate with 6-month warranty", "App adoption curve — mitigate with free tier"],
            scores=IdeaScores(urgency=7, differentiation=8, speed_to_revenue=7, margin=8, defensibility=7, distribution=6),
            keywords=[product, "smart", "IoT", "sensor", "connected device"],
        ),
        IdeaVariant(
            id=str(uuid.uuid4()),
            title=f"Eco{product.title().replace(' ', '')}",
            summary=f"Sustainable {product} made from recycled ocean plastic with carbon-neutral shipping.",
            tier="top",
            one_line_pitch=f"A premium {product} that's better for the planet without compromising quality.",
            target_customer="Eco-conscious consumers willing to pay 20% premium for sustainability",
            core_problem=f"Current {product} options use virgin plastics and have high carbon footprint.",
            solution="Recycled ocean plastic construction + carbon offset program + take-back recycling.",
            why_it_wins=["Growing $150B sustainable goods market", "Premium pricing justified by mission", "B-Corp certification path"],
            monetization=f"$34.99 (20% premium over standard)",
            unit_economics="COGS ~$12, 66% gross margin",
            defensibility_note="Certified supply chain + brand loyalty from mission-driven customers",
            mvp_90_days="Source recycled materials + prototype + sustainability certification",
            go_to_market=["Whole Foods / REI placement", "Sustainability influencer partnerships", "Earth Day launch campaign"],
            risks=["Supply chain for recycled materials — mitigate with multiple suppliers", "Greenwashing perception — mitigate with third-party certification"],
            scores=IdeaScores(urgency=6, differentiation=7, speed_to_revenue=8, margin=7, defensibility=5, distribution=7),
            keywords=[product, "sustainable", "recycled", "eco-friendly", "ocean plastic"],
        ),
        IdeaVariant(
            id=str(uuid.uuid4()),
            title=f"Pro{product.title().replace(' ', '')}",
            summary=f"Professional-grade {product} with modular attachments for power users.",
            tier="top",
            one_line_pitch=f"The prosumer {product} with swappable modules for any situation.",
            target_customer=f"Power users and small business owners who use {product} daily",
            core_problem=f"One-size-fits-all {product} can't adapt to different professional needs.",
            solution="Magnetic modular system with snap-on attachments for different use cases.",
            why_it_wins=["Razor/blade model locks in repeat purchases", "Modular = one product covers multiple needs", "Patent-eligible connection mechanism"],
            monetization=f"$59.99 base + $14.99/attachment",
            unit_economics="COGS ~$22 base, $4 per attachment. 63% margin base, 73% attachments",
            defensibility_note="Patentable magnetic connection system + ecosystem lock-in",
            mvp_90_days="Base unit + 3 most popular attachments",
            go_to_market=["Amazon with bundle deals", "Trade show demos", "YouTube review seeding"],
            risks=["Attachment adoption — mitigate with starter bundle", "Manufacturing complexity — mitigate with standardized connector"],
            scores=IdeaScores(urgency=8, differentiation=7, speed_to_revenue=8, margin=9, defensibility=8, distribution=7),
            keywords=[product, "modular", "professional", "attachments", "magnetic"],
        ),
    ]

    moonshot = IdeaVariant(
        id=str(uuid.uuid4()),
        title=f"{product.title().replace(' ', '')}OS",
        summary=f"AI-powered {product} platform that learns from every user to get smarter over time.",
        tier="moonshot",
        one_line_pitch=f"The {product} that gets better the more people use it — powered by collective intelligence.",
        target_customer=f"Early adopters and tech enthusiasts in the {product} space",
        core_problem=f"Every {product} is static — it never improves after purchase.",
        solution=f"On-device ML that learns usage patterns + cloud aggregation for continuous improvement.",
        why_it_wins=["Network effects from shared learning", "Defensible data moat", "Platform potential for third-party modules"],
        monetization=f"$79.99 hardware + $9.99/mo platform access",
        unit_economics="COGS ~$35, 56% hardware margin, 85% platform margin at scale",
        defensibility_note="Data moat from millions of usage patterns + ML models + developer ecosystem",
        mvp_90_days="Basic learning algorithm + cloud sync + simple improvement demos",
        go_to_market=["Product Hunt launch", "Dev community evangelism", "Strategic partnership with major retailer"],
        risks=["ML accuracy in early stages — mitigate with curated training data", "Privacy concerns — mitigate with on-device processing + clear opt-in"],
        scores=IdeaScores(urgency=5, differentiation=10, speed_to_revenue=4, margin=9, defensibility=10, distribution=5),
        keywords=[product, "AI", "machine learning", "platform", "network effects"],
    )

    upgrades = [
        IdeaVariant(id=str(uuid.uuid4()), title=f"Compact {product.title()}", summary=f"Travel-sized {product} that folds flat.", tier="upgrade", keywords=[]),
        IdeaVariant(id=str(uuid.uuid4()), title=f"Silent {product.title()}", summary=f"Noise-reducing {product} for shared spaces.", tier="upgrade", keywords=[]),
        IdeaVariant(id=str(uuid.uuid4()), title=f"Glow {product.title()}", summary=f"LED-enhanced {product} with ambient lighting.", tier="upgrade", keywords=[]),
        IdeaVariant(id=str(uuid.uuid4()), title=f"Quick {product.title()}", summary=f"Speed-optimized {product} that works 3x faster.", tier="upgrade", keywords=[]),
        IdeaVariant(id=str(uuid.uuid4()), title=f"Grip {product.title()}", summary=f"Ergonomic {product} with anti-slip texture.", tier="upgrade", keywords=[]),
    ]

    adjacent = [
        IdeaVariant(id=str(uuid.uuid4()), title=f"{product.title()} Caddy", summary=f"Organizer designed specifically for {product} accessories.", tier="adjacent", keywords=[]),
        IdeaVariant(id=str(uuid.uuid4()), title=f"{product.title()} Care Kit", summary=f"Cleaning and maintenance bundle for {product} owners.", tier="adjacent", keywords=[]),
        IdeaVariant(id=str(uuid.uuid4()), title=f"{product.title()} Shield", summary=f"Protective case that extends {product} lifespan 3x.", tier="adjacent", keywords=[]),
        IdeaVariant(id=str(uuid.uuid4()), title=f"{product.title()} Starter Pack", summary=f"Everything a new {product} buyer needs in one box.", tier="adjacent", keywords=[]),
        IdeaVariant(id=str(uuid.uuid4()), title=f"{product.title()} Stand", summary=f"Display stand that doubles as a charging dock.", tier="adjacent", keywords=[]),
    ]

    recurring = [
        IdeaVariant(id=str(uuid.uuid4()), title=f"{product.title()} Club", summary=f"Monthly subscription box with {product} accessories and upgrades.", tier="recurring", keywords=[]),
        IdeaVariant(id=str(uuid.uuid4()), title=f"{product.title()} Refills", summary=f"Auto-ship consumable refills on a customizable schedule.", tier="recurring", keywords=[]),
        IdeaVariant(id=str(uuid.uuid4()), title=f"{product.title()} Pro Plan", summary=f"Premium support + extended warranty + exclusive content.", tier="recurring", keywords=[]),
    ]

    return top_ideas + [moonshot] + upgrades + adjacent + recurring


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

def _parse_scores(raw: dict | None) -> IdeaScores | None:
    """Parse scores dict from LLM (handles camelCase and snake_case)."""
    if not raw or not isinstance(raw, dict):
        return None
    return IdeaScores(
        urgency=int(raw.get("urgency", 0)),
        differentiation=int(raw.get("differentiation", 0)),
        speed_to_revenue=int(raw.get("speed_to_revenue", raw.get("speedToRevenue", 0))),
        margin=int(raw.get("margin", 0)),
        defensibility=int(raw.get("defensibility", 0)),
        distribution=int(raw.get("distribution", 0)),
    )


def _parse_detailed_idea(raw: dict, tier: str) -> IdeaVariant:
    """Parse a detailed idea (top3 or moonshot) from LLM output."""
    return IdeaVariant(
        id=raw.get("id", str(uuid.uuid4())),
        title=raw.get("name", raw.get("title", "Untitled")),
        summary=raw.get("one_line_pitch", raw.get("oneLinePitch", raw.get("summary", ""))),
        tier=tier,
        one_line_pitch=raw.get("one_line_pitch", raw.get("oneLinePitch", "")),
        target_customer=raw.get("target_customer", raw.get("targetCustomer", "")),
        core_problem=raw.get("core_problem", raw.get("coreProblem", "")),
        solution=raw.get("solution", ""),
        why_it_wins=raw.get("why_it_wins", raw.get("whyItWins", [])),
        monetization=raw.get("monetization", ""),
        unit_economics=raw.get("unit_economics", raw.get("unitEconomics", "")),
        defensibility_note=raw.get("defensibility", raw.get("defensibility_note", "")),
        mvp_90_days=raw.get("mvp_90_days", raw.get("mvp90Days", "")),
        go_to_market=raw.get("go_to_market", raw.get("goToMarket", [])),
        risks=raw.get("risks", []),
        scores=_parse_scores(raw.get("scores")),
        keywords=raw.get("keywords", []),
    )


def _parse_brief_idea(raw: dict, tier: str) -> IdeaVariant:
    """Parse a brief idea (upgrade/adjacent/recurring) from LLM output."""
    # Determine summary from various possible fields
    summary = (
        raw.get("one_line_pitch", "")
        or raw.get("oneLinePitch", "")
        or raw.get("why_it_wins", "")
        or raw.get("why_it_sells", "")
        or raw.get("model", "")
        or ""
    )
    # For brief ideas, combine pitch + reason into summary
    why = (
        raw.get("why_it_wins", "")
        or raw.get("why_it_sells", "")
        or raw.get("why_retention", "")
        or ""
    )

    return IdeaVariant(
        id=raw.get("id", str(uuid.uuid4())),
        title=raw.get("name", raw.get("title", "Untitled")),
        summary=summary if summary else why,
        tier=tier,
        one_line_pitch=raw.get("one_line_pitch", raw.get("oneLinePitch", None)),
        why_it_wins=[why] if why and isinstance(why, str) else raw.get("why_it_wins", []),
        monetization=raw.get("model", None),  # recurring_revenue uses "model"
    )


@router.post("/generate", response_model=GenerateIdeasResponse)
async def generate_ideas(
    req: GenerateIdeasRequest,
    user: User = Depends(require_credits),
    session: AsyncSession = Depends(get_session),
):
    """Generate idea variants for a product."""
    product = req.text or "generic product"

    if not _has_llm_key():
        log.warning("No LLM API key configured — returning mock variants")
        return GenerateIdeasResponse(
            variants=_mock_variants(product),
            customer_truth=_mock_customer_truth(product),
        )

    prompt = build_generate_variants_prompt(product, req.category, random=req.random)
    try:
        data = call_llm(
            prompt,
            json_schema_hint=GENERATE_VARIANTS_SCHEMA,
            system=GENERATE_VARIANTS_SYSTEM,
        )
    except LLMError as exc:
        log.error("LLM call failed: %s", exc)
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    # Parse customer truth
    ct_raw = data.get("customer_truth", data.get("customerTruth"))
    customer_truth = None
    if ct_raw and isinstance(ct_raw, dict):
        customer_truth = CustomerTruth(
            buyer=ct_raw.get("buyer", ""),
            job_to_be_done=ct_raw.get("job_to_be_done", ct_raw.get("jobToBeDone", "")),
            purchase_drivers=ct_raw.get("purchase_drivers", ct_raw.get("purchaseDrivers", [])),
            complaints=ct_raw.get("complaints", []),
        )

    # Flatten all idea tiers into a single variants list
    variants: list[IdeaVariant] = []

    # Top ideas (detailed)
    for raw in data.get("top_ideas", data.get("topIdeas", [])):
        variants.append(_parse_detailed_idea(raw, "top"))

    # Moonshot (detailed) — can be a single object or a list
    moonshot_raw = data.get("moonshot")
    if moonshot_raw:
        if isinstance(moonshot_raw, list):
            for raw in moonshot_raw:
                variants.append(_parse_detailed_idea(raw, "moonshot"))
        elif isinstance(moonshot_raw, dict):
            variants.append(_parse_detailed_idea(moonshot_raw, "moonshot"))

    # More upgrades (brief)
    for raw in data.get("more_upgrades", data.get("moreUpgrades", [])):
        variants.append(_parse_brief_idea(raw, "upgrade"))

    # Adjacent products (brief)
    for raw in data.get("adjacent_products", data.get("adjacentProducts", [])):
        variants.append(_parse_brief_idea(raw, "adjacent"))

    # Recurring revenue (brief)
    for raw in data.get("recurring_revenue", data.get("recurringRevenue", [])):
        variants.append(_parse_brief_idea(raw, "recurring"))

    # Deduct credit after successful generation (admin bypass)
    if not user.is_admin:
        from app.services.credits import deduct_credit
        await deduct_credit(
            session, user.id,
            transaction_type="idea_generation",
            description=f"Idea generation for: {product[:100]}",
        )
        await session.commit()

    return GenerateIdeasResponse(variants=variants, customer_truth=customer_truth)


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
