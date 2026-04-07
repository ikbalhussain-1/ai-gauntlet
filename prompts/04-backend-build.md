# Prompt 04 — Backend Implementation

**Time:** ~50 minutes
**Goal:** Implement the full backend. Tests are your acceptance criteria — you are done when they all pass.

**Run this in parallel with Prompt 03 (wireframes) in a separate terminal.**

---

## Prerequisites
- [ ] `backend/openapi.yaml` exists
- [ ] `tests/test_api.py` exists with failing tests
- [ ] `.env` exists with `ANTHROPIC_API_KEY` set

---

## The Core Prompt

Paste this into Claude Code in a terminal inside your project directory:

```
Read CLAUDE.md, PRD.md, and backend/openapi.yaml.

Implement the full backend API that makes all tests in tests/test_api.py pass.

Requirements:
- Implement every endpoint defined in openapi.yaml
- Use SQLite for storage (path from DATABASE_URL env var)
- Use the Anthropic Python SDK for Claude API calls
- The Claude API must return structured JSON with this exact shape per review:
  {"theme": "...", "sentiment": "...", "key_phrases": ["...", "..."]}
  Use this system prompt for the analysis:
  "You are a customer review analyst. Classify the review into exactly one theme
   from: Product Quality, Efficacy, Taste/Smell, Packaging, Delivery, Customer Service,
   Pricing, Other. Classify sentiment as exactly one of: Positive, Negative, Neutral.
   Extract 1-2 key phrases. Respond only with valid JSON."
- Load ANTHROPIC_API_KEY from environment — never hardcode it
- Handle errors gracefully: invalid CSV returns 400, missing upload_id returns 404
- After implementing each endpoint, run the relevant test and show me the result
- Do not ask me to review anything until ALL tests in test_api.py pass

After all tests pass, run: pytest tests/test_api.py -v
Show me the final test output.
```

---

## If Claude Gets Stuck

Paste the error output directly into Claude and say:

```
Here is the error. Fix it. Do not explain — just fix and rerun the test.

[paste error here]
```

Claude will diagnose and fix. You do not need to understand the error yourself.

---

## Handling Rate Limits / Slow Analysis

If the /analyze endpoint is slow because it calls Claude for every review sequentially, say:

```
The analysis is too slow because we call Claude once per review.
Refactor to send reviews in batches of 10 in a single Claude call.
Each batch should return a JSON array of results. Maintain the same API contract.
```

---

## Final Check

Once all tests pass, run this manually to confirm the backend is working end-to-end:

```bash
# Start the backend
cd backend && uvicorn main:app --reload --port 8000
# (or: node server.js)

# In another terminal — upload and analyse the sample data
curl -X POST http://localhost:8000/upload \
  -F "file=@data/sample-reviews.csv"
# Copy the upload_id from the response, then:
curl -X POST http://localhost:8000/analyze/UPLOAD_ID_HERE
curl http://localhost:8000/results/UPLOAD_ID_HERE | head -c 500
```

---

## You're ready for Phase 4 (frontend wiring) when:
- [ ] All 5 pytest tests pass (green)
- [ ] Backend runs on port 8000
- [ ] `/results/{id}` returns properly structured JSON

**Move to `prompts/05-frontend-build.md`**
