# Prompt 03 — Wireframes with Google Stitch

**Time:** ~15 minutes
**Goal:** Generate UI wireframes using Google Stitch. These become the visual spec Claude uses to build the frontend. You will never describe UI in words again.

**Run this in parallel with Prompt 04 (backend build) in a second terminal.**

---

## Step 1 — Open Google Stitch

Go to: **https://stitch.withgoogle.com**

Sign in with your Google account. Create a new project.

---

## Step 2 — Generate Wireframes

In the Stitch prompt box, paste this exactly:

```
Design a web application for a Customer Experience team to analyse open-ended 
customer reviews. The app has three screens:

SCREEN 1 — Upload Screen
- Clean centered layout with a large drag-and-drop file upload zone
- Accepts CSV files only, shows file name once selected
- A prominent "Analyse Reviews" button (disabled until file selected)
- Brief instruction text: "Upload your weekly reviews CSV to get instant insights"
- Progress indicator that appears after clicking Analyse

SCREEN 2 — Analysis Dashboard (main screen after upload)
- Header with: app name "Review Intelligence", number of reviews analysed, date
- Row of 3 summary cards: Total Reviews, Positive Sentiment %, Most Common Theme
- Theme Distribution: horizontal bar chart showing count per theme
- Sentiment Breakdown: donut chart (Positive / Negative / Neutral)
- Reviews Table below the charts:
  - Columns: Product, Review Text (truncated), Theme (coloured badge), Sentiment (icon), Key Phrases
  - Filter bar above table: filter by Theme dropdown, filter by Sentiment dropdown, search box
  - Pagination at bottom

SCREEN 3 — Theme Detail View
- Accessible by clicking a theme in the bar chart or table
- Header: theme name + count + sentiment distribution for that theme
- Full list of reviews for that theme with sentiment and key phrases
- Back button to return to dashboard

Use a clean, modern design system. Sidebar navigation is not needed.
Mobile responsive layout preferred.
```

Click Generate. Wait for Stitch to produce the wireframes.

---

## Step 3 — Export

Once generated:
1. Review all 3 screens — adjust anything that looks off using Stitch's edit tools
2. Export as **PNG** (one image per screen, or a combined view)
3. Save the exported images to your project as:
   - `docs/wireframe-upload.png`
   - `docs/wireframe-dashboard.png`
   - `docs/wireframe-detail.png`

Create the `docs/` folder if it doesn't exist.

---

## Step 4 — Generate QA Checklist from Wireframes

Open Claude Code and paste this (attach the wireframe images):

```
You are a QA engineer. I am attaching wireframes for a 3-screen web application.

Based on these wireframes, write a detailed QA checklist covering:
1. Every user interaction (clicks, uploads, filters, navigation)
2. Every state each screen can be in (empty, loading, error, success, no results)
3. Every visual element that must be present on each screen
4. Data validation rules visible in the design

Format as a numbered list grouped by screen. Be specific — "Upload button is disabled 
when no file is selected" not "Upload button works correctly".

This checklist will be used by an automated browser agent (Chrome MCP) to test the 
frontend. Every item must be independently testable.
```

Save Claude's output as `qa-checklist.md` in your project root.

---

## You're ready for Phase 4 (frontend) when:
- [ ] Wireframe PNGs exist in `docs/`
- [ ] `qa-checklist.md` exists with 20+ numbered items
- [ ] You understand the 3 screens you need to build

**Move to `prompts/05-frontend-build.md`**
