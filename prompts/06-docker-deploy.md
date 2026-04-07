# Prompt 06 — Docker + Local Deploy

**Time:** ~15 minutes
**Goal:** Containerise everything so the app runs with a single command. This is the "local production" proof point.

---

## Prerequisites
- [ ] Backend tests all pass
- [ ] Frontend QA checklist passes
- [ ] Both services run locally

---

## The Prompt

Paste this into Claude Code:

```
Read CLAUDE.md and the backend + frontend code.

Create the full infrastructure to run this app locally with docker-compose:

1. infra/docker-compose.yml with these services:
   - backend: builds from ./backend, port 8000, reads .env file, 
     mounts ./data as /app/data (for the sample CSV)
   - frontend: builds from ./frontend, served via nginx on port 3000,
     nginx proxies /api/* to backend:8000
   - A named volume for the SQLite database file

2. backend/Dockerfile:
   - Python slim base image
   - Install requirements, copy source, run uvicorn on 0.0.0.0:8000
   - Non-root user

3. frontend/Dockerfile:
   - Node image for build stage, nginx:alpine for serve stage
   - Multi-stage build: npm run build → copy dist to nginx html

4. infra/nginx.conf:
   - Serve React app at /
   - Proxy /api/* → http://backend:8000/
   - Gzip enabled

5. Makefile in project root with:
   - make dev        → starts backend + frontend locally (not docker)
   - make build      → docker-compose build
   - make up         → docker-compose up -d
   - make down       → docker-compose down
   - make test       → runs pytest integration tests
   - make logs       → docker-compose logs -f

After creating all files, validate:
- Run: docker-compose -f infra/docker-compose.yml config
  (This validates the YAML syntax — fix any errors before finishing)
- Tell me the exact command to start the full stack
```

---

## Start the Stack

Once Claude has created everything:

```bash
make build
make up
```

Then ask Claude to verify it's working:

```
Use Chrome MCP to open http://localhost:3000.
Confirm the Upload Screen loads correctly.
Upload data/sample-reviews.csv through the UI.
Wait for analysis to complete.
Confirm the Dashboard loads with charts and review data.
Report pass/fail.
```

---

## Troubleshooting (paste errors to Claude)

If `make build` fails:
```
docker-compose build output:
[paste error]
Fix this. Show me only the changed files as diffs.
```

If `make up` fails or services crash:
```
docker-compose logs output:
[paste logs]
Fix this.
```

---

## You're ready for Phase 6 when:
- [ ] `docker-compose config` validates without errors
- [ ] `make up` starts all services
- [ ] App is accessible at http://localhost:3000
- [ ] Full flow works end-to-end in Docker (not just local dev)

**Move to `prompts/07-git-pr.md`**
