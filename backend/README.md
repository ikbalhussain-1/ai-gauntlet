# Backend

FastAPI application serving the CX Review Analysis API on port 8000.

## Structure

- `main.py` — app entry point, CORS config, route registration
- `requirements.txt` — Python dependencies
- `database.py` — SQLite connection and table setup (added in Phase 2)
- `routes/` — endpoint handlers grouped by feature (added in Phase 2)
- `ai.py` — Claude API integration (added in Phase 2)

## Running locally

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Requires `.env` in the project root with `ANTHROPIC_API_KEY` set.
