# Prompt 01 — Project Scaffold

**Time:** ~10 minutes
**Goal:** Scaffold the full project structure from scratch. No manual folder creation.

---

## Prerequisites
- [ ] `PRD.md` exists (from Prompt 00)
- [ ] You have decided on a backend stack

---

## The Prompt

Open a **new Claude Code session** in your project directory and paste this:

```
I am building a CX review thematic analysis tool. Read my CLAUDE.md and PRD.md
for context.

Please do the following in order:

1. Recommend whether Python/FastAPI or Node/Express is the better backend choice
   for this project, given the AI integration requirements. State your recommendation
   in one sentence with a reason.

2. Scaffold the full project structure based on your recommendation:
   - /backend   (the API server)
   - /frontend  (React + Vite)
   - /tests     (integration tests)
   - /infra     (docker-compose and nginx config)
   Each folder should have a brief README.md explaining what goes in it.

3. In the backend, create:
   - A health endpoint: GET /health → {"status": "ok"}
   - A requirements.txt or package.json with all dependencies needed
   - A .env loader that reads from the project root .env file
   - A basic app entry point (main.py or server.js)

4. In the frontend:
   - Initialise a Vite + React project
   - Install: axios, recharts
   - Create a basic App.jsx with a placeholder "Review Analysis Tool" heading

5. Copy .env.example to .env (do not fill in the API key — leave the placeholder)

6. Initialise git and make the first commit with message: "chore: initial scaffold"

Show me the full folder tree when done.
```

---

## You're ready for Phase 2 when:
- [ ] `backend/` exists with a runnable health endpoint
- [ ] `frontend/` exists and `npm run dev` works
- [ ] `git log` shows at least one commit
- [ ] `tree` (or Claude's summary) shows the expected structure

**Move to `prompts/02-api-contract.md`**
