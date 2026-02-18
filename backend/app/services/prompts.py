"""Prompt templates and helpers for the MouseTrap LLM calls.

Tone: Inspired by Lori Greiner — warm, direct, consumer-focused,
encouraging, and decisive. "Hero or a Zero" product evaluation style.
"""


# ── Shared helpers ───────────────────────────────────────────────────

def safe_json_instructions() -> str:
    return (
        "Respond with ONLY valid JSON. "
        "Do not include markdown fences, comments, or any text outside the JSON object."
    )


def no_legal_advice_instructions() -> str:
    return (
        "IMPORTANT: Do NOT make any legal conclusions about patentability. "
        "Do NOT state that an idea is or is not patentable. "
        "Use risk-signal language only (e.g., 'novelty risk: low/medium/high'). "
        "Always include a disclaimer that this is not legal advice."
    )


def lori_tone_instructions() -> str:
    return (
        "Write in a warm, enthusiastic, and direct voice — like Lori Greiner from Shark Tank. "
        "Channel her consumer-first instinct: she knows what everyday people need and want. "
        "Use her vocabulary: 'clever and unique', 'fresh and necessary', 'must-have', "
        "'solves a real problem', 'broad mass appeal', 'utilitarian luxury'. "
        "Be encouraging and decisive. Frame ideas through the lens of: "
        "Would this sell on QVC in four minutes? Would a shopper at Target pick this up "
        "and say 'I need that'? Could you demonstrate this on camera in 30 seconds? "
        "Think products that make everyday life easier, better, and more enjoyable. "
        "Keep language conversational, not technical or academic."
    )


# ── Prompt A: Generate Idea Variants (Sellable Ideas Engine) ─────────

GENERATE_VARIANTS_SYSTEM = (
    'You are the "Sellable Ideas Engine" — a product invention and commercialization expert. '
    "Your job: when a user inputs an existing product, app idea, or problem, you must generate "
    "ONLY the most sellable, high-quality upgrade ideas and adjacent product opportunities.\n\n"
    "PRIMARY OBJECTIVE — Generate ideas that are:\n"
    "- Highly desirable to real customers (painkiller > vitamin)\n"
    "- Realistic to build in < 12 months for an MVP and < 24 months for full product\n"
    "- Monetizable with clear pricing and strong margins\n"
    "- Differentiated with defensibility (patentable mechanism, data moat, network effects, distribution edge)\n"
    "- Written clearly enough to pitch to a retailer, investor, or engineering team immediately\n\n"
    "NON-NEGOTIABLE QUALITY BAR (FAIL FAST) — Before presenting ANY idea, silently reject it if:\n"
    "1) No clear target customer with urgent need\n"
    "2) No clear 'why this wins' vs alternatives\n"
    "3) No plausible path to $10M+ revenue\n"
    "4) No obvious monetization/pricing\n"
    '5) Too generic ("AI app for X") without a specific proprietary mechanism\n'
    "6) Depends on unrealistic behavior change or vague adoption\n\n"
    "GUARDRAILS:\n"
    "- Do not include copyrighted brands, trademarks, or cloning existing famous products.\n"
    "- Do not invent medical claims; if health-related, use 'wellness' language and suggest validation.\n"
    "- Avoid unsafe/illegal products.\n"
    "- Avoid ideas that require huge capex or regulated manufacturing unless user asked for it.\n"
    "- Prefer simple, shippable, high-margin ideas."
)

GENERATE_VARIANTS_SCHEMA = """{
  "customer_truth": {
    "buyer": "<who buys this>",
    "job_to_be_done": "<main job-to-be-done>",
    "purchase_drivers": ["driver1", "driver2", "driver3", "driver4", "driver5"],
    "complaints": ["complaint1", "complaint2", "complaint3", "complaint4", "complaint5"]
  },
  "top_ideas": [
    {
      "name": "<brandable 1-3 word name>",
      "one_line_pitch": "<one sentence pitch>",
      "target_customer": "<who specifically>",
      "core_problem": "<the pain point>",
      "solution": "<how it works>",
      "why_it_wins": ["<reason1>", "<reason2>", "<reason3>"],
      "monetization": "<price + model>",
      "unit_economics": "<COGS / margin notes>",
      "defensibility": "<what is claimable / moat>",
      "mvp_90_days": "<what to build first>",
      "go_to_market": ["<channel1>", "<channel2>", "<channel3>"],
      "risks": ["<risk + mitigation 1>", "<risk + mitigation 2>"],
      "scores": {
        "urgency": 8, "differentiation": 7, "speed_to_revenue": 9,
        "margin": 8, "defensibility": 6, "distribution": 7
      },
      "keywords": ["keyword1", "keyword2", "keyword3", "keyword4", "keyword5"]
    }
  ],
  "moonshot": {
    "name": "...", "one_line_pitch": "...", "target_customer": "...",
    "core_problem": "...", "solution": "...",
    "why_it_wins": ["...", "...", "..."],
    "monetization": "...", "unit_economics": "...", "defensibility": "...",
    "mvp_90_days": "...", "go_to_market": ["...", "...", "..."],
    "risks": ["...", "..."],
    "scores": { "urgency": 0, "differentiation": 0, "speed_to_revenue": 0, "margin": 0, "defensibility": 0, "distribution": 0 },
    "keywords": ["...", "...", "..."]
  },
  "more_upgrades": [
    { "name": "...", "one_line_pitch": "...", "why_it_wins": "..." }
  ],
  "adjacent_products": [
    { "name": "...", "one_line_pitch": "...", "why_it_sells": "..." }
  ],
  "recurring_revenue": [
    { "name": "...", "model": "...", "why_retention": "..." }
  ]
}"""


def build_generate_variants_prompt(product_text: str, category: str | None = None, random: bool = False) -> str:
    if random:
        product_line = (
            "Pick a random, common everyday consumer product — something you'd find in a "
            "typical household, kitchen, office, gym bag, car, or backpack. "
            "Think items like: water bottles, phone stands, lunch boxes, pet bowls, "
            "closet organizers, travel pillows, cable organizers, shower caddies, etc. "
            "Pick something that a wide cross-section of people use every single day. "
            "State which product you picked, then proceed with the full analysis."
        )
    else:
        product_line = f"Product: {product_text}"

    cat_line = f"\nProduct category: {category}" if category else ""

    return f"""{product_line}{cat_line}

Follow this exact process:

STEP 1 — Define the starting point:
- What the product is
- Who buys it
- The top 5 purchase drivers (what people actually pay for)
- The top 5 complaints/frictions

STEP 2 — Find the "unfair advantages":
Generate 10-15 candidate differentiators using:
- Convenience multipliers (time saved, steps removed)
- Reliability improvements (less failure, fewer errors)
- Status/aesthetics/identity
- Personalization
- Bundling/attachment/consumables
- Subscription/refill economics
- Marketplace/network effect possibilities
- Sensor/data/automation opportunities
- Regulatory or compliance angles (if relevant)

STEP 3 — Generate only BEST-IN-CLASS outputs:
A) 8 "Upgrade the product" concepts (next-gen versions)
B) 5 "Adjacent products" that this buyer would also want
C) 3 "Platform/recurring revenue" plays (subscription, consumables, services, data)

STEP 4 — Score and select winners:
For every idea, score 1-10 on: Customer urgency, Differentiation strength, Speed to revenue,
Margin potential, Defensibility, Distribution advantage.
Then choose:
- Top 3 "Most Sellable Now"
- Top 1 "Moonshot but Plausible"

OUTPUT REQUIREMENTS:
- "customer_truth": buyer analysis from Step 1
- "top_ideas": exactly 3 most sellable ideas with FULL detail (all fields filled)
- "moonshot": 1 moonshot idea with FULL detail
- "more_upgrades": 5 remaining upgrade ideas (name + pitch + why)
- "adjacent_products": 5 adjacent products (name + pitch + why)
- "recurring_revenue": 3 recurring revenue plays (name + model + why)

For each top idea and moonshot, include 3-5 keywords useful for patent searching
(include technical synonyms).

{safe_json_instructions()}"""


def build_guided_variants_prompt(
    product_text: str,
    guided_context: dict,
    category: str | None = None,
) -> str:
    """Build a richer prompt using the user's guided wizard answers."""
    pain_points = guided_context.get("pain_points", "").strip()
    target_customer = guided_context.get("target_customer", "").strip()
    hypothesis = guided_context.get("hypothesis", "").strip()
    market_context = guided_context.get("market_context", "").strip()

    cat_line = f"\nProduct category: {category}" if category else ""

    brief_sections = []
    if pain_points:
        brief_sections.append(f"PAIN POINTS & FRUSTRATIONS:\n{pain_points}")
    if target_customer:
        brief_sections.append(f"TARGET CUSTOMER:\n{target_customer}")
    if hypothesis:
        brief_sections.append(f"OWNER'S HYPOTHESIS / INSTINCT:\n{hypothesis}")
    if market_context:
        brief_sections.append(f"COMPETITIVE LANDSCAPE & WHITE SPACE:\n{market_context}")

    brief_block = "\n\n".join(brief_sections)

    return f"""Product: {product_text}{cat_line}

--- CLIENT BRIEF FROM THE PRODUCT OWNER ---
The product owner has provided first-hand research and insights. Treat this as
primary qualitative research — it should heavily influence your idea generation.

{brief_block}
--- END CLIENT BRIEF ---

Using the owner's brief as your primary input, follow this process:

STEP 1 — Validate and enrich the starting point:
- Confirm or refine the product definition using the owner's brief
- Identify the buyer (use the owner's target customer input as the starting point)
- Map the top 5 purchase drivers — prioritize the pain points the owner identified
- Map the top 5 complaints/frictions — start from the owner's frustrations

STEP 2 — Find the "unfair advantages" (informed by the owner's hypothesis):
Generate 10-15 candidate differentiators. Weight the owner's instincts heavily:
- Convenience multipliers (time saved, steps removed)
- Reliability improvements (less failure, fewer errors)
- Status/aesthetics/identity
- Personalization
- Bundling/attachment/consumables
- Subscription/refill economics
- Marketplace/network effect possibilities
- Sensor/data/automation opportunities
- Regulatory or compliance angles (if relevant)
- White space identified in the owner's market context

STEP 3 — Generate only BEST-IN-CLASS outputs:
A) 8 "Upgrade the product" concepts (next-gen versions) — align with owner's hypothesis
B) 5 "Adjacent products" that this buyer would also want
C) 3 "Platform/recurring revenue" plays (subscription, consumables, services, data)

STEP 4 — Score and select winners:
For every idea, score 1-10 on: Customer urgency, Differentiation strength, Speed to revenue,
Margin potential, Defensibility, Distribution advantage.
Then choose:
- Top 3 "Most Sellable Now"
- Top 1 "Moonshot but Plausible"

OUTPUT REQUIREMENTS:
- "customer_truth": buyer analysis from Step 1 (enriched by owner's brief)
- "top_ideas": exactly 3 most sellable ideas with FULL detail (all fields filled)
- "moonshot": 1 moonshot idea with FULL detail
- "more_upgrades": 5 remaining upgrade ideas (name + pitch + why)
- "adjacent_products": 5 adjacent products (name + pitch + why)
- "recurring_revenue": 3 recurring revenue plays (name + model + why)

For each top idea and moonshot, include 3-5 keywords useful for patent searching
(include technical synonyms).

{safe_json_instructions()}"""


# ── Prompt B: Generate Idea Spec (claim-like) ────────────────────────

GENERATE_SPEC_SYSTEM = (
    "You are an expert at turning great product ideas into clear, structured concept specs. "
    "You think like Lori Greiner — always starting from the consumer benefit and working "
    "backward to the mechanism. You highlight what makes an idea clever and unique, "
    "how it actually works, and why it's different from what's already on the market. "
    "You write in a direct, accessible style — no jargon unless necessary for patent searching. "
    + no_legal_advice_instructions()
)

GENERATE_SPEC_SCHEMA = """{
  "spec": {
    "novelty": "<what is new about this approach>",
    "mechanism": "<how it works technically>",
    "baseline": "<what currently exists that this improves upon>",
    "differentiators": ["diff1", "diff2", "..."],
    "keywords": ["keyword1", "keyword2", "..."],
    "searchQueries": ["query1", "query2", "query3"],
    "disclaimer": "This is not legal advice. This search is not exhaustive. Consult a patent attorney."
  }
}"""


def build_generate_spec_prompt(
    product_text: str,
    variant_title: str,
    variant_summary: str,
    variant_keywords: list[str],
) -> str:
    kw_str = ", ".join(variant_keywords)
    return f"""Original product: {product_text}

Selected improvement variant:
  Title: {variant_title}
  Summary: {variant_summary}
  Keywords: {kw_str}

Create a structured concept specification for this variant. Think like a product innovator
who knows what sells — start with WHY a consumer would love this, then get into HOW it works.

Include:
1. "novelty" — What's genuinely clever and unique about this approach? What makes it fresh
   and necessary? Write 1-2 sentences a consumer could understand. (Think: what would make
   someone say "why didn't this exist before?")
2. "mechanism" — How does the improvement actually work at a technical level? Be specific
   but accessible. (2-3 sentences)
3. "baseline" — What currently exists in the market? What do consumers use today, and what's
   frustrating about it? (1-2 sentences)
4. "differentiators" — A list of 3-5 specific ways this stands apart from existing solutions.
   Frame each one as a consumer benefit.
5. "keywords" — 5-8 technical keywords and synonyms useful for patent prior-art searching.
   Include both everyday terms and technical/CPC/IPC classification terms.
6. "searchQueries" — 3-5 natural-language search queries suitable for a patent database search.
   Each should target a different angle of the invention.
7. "disclaimer" — Always set to: "This is not legal advice. This search is not exhaustive. Consult a patent attorney."

{safe_json_instructions()}"""


# ── Prompt C: Rerank + Explain Similarity ────────────────────────────

RERANK_SYSTEM = (
    "You are a sharp-eyed patent analyst who evaluates prior art the way a savvy product "
    "investor would — looking at real functional overlap, not just surface-level keyword matches. "
    "You give concrete, specific explanations that a non-lawyer could understand. "
    "Be honest and direct: if something is really similar, say so clearly. If it's only "
    "tangentially related, explain why it's not a real concern. "
    + no_legal_advice_instructions()
)

RERANK_SCHEMA = """{
  "results": [
    {
      "patentId": "<patent id>",
      "score": 0.0 to 1.0,
      "whySimilar": "<2-3 sentences explaining concrete overlap and differences>"
    }
  ]
}"""


def build_rerank_prompt(
    spec_novelty: str,
    spec_mechanism: str,
    spec_differentiators: list[str],
    patents: list[dict],
) -> str:
    diffs = "\n".join(f"  - {d}" for d in spec_differentiators)
    patent_block = ""
    for p in patents:
        patent_block += (
            f"\n--- Patent {p['patent_id']} ---\n"
            f"Title: {p['title']}\n"
            f"Abstract: {p['abstract']}\n"
        )

    return f"""Invention concept:
  Novelty: {spec_novelty}
  Mechanism: {spec_mechanism}
  Differentiators:
{diffs}

Below are patent search results. For each patent, assess how similar it really is to our
invention concept — look at actual functional overlap, not just shared keywords.

Give each a score from 0.0 (completely unrelated) to 1.0 (virtually identical).
Write 2-3 clear sentences explaining WHY it is similar or different — be specific about
overlapping features, shared mechanisms, or addressed problem domains. Write so a
non-patent-expert could understand the comparison.

Patents to evaluate:
{patent_block}

{safe_json_instructions()}"""


# ── Prompt D: USPTO Provisional Patent Application ─────────────────

PROVISIONAL_PATENT_SYSTEM = (
    "You are a USPTO provisional patent application drafting assistant. "
    "You create provisional patent applications that comply with 35 U.S.C. §112(a) "
    "and follow the USPTO provisional application format. Your drafts include all "
    "required sections: cover sheet, complete specification (title, background, summary, "
    "detailed description), abstract, and claims. You write with precise technical "
    "terminology but clearly enough that an inventor can understand every section. "
    "Your goal is to produce a draft that is 'as complete as possible' per USPTO guidance, "
    "so the inventor can file it to establish a priority date and later convert to a "
    "nonprovisional application within the 12-month pendency period. "
    + no_legal_advice_instructions()
)

PROVISIONAL_PATENT_SCHEMA = """{
  "cover_sheet": {
    "invention_title": "<formal descriptive title, not marketing language>",
    "filing_date_note": "<note about 12-month pendency period>"
  },
  "specification": {
    "title_of_invention": "<same as cover sheet title>",
    "cross_reference": null,
    "background": {
      "field_of_invention": "<1-2 paragraphs describing the technical field>",
      "description_of_prior_art": "<2-3 paragraphs on existing solutions and their limitations>"
    },
    "summary": "<2-3 paragraphs summarizing the invention and its advantages>",
    "brief_description_of_drawings": "<optional: describe what figures would show>",
    "detailed_description": "<4-6 paragraphs: preferred embodiment, operation, variations, advantages>"
  },
  "abstract": "<exactly 150 words - technical summary of the disclosure>",
  "claims": {
    "independent": ["<claim 1>", "<claim 2>"],
    "dependent": ["<claim 3 referencing claim 1>", "<claim 4>", "..."]
  },
  "drawings_note": "<recommendation on whether drawings should be prepared and what they should depict>"
}"""


def build_provisional_patent_prompt(
    product_text: str,
    variant_title: str,
    variant_summary: str,
    spec_novelty: str,
    spec_mechanism: str,
    spec_baseline: str,
    spec_differentiators: list[str],
    patent_hits: list[dict],
) -> str:
    diffs = "\n".join(f"  - {d}" for d in spec_differentiators)

    prior_art_block = ""
    if patent_hits:
        for p in patent_hits[:5]:
            prior_art_block += (
                f"\n  - {p.get('title', 'Unknown')} ({p.get('patent_id', '')}): "
                f"Score {p.get('score', 0):.2f} — {p.get('why_similar', '')}"
            )
    else:
        prior_art_block = "\n  No significant prior art found."

    return f"""Draft a complete USPTO provisional patent application for this invention.
Follow the provisional application format per 35 U.S.C. §111(b) and comply with
the written description requirement of 35 U.S.C. §112(a).

Product: {product_text}
Invention: {variant_title}
Summary: {variant_summary}

Technical Details:
  Novelty: {spec_novelty}
  Mechanism: {spec_mechanism}
  Baseline (existing solutions): {spec_baseline}
  Differentiators:
{diffs}

Prior Art Search Results:{prior_art_block}

Generate a complete provisional patent application with these sections:

1. "cover_sheet" — Object with:
   - "invention_title": A formal, descriptive title (not marketing language)
   - "filing_date_note": A brief note about the 12-month pendency period

2. "specification" — Object with the full written description:
   - "title_of_invention": Same as cover sheet title
   - "cross_reference": null (no related applications)
   - "background": Object with:
     - "field_of_invention": 1-2 paragraphs on the technical field
     - "description_of_prior_art": 2-3 paragraphs describing existing solutions,
       referencing the prior art found above, and explaining their limitations
   - "summary": 2-3 paragraphs summarizing the invention and its key advantages
   - "brief_description_of_drawings": Describe what figures would depict (e.g.,
     "FIG. 1 is a perspective view...", "FIG. 2 is a block diagram...")
   - "detailed_description": 4-6 substantive paragraphs covering:
     - The preferred embodiment in detail
     - How the invention operates
     - Alternative embodiments or variations
     - Specific materials, dimensions, or configurations where applicable
     - Advantages over the prior art
     The description must be detailed enough that someone skilled in the art could
     make and use the invention (enablement requirement).

3. "abstract" — Exactly 150 words. Technical summary of the disclosure. Must state
   the technical field, the problem solved, and the gist of the solution.

4. "claims" — Object with:
   - "independent": 2-3 independent claims in standard patent language
     (e.g., "A device comprising: a first element configured to...; a second element...")
   - "dependent": 4-6 dependent claims referencing independent claims
     (e.g., "The device of claim 1, wherein the first element further comprises...")
   Note: Claims are optional in a provisional but strongly recommended for scope.

5. "drawings_note" — Recommend what drawings the inventor should prepare before filing.
   Suggest specific figures (perspective view, exploded view, block diagram, flowchart)
   that would best illustrate the invention. Note that drawings cannot be added after filing.

IMPORTANT REQUIREMENTS:
- The specification must be as complete as possible. The nonprovisional application
  filed within 12 months can only claim subject matter disclosed in this provisional.
- Keep the "detailed_description" to 4-6 focused paragraphs (not excessively long).
- You MUST include ALL sections: cover_sheet, specification, abstract, claims, AND drawings_note.
  Do NOT omit the abstract, claims, or drawings_note — they are required fields.

{safe_json_instructions()}"""


# ── Prompt H: Daily Insight ───────────────────────────────────────────

DAILY_INSIGHT_SYSTEM = (
    "You are a retail trend analyst and go-to-market strategist. "
    "You produce a single punchy, actionable insight about consumer product trends, "
    "retail go-to-market strategies, or product innovation opportunities. "
    + lori_tone_instructions()
)

DAILY_INSIGHT_SCHEMA = """{
  "insight": "<2-3 sentence insight about a current retail/product trend or go-to-market tip>"
}"""


def build_daily_insight_prompt() -> str:
    import random
    topics = [
        "a surprising consumer product trend gaining traction right now",
        "a go-to-market strategy that's working for new consumer products",
        "an underserved product category with high demand",
        "a retail channel strategy tip for new product launches",
        "a pricing or packaging insight for consumer goods",
        "a social media or influencer strategy for product launches",
        "a D2C vs retail distribution insight",
        "a product bundling or subscription model trend",
    ]
    topic = random.choice(topics)
    return f"""Generate ONE fresh, specific insight about: {topic}

The insight should be:
- Specific (name a real category, channel, or tactic — not generic advice)
- Actionable (something an inventor or entrepreneur could act on this week)
- Current (feels like 2025/2026 market intelligence)
- Concise (2-3 punchy sentences max)

{safe_json_instructions()}"""


# ── Prompt I: Market Trends ──────────────────────────────────────────

MARKET_TRENDS_SYSTEM = (
    "You are a consumer product market analyst who tracks trending product "
    "categories, emerging consumer behaviors, and high-growth opportunities. "
    "You combine data-driven thinking with consumer intuition. "
    + lori_tone_instructions()
)

MARKET_TRENDS_SCHEMA = """{
  "trends": [
    {
      "rank": 1,
      "title": "<trend name>",
      "category": "<product category>",
      "description": "<2-3 sentence description of the trend>",
      "opportunity": "<1 sentence about the product opportunity>",
      "growth_signal": "<what data or signal indicates this is growing>"
    }
  ]
}"""


def build_market_trends_prompt() -> str:
    return f"""Generate the TOP 10 current market trends for consumer-focused products.

Focus on:
- Product categories with high growth or emerging demand
- Consumer behavior shifts creating new product opportunities
- Categories where innovative products could win big

For each trend provide:
1. "rank" — 1 through 10 (most impactful first)
2. "title" — Short, punchy trend name (3-6 words)
3. "category" — The product category (e.g., "Home & Kitchen", "Pet Tech", "Personal Wellness")
4. "description" — 2-3 sentences on what's happening and why it matters
5. "opportunity" — 1 sentence on the product opportunity for an inventor/entrepreneur
6. "growth_signal" — What data point or signal indicates this trend is real and growing

Make these feel current and specific — not generic "AI is growing" type observations.
Think categories where a scrappy inventor could actually launch something.

{safe_json_instructions()}"""


# ── Prompt F: Invention Analysis (Pre-Search) ────────────────────────

INVENTION_ANALYSIS_SYSTEM = (
    "You are an expert patent search strategist. Before searching any database, you "
    "thoroughly analyze an invention to understand its core concept, essential elements, "
    "and the multiple angles from which prior art might exist. You think like a patent "
    "examiner — considering not just what the invention IS, but what it DOES, how it "
    "works, what problem it solves, and what alternative implementations could achieve "
    "the same result. You are an expert in CPC (Cooperative Patent Classification) codes "
    "and know how to construct diverse search strategies that cover keyword variations, "
    "technical structure, use cases, and functional synonyms. "
    + no_legal_advice_instructions()
)

INVENTION_ANALYSIS_SCHEMA = """{
  "core_concept": "<1-2 sentences describing the fundamental inventive concept>",
  "essential_elements": ["<element 1>", "<element 2>", "..."],
  "alternative_implementations": ["<alt 1>", "<alt 2>", "..."],
  "cpc_codes": [
    {
      "code": "<CPC code, e.g., A47J36/02>",
      "description": "<what this classification covers>",
      "rationale": "<why this is relevant to the invention>"
    }
  ],
  "search_strategies": [
    {
      "query": "<patent search query>",
      "approach": "function_words|technical_structure|use_case|synonyms",
      "target_field": "title|abstract"
    }
  ]
}"""


def build_invention_analysis_prompt(
    product_text: str,
    variant_title: str,
    variant_summary: str,
    variant_keywords: list[str],
    spec_novelty: str,
    spec_mechanism: str,
    spec_baseline: str,
    spec_differentiators: list[str],
    spec_keywords: list[str],
) -> str:
    v_kw = ", ".join(variant_keywords)
    s_kw = ", ".join(spec_keywords)
    diffs = "\n".join(f"  - {d}" for d in spec_differentiators)

    return f"""Analyze this invention BEFORE we search any patent database. Your analysis will
guide our multi-phase patent search strategy.

Product: {product_text}
Invention: {variant_title}
Summary: {variant_summary}
Variant Keywords: {v_kw}

Concept Specification:
  Novelty: {spec_novelty}
  Mechanism: {spec_mechanism}
  Baseline (what exists today): {spec_baseline}
  Differentiators:
{diffs}
  Technical Keywords: {s_kw}

Perform a thorough invention analysis:

1. "core_concept" — Distill the invention into its fundamental inventive concept in 1-2 sentences.
   Focus on what is truly new — the combination of elements, the mechanism, or the application
   that makes this different from what exists.

2. "essential_elements" — List 4-6 essential elements that define this invention. These are the
   features that, taken together, make this invention novel. Think like a patent examiner
   identifying claim elements.

3. "alternative_implementations" — List 3-5 alternative ways someone might achieve the same
   result or solve the same problem. This helps us find prior art that approaches the problem
   from different angles but achieves similar outcomes.

4. "cpc_codes" — Suggest 3-5 CPC classification codes that are most likely to contain relevant
   prior art. For each, provide the code (e.g., A47J36/02), a brief description of what that
   classification covers, and why it's relevant to this invention. Be specific — don't just
   use top-level codes. Think about both the primary technology area AND secondary areas
   where related solutions might be classified.

5. "search_strategies" — Generate 12-16 diverse search queries using FIVE different approaches:
   - "baseline_product": Queries for the BASE PRODUCT CATEGORY that already exists on the market.
     These should find EXISTING competing products and their patents. Use simple, common product
     terms that real consumers and companies use. For example, if the invention is a "smart dog
     collar with geofencing", the baseline queries should be "GPS pet tracker", "dog location
     tracking collar", "pet GPS tracking device". 3-4 queries. THIS IS THE MOST IMPORTANT
     CATEGORY — if you skip this, we will miss the most obvious prior art.
   - "function_words": Queries using functional language (e.g., "apparatus for tracking animal
     location using wireless signals"). 2-3 queries.
   - "technical_structure": Queries describing the physical/technical structure (e.g., "wearable
     collar with integrated GPS receiver and cellular transmitter"). 2-3 queries.
   - "use_case": Queries describing the use case or problem solved (e.g., "pet escape prevention
     and recovery system"). 2-3 queries.
   - "synonyms": Queries using alternative terminology and synonyms (e.g., "companion animal
     monitoring apparatus with geofence boundary detection"). 2-3 queries.

   For each query, specify whether it should target the patent "title" or "abstract" field.
   Title searches are more precise; abstract searches cast a wider net.
   IMPORTANT: baseline_product queries should target "title" for precision.

CRITICAL: Do NOT only search for the NOVEL features of the invention. You MUST also search for
the BASE PRODUCT CATEGORY. A patent examiner always starts by finding what already exists in
the product space before evaluating what is new. The most relevant prior art is often the
existing product that this invention improves upon.

{safe_json_instructions()}"""


# ── Prompt G: Professional Patent Analysis (Post-Search) ─────────────

PROFESSIONAL_ANALYSIS_SYSTEM = (
    "You are a patent analysis professional who evaluates prior art search results to "
    "provide a comprehensive risk assessment. You think like a patent examiner conducting "
    "a novelty and non-obviousness analysis under 35 U.S.C. §§ 102 and 103. You assess "
    "each piece of prior art on its merits and produce a clear, structured evaluation. "
    "You are thorough but practical — your analysis helps inventors make informed decisions "
    "about whether and how to pursue patent protection. You write clearly enough for a "
    "non-lawyer to understand, but with enough rigor for a patent attorney to use as a "
    "starting point. "
    + no_legal_advice_instructions() + " "
    + lori_tone_instructions()
)

PROFESSIONAL_ANALYSIS_SCHEMA = """{
  "novelty_assessment": {
    "risk_level": "low|medium|high",
    "summary": "<2-3 sentence assessment of novelty risk>",
    "closest_reference": "<patent_id of closest prior art, or null>",
    "missing_elements": ["<elements of the invention NOT found in any prior art>"]
  },
  "obviousness_assessment": {
    "risk_level": "low|medium|high",
    "summary": "<2-3 sentence assessment of obviousness risk>",
    "combination_refs": ["<patent_ids that could be combined to render obvious>"]
  },
  "eligibility_note": {
    "applies": true/false,
    "summary": "<1-2 sentences on §101 eligibility concerns, if any>"
  },
  "prior_art_summary": {
    "overall_risk": "low|medium|high",
    "narrative": "<3-5 sentence narrative summarizing the prior art landscape>",
    "key_findings": ["<finding 1>", "<finding 2>", "..."]
  },
  "claim_strategy": {
    "recommended_filing": "provisional|non_provisional|design_patent|defer|abandon",
    "rationale": "<2-3 sentence explanation of the recommendation>",
    "suggested_independent_claims": ["<claim 1 in patent language>", "..."],
    "risk_areas": ["<area of risk 1>", "..."]
  },
  "scored_hits": [
    {
      "patent_id": "<patent_id>",
      "score": 0.0,
      "why_similar": "<2-3 sentences>"
    }
  ],
  "disclaimer": "This is an automated preliminary analysis and does not constitute legal advice. This search is not exhaustive. Consult a registered patent attorney for a professional patentability opinion."
}"""


def build_professional_analysis_prompt(
    product_text: str,
    variant_title: str,
    variant_summary: str,
    spec_novelty: str,
    spec_mechanism: str,
    spec_baseline: str,
    spec_differentiators: list[str],
    essential_elements: list[str],
    patents: list[dict],
) -> str:
    diffs = "\n".join(f"  - {d}" for d in spec_differentiators)
    elements = "\n".join(f"  - {e}" for e in essential_elements)

    patent_block = ""
    for p in patents:
        cpc_str = ", ".join(p.get("cpc_codes", []))
        patent_block += (
            f"\n--- Patent {p.get('patent_id', 'Unknown')} (Source: {p.get('source_phase', 'unknown')}) ---\n"
            f"Title: {p.get('title', '')}\n"
            f"Abstract: {p.get('abstract', '')}\n"
            f"Assignee: {p.get('assignee', 'Unknown')}\n"
            f"Date: {p.get('date', 'Unknown')}\n"
        )
        if cpc_str:
            patent_block += f"CPC Codes: {cpc_str}\n"

    return f"""Perform a comprehensive patent analysis based on the invention and prior art below.

INVENTION:
  Product: {product_text}
  Title: {variant_title}
  Summary: {variant_summary}

SPECIFICATION:
  Novelty: {spec_novelty}
  Mechanism: {spec_mechanism}
  Baseline: {spec_baseline}
  Differentiators:
{diffs}

ESSENTIAL ELEMENTS (from invention analysis):
{elements}

PRIOR ART FOUND ({len(patents)} patents):
{patent_block if patent_block else "  No prior art found in the search."}

Analyze the prior art and provide:

1. "novelty_assessment" — Assess novelty risk (low/medium/high).
   - LOW: No single prior art reference discloses all essential elements.
   - MEDIUM: One reference comes close but is missing 1-2 key elements.
   - HIGH: A single reference appears to disclose substantially all elements.
   Identify the closest reference and list which essential elements are NOT found in prior art.

2. "obviousness_assessment" — Assess non-obviousness risk (low/medium/high).
   - LOW: The combination of elements would not be obvious to someone skilled in the art.
   - MEDIUM: 2-3 references could plausibly be combined to arrive at the invention.
   - HIGH: The invention seems like an obvious combination of known elements.
   List which patents could be combined to render the invention obvious.

3. "eligibility_note" — Flag any §101 patent eligibility concerns.
   Set "applies" to true only if there's a genuine concern (abstract ideas, laws of nature,
   natural phenomena). Most consumer products are eligible — don't flag unless there's a real issue.

4. "prior_art_summary" — Provide an overall risk assessment (low/medium/high).
   Write a 3-5 sentence narrative summarizing the prior art landscape in plain language —
   warm, direct, and encouraging where appropriate. Like explaining to a friend whether their
   idea has a clear path forward. List 3-5 key findings.

5. "claim_strategy" — Recommend a filing strategy:
   - "provisional" — Good idea with some risk; file provisional to establish priority date.
   - "non_provisional" — Strong idea with low risk; worth investing in a full application.
   - "design_patent" — Utility claims risky but the design/appearance is protectable.
   - "defer" — More research needed before filing.
   - "abandon" — Very high risk; prior art substantially covers the invention.
   Provide 2-3 suggested independent claims in standard patent language.
   List specific risk areas to address.

6. "scored_hits" — For each patent, provide a relevance score (0.0-1.0) and a 2-3 sentence
   explanation of how it compares to the invention. Be specific about overlapping and
   different features.

7. "disclaimer" — Always include: "This is an automated preliminary analysis and does not
   constitute legal advice. This search is not exhaustive. Consult a registered patent
   attorney for a professional patentability opinion."

{safe_json_instructions()}"""
