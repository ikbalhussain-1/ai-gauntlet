# CLAUDE.md

This file provides context to all Claude agents working in this project. Read it before starting any task.

## Project

**CX Review Thematic Analysis Tool** — a web application that lets a customer experience team upload a CSV of open-ended customer reviews, automatically categorise and analyse each review using AI, and explore results via a dashboard.

This is being built as part of a hands-on AI training session. Prefer working code over perfect architecture. Speed and correctness matter more than elegance.

## Stack

- **Backend:** FastAPI (Python) or Express (Node.js) — Claude will recommend based on context
- **Frontend:** React + Vite, Recharts for charts, axios for API calls
- **AI:** Anthropic SDK, model `claude-sonnet-4-6`
- **Storage:** SQLite (local file, no setup needed)
- **Infrastructure:** docker-compose, nginx for frontend serving

## AI Output Contract

Every call to the Claude API for analysis **must** return structured JSON. Use this exact shape:

```json
{
  "theme": "Product Quality",
  "sentiment": "Positive",
  "key_phrases": ["great taste", "good quality"]
}
```

Valid themes: `Product Quality`, `Efficacy`, `Taste/Smell`, `Packaging`, `Delivery`, `Customer Service`, `Pricing`, `Other`
Valid sentiments: `Positive`, `Negative`, `Neutral`

Always use `response_format` or explicit JSON prompting to enforce this structure. Never parse free-text sentiment/theme strings.

## API Endpoints (minimum required)

- `GET  /health` → `{"status": "ok"}`
- `POST /upload` → accepts multipart CSV, returns `{"upload_id": "...", "count": N}`
- `POST /analyze/{upload_id}` → triggers Claude analysis, returns job status
- `GET  /results/{upload_id}` → returns array of analysed reviews
- `GET  /analytics/{upload_id}` → returns aggregate stats (theme distribution, sentiment breakdown)

## Testing Strategy

- **Backend:** pytest integration tests + Postman collection. Tests must pass before any PR.
- **Frontend:** QA checklist (`qa-checklist.md`) run via Chrome MCP after every screen change.
- **AI accuracy:** 5 labelled eval reviews in `data/eval-reviews-labeled.csv` — the scoring script will test these.

## Data

Sample reviews: `data/sample-reviews.csv` (30 rows, columns: review_id, product, review_text, date)
Eval reviews: `data/eval-reviews-labeled.csv` (5 rows with ground truth labels — do not modify)

## Session Constraints

- Do not implement user authentication
- Do not use any database other than SQLite
- Backend must run on port 8000, frontend on port 3000
- All environment variables must be loaded from `.env`
- The `ANTHROPIC_API_KEY` env var must never be hardcoded
