"""Prompt templates and helpers for the Better Mousetrap LLM calls."""


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
    "You are an expert product innovation consultant. "
    "Given a product description, you brainstorm creative improvements. "
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


def build_generate_variants_prompt(product_text: str, category: str | None = None) -> str:
    cat_line = f"\nProduct category: {category}" if category else ""
    return f"""Product: {product_text}{cat_line}

Generate exactly 10 creative "better version" variants of this product. Each variant should
propose a meaningfully different improvement. Cover a diverse mix of improvement modes:
cost_down, durability, safety, convenience, sustainability, performance, and mashup (combining
ideas from other domains).

For each variant provide:
- A unique UUID as the id
- A concise, descriptive title
- A 2-3 sentence summary of the improvement
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
