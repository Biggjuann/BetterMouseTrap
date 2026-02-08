"""Export service — generates markdown and plain-text one-pager summaries."""

from app.schemas.export import ExportRequest

DISCLAIMER = (
    "This is not legal advice. The prior-art search is not exhaustive "
    "and should not be used as a substitute for professional patent counsel."
)

NEXT_STEPS = [
    "Conduct a professional prior-art search",
    "Consult a patent attorney",
    "Document prototypes and iterations",
]


def build_markdown(req: ExportRequest) -> str:
    """Build a markdown-formatted one-pager from the export request."""
    lines = [
        f"# Concept One-Pager: {req.variant.title}",
        "",
        "## Product",
        req.product.text,
    ]

    if req.product.url:
        lines.append(f"\nReference: {req.product.url}")

    lines += [
        "",
        "## Concept Summary",
        req.variant.summary,
        "",
        "## Novelty",
        req.spec.novelty,
        "",
        "## Mechanism",
        req.spec.mechanism,
        "",
        "## Baseline",
        req.spec.baseline,
        "",
        "## Differentiators",
    ]
    for d in req.spec.differentiators:
        lines.append(f"- {d}")

    lines += [
        "",
        "## Keywords",
        ", ".join(req.spec.keywords),
        "",
        "## Closest Patents Found",
        "",
    ]

    if req.hits:
        for i, h in enumerate(req.hits[:10], 1):
            lines.append(f"### {i}. {h.title} ({h.patent_id})")
            lines.append(f"- **Score:** {h.score:.2f}")
            if h.assignee:
                lines.append(f"- **Assignee:** {h.assignee}")
            if h.date:
                lines.append(f"- **Date:** {h.date}")
            lines.append(f"- **Why similar:** {h.why_similar}")
            lines.append("")
    else:
        lines.append("_No patent results found._")
        lines.append("")

    lines += [
        "## Next Steps",
    ]
    for step in NEXT_STEPS:
        lines.append(f"- [ ] {step}")

    lines += [
        "",
        "---",
        f"**Disclaimer:** {DISCLAIMER}",
        "",
    ]

    return "\n".join(lines)


def build_plain_text(req: ExportRequest) -> str:
    """Build a plain-text formatted one-pager from the export request."""
    lines = [
        f"CONCEPT ONE-PAGER: {req.variant.title}",
        "=" * 60,
        "",
        f"PRODUCT: {req.product.text}",
    ]

    if req.product.url:
        lines.append(f"REFERENCE: {req.product.url}")

    lines += [
        "",
        f"SUMMARY: {req.variant.summary}",
        "",
        f"NOVELTY: {req.spec.novelty}",
        "",
        f"MECHANISM: {req.spec.mechanism}",
        "",
        f"BASELINE: {req.spec.baseline}",
        "",
        "DIFFERENTIATORS:",
    ]
    for d in req.spec.differentiators:
        lines.append(f"  - {d}")

    lines += [
        "",
        f"KEYWORDS: {', '.join(req.spec.keywords)}",
        "",
        "CLOSEST PATENTS FOUND:",
        "-" * 40,
    ]

    if req.hits:
        for i, h in enumerate(req.hits[:10], 1):
            lines.append(f"  {i}. {h.title} ({h.patent_id})")
            lines.append(f"     Score: {h.score:.2f}")
            if h.assignee:
                lines.append(f"     Assignee: {h.assignee}")
            if h.date:
                lines.append(f"     Date: {h.date}")
            lines.append(f"     Why similar: {h.why_similar}")
            lines.append("")
    else:
        lines.append("  No patent results found.")
        lines.append("")

    lines += [
        "NEXT STEPS:",
    ]
    for step in NEXT_STEPS:
        lines.append(f"  - {step}")

    lines += [
        "",
        "-" * 60,
        f"DISCLAIMER: {DISCLAIMER}",
    ]

    return "\n".join(lines)
