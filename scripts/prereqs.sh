#!/usr/bin/env bash
# =============================================================
#  AI Gauntlet — Prerequisites Check
#  Run this BEFORE the session starts: bash scripts/prereqs.sh
# =============================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0

ok()   { echo -e "${GREEN}  ✅  $1${NC}"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}  ❌  $1${NC}"; FAIL=$((FAIL+1)); }
warn() { echo -e "${YELLOW}  ⚠️   $1${NC}"; }
sep()  { echo -e "${BOLD}$1${NC}"; }

echo ""
sep "─────────────────────────────────────────────────────"
sep "  AI Gauntlet — Environment Check"
sep "─────────────────────────────────────────────────────"
echo ""

# ── Claude Code CLI ───────────────────────────────────────────
sep "Claude Code"
if command -v claude &>/dev/null; then
  VERSION=$(claude --version 2>/dev/null | head -1)
  ok "Claude Code installed ($VERSION)"
else
  fail "Claude Code not installed — run: npm install -g @anthropic-ai/claude-code"
fi

# YOLO mode — just remind them, not checkable pre-session
warn "Remember: start the session with: claude --dangerously-skip-permissions"
warn "Or press Shift+Tab inside Claude Code to enable Auto-approve mode"
echo ""

# ── Node.js ───────────────────────────────────────────────────
sep "Node.js"
if command -v node &>/dev/null; then
  NODE_VER=$(node --version)
  MAJOR=$(echo "$NODE_VER" | sed 's/v\([0-9]*\).*/\1/')
  if [ "${MAJOR:-0}" -ge 18 ]; then
    ok "Node.js $NODE_VER (≥ v18 required)"
  else
    fail "Node.js $NODE_VER is too old — need v18+"
  fi
else
  fail "Node.js not found — install from nodejs.org"
fi

if command -v npm &>/dev/null; then
  ok "npm $(npm --version)"
else
  fail "npm not found"
fi
echo ""

# ── Python ────────────────────────────────────────────────────
sep "Python"
if command -v python3 &>/dev/null; then
  PY_VER=$(python3 --version)
  PY_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
  ok "Python $PY_VER"
  [ "${PY_MINOR:-0}" -lt 9 ] && warn "Python 3.${PY_MINOR} — recommend Python 3.9+" || true

  # Check pip
  python3 -m pip --version &>/dev/null \
    && ok "pip available" \
    || fail "pip not available"

  # Check uvicorn
  python3 -m uvicorn --version &>/dev/null \
    && ok "uvicorn installed" \
    || warn "uvicorn not installed — Claude will install it: pip install uvicorn fastapi"

  # Check anthropic SDK
  python3 -c "import anthropic" 2>/dev/null \
    && ok "Anthropic Python SDK installed" \
    || warn "Anthropic SDK not installed — Claude will install it: pip install anthropic"
else
  fail "Python 3 not found — install from python.org"
fi
echo ""

# ── Docker ────────────────────────────────────────────────────
sep "Docker"
if command -v docker &>/dev/null; then
  ok "Docker CLI found"
  if docker info &>/dev/null 2>&1; then
    ok "Docker Desktop is running"
  else
    fail "Docker Desktop is not running — open Docker Desktop before the session"
  fi
else
  fail "Docker not found — install Docker Desktop from docker.com"
fi
echo ""

# ── GitHub CLI ────────────────────────────────────────────────
sep "GitHub CLI"
if command -v gh &>/dev/null; then
  ok "gh CLI installed ($(gh --version | head -1))"
  if gh auth status &>/dev/null 2>&1; then
    ok "gh CLI authenticated (logged in)"
  else
    fail "gh CLI not authenticated — run: gh auth login"
  fi
else
  fail "gh CLI not installed — run: brew install gh"
fi
echo ""

# ── Git ───────────────────────────────────────────────────────
sep "Git"
if command -v git &>/dev/null; then
  ok "git $(git --version | awk '{print $3}')"
  GIT_USER=$(git config --global user.name 2>/dev/null)
  GIT_EMAIL=$(git config --global user.email 2>/dev/null)
  [ -n "$GIT_USER" ]  && ok "git user.name = $GIT_USER"  || fail "git user.name not set — run: git config --global user.name 'Your Name'"
  [ -n "$GIT_EMAIL" ] && ok "git user.email = $GIT_EMAIL" || fail "git user.email not set — run: git config --global user.email 'you@example.com'"
else
  fail "git not found"
fi
echo ""

# ── ANTHROPIC_API_KEY ─────────────────────────────────────────
sep "API Keys"
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  MASKED="${ANTHROPIC_API_KEY:0:8}...${ANTHROPIC_API_KEY: -4}"
  ok "ANTHROPIC_API_KEY is set ($MASKED)"
else
  fail "ANTHROPIC_API_KEY not set in environment — add to your shell profile or .env file"
fi
echo ""

# ── MCP / Chrome ──────────────────────────────────────────────
sep "Chrome MCP (optional — needed for automated UI testing)"
if npx @modelcontextprotocol/server-puppeteer --version &>/dev/null 2>&1; then
  ok "Puppeteer MCP server available"
else
  warn "Puppeteer MCP not cached — it will auto-install on first use via npx"
fi
echo ""

# ── Summary ───────────────────────────────────────────────────
echo "─────────────────────────────────────────────────────"
if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}${BOLD}  ✅  All checks passed ($PASS/$((PASS+FAIL))) — you're ready!${NC}"
else
  echo -e "${RED}${BOLD}  ❌  $FAIL check(s) failed — fix the red items above before the session.${NC}"
  echo -e "${YELLOW}  ⚠️   $PASS check(s) passed.${NC}"
fi
echo "─────────────────────────────────────────────────────"
echo ""
