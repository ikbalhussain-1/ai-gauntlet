# Backend

Express (Node.js) API server for the CX Review Analysis Tool on port 8000.

## Structure

- `server.js` — app entry point, CORS config, route registration
- `package.json` — Node dependencies
- `db.js` — SQLite setup via better-sqlite3 (added in Phase 2)
- `routes/` — endpoint handlers grouped by feature (added in Phase 2)
- `ai.js` — Claude API integration via @anthropic-ai/sdk (added in Phase 2)

## Running locally

```bash
npm install
npm run dev
```

Requires `.env` in the project root with `ANTHROPIC_API_KEY` set.
