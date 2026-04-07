# Prompt 02 — API Contract + Test Suite

**Time:** ~20 minutes
**Goal:** Define the full API contract and generate tests BEFORE writing any implementation. This is the anti-hallucination layer.

The tests you generate here become the acceptance criteria for the backend. Claude will implement against them. If tests pass, the backend is correct.

---

## Prerequisites
- [ ] Scaffold complete (Prompt 01 done)
- [ ] Backend health endpoint runs

---

## Step 1 — Generate OpenAPI Spec

Paste this into Claude Code:

```
Read my PRD.md and CLAUDE.md.

Generate a complete OpenAPI 3.0 specification (openapi.yaml) for the backend API.
It must include these endpoints at minimum:

- GET  /health
- POST /upload        (multipart/form-data with a CSV file)
- POST /analyze/{upload_id}   (trigger AI analysis of uploaded reviews)
- GET  /results/{upload_id}   (return all analysed reviews as JSON array)
- GET  /analytics/{upload_id} (return aggregated stats: theme distribution, sentiment breakdown)

For each endpoint include:
- Summary and description
- Request schema (body, params, query)
- Response schema (success and error cases)
- Example request and response

The analysis result for each review must follow this exact shape:
{
  "review_id": "string",
  "product": "string",
  "review_text": "string",
  "theme": "Product Quality | Efficacy | Taste/Smell | Packaging | Delivery | Customer Service | Pricing | Other",
  "sentiment": "Positive | Negative | Neutral",
  "key_phrases": ["string"]
}

Save the spec to backend/openapi.yaml
```

---

## Step 2 — Generate Postman Collection

```
Using the openapi.yaml you just created, generate a Postman collection (JSON format)
with:
- One request per endpoint
- Test scripts that assert: correct status code, response body structure,
  required fields present
- A pre-request script that sets baseUrl to http://localhost:8000
- Environment variables for upload_id (set dynamically from the /upload response)

Save it to tests/postman-collection.json
```

---

## Step 3 — Generate pytest Integration Tests

```
Generate a pytest integration test file at tests/test_api.py

Include these test cases:
1. test_health — GET /health returns 200 and {"status": "ok"}
2. test_upload_csv — POST /upload with data/sample-reviews.csv returns 200,
   upload_id is present, count equals 30
3. test_analyze_and_results — POST /analyze/{upload_id} triggers analysis,
   then GET /results/{upload_id} returns 30 items each with theme, sentiment,
   key_phrases fields present and non-empty
4. test_analytics — GET /analytics/{upload_id} returns theme_distribution dict
   and sentiment_breakdown dict, both non-empty
5. test_invalid_upload — POST /upload with a non-CSV file returns 400

Use httpx for requests. Load base_url from environment (default: http://localhost:8000).
Add a fixture that uploads the sample CSV and returns the upload_id for reuse.

Note: these tests will FAIL right now — that is correct and expected.
```

---

## Step 4 — Run the tests (they should all fail)

```bash
cd tests && pip install pytest httpx && pytest test_api.py -v
```

Expected: all red. Screenshot or note how many tests failed. This is your starting point.

---

## You're ready for Phase 3 when:
- [ ] `backend/openapi.yaml` exists
- [ ] `tests/postman-collection.json` exists
- [ ] `tests/test_api.py` exists with 5+ test cases
- [ ] Tests run (and fail) — confirms the test setup works

**Move to `prompts/03-stitch-wireframes.md` (frontend) and `prompts/04-backend-build.md` (backend) simultaneously. Open two terminal sessions.**
