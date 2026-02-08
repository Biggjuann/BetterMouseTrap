# Better Mousetrap — Claude Code Plan (MVP v1)

## 0) Product Goal (MVP)
An iPhone app that:
1) Takes a product input (text, optional URL, or "Random").
2) Generates 8–12 "better versions" (idea variants).
3) Lets user pick one variant and produces a structured "claim-like" concept spec.
4) Runs a prior-art search against patents (PatentsView PatentSearch API) and returns top matches with similarity explanations.
5) Exports a 1-page concept + prior-art summary (PDF or share sheet text).

Constraints:
- Do NOT claim "patentable/not patentable." Use risk signals + disclaimers.
- MVP uses only patent search (no scraping products). Product links are optional; extract features later.

---

## 1) Architecture Overview
### Client (iOS)
- SwiftUI app
- Screens:
  - Home / Input
  - Ideas list
  - Idea detail (structured spec)
  - Prior art results
  - Export/share

### Backend (FastAPI)
Responsibilities:
- Idea generation (LLM call)
- "Claim-like" structured concept generation (LLM call)
- Patent prior-art search via PatentsView API
- Lightweight similarity scoring + explanation (LLM rerank/explain)
- Export payload builder

Data:
- MVP stores sessions in SQLite (or Postgres if you prefer), but can be stateless initially.

---

## 2) Repo Layout
Create a mono-repo:
better-mousetrap/
  ios/
    BetterMousetrap/
      BetterMousetrapApp.swift
      Views/
      Models/
      Services/
      Assets.xcassets
  backend/
    app/
      main.py
      api/
        routes_ideas.py
        routes_patents.py
      core/
        config.py
        logging.py
      services/
        llm.py
        prompts.py
        patentsview.py
        scoring.py
      schemas/
        idea.py
        patent.py
        export.py
    tests/
    requirements.txt
    Dockerfile
    README.md

---

## 3) MVP Data Models (Schemas)

### iOS Models
- ProductInput
  - text: String
  - url: String?
  - category: String?
- IdeaVariant
  - id: String
  - title: String
  - summary: String
  - improvementMode: String  // cost_down, durability, safety, convenience, sustainability, performance, mashup
  - keywords: [String]
- IdeaSpec (claim-like)
  - novelty: String
  - mechanism: String
  - baseline: String
  - differentiators: [String]
  - keywords: [String]
  - searchQueries: [String]
  - disclaimer: String
- PatentHit
  - patentId: String
  - title: String
  - abstract: String
  - assignee: String?
  - date: String?
  - score: Double
  - whySimilar: String

### Backend Pydantic Schemas
- POST /ideas/generate
  Request:
    { "text": "...", "category": "...", "random": false }
  Response:
    { "variants": [IdeaVariant] }

- POST /ideas/spec
  Request:
    { "productText": "...", "variantId": "...", "variant": { ... } }
  Response:
    { "spec": IdeaSpec }

- POST /patents/search
  Request:
    { "queries": ["..."], "keywords": ["..."], "limit": 10 }
  Response:
    { "hits": [PatentHit], "confidence": "low|med|high" }

- POST /export/onepager
  Request:
    { "product": ProductInput, "variant": IdeaVariant, "spec": IdeaSpec, "hits": [PatentHit] }
  Response:
    { "markdown": "...", "plainText": "..." }

---

## 4) External Integrations

### PatentSearch API (PatentsView)
- Use PatentsView PatentSearch API with API key via header.
- Store key in backend env var: PATENTSVIEW_API_KEY
- Service: services/patentsview.py
Functions:
- build_query_payload(queries, keywords, limit)
- search_patents(payload) -> list[raw]
- normalize_hits(raw) -> list[PatentHit]

If API returns minimal info, fall back to retrieving more fields with a second query by patent_id (optional).

---

## 5) Prompting Strategy (Backend)

### Prompt Style Rules
- Always output strict JSON for generation endpoints.
- No legal conclusions. Use "risk signals" language.
- Ensure outputs include search synonyms.

#### Prompt A: Generate Idea Variants
Input: product text + optional category
Output: 10 variants with improvement modes + keywords.
JSON schema:
{
  "variants": [
    {
      "id": "uuid",
      "title": "...",
      "summary": "...",
      "improvementMode": "cost_down|durability|safety|convenience|sustainability|performance|mashup",
      "keywords": ["...", "..."]
    }
  ]
}

#### Prompt B: Generate IdeaSpec (claim-like)
Input: product text + selected variant
Output schema:
{
  "spec": {
    "novelty": "...",
    "mechanism": "...",
    "baseline": "...",
    "differentiators": ["...", "..."],
    "keywords": ["...", "..."],
    "searchQueries": ["...", "..."],
    "disclaimer": "Not legal advice..."
  }
}

#### Prompt C: Rerank + Explain Similarity
Input: spec + top 20 patent hits
Output:
- score 0–1
- whySimilar (2–3 sentences, concrete)

---

## 6) Backend Implementation Steps (Claude Tasks)

### Task 1 — Backend scaffold
- Create FastAPI app with routers:
  - /ideas
  - /patents
  - /export
- Add config loader from env (pydantic-settings)
- Add CORS for iOS dev.

Acceptance:
- `GET /health` returns ok
- `POST /ideas/generate` returns mock JSON (temporary)

### Task 2 — LLM service abstraction
- services/llm.py
  - call_llm(prompt: str, json_schema_hint: str) -> dict
- Make provider pluggable (Anthropic/OpenAI). Default to Anthropic since user uses Claude Code.

Acceptance:
- unit test: prompt -> parsed JSON -> validates schema

### Task 3 — Prompts module
- services/prompts.py stores prompt templates A/B/C.
- Add helpers: safe_json_instructions(), no_legal_advice_instructions()

Acceptance:
- Running endpoint returns valid JSON conforming to schemas

### Task 4 — PatentsView client
- services/patentsview.py
  - build payload and call API
  - normalize to PatentHit list
- services/scoring.py
  - initial scoring heuristic (keyword overlap + recency bonus)
  - optionally do LLM rerank on top 10

Acceptance:
- POST /patents/search with "vacuum insulated bottle leakproof cap" returns a list (even if scores are rough)

### Task 5 — Export generator
- services/export.py
  - produce Markdown and plain text one-pager
  - include disclaimer block
- Later: generate PDF in backend or do it in iOS (MVP can be Markdown share)

Acceptance:
- /export/onepager returns a clean formatted markdown doc

---

## 7) iOS Implementation Steps (Claude Tasks)

### Task 6 — SwiftUI skeleton
Screens:
1. HomeInputView
2. IdeasListView
3. IdeaDetailView
4. PriorArtResultsView
5. ExportView (or share sheet)

Services:
- ApiClient with:
  - generateIdeas(productText)
  - generateSpec(productText, variant)
  - searchPatents(spec.searchQueries, spec.keywords)
  - exportOnePager(...)

Acceptance:
- Can navigate end-to-end with mocked backend responses.

### Task 7 — Integrate real backend
- Replace mocks with real endpoints.
- Add loading states, retry, basic error UI.

Acceptance:
- Input -> variants -> spec -> prior art results working live.

---

## 8) Safety + Legal UX Requirements (Hard Requirements)
- Always show: "Not legal advice. Search not exhaustive."
- Use "Novelty risk / Obviousness risk" as "signals", not determinations.
- Provide "Next steps" checklist:
  - Do a professional prior-art search
  - Consult a patent attorney
  - Document prototypes & iterations

---

## 9) Minimal UI Copy (MVP)
- Button: "Make it better"
- Section: "Closest patents we found"
- Tag: "Search confidence: Low/Medium/High"
- Tag: "Novelty risk: Low/Medium/High" (based on similarity distribution)
- CTA: "Export one-pager"

---

## 10) DevOps / Run Instructions

### Backend
- cd backend
- python -m venv .venv && source .venv/bin/activate
- pip install -r requirements.txt
- export PATENTSVIEW_API_KEY=...
- export ANTHROPIC_API_KEY=...
- uvicorn app.main:app --reload --port 8000

### iOS
- Open ios/BetterMousetrap.xcodeproj
- Set API_BASE_URL to http://localhost:8000

---

## 11) Quality Bar (What "done" means)
MVP is done when:
- A user can input "mousetrap"
- App generates 10 better variants
- Selecting one creates a structured spec
- Patent search returns top 10 hits with "why similar"
- User can export/share the concept summary
- No screen claims "patentable."

---

## 12) Next Iterations (Post-MVP)
- Add product search (via user-provided URLs first)
- Add embeddings + vector DB for semantic patent similarity
- Add saved projects + history
- Add diagrams (simple generated SVG)
- Add "constraints mode" sliders

END
