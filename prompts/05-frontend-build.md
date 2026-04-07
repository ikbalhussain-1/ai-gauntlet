# Prompt 05 — Frontend Build

**Time:** ~40 minutes
**Goal:** Build the React UI from the Stitch wireframes. Chrome MCP validates every screen — you do not click anything yourself.

---

## Prerequisites
- [ ] Wireframe PNGs in `docs/`
- [ ] `qa-checklist.md` exists
- [ ] Backend is running on port 8000 (or at least the API contract is defined)

---

## Step 1 — Set Up Chrome MCP

Before building the frontend, configure Chrome MCP so Claude can test your UI automatically.

In Claude Code settings, add the Puppeteer MCP server:

```json
{
  "mcpServers": {
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"]
    }
  }
}
```

Verify it's connected: ask Claude `"List available MCP tools"` — you should see browser navigation tools.

---

## Step 2 — Build the UI from Wireframes

Attach your wireframe PNGs and paste this into Claude Code:

```
I am attaching wireframes for my Review Intelligence app (3 screens).
Also read qa-checklist.md for the full list of UI requirements.

Build a complete React frontend that matches these wireframes.

Requirements:
- Use React + Vite (already scaffolded in /frontend)
- Use Recharts for all charts (bar chart for themes, donut chart for sentiment)
- Use axios for API calls (backend at http://localhost:8000)
- Build these components:
    UploadScreen.jsx   — file upload with drag-drop, progress indicator
    Dashboard.jsx      — summary cards, charts, filterable review table
    ThemeDetail.jsx    — detail view for a single theme
    App.jsx            — routing between screens (react-router-dom)
- Handle loading states: show a spinner while analysis is running
- Handle error states: show a user-friendly error message if API fails
- The review table must support: filter by theme, filter by sentiment, text search
- Match the visual design from the wireframes as closely as possible

After building each component, tell me which qa-checklist.md items it addresses.
Do not ask me to click anything in the browser — use Chrome MCP to validate.
```

---

## Step 3 — Chrome MCP Automated Testing

After each screen is built, ask Claude to test it:

```
The frontend is running at http://localhost:3000 (run npm run dev first if needed).
Open Chrome via MCP and run through qa-checklist.md items [X] to [Y].
For each item, report ✅ if it passes or ❌ followed by what you observed vs expected.
Fix any ❌ items before reporting back to me.
Do not ask me to verify anything manually.
```

Replace [X] and [Y] with the relevant range. Claude will browse, interact, and report.

---

## Step 4 — Wire to Live Backend

Once UI is built against mocks, wire it to the real backend:

```
The backend is running at http://localhost:8000.
Update the frontend to use the real API (no mocks).
Then use Chrome MCP to run through the full qa-checklist.md end-to-end
with a real CSV upload (use data/sample-reviews.csv as the test file).
Report pass/fail for each checklist item.
```

---

## If a test fails

Paste the Chrome MCP output back into Claude:

```
Chrome MCP reported these failures:
[paste failures]

Fix each one. Use Chrome MCP to verify the fix before telling me it is done.
```

---

## You're ready for Phase 5 when:
- [ ] All 3 screens are built and visually match wireframes
- [ ] Chrome MCP passes all qa-checklist.md items (or you have documented exceptions)
- [ ] Frontend is wired to the live backend
- [ ] Full flow works: upload CSV → trigger analysis → view dashboard → click theme detail

**Move to `prompts/06-docker-deploy.md`**
