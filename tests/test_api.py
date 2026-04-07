"""
Integration tests for the CX Review Analysis API.
These tests hit the running Express server via HTTP.

Run:
    pip install pytest httpx
    pytest tests/test_api.py -v

Note: all tests will FAIL until the backend routes are implemented (Phase 4).
"""

import os
import pytest
import httpx

BASE_URL = os.environ.get("BASE_URL", "http://localhost:8000")
SAMPLE_CSV = os.path.join(os.path.dirname(__file__), "../data/sample-reviews.csv")
README_PATH = os.path.join(os.path.dirname(__file__), "../README.md")


@pytest.fixture(scope="session")
def upload_id():
    """Upload the sample CSV once and return the upload_id for reuse."""
    with open(SAMPLE_CSV, "rb") as f:
        response = httpx.post(
            f"{BASE_URL}/upload",
            files={"file": ("sample-reviews.csv", f, "text/csv")},
        )
    assert response.status_code == 200, f"Upload failed: {response.text}"
    data = response.json()
    assert "upload_id" in data
    return data["upload_id"]


def test_health():
    response = httpx.get(f"{BASE_URL}/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_upload_csv():
    with open(SAMPLE_CSV, "rb") as f:
        response = httpx.post(
            f"{BASE_URL}/upload",
            files={"file": ("sample-reviews.csv", f, "text/csv")},
        )
    assert response.status_code == 200
    body = response.json()
    assert "upload_id" in body
    assert isinstance(body["upload_id"], str) and body["upload_id"]
    assert body["count"] == 30


def test_analyze_and_results(upload_id):
    # Trigger analysis (async — responds immediately)
    response = httpx.post(f"{BASE_URL}/analyze/{upload_id}", timeout=120)
    assert response.status_code == 200
    body = response.json()
    assert body["upload_id"] == upload_id
    assert body["status"] in ("complete", "processing")

    # Poll for results (up to 90s)
    import time
    results = None
    for _ in range(45):
        r = httpx.get(f"{BASE_URL}/results/{upload_id}")
        data = r.json()
        if isinstance(data, list) and data and data[0].get("theme"):
            results = data
            break
        time.sleep(2)
    assert results is not None, "Analysis did not complete within 90s"

    # Fetch results
    response = httpx.get(f"{BASE_URL}/results/{upload_id}")
    assert response.status_code == 200
    results = response.json()
    assert isinstance(results, list)
    assert len(results) == 30

    valid_themes = {
        "Product Quality", "Efficacy", "Taste/Smell", "Packaging",
        "Delivery", "Customer Service", "Pricing", "Other",
    }
    valid_sentiments = {"Positive", "Negative", "Neutral"}

    for review in results:
        assert review.get("review_id"), "review_id missing or empty"
        assert review.get("theme") in valid_themes, f"Invalid theme: {review.get('theme')}"
        assert review.get("sentiment") in valid_sentiments, f"Invalid sentiment: {review.get('sentiment')}"
        assert isinstance(review.get("key_phrases"), list) and review["key_phrases"], "key_phrases missing or empty"


def test_analytics(upload_id):
    response = httpx.get(f"{BASE_URL}/analytics/{upload_id}")
    assert response.status_code == 200
    body = response.json()

    assert isinstance(body.get("theme_distribution"), dict)
    assert len(body["theme_distribution"]) > 0

    assert isinstance(body.get("sentiment_breakdown"), dict)
    for key in ("Positive", "Negative", "Neutral"):
        assert key in body["sentiment_breakdown"], f"Missing sentiment key: {key}"

    assert body.get("total_reviews") == 30


def test_invalid_upload():
    with open(README_PATH, "rb") as f:
        response = httpx.post(
            f"{BASE_URL}/upload",
            files={"file": ("README.md", f, "text/markdown")},
        )
    assert response.status_code == 400
    body = response.json()
    assert "error" in body and body["error"]
