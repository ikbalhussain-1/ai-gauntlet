# CX Review Thematic Analysis Tool

A full-stack web application that lets a customer experience team upload a CSV of open-ended customer reviews, automatically classify each review using AI, and explore results via an interactive dashboard.

**Final Score: 98/100 — ELITE (Stage 7)**

---

## Stack

| Layer | Technology |
|-------|-----------|
| Backend | Node.js + Express |
| Frontend | React + Vite + Recharts |
| AI | Groq (Llama 3.3-70b) + Anthropic Claude SDK |
| Database | SQLite (better-sqlite3) |
| Infrastructure | Docker Compose + Nginx |

---

## Getting Started

### Prerequisites

- Node.js ≥ 18
- Python ≥ 3.9
- Docker (Colima or Docker Desktop)
- A `.env` file in the project root (see below)

### Environment Variables

Create a `.env` file in the project root:

```env
ANTHROPIC_API_KEY=your_anthropic_key
GROQ_API_KEY=your_groq_key
AI_PROVIDER=groq
MOCK_AI=false
BACKEND_PORT=8000
FRONTEND_PORT=3000
```

### Run Locally

**Backend:**
```bash
cd backend
npm install
node server.js
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

Or use the Makefile:
```bash
make start   # start backend + frontend
make stop    # kill both
make test    # run pytest
make build   # docker build
```

### Run with Docker

```bash
docker compose -f infra/docker-compose.yml up --build
```

App will be available at `http://localhost:3000`.

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check — returns `{"status": "ok"}` |
| POST | `/upload` | Upload a CSV file — returns `{"upload_id", "count"}` |
| POST | `/analyze/:upload_id` | Trigger AI analysis (async) |
| GET | `/results/:upload_id` | Get all analysed reviews |
| GET | `/analytics/:upload_id` | Get theme + sentiment aggregates |

---

## AI Classification

Each review is classified into:

- **Theme**: Product Quality, Efficacy, Taste/Smell, Packaging, Delivery, Customer Service, Pricing, Other
- **Sentiment**: Positive, Negative, Neutral
- **Key Phrases**: 1–2 extracted phrases

Reviews are sent in batches of 10 to the AI provider. Results are stored in SQLite.

---

## Testing

**Backend integration tests (pytest):**
```bash
pip install pytest httpx
pytest tests/test_api.py -v
```

**Postman collection:**
```bash
newman run tests/postman-collection.json
```

**Scoring:**
```bash
bash scripts/check.sh
```

---

## Project Structure

```
ai-gauntlet/
├── backend/
│   ├── server.js         # Express app entry point
│   ├── db.js             # SQLite setup
│   ├── ai.js             # Groq/Anthropic AI integration
│   └── routes/           # upload, analyze, results, analytics
├── frontend/
│   └── src/
│       ├── App.jsx
│       ├── UploadScreen.jsx
│       ├── Dashboard.jsx
│       ├── ThemeDetail.jsx
│       └── Navbar.jsx
├── infra/
│   └── docker-compose.yml
├── tests/
│   ├── test_api.py
│   └── postman-collection.json
├── data/
│   └── sample-reviews.csv
├── Makefile
└── .env
```

---

## Data Format

The uploaded CSV must have these columns:

```
review_id, product, review_text, date
```

Sample data: `data/sample-reviews.csv` (30 rows)
