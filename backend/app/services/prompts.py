"""Prompt templates and helpers for the MouseTrap LLM calls."""


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


# ── Prompt A: Generate Idea Variants ─────────────────────────────────

GENERATE_VARIANTS_SYSTEM = (
    "You are an expert consumer product innovation consultant. "
    "You specialize in everyday consumer products — the kind of items that sell well "
    "on Amazon, at Target, Walmart, or Costco. Think kitchen gadgets, home organization, "
    "fitness accessories, pet products, travel gear, phone accessories, desk accessories, "
    "kids' products, and similar mass-market goods. "
    "Your ideas should be practical, manufacturable, and appealing to everyday shoppers — "
    "not scientific instruments, industrial equipment, or overly technical devices. "
    "Each idea should feel like something a regular person would see and say 'I need that.' "
    + no_legal_advice_instructions()
)

GENERATE_VARIANTS_SCHEMA = """{
  "variants": [
    {
      "id": "<uuid string>",
      "title": "<short title>",
      "summary": "<2-3 sentence description>",
      "improvementMode": "cost_down|durability|safety|convenience|sustainability|performance|mashup",
      "keywords": ["keyword1", "keyword2", "..."]
    }
  ]
}"""


def build_generate_variants_prompt(product_text: str, category: str | None = None, random: bool = False) -> str:
    if random:
        product_line = (
            "Pick a random, common everyday consumer product — something you'd find in a "
            "typical household, kitchen, office, gym bag, car, or backpack. "
            "Think items like: water bottles, phone stands, lunch boxes, pet bowls, "
            "closet organizers, travel pillows, cable organizers, shower caddies, etc."
        )
    else:
        product_line = (
            f"Product: {product_text}\n\n"
            "Think about this product as a consumer would encounter it — on a store shelf, "
            "in an Amazon listing, or in a friend's house. What would make someone pick up "
            "this product and say 'this is way better than what I have now'?"
        )

    cat_line = f"\nProduct category: {category}" if category else ""

    return f"""{product_line}{cat_line}

Generate exactly 10 creative "better version" variants of this product. Each variant should
propose a meaningfully different improvement that a mass-market consumer would actually want.

CRITICAL — Keep ideas consumer-focused and sellable:
- Every idea should feel like a real product listing on Amazon, Target, or Costco
- Write titles like product names a shopper would search for (e.g., "Self-Draining Dish Rack with Built-In Drying Mat")
- Focus on everyday pain points: mess, storage, portability, ease of cleaning, setup time, etc.
- Avoid overly scientific, industrial, or technical solutions — no lab equipment, no industrial machinery
- Each idea should be simple enough to explain in one sentence to a friend
- Think about what makes a product go viral on TikTok or get featured on Shark Tank
- Consider the "I didn't know I needed this" factor

Make each variant meaningfully DIFFERENTIATED from the others — don't just tweak the same angle 10 times.
Cover a diverse mix of improvement modes:
cost_down, durability, safety, convenience, sustainability, performance, and mashup (combining
ideas from other product domains in surprising ways).

For each variant provide:
- A unique UUID as the id
- A concise, catchy title (like a product listing name shoppers would click on)
- A 2-3 sentence summary written like a compelling product description, not a technical paper
- The primary improvement mode
- 3-5 keywords useful for patent searching (include technical synonyms)

{safe_json_instructions()}"""


# ── Prompt B: Generate Idea Spec (claim-like) ────────────────────────

GENERATE_SPEC_SYSTEM = (
    "You are an expert at structuring invention disclosures. "
    "You translate product improvement ideas into structured concept specifications "
    "that highlight what is novel, the mechanism, and how it differs from the baseline. "
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

Create a structured concept specification for this variant. Include:
1. "novelty" — What is genuinely new about this approach (1-2 sentences).
2. "mechanism" — How the improvement works at a technical level (2-3 sentences).
3. "baseline" — What currently exists in the market that this improves upon (1-2 sentences).
4. "differentiators" — A list of 3-5 specific ways this differs from existing solutions.
5. "keywords" — 5-8 technical keywords and synonyms useful for patent prior-art searching.
   Include both common and technical terms. Think about CPC/IPC classification terms.
6. "searchQueries" — 3-5 natural-language search queries suitable for a patent database search.
   Each should target a different angle of the invention.
7. "disclaimer" — Always set to: "This is not legal advice. This search is not exhaustive. Consult a patent attorney."

{safe_json_instructions()}"""


# ── Prompt C: Rerank + Explain Similarity ────────────────────────────

RERANK_SYSTEM = (
    "You are a patent analyst. You assess how similar a patent is to an invention concept. "
    "You give concrete, specific explanations of overlap and differences. "
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

Below are patent search results. For each patent, assess its similarity to the invention concept.
Give each a score from 0.0 (completely unrelated) to 1.0 (virtually identical).
Write 2-3 sentences explaining WHY it is similar or different — be specific about overlapping
features, shared mechanisms, or addressed problem domains.

Patents to evaluate:
{patent_block}

{safe_json_instructions()}"""


# ── Prompt D: Provisional Patent Draft ─────────────────────────────

PROVISIONAL_PATENT_SYSTEM = (
    "You are a patent drafting assistant. You create provisional patent application "
    "drafts in standard USPTO format. You write in formal patent language with precise "
    "technical terminology. "
    + no_legal_advice_instructions()
)

PROVISIONAL_PATENT_SCHEMA = """{
  "title": "<invention title>",
  "abstract": "<150-word abstract>",
  "claims": {
    "independent": ["<independent claim 1>", "..."],
    "dependent": ["<dependent claim referencing an independent claim>", "..."]
  },
  "detailed_description": "<multi-paragraph detailed description of the invention>",
  "prior_art_discussion": "<discussion of known prior art and how this invention differs>"
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

    return f"""Create a provisional patent application draft for this invention.

Product: {product_text}
Invention: {variant_title}
Summary: {variant_summary}

Technical Details:
  Novelty: {spec_novelty}
  Mechanism: {spec_mechanism}
  Baseline: {spec_baseline}
  Differentiators:
{diffs}

Prior Art Search Results:{prior_art_block}

Draft a complete provisional patent application with:
1. "title" — A formal invention title (descriptive, not marketing language)
2. "abstract" — A 150-word abstract in patent style
3. "claims" — An object with:
   - "independent": 2-3 independent claims covering the core invention
   - "dependent": 3-5 dependent claims adding specific features
   Claims should use standard patent claim language ("A method comprising...", "The method of claim 1, wherein...")
4. "detailed_description" — 3-5 paragraphs covering: field of invention, background, summary, detailed description of embodiments
5. "prior_art_discussion" — 1-2 paragraphs discussing the prior art found and how this invention differs

Include the disclaimer that this is not legal advice and should be reviewed by a patent attorney.

{safe_json_instructions()}"""


# ── Prompt E: Prototyping Package ──────────────────────────────────

PROTOTYPING_SYSTEM = (
    "You are an expert product prototyping consultant with deep experience in "
    "3D printing, electronics, CNC machining, woodworking, and other fabrication methods. "
    "You assess what fabrication methods are most appropriate for a given product and "
    "provide detailed, actionable build guides. Only suggest approaches that genuinely "
    "make sense for the product's form factor, materials, and complexity."
)

PROTOTYPING_SCHEMA = """{
  "approaches": [
    {
      "method": "<fabrication method, e.g., '3D Printing (FDM)', 'Arduino + 3D Printed Enclosure'>",
      "rationale": "<why this method fits this product>",
      "specs": {
        "dimensions": "<approximate dimensions>",
        "materials": "<recommended materials>",
        "tolerances": "<relevant tolerances if applicable>",
        "finish": "<surface finish recommendations>"
      },
      "bill_of_materials": [
        {"item": "<component name>", "quantity": "<qty>", "estimated_cost": "<USD>", "source": "<where to buy>"}
      ],
      "assembly_instructions": ["<step 1>", "<step 2>", "..."]
    }
  ]
}"""


def build_prototyping_prompt(
    product_text: str,
    variant_title: str,
    variant_summary: str,
    spec_mechanism: str,
    spec_differentiators: list[str],
) -> str:
    diffs = "\n".join(f"  - {d}" for d in spec_differentiators)

    return f"""Design a prototyping package for this product invention.

Product: {product_text}
Invention: {variant_title}
Summary: {variant_summary}

Technical Details:
  Mechanism: {spec_mechanism}
  Key Differentiators:
{diffs}

Provide 1-2 practical fabrication approaches for building a working prototype. For each approach:

1. "method" — The fabrication method (e.g., "3D Printing (FDM/SLA)", "Arduino + 3D Printed Enclosure",
   "CNC Machined Aluminum", "Laser-Cut Acrylic + Electronics", etc.)
   Only suggest methods that realistically work for this type of product.
2. "rationale" — Why this method is a good fit (2-3 sentences)
3. "specs" — Object with dimensions, materials, tolerances, and finish recommendations
4. "bill_of_materials" — Complete list of parts/materials with quantities, estimated costs in USD,
   and where to source them (Amazon, McMaster-Carr, Adafruit, local hardware store, etc.)
5. "assembly_instructions" — Step-by-step instructions (8-15 steps) that a hobbyist maker could follow

If the product involves electronics, include specific components (microcontrollers, sensors, etc.).
If 3D printing is appropriate, mention specific settings (layer height, infill, orientation).
Keep total prototype cost under $200 if possible.

{safe_json_instructions()}"""
