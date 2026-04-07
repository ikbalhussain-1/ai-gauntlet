# AI Gauntlet Score Report

**Participant:** Ikbal Hussain
**Date:** 2026-04-07 13:30
**Score:** 69 / 100
**Badge:** STAGE 5 — Single agent, solid output

## Breakdown

| Check | Result | Points |
|-------|--------|--------|
| backend/ directory exists | PASS | +2 |
| frontend/ directory exists | PASS | +2 |
| docker-compose.yml found | PASS | +2 |
| tests/ directory has files | PASS | +2 |
| .env file exists | PASS | +2 |
| Backend is running and healthy | PASS | +3 |
| /health body incorrect — expected {"status": "ok"} | FAIL | 0 |
| POST /upload accepts CSV (HTTP 200) | PASS | +4 |
| GET /results returns structured review data | PASS | +5 |
| GET /analytics: expected theme_distribution + sentiment_breakdown fields | NOTE | - |
| Key React components found (5 of 5 keywords) | PASS | +5 |
| Recharts used for charts | PASS | +3 |
| npm run build succeeds (no errors) | PASS | +5 |
| Frontend running at localhost:3000 | PASS | +2 |
| Anthropic SDK used in backend code | PASS | +5 |
| Structured JSON output used in Claude API calls | PASS | +5 |
| AI eval skipped (ANTHROPIC_API_KEY not set) | NOTE | - |
| Integration test files exist in tests/ | PASS | +5 |
| All 5 pytest tests pass | PASS | +8 |
| Postman collection at tests/postman-collection.json | PASS | +4 |
| qa-checklist.md present in project root | PASS | +3 |
| PRD.md exists | PASS | +0 |
| docker-compose.yml found (infra/docker-compose.yml) | PASS | +2 |
| Docker Desktop not running — skipping compose validation | NOTE | - |
| Too few commits (1) — commit as you build | FAIL | 0 |
| 0 | NOTE | - |
| gh CLI not found — skipping PR check | NOTE | - |
