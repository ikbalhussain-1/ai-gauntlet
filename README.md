# AI Gauntlet — Review Intelligence Challenge

You are going to build a real product in one session — from an ambiguous business requirement all the way to a running, tested, containerised application — without writing a single line of code manually.

This is a real problem from your company's backlog. The CX team spends 3 hours every week manually categorising customer reviews. You are going to solve that today, using AI as your hands.

---

## Before You Start

Run the prerequisites check — fix anything red before proceeding:

```bash
bash scripts/prereqs.sh
```

**What you need:**
- Claude Code CLI installed and logged in (`claude --version` works)
- Node.js ≥ 18, Python ≥ 3.9
- Docker Desktop running
- `gh` CLI authenticated
- `ANTHROPIC_API_KEY` set in your environment

---

## Read This First

Before you open anything else, read `GETTING_STARTED.md`. It tells you exactly how to set up and where to work. Then read `PHILOSOPHY.md` — it explains why this approach eliminates hallucination. These two documents are the frame for everything that follows.

---

## The Rules

These are non-negotiable. They are the mechanism — not the obstacle.

1. **No typing in code files.** Prompts and terminal only.
2. **No Google, no docs sites.** Claude only. If you are stuck, paste the error to Claude.
3. **YOLO mode is on.** Run once: `claude config set autoApproveTools true`
4. **Tests decide if something works — not your eyes.** Green tests = done.
5. **Chrome MCP runs your UI tests.** You do not click anything in the browser.
6. **Claude writes your commits and PR description.** Use `prompts/07-git-pr.md`.

---

## The Problem

Read `PROBLEM.md` — it is a real BRD submitted by a BA on the CX team, exactly as written. Your job is to turn it into a product.

Sample data for development: `data/sample-reviews.csv`

---

## Phases

Work through each prompt file in order. Each one tells you exactly what to do and how long it should take. Every prompt is copy-paste ready.

---

### Phase 0 — BRD → PRD (~20 min)
**`prompts/00-brd-to-prd.md`**

Use Claude to interrogate the ambiguous BRD and produce a proper PRD with acceptance criteria, API contract, and tech stack decision. You own the PRD — Claude helps you write it.

**Done when:** `PRD.md` exists in your project root.

---

### Phase 1 — Scaffold (~10 min)
**`prompts/01-project-scaffold.md`**

Claude creates the full folder structure, backend health endpoint, blank React app, and first git commit.

**Done when:** `backend/` and `frontend/` exist, health endpoint returns `{"status": "ok"}`.

---

### Phase 2 — API Contract + Tests (~20 min)
**`prompts/02-api-contract.md`**

Claude generates the OpenAPI spec, Postman collection, and pytest integration tests — **before any implementation**. All tests will fail at this point. That is correct.

**Done when:** `tests/test_api.py` exists and runs (all failing).

---

### Phase 3A — Wireframes with Google Stitch (~15 min)
### Phase 3B — Backend Build (~50 min)
**`prompts/03-stitch-wireframes.md`** and **`prompts/04-backend-build.md`**

**Open two terminal windows and run these in parallel.**

- Terminal 1: Use Google Stitch to generate wireframes → export → generate QA checklist
- Terminal 2: Claude implements the backend until all pytest tests pass

**Done when:**
- Wireframe PNGs in `docs/`, `qa-checklist.md` exists
- All 5 pytest tests pass

---

### Phase 4 — Frontend Build (~40 min)
**`prompts/05-frontend-build.md`**

Claude builds the React UI from your wireframes. Chrome MCP validates every screen. You do not click anything.

**Done when:** Chrome MCP passes all QA checklist items end-to-end with real API data.

---

### Phase 5 — Docker Deploy (~15 min)
**`prompts/06-docker-deploy.md`**

Claude writes the docker-compose, Dockerfiles, nginx config, and Makefile. One command starts everything.

**Done when:** `make up` → app running at `localhost:3000`.

---

### Phase 6 — Commit + PR (~10 min)
**`prompts/07-git-pr.md`**

Claude reviews the diff for bugs, writes commit messages, and creates the PR on GitHub.

**Done when:** PR exists on your GitHub.

---

### Final — Score (~5 min)

```bash
bash scripts/check.sh   # macOS
# or
.\scripts\check.ps1     # Windows
```

Screenshot the result. Share in the group chat.

---

## Tips (non-obvious ones)

**Paste errors directly into Claude.** Don't read the stack trace yourself. Copy the full error output and say "fix this." Claude's diagnosis is almost always faster and more accurate than yours.

**Open two terminal sessions from Phase 3.** One for frontend work, one for backend. This is your first taste of multi-agent mode — two Claude instances running simultaneously on different parts of the same system.

**When tests are red, say exactly this:**
```
Here are the failing tests. Do not explain — fix them and rerun.
[paste pytest output]
```

**When Chrome MCP finds a UI bug:**
```
Chrome MCP reported these failures: [paste output]
Fix each one. Use Chrome MCP to verify before telling me it's done.
```

**If you feel stuck:** Open `PRD.md`, find the acceptance criterion for what you're working on, and re-read it. The spec usually has the answer.

---

## Stuck?

Ask Claude. That is the rule. Describe your problem clearly — paste the error, paste the relevant context — and let Claude solve it.

If you genuinely believe something is a blocker beyond Claude's ability to fix, raise your hand.

But try Claude first.

---

## Scoring

Run `bash scripts/check.sh` when you're done. See `leaderboard/SUBMIT.md` for the score guide and submission instructions.

---

Good luck. The first person to say "I never touched the code and it works" wins.
