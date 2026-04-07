# Tests

Integration tests for the backend API using pytest.

## Structure

- `test_health.py` — health endpoint smoke test
- `test_upload.py` — CSV upload and validation tests
- `test_analyze.py` — analysis trigger and result tests
- `test_analytics.py` — aggregate stats endpoint tests
- `conftest.py` — shared fixtures (test client, sample CSV path)

## Running

```bash
cd backend
pip install -r requirements.txt
pip install pytest httpx
pytest ../tests/ -v
```

All tests must pass before any PR is merged.
