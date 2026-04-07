#!/usr/bin/env bash
# =============================================================
#  AI GAUNTLET — Scoring Script
#  Run from your project root: bash scripts/check.sh
# =============================================================
# Does NOT use set -e — we continue even when checks fail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

SCORE=0
BACKEND_PID=""
BACKEND_STARTED=false
REPORT=()

# ── Helpers ──────────────────────────────────────────────────
chk_pass() {
  local desc="$1" pts="$2"
  SCORE=$((SCORE + pts))
  printf "${GREEN}  ✅  %-55s +%d pts${NC}\n" "$desc" "$pts"
  REPORT+=("PASS|$desc|$pts")
}
chk_fail() {
  local desc="$1"
  printf "${RED}  ❌  %-55s  0 pts${NC}\n" "$desc"
  REPORT+=("FAIL|$desc|0")
}
chk_warn() {
  local desc="$1"
  printf "${YELLOW}  ⚠️   %-53s${NC}\n" "$desc"
  REPORT+=("WARN|$desc|-")
}
section() { printf "\n${BOLD}${CYAN}━━━ %s${NC}\n" "$1"; }

# Safe grep count — never lets grep -c exit code cause issues
grep_count() {
  local pattern="$1"
  echo "${@:2}" | grep -c "$pattern" 2>/dev/null || echo "0"
}

cleanup() {
  [ -n "$BACKEND_PID" ] && kill "$BACKEND_PID" 2>/dev/null || true
  wait "$BACKEND_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

wait_for_backend() {
  printf "  ${DIM}  Waiting for backend"
  for i in $(seq 1 25); do
    sleep 1
    printf "."
    if curl -sf http://localhost:8000/health > /dev/null 2>&1; then
      printf " ready${NC}\n"
      return 0
    fi
    # If process died, exit early
    if [ -n "$BACKEND_PID" ] && ! kill -0 "$BACKEND_PID" 2>/dev/null; then
      printf " process died${NC}\n"
      printf "  ${RED}  Backend crash log:${NC}\n"
      tail -5 /tmp/gauntlet_backend.log 2>/dev/null | sed 's/^/  /'
      return 1
    fi
  done
  printf " timeout${NC}\n"
  printf "  ${DIM}  Last log lines:${NC}\n"
  tail -5 /tmp/gauntlet_backend.log 2>/dev/null | sed 's/^/    /'
  return 1
}

docker_compose() {
  # Support both docker compose (v2) and docker-compose (v1)
  if docker compose version &>/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose &>/dev/null; then
    docker-compose "$@"
  else
    return 1
  fi
}

# ── Banner ────────────────────────────────────────────────────
clear
printf "${BOLD}"
printf "  ╔══════════════════════════════════════════════════════╗\n"
printf "  ║         AI GAUNTLET — SCORING SYSTEM                ║\n"
printf "  ║          Review Intelligence Challenge               ║\n"
printf "  ╚══════════════════════════════════════════════════════╝\n"
printf "${NC}\n"
printf "  Running from: ${BOLD}$(pwd)${NC}\n"
read -rp "  Enter your name: " PARTICIPANT_NAME
printf "\n  Scoring: ${BOLD}%s${NC}  |  %s\n\n" "$PARTICIPANT_NAME" "$(date '+%Y-%m-%d %H:%M')"

# Early checks
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  printf "${YELLOW}  ⚠️   ANTHROPIC_API_KEY not set — AI eval tests will be skipped${NC}\n"
fi
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
  printf "${YELLOW}  ⚠️   Port 8000 is already in use. Will use existing server for backend tests.${NC}\n"
  printf "${DIM}      (If this isn't your backend, kill it: lsof -ti:8000 | xargs kill)${NC}\n\n"
  BACKEND_STARTED=true
fi

# ═════════════════════════════════════════════════════════════
#  1. PROJECT STRUCTURE  (10 pts)
# ═════════════════════════════════════════════════════════════
section "1/7  PROJECT STRUCTURE  (10 pts)"

[ -d "backend" ]  \
  && chk_pass "backend/ directory exists" 2 \
  || chk_fail "backend/ directory missing"

[ -d "frontend" ] \
  && chk_pass "frontend/ directory exists" 2 \
  || chk_fail "frontend/ directory missing"

{ [ -f "docker-compose.yml" ] || [ -f "infra/docker-compose.yml" ]; } \
  && chk_pass "docker-compose.yml found" 2 \
  || chk_fail "docker-compose.yml not found"

{ find tests -name "*.py" -o -name "*.test.js" -o -name "*.spec.js" -o -name "*.json" 2>/dev/null | grep -q .; } \
  && chk_pass "tests/ directory has files" 2 \
  || chk_fail "tests/ empty or missing"

[ -f ".env" ] \
  && chk_pass ".env file exists" 2 \
  || chk_fail ".env missing — run: cp .env.example .env"

# ═════════════════════════════════════════════════════════════
#  2. BACKEND HEALTH  (20 pts)
# ═════════════════════════════════════════════════════════════
section "2/7  BACKEND HEALTH  (20 pts)"

# ── Detect backend entry point ───────────────────────────────
# Try: backend/main.py, backend/app.py, then search 3 levels deep
detect_backend() {
  local entry=""
  for candidate in "backend/main.py" "backend/app.py" "backend/api/main.py" "backend/src/main.py"; do
    if [ -f "$candidate" ]; then
      # Convert path to module notation: backend/app/main.py → app.main:app
      entry="${candidate#backend/}"  # strip leading "backend/"
      entry="${entry%.py}"           # strip .py
      entry="${entry//\//.}:app"     # convert / to . and append :app
      echo "$entry"
      return 0
    fi
  done
  # Broader search
  local found
  found=$(find backend -maxdepth 3 -name "main.py" -type f 2>/dev/null | head -1)
  if [ -n "$found" ]; then
    entry="${found#backend/}"
    entry="${entry%.py}"
    entry="${entry//\//.}:app"
    echo "$entry"
    return 0
  fi
  return 1
}

# ── Start backend if not already running ─────────────────────
if ! $BACKEND_STARTED; then
  if [ -f "backend/requirements.txt" ] || [ -f "backend/pyproject.toml" ]; then
    printf "  ${DIM}Detected: Python backend${NC}\n"
    ENTRY=$(detect_backend)
    if [ -n "$ENTRY" ]; then
      printf "  ${DIM}Installing dependencies...${NC}\n"
      (cd backend && pip install -q -r requirements.txt 2>/dev/null) || true
      printf "  ${DIM}Starting: uvicorn %s${NC}\n" "$ENTRY"
      (cd backend && python -m uvicorn "$ENTRY" --port 8000 --log-level warning 2>&1) \
        > /tmp/gauntlet_backend.log &
      BACKEND_PID=$!
    else
      chk_warn "Could not find Python entry point (main.py or app.py in backend/)"
    fi
  elif [ -f "backend/package.json" ]; then
    printf "  ${DIM}Detected: Node backend${NC}\n"
    printf "  ${DIM}Installing dependencies...${NC}\n"
    (cd backend && npm install --silent 2>/dev/null) || true
    (cd backend && npm start 2>&1) > /tmp/gauntlet_backend.log &
    BACKEND_PID=$!
  else
    chk_warn "Cannot detect backend type — no requirements.txt or package.json in backend/"
  fi

  if [ -n "$BACKEND_PID" ]; then
    if wait_for_backend; then
      BACKEND_STARTED=true
    fi
  fi
fi

# ── Test backend endpoints ────────────────────────────────────
if $BACKEND_STARTED; then
  chk_pass "Backend is running and healthy" 3

  # /health response body
  HEALTH=$(curl -sf http://localhost:8000/health 2>/dev/null)
  echo "$HEALTH" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
  exit(0 if d.get('status')=='ok' else 1)
except Exception: exit(1)
" 2>/dev/null \
    && chk_pass '/health returns {"status": "ok"}' 3 \
    || chk_fail '/health body incorrect — expected {"status": "ok"}'

  # POST /upload
  HTTP_CODE=$(curl -sf -o /tmp/gauntlet_upload.json -w "%{http_code}" \
    -X POST http://localhost:8000/upload \
    -F "file=@data/sample-reviews.csv" 2>/dev/null)

  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    chk_pass "POST /upload accepts CSV (HTTP $HTTP_CODE)" 4

    UPLOAD_ID=$(python3 -c "
import json,sys
try:
  d=json.load(open('/tmp/gauntlet_upload.json'))
  uid = d.get('upload_id') or d.get('id') or ''
  print(uid)
except: pass
" 2>/dev/null)

    if [ -n "$UPLOAD_ID" ]; then
      # Trigger analysis — handle both sync (returns results) and async (fire-and-forget)
      ANALYZE_RESP=$(curl -sf -X POST "http://localhost:8000/analyze/$UPLOAD_ID" 2>/dev/null)

      # Check if analyze returned results directly (sync) or we need to poll (async)
      SYNC_RESULTS=$(echo "$ANALYZE_RESP" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
  if isinstance(d,list) and len(d)>0 and d[0].get('theme'):
    print('sync')
  else:
    print('async')
except: print('async')
" 2>/dev/null)

      RESULTS_OK=false
      if [ "$SYNC_RESULTS" = "sync" ]; then
        # Analyze returned data directly
        echo "$ANALYZE_RESP" > /tmp/gauntlet_results.json
        RESULTS_OK=true
      else
        # Poll /results with 90s timeout
        printf "  ${DIM}  Polling for results (up to 90s)...${NC}"
        for i in $(seq 1 45); do
          sleep 2
          printf "."
          RESULTS=$(curl -sf "http://localhost:8000/results/$UPLOAD_ID" 2>/dev/null)
          HAS_DATA=$(echo "$RESULTS" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
  ok = isinstance(d,list) and len(d)>0 and bool(d[0].get('theme'))
  print('ok' if ok else 'wait')
except: print('wait')
" 2>/dev/null)
          if [ "$HAS_DATA" = "ok" ]; then
            printf " done${NC}\n"
            echo "$RESULTS" > /tmp/gauntlet_results.json
            RESULTS_OK=true
            break
          fi
        done
        [ "$RESULTS_OK" = "false" ] && printf " timeout${NC}\n"
      fi

      if $RESULTS_OK; then
        chk_pass "GET /results returns structured review data" 5
        echo "$UPLOAD_ID" > /tmp/gauntlet_upload_id

        # Analytics
        ANALYTICS=$(curl -sf "http://localhost:8000/analytics/$UPLOAD_ID" 2>/dev/null)
        echo "$ANALYTICS" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
  # Accept multiple naming conventions
  has_themes = bool(d.get('theme_distribution') or d.get('themes') or d.get('by_theme'))
  has_sent   = bool(d.get('sentiment_breakdown') or d.get('sentiments') or d.get('by_sentiment'))
  exit(0 if (has_themes and has_sent) else 1)
except Exception: exit(1)
" 2>/dev/null \
          && chk_pass "GET /analytics returns theme + sentiment aggregates" 5 \
          || chk_warn "GET /analytics: expected theme_distribution + sentiment_breakdown fields"
      else
        chk_fail "GET /results: no data after 90s (is Claude API key set and analysis running?)"
      fi
    else
      chk_fail "upload_id not in /upload response — check response body"
    fi
  else
    chk_fail "POST /upload failed (HTTP $HTTP_CODE) — check backend logs"
    chk_fail "GET /results (skipped — upload failed)"
  fi
else
  chk_fail "Backend not running — could not start or detect entry point"
  chk_fail "POST /upload (skipped)"
  chk_fail "GET /results (skipped)"
fi

# ═════════════════════════════════════════════════════════════
#  3. FRONTEND BUILD  (15 pts)
# ═════════════════════════════════════════════════════════════
section "3/7  FRONTEND BUILD  (15 pts)"

if [ -f "frontend/package.json" ]; then
  # Key component detection (flexible — looks for keywords in JSX/TSX files)
  COMP_COUNT=0
  for kw in Upload Dashboard Chart Detail Review; do
    find frontend/src -name "*.jsx" -o -name "*.tsx" -o -name "*.js" 2>/dev/null \
      | xargs grep -l "$kw" 2>/dev/null | grep -q . && COMP_COUNT=$((COMP_COUNT+1)) || true
  done
  [ $COMP_COUNT -ge 3 ] \
    && chk_pass "Key React components found ($COMP_COUNT of 5 keywords)" 5 \
    || chk_fail "Missing components (found $COMP_COUNT keywords, need 3+: Upload/Dashboard/Chart/Detail/Review)"

  # Recharts
  grep -r "recharts" frontend/src 2>/dev/null | grep -q . \
    && chk_pass "Recharts used for charts" 3 \
    || chk_fail "Recharts not found in frontend/src"

  # Build
  printf "  ${DIM}Running npm run build...${NC}\n"
  (cd frontend && npm run build > /tmp/gauntlet_build.log 2>&1)
  [ $? -eq 0 ] \
    && chk_pass "npm run build succeeds (no errors)" 5 \
    || chk_fail "npm run build failed — see /tmp/gauntlet_build.log"

  # Live check
  curl -sf http://localhost:3000 > /dev/null 2>&1 \
    && chk_pass "Frontend running at localhost:3000" 2 \
    || chk_warn "Frontend not at localhost:3000 — start with: cd frontend && npm run dev"
else
  chk_fail "frontend/package.json not found"
fi

# ═════════════════════════════════════════════════════════════
#  4. AI INTEGRATION  (20 pts)
# ═════════════════════════════════════════════════════════════
section "4/7  AI INTEGRATION  (20 pts)"

# Anthropic SDK
grep -rn "anthropic\|Anthropic" backend/ 2>/dev/null \
  | grep -v "node_modules\|__pycache__\|\.pyc" | grep -q . \
  && chk_pass "Anthropic SDK used in backend code" 5 \
  || chk_fail "Anthropic SDK import not found in backend/"

# Structured JSON output
grep -rn "key_phrases\|response_format\|json_object\|tool_choice\|JSON" backend/ 2>/dev/null \
  | grep -v "node_modules\|__pycache__\|\.pyc" | grep -qi "key_phrases\|json" \
  && chk_pass "Structured JSON output used in Claude API calls" 5 \
  || chk_fail "Structured output (key_phrases/response_format) not found in backend"

# ── AI Eval accuracy (10 pts — 2 pts per correct review) ─────
printf "\n  ${DIM}Running AI eval: 5 labelled reviews vs Claude output...${NC}\n"

EVAL_PTS=0
if $BACKEND_STARTED && [ -f "data/eval-reviews-labeled.csv" ] && [ -n "${ANTHROPIC_API_KEY:-}" ]; then

  EVAL_RESULT=$(python3 - <<'PYEOF' 2>/tmp/gauntlet_eval_detail
import csv, json, urllib.request, urllib.error, time, sys, uuid, io

BASE = "http://localhost:8000"

def post_multipart(url, filename, csv_bytes):
    boundary = uuid.uuid4().hex  # Long random boundary — RFC-safe
    crlf = b"\r\n"
    body = (
        b"--" + boundary.encode() + crlf +
        f'Content-Disposition: form-data; name="file"; filename="{filename}"'.encode() + crlf +
        b"Content-Type: text/csv" + crlf + crlf +
        csv_bytes + crlf +
        b"--" + boundary.encode() + b"--" + crlf
    )
    req = urllib.request.Request(url, data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.loads(r.read()), None
    except urllib.error.HTTPError as e:
        return None, f"HTTP {e.code}: {e.read().decode()[:200]}"
    except Exception as e:
        return None, str(e)

def http_post(url):
    try:
        req = urllib.request.Request(url, data=b"", method="POST",
            headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=15) as r:
            return json.loads(r.read()), None
    except Exception as e:
        return None, str(e)

def http_get(url):
    try:
        with urllib.request.urlopen(url, timeout=15) as r:
            return json.loads(r.read()), None
    except Exception as e:
        return None, str(e)

# Read eval labels
rows = []
with open("data/eval-reviews-labeled.csv") as f:
    for r in csv.DictReader(f):
        rows.append(r)

if not rows:
    print("ERROR:eval_csv_empty", file=sys.stderr)
    print("SCORE:0")
    sys.exit(0)

# Build CSV with proper escaping
out = io.StringIO()
writer = __import__('csv').writer(out, quoting=__import__('csv').QUOTE_ALL)
writer.writerow(["review_id", "product", "review_text", "date"])
for i, r in enumerate(rows, 1):
    writer.writerow([i, "EvalProduct", r["review_text"], "2024-01-01"])
csv_bytes = out.getvalue().encode("utf-8")

# Upload eval CSV
print("Uploading eval CSV...", file=sys.stderr)
up, err = post_multipart(f"{BASE}/upload", "eval.csv", csv_bytes)
if not up:
    print(f"ERROR:upload_failed:{err}", file=sys.stderr)
    print("SCORE:0")
    sys.exit(0)

uid = up.get("upload_id") or up.get("id", "")
if not uid:
    print(f"ERROR:no_upload_id (response: {json.dumps(up)[:100]})", file=sys.stderr)
    print("SCORE:0")
    sys.exit(0)

# Trigger analysis
print(f"Triggering analysis for {uid}...", file=sys.stderr)
analyze_resp, _ = http_post(f"{BASE}/analyze/{uid}")

# Check if analyze returned results synchronously
results = None
if analyze_resp and isinstance(analyze_resp, list) and len(analyze_resp) > 0 and analyze_resp[0].get("theme"):
    results = analyze_resp
    print("Analysis was synchronous", file=sys.stderr)

# Poll for async results
if not results:
    print("Polling for async results (up to 90s)...", file=sys.stderr)
    for attempt in range(45):
        time.sleep(2)
        r, err = http_get(f"{BASE}/results/{uid}")
        if r and isinstance(r, list) and len(r) > 0 and r[0].get("theme"):
            results = r
            print(f"Got results after {(attempt+1)*2}s", file=sys.stderr)
            break

if not results:
    print("ERROR:no_results_after_90s", file=sys.stderr)
    print("SCORE:0")
    sys.exit(0)

# Score
correct = 0
for i, expected in enumerate(rows):
    if i >= len(results):
        print(f"MISS:{i+1}:result_not_present", file=sys.stderr)
        continue
    actual = results[i]
    got_theme = actual.get("theme", "").strip()
    got_sent  = actual.get("sentiment", "").strip()
    exp_theme = expected["expected_theme"].strip()
    exp_sent  = expected["expected_sentiment"].strip()
    theme_ok = got_theme.lower() == exp_theme.lower()
    sent_ok  = got_sent.lower() == exp_sent.lower()
    if theme_ok and sent_ok:
        correct += 1
        print(f"PASS:{i+1}:{got_theme}:{got_sent}", file=sys.stderr)
    else:
        print(f"FAIL:{i+1}:got({got_theme}/{got_sent}) expected({exp_theme}/{exp_sent})", file=sys.stderr)

print(f"SCORE:{correct}")
PYEOF
  )

  # Parse eval output
  while IFS= read -r line; do
    case "$line" in
      PASS:*) n="${line#PASS:}"; IFS=: read -r num theme sent <<< "$n"
              printf "  ${GREEN}    ✅ Review %s: %-22s / %s${NC}\n" "$num" "$theme" "$sent" ;;
      FAIL:*) printf "  ${RED}    ❌ %s${NC}\n" "${line#FAIL:}" ;;
      ERROR:*)printf "  ${RED}    ⚠  Eval error: %s${NC}\n" "${line#ERROR:}" ;;
      MISS:*) printf "  ${YELLOW}    ⚠  %s${NC}\n" "${line#MISS:}" ;;
    esac
  done < /tmp/gauntlet_eval_detail

  if echo "$EVAL_RESULT" | grep -q "^SCORE:"; then
    CORRECT=$(echo "$EVAL_RESULT" | grep "^SCORE:" | cut -d: -f2 | tr -d '[:space:]')
    EVAL_PTS=$((${CORRECT:-0} * 2))
    SCORE=$((SCORE + EVAL_PTS))
    printf "  ${GREEN}  ✅  %-55s +%d pts${NC}\n" "AI eval accuracy: ${CORRECT:-0}/5 reviews correct" "$EVAL_PTS"
    REPORT+=("PASS|AI eval accuracy: ${CORRECT:-0}/5 reviews correct|$EVAL_PTS")
  else
    chk_fail "AI eval did not complete — check /tmp/gauntlet_eval_detail"
  fi

elif ! $BACKEND_STARTED; then
  chk_warn "AI eval skipped (backend not running)"
elif [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  chk_warn "AI eval skipped (ANTHROPIC_API_KEY not set)"
else
  chk_warn "AI eval skipped (data/eval-reviews-labeled.csv not found)"
fi

# ═════════════════════════════════════════════════════════════
#  5. TESTING COMPLETENESS  (20 pts)
# ═════════════════════════════════════════════════════════════
section "5/7  TESTING COMPLETENESS  (20 pts)"

find tests -name "test_*.py" -o -name "*.test.js" -o -name "*.spec.js" 2>/dev/null | grep -q . \
  && chk_pass "Integration test files exist in tests/" 5 \
  || chk_fail "No integration test files found in tests/"

if [ -f "tests/test_api.py" ]; then
  printf "  ${DIM}Running pytest...${NC}\n"
  PYTEST_RAW=$(python3 -m pytest tests/test_api.py -v --tb=line 2>&1 || true)
  # Safe count — avoid grep -c exit code issue
  PASSED=$(printf "%s" "$PYTEST_RAW" | grep -c " PASSED" || true); PASSED="${PASSED:-0}"
  FAILED=$(printf "%s" "$PYTEST_RAW" | grep -c " FAILED" || true); FAILED="${FAILED:-0}"
  TOTAL_T=$(( ${PASSED:-0} + ${FAILED:-0} ))

  if [ "${FAILED:-1}" -eq 0 ] && [ "${PASSED:-0}" -gt 0 ]; then
    chk_pass "All $PASSED pytest tests pass" 8
  elif [ "${PASSED:-0}" -ge 3 ]; then
    chk_pass "$PASSED/$TOTAL_T tests pass" 4
    chk_fail "$FAILED test(s) still failing"
  else
    chk_fail "Tests failing: ${PASSED:-0} passed, ${FAILED:-0} failed"
  fi
elif find tests -name "*.test.js" -o -name "*.spec.js" 2>/dev/null | grep -q .; then
  printf "  ${DIM}Running jest...${NC}\n"
  (cd tests && npm test -- --watchAll=false > /tmp/gauntlet_jest.log 2>&1) && \
    chk_pass "All jest tests pass" 8 || \
    chk_fail "Some jest tests failing — see /tmp/gauntlet_jest.log"
else
  chk_fail "No runnable test suite found (test_api.py or *.test.js)"
fi

[ -f "tests/postman-collection.json" ] \
  && chk_pass "Postman collection at tests/postman-collection.json" 4 \
  || chk_fail "tests/postman-collection.json not found"

[ -f "qa-checklist.md" ] \
  && chk_pass "qa-checklist.md present in project root" 3 \
  || chk_fail "qa-checklist.md not found"

# Bonus check — did they start from a PRD?
[ -f "PRD.md" ] \
  && { printf "${GREEN}  ✅  PRD.md exists (Phase 0 complete)${NC}\n"; REPORT+=("PASS|PRD.md exists|0"); } \
  || { printf "${YELLOW}  ⚠️   PRD.md not found — did you complete Phase 0?${NC}\n"; REPORT+=("WARN|PRD.md missing|-"); }

# ═════════════════════════════════════════════════════════════
#  6. DOCKER  (10 pts)
# ═════════════════════════════════════════════════════════════
section "6/7  DOCKER & INFRASTRUCTURE  (10 pts)"

COMPOSE_FILE=""
[ -f "docker-compose.yml" ]       && COMPOSE_FILE="docker-compose.yml"
[ -f "infra/docker-compose.yml" ] && COMPOSE_FILE="infra/docker-compose.yml"

if [ -n "$COMPOSE_FILE" ]; then
  chk_pass "docker-compose.yml found ($COMPOSE_FILE)" 2

  if command -v docker &>/dev/null && docker info >/dev/null 2>&1; then
    docker_compose -f "$COMPOSE_FILE" config > /dev/null 2>&1 \
      && chk_pass "docker-compose config validates (no YAML errors)" 4 \
      || chk_fail "docker-compose config has errors — run: docker compose config"

    SERVICES=$(docker_compose -f "$COMPOSE_FILE" config --services 2>/dev/null || echo "")
    echo "$SERVICES" | grep -qi "backend\|api\|server" \
      && chk_pass "Backend service defined in compose" 2 \
      || chk_fail "Backend service not found in docker-compose"
    echo "$SERVICES" | grep -qi "frontend\|web\|nginx\|client" \
      && chk_pass "Frontend/nginx service defined in compose" 2 \
      || chk_fail "Frontend service not found in docker-compose"
  elif command -v docker &>/dev/null; then
    chk_warn "Docker Desktop not running — skipping compose validation"
  else
    chk_warn "Docker not installed — skipping compose validation"
  fi
else
  chk_fail "docker-compose.yml not found (checked root and infra/)"
fi

[ -f "Makefile" ] \
  && { printf "${GREEN}  ✅  Makefile present${NC}\n"; REPORT+=("PASS|Makefile present|0"); } \
  || printf "${YELLOW}  ⚠️   Makefile not found (recommended)${NC}\n"

# ═════════════════════════════════════════════════════════════
#  7. GIT HYGIENE  (5 pts)
# ═════════════════════════════════════════════════════════════
section "7/7  GIT HYGIENE  (5 pts)"

if git rev-parse --git-dir > /dev/null 2>&1; then
  COMMIT_LOG=$(git log --oneline 2>/dev/null || echo "")
  COMMIT_COUNT=$(printf "%s\n" "$COMMIT_LOG" | grep -c "." || echo "0")
  COMMIT_COUNT="${COMMIT_COUNT:-0}"

  [ "$COMMIT_COUNT" -ge 4 ] \
    && chk_pass "Strong commit history ($COMMIT_COUNT commits)" 2 \
    || { [ "$COMMIT_COUNT" -ge 2 ] \
      && chk_pass "Commit history present ($COMMIT_COUNT commits)" 1 \
      || chk_fail "Too few commits ($COMMIT_COUNT) — commit as you build"; }

  # Only flag truly generic one-word messages — not short but meaningful ones
  GENERIC_COUNT=$(printf "%s\n" "$COMMIT_LOG" \
    | grep -ciE "^[a-f0-9]+ (initial commit|update|fix|wip|test|done|checkpoint)$" || echo "0")
  GENERIC_COUNT="${GENERIC_COUNT:-0}"
  [ "$GENERIC_COUNT" -le 1 ] \
    && chk_pass "Meaningful commit messages" 2 \
    || chk_warn "$GENERIC_COUNT generic commit message(s) (e.g. 'update', 'fix')"

  if command -v gh &>/dev/null; then
    PR_LIST=$(gh pr list --state all 2>/dev/null || echo "")
    PR_COUNT=$(printf "%s\n" "$PR_LIST" | grep -c "." || echo "0")
    [ "${PR_COUNT:-0}" -ge 1 ] \
      && chk_pass "GitHub PR exists" 1 \
      || chk_fail "No PR found — run: gh pr create"
  else
    chk_warn "gh CLI not found — skipping PR check"
  fi
else
  chk_fail "Not a git repository — run: git init"
fi

# ═════════════════════════════════════════════════════════════
#  FINAL SCORE
# ═════════════════════════════════════════════════════════════
printf "\n${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"

# Determine badge
if   [ $SCORE -ge 90 ]; then BADGE="ELITE — Stage 7 — You're running a fleet";    BC=$GREEN
elif [ $SCORE -ge 75 ]; then BADGE="STAGE 6 — Fleet commander — multi-agent";     BC=$GREEN
elif [ $SCORE -ge 55 ]; then BADGE="STAGE 5 — Single agent, solid output";        BC=$YELLOW
elif [ $SCORE -ge 35 ]; then BADGE="STAGE 4 — Getting there, tests need work";    BC=$YELLOW
else                          BADGE="STAGE 3 — Where we started — keep pushing";  BC=$RED
fi

printf "  ${BOLD}Participant:${NC} %s\n" "$PARTICIPANT_NAME"
printf "  ${BOLD}Timestamp:${NC}   %s\n\n" "$(date '+%Y-%m-%d %H:%M')"
printf "${BOLD}${BC}"
printf "  ┌──────────────────────────────────────────────┐\n"
printf "  │   FINAL SCORE:   %3d / 100                  │\n" "$SCORE"
printf "  │   %-44s│\n" "$BADGE"
printf "  └──────────────────────────────────────────────┘\n"
printf "${NC}\n"

printf "  ${BOLD}Full breakdown:${NC}\n"
printf "  ${DIM}%-42s %s${NC}\n" "Check" "Points"
printf "  ${DIM}%s${NC}\n" "─────────────────────────────────────────────────"
for entry in "${REPORT[@]}"; do
  IFS='|' read -r status label pts <<< "$entry"
  case "$status" in
    PASS) printf "  ${GREEN}%-44s +%s${NC}\n" "$label" "$pts" ;;
    FAIL) printf "  ${RED}%-44s  0${NC}\n"   "$label" ;;
    WARN) printf "  ${YELLOW}%-44s  -%s${NC}\n" "$label" "" ;;
  esac
done

# Save markdown report
{
  echo "# AI Gauntlet Score Report"
  echo ""
  echo "**Participant:** $PARTICIPANT_NAME"
  echo "**Date:** $(date '+%Y-%m-%d %H:%M')"
  echo "**Score:** $SCORE / 100"
  echo "**Badge:** $BADGE"
  echo ""
  echo "## Breakdown"
  echo ""
  echo "| Check | Result | Points |"
  echo "|-------|--------|--------|"
  for entry in "${REPORT[@]}"; do
    IFS='|' read -r status label pts <<< "$entry"
    case "$status" in
      PASS) echo "| $label | PASS | +$pts |" ;;
      FAIL) echo "| $label | FAIL | 0 |" ;;
      WARN) echo "| $label | NOTE | - |" ;;
    esac
  done
} > SCORE_REPORT.md

printf "\n  ${BOLD}Report saved to:${NC} SCORE_REPORT.md\n"
printf "\n${BOLD}${CYAN}  Screenshot this terminal and share in the group chat!${NC}\n"
printf "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
