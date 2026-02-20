import logging

from fastapi import APIRouter, Depends

from app.auth.dependencies import get_current_user
from app.core.config import settings
from app.services.llm import LLMError, call_llm_async
from app.services.prompts import (
    DAILY_INSIGHT_SCHEMA,
    DAILY_INSIGHT_SYSTEM,
    MARKET_TRENDS_SCHEMA,
    MARKET_TRENDS_SYSTEM,
    build_daily_insight_prompt,
    build_market_trends_prompt,
)

log = logging.getLogger("mousetrap.routes_insights")

router = APIRouter(prefix="/insights", tags=["insights"], dependencies=[Depends(get_current_user)])


def _has_llm_key() -> bool:
    if settings.llm_provider == "anthropic":
        return bool(settings.anthropic_api_key)
    return bool(settings.openai_api_key)


# ── Mock fallbacks ───────────────────────────────────────────────────

def _mock_insight() -> dict:
    return {
        "insight": (
            "Refillable home cleaning products are surging — brands like Blueland "
            "and CleanCult prove consumers will pay a premium for sustainable refill "
            "systems. If you can apply the refill model to any consumable category, "
            "you've got a built-in recurring revenue engine."
        )
    }


def _mock_trends() -> dict:
    return {
        "trends": [
            {
                "rank": 1,
                "title": "Smart Home Wellness Devices",
                "category": "Personal Wellness",
                "description": "Consumers want air quality monitors, sleep trackers, and circadian lighting built into everyday home products. The wellness-at-home market is projected to grow 18% YoY.",
                "opportunity": "Build wellness sensing into a product people already own — lamps, humidifiers, fans.",
                "growth_signal": "Amazon searches for 'air quality monitor' up 140% since 2024.",
            },
            {
                "rank": 2,
                "title": "Pet Tech Goes Mainstream",
                "category": "Pet Products",
                "description": "Pet owners now spend like parents. GPS trackers, automatic feeders, and pet cameras are the fastest-growing subcategory in consumer electronics.",
                "opportunity": "Any 'dumb' pet product (bowls, leashes, beds) can be upgraded with a smart sensor or connected feature.",
                "growth_signal": "Pet tech market hit $8B in 2025, up from $5B in 2023.",
            },
            {
                "rank": 3,
                "title": "Refillable Everything",
                "category": "Home & Kitchen",
                "description": "From soap to spices to laundry pods, consumers are embracing refill models that reduce packaging waste and lock in repeat purchases.",
                "opportunity": "Create a refill system for any frequently-repurchased consumable and you have built-in retention.",
                "growth_signal": "Blueland, Grove, and CleanCult collectively raised $300M+ proving the model works.",
            },
            {
                "rank": 4,
                "title": "Desk & WFH Upgrades",
                "category": "Office & Productivity",
                "description": "Remote and hybrid work is permanent. Workers are still upgrading home offices with ergonomic, aesthetic, and productivity-boosting accessories.",
                "opportunity": "Products that combine ergonomics with aesthetics (standing desk accessories, cable management, monitor arms) fly off shelves.",
                "growth_signal": "WFH accessory category on Amazon grew 22% in 2025.",
            },
            {
                "rank": 5,
                "title": "Portable Power & Solar",
                "category": "Outdoor & Travel",
                "description": "Power stations, solar panels, and portable batteries are mainstream now. Outdoor enthusiasts, van-lifers, and emergency preppers are all buying.",
                "opportunity": "Niche-specific portable power solutions (camping kitchen power, pet travel power) are underserved.",
                "growth_signal": "Jackery and EcoFlow exceeded $1B combined revenue in 2025.",
            },
            {
                "rank": 6,
                "title": "Kitchen Gadgets for One",
                "category": "Home & Kitchen",
                "description": "Single-person households are the fastest-growing demographic. Products sized for one — mini air fryers, single-serve coffee, compact cookware — are booming.",
                "opportunity": "Resize any popular kitchen product for single servings and you've got an instant market.",
                "growth_signal": "Single-person households now represent 29% of US homes.",
            },
            {
                "rank": 7,
                "title": "Sensory & Calm Products",
                "category": "Personal Wellness",
                "description": "Anxiety and stress products have gone mainstream. Weighted blankets were just the start — now it's fidget tools, aromatherapy wearables, and noise-masking devices.",
                "opportunity": "Any product that delivers a tangible 'calm' sensation has a willing buyer in the stressed-out consumer.",
                "growth_signal": "Calm/wellness product searches up 85% since 2023 across all demographics.",
            },
            {
                "rank": 8,
                "title": "Kids STEM & Creative Play",
                "category": "Toys & Education",
                "description": "Parents are actively seeking screen-free, educational toys. STEM kits, building sets, and creative play products command premium prices.",
                "opportunity": "Combine education with genuine fun — parents will pay 3x more for a toy they feel good about buying.",
                "growth_signal": "STEM toy market growing 12% annually, outpacing overall toy market at 3%.",
            },
            {
                "rank": 9,
                "title": "Car Organization & Accessories",
                "category": "Automotive",
                "description": "As people spend more time in cars (commutes, road trips, delivery gigs), vehicle organization and comfort accessories are a quiet goldmine.",
                "opportunity": "Simple, well-designed car organizers, phone mounts, and comfort accessories have massive volume potential.",
                "growth_signal": "Car accessories is a $50B global market with low brand loyalty — perfect for new entrants.",
            },
            {
                "rank": 10,
                "title": "Aging-in-Place Products",
                "category": "Health & Accessibility",
                "description": "Baby boomers want to stay in their homes longer. Products that add safety, comfort, and independence without looking 'medical' are in huge demand.",
                "opportunity": "Redesign any senior safety product to look modern and stylish — grab bars, pill organizers, shower seats.",
                "growth_signal": "65+ population growing 2x faster than total population; aging-in-place market at $15B.",
            },
        ]
    }


# ── Endpoints ────────────────────────────────────────────────────────

@router.get("/daily")
async def get_daily_insight():
    """Return a fresh LLM-generated go-to-market insight."""
    if not _has_llm_key():
        log.info("No LLM key — returning mock insight")
        return _mock_insight()

    try:
        prompt = build_daily_insight_prompt()
        result = await call_llm_async(
            prompt=prompt,
            json_schema_hint=DAILY_INSIGHT_SCHEMA,
            system=DAILY_INSIGHT_SYSTEM,
        )
        insight_text = result.get("insight", "")
        if not insight_text:
            return _mock_insight()
        return {"insight": insight_text}
    except (LLMError, Exception) as e:
        log.error("Daily insight LLM call failed: %s", e)
        return _mock_insight()


@router.get("/trends")
async def get_market_trends():
    """Return LLM-generated top 10 market trends for consumer products."""
    if not _has_llm_key():
        log.info("No LLM key — returning mock trends")
        return _mock_trends()

    try:
        prompt = build_market_trends_prompt()
        result = await call_llm_async(
            prompt=prompt,
            json_schema_hint=MARKET_TRENDS_SCHEMA,
            system=MARKET_TRENDS_SYSTEM,
        )
        trends = result.get("trends", [])
        if not trends:
            return _mock_trends()
        return {"trends": trends}
    except (LLMError, Exception) as e:
        log.error("Market trends LLM call failed: %s", e)
        return _mock_trends()
