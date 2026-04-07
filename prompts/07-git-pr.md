# Prompt 07 — Commit + Pull Request

**Time:** ~10 minutes
**Goal:** Ship everything with a proper commit history and PR — written by Claude.

---

## Prerequisites
- [ ] All tests pass
- [ ] Docker works
- [ ] You have a private GitHub repo created (create one now if not done — takes 2 minutes)

---

## Step 1 — Create Your GitHub Repo (if not done)

```bash
gh repo create review-intelligence --private --source=. --remote=origin --push
```

Or if the repo already exists and you need to push:

```bash
git remote add origin https://github.com/YOUR_USERNAME/review-intelligence.git
git push -u origin main
```

---

## Step 2 — Create a Feature Branch

```bash
git checkout -b feat/review-analysis-tool
```

---

## Step 3 — Let Claude Review and Commit

Paste this into Claude Code:

```
Run: git diff main
Review the diff as a senior engineer. Identify:
1. Any bugs, security issues, or bad patterns (especially: hardcoded secrets,
   missing error handling on Claude API calls, SQL injection risks)
2. Anything that would fail in production but not in local dev

Then:
- Stage all changed files (be selective — do not stage .env or any file
  containing secrets)
- Create a meaningful commit for each logical group of changes
  (e.g., one commit for backend, one for frontend, one for infra)
- Write commit messages that explain WHY, not just what changed

Show me the staged files before committing. Wait for my approval.
```

Review what Claude stages. If anything looks wrong, tell it specifically what to exclude.

---

## Step 4 — Write and Create the PR

```
Write a GitHub Pull Request for this work.

Title: should be under 70 characters, describe what was built

Body must include:
## Summary
- 3 bullet points describing what this PR does

## Problem Solved
One paragraph linking back to the original business problem 
(CX team spending 3 hours/week on manual review categorisation)

## What was built
- List each major component built

## How to test locally
Step-by-step instructions to run the app and verify it works

## Test coverage
- What integration tests exist
- What QA checklist items were verified by Chrome MCP
- AI eval accuracy (mention it will be checked by the scoring script)

## Screenshots
[Note: Add screenshots of the running app here]

Then create the PR using:
gh pr create --title "..." --body "..."
```

---

## Step 5 — Run the Scoring Script

You're done. Time to see your score:

```bash
bash scripts/check.sh
```

The script will:
- Verify everything is in place
- Start your backend and test all endpoints
- Run the 5 eval reviews through your AI and check accuracy
- Check your Docker config
- Check your git history and PR
- Give you a final score out of 100

Screenshot the output and share it in the group chat.

---

## Congrats

You just went from an ambiguous BRD to a shipped, tested, containerised, AI-powered product — in one session, without writing a single line of code manually.

That is Stage 6.
