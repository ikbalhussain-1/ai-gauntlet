# Product Requirements Document
## CX Review Thematic Analysis Tool

**Author:** Generated from BRD (Avinash Bamboria, BA — CX Team)
**Date:** 2026-04-07
**Priority:** P2
**Status:** Approved for build

---

## 1. Problem Statement

The Customer Experience team receives open-ended product reviews from multiple sources (Excel exports, Zykrr) and currently spends ~3 hours per week manually reading each review, assigning a theme category, and judging sentiment — all in Excel. This process is slow, inconsistent across analysts, and leaves no time for actual insight work. We need a tool that automates categorisation and sentiment analysis using AI, turning a weekly CSV upload into a structured, ready-to-analyse dashboard in minutes.

---

## 2. User Persona

**Name:** CX Analyst (e.g. Avinash)
**Role:** Customer Experience / Insights team member
**Technical level:** Comfortable with Excel and web apps; not a developer
**Weekly workflow:**
- Exports reviews from Zykrr and other sources as CSV
- Needs them categorised and sentiment-tagged quickly
- Wants to identify trends across themes and products for stakeholder reporting

**What they need:**
- Upload a CSV and walk away — no manual tagging
- See a dashboard with theme and sentiment breakdowns
- Drill into individual reviews per theme if needed

---

## 3. Feature List with Acceptance Criteria

### F1 — CSV Upload
Users can upload a CSV of customer reviews.

- **AC1:** Accepts `.csv` files with columns: `review_id`, `product`, `review_text`, `date`
- **AC2:** Returns an `upload_id` and count of rows detected within 2 seconds
- **AC3:** Rejects non-CSV files with a clear error message

### F2 — AI Analysis
Each review is analysed by Claude and tagged with a theme and sentiment.

- **AC1:** Every review receives exactly one theme from the valid set: `Product Quality`, `Efficacy`, `Taste/Smell`, `Packaging`, `Delivery`, `Customer Service`, `Pricing`, `Other`
- **AC2:** Every review receives exactly one sentiment: `Positive`, `Negative`, `Neutral`
- **AC3:** Analysis returns structured JSON — no free-text parsing; invalid responses are flagged as errors

### F3 — Results View
Users can see all analysed reviews in a table.

- **AC1:** Table shows `review_id`, `product`, `review_text`, `date`, `theme`, `sentiment`, `key_phrases`
- **AC2:** Table is filterable by theme and sentiment
- **AC3:** Results are available via API within 30 seconds of triggering analysis for a 30-row CSV

### F4 — Analytics Dashboard
Users see aggregate stats for an uploaded batch.

- **AC1:** Displays theme distribution (count per theme) as a bar or pie chart
- **AC2:** Displays sentiment breakdown (Positive / Negative / Neutral counts) as a chart
- **AC3:** Dashboard updates automatically once analysis is complete

### F5 — Health Check
System exposes a health endpoint for monitoring.

- **AC1:** `GET /health` returns `{"status": "ok"}` with HTTP 200

---

## 4. Data Model

### `upload` table
| Field | Type | Notes |
|---|---|---|
| upload_id | TEXT (UUID) | Primary key |
| filename | TEXT | Original CSV filename |
| row_count | INTEGER | Number of reviews uploaded |
| status | TEXT | `pending`, `processing`, `complete`, `error` |
| created_at | DATETIME | Upload timestamp |

### `review` table
| Field | Type | Notes |
|---|---|---|
| id | INTEGER | Primary key, auto-increment |
| upload_id | TEXT | Foreign key → upload.upload_id |
| review_id | TEXT | From CSV |
| product | TEXT | From CSV |
| review_text | TEXT | From CSV |
| date | TEXT | From CSV |
| theme | TEXT | AI output — one of 8 valid themes |
| sentiment | TEXT | AI output — Positive / Negative / Neutral |
| key_phrases | TEXT | JSON array stored as string |
| analysed_at | DATETIME | When Claude processed this row |

---

## 5. API Contract

### `GET /health`
```
Response 200: { "status": "ok" }
```

### `POST /upload`
```
Request:  multipart/form-data, field "file" = CSV
Response 200: { "upload_id": "uuid", "count": 30 }
Response 400: { "error": "Invalid file type" }
```

### `POST /analyze/{upload_id}`
```
Response 200: { "upload_id": "uuid", "status": "processing" }
Response 404: { "error": "Upload not found" }
```

### `GET /results/{upload_id}`
```
Response 200: [
  {
    "review_id": "1",
    "product": "Aloe Vera Juice",
    "review_text": "...",
    "date": "2024-01-15",
    "theme": "Efficacy",
    "sentiment": "Positive",
    "key_phrases": ["digestion improved", "daily use"]
  },
  ...
]
```

### `GET /analytics/{upload_id}`
```
Response 200: {
  "theme_distribution": {
    "Efficacy": 8,
    "Taste/Smell": 4,
    "Pricing": 5,
    ...
  },
  "sentiment_breakdown": {
    "Positive": 15,
    "Negative": 10,
    "Neutral": 5
  },
  "total_reviews": 30
}
```

---

## 6. Tech Stack

| Layer | Choice | Justification |
|---|---|---|
| Backend | FastAPI (Python) | Native async support; excellent for I/O-bound AI calls; Pydantic models enforce response shapes |
| Frontend | React + Vite | Fast dev setup; Recharts for charts without heavy dependencies |
| AI | Anthropic SDK (`claude-sonnet-4-6`) | Best instruction-following for structured JSON output |
| Database | SQLite | Zero setup, file-based, sufficient for weekly batch workloads |
| Infrastructure | docker-compose + nginx | One-command local start; nginx serves React on port 3000 |
| HTTP client | axios | Standard for React API calls |

---

## 7. Out of Scope

- User authentication / login
- Multi-tenant or team-based access
- Real-time streaming of analysis results (polling is sufficient)
- Integration directly with Zykrr API (CSV export remains manual for now)
- Export of results back to Excel/CSV
- Review editing or manual theme overrides
- Any database other than SQLite
- Deployment to cloud infrastructure

---

## 8. Definition of Done

- [ ] All 5 API endpoints implemented and returning correct shapes
- [ ] `POST /upload` correctly parses the sample CSV (`data/sample-reviews.csv`)
- [ ] `POST /analyze/{upload_id}` calls Claude for all reviews and stores results
- [ ] AI output strictly conforms to the JSON contract (theme + sentiment + key_phrases)
- [ ] React dashboard renders theme distribution and sentiment breakdown charts
- [ ] Results table displays all reviews with theme and sentiment columns
- [ ] pytest integration tests pass for all endpoints
- [ ] Eval script scores ≥ 4/5 on `data/eval-reviews-labeled.csv`
- [ ] `docker-compose up` starts the full stack with no manual steps
- [ ] `ANTHROPIC_API_KEY` loaded from `.env`, never hardcoded
