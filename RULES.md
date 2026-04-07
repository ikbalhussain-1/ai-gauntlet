# Session Rules

These apply for the full duration of the session. They are constraints by design — the discomfort is the point.

---

**Rule 1 — No typing in code files.**
You may only type in Claude's prompt box or the terminal. If your cursor is in a `.py`, `.js`, `.ts`, `.tsx`, `.html`, or `.css` file, stop and move to the prompt instead.

**Rule 2 — No Google, no docs sites.**
Claude only. If you need to know how a library works, ask Claude. If you are stuck on an error, paste the error into Claude. Treat this as a hard constraint, not a suggestion.

**Rule 3 — YOLO mode is on.**
Start every Claude Code session like this (from your project root):
```bash
claude --dangerously-skip-permissions
```
Or, once inside Claude Code, press **Shift+Tab** to cycle to **Auto-approve** mode.
No approval prompts. Claude acts; you review diffs.

**Rule 4 — Tests decide if something works, not your eyes.**
Do not manually test by clicking around your app. If your integration tests pass, the backend is correct. If Chrome MCP passes the QA checklist, the frontend is correct. Human judgment is only for reviewing diffs.

**Rule 5 — Chrome MCP runs your UI tests.**
After building any frontend screen, use Claude to drive Chrome through `qa-checklist.md`. You do not click anything in the browser yourself.

**Rule 6 — Claude writes your commits and PR description.**
Do not write commit messages or PR descriptions yourself. Use the prompt in `prompts/07-git-pr.md`.

---

The goal is not to follow rules. The goal is to build the muscle memory of directing AI rather than writing code. These rules make that the only option.
