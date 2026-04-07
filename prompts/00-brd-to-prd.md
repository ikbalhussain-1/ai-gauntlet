# Prompt 00 — BRD → PRD

**Time:** ~20 minutes
**Goal:** Turn the ambiguous BRD into a proper PRD that defines exactly what you'll build.

This is Phase 0. Do not open your code editor yet. Do not scaffold anything. Just you and Claude, thinking through the problem.

---

## Step 1 — Interrogate the BRD

Open Claude Code (or claude.ai) and paste this prompt:

```
I have a business requirement document (BRD) from our Customer Experience team.
Act as a senior product manager. Your job is to interrogate this BRD and identify
every ambiguity, assumption, and missing requirement.

Ask me clarifying questions — one topic at a time. Wait for my answer before
moving to the next question. Do not write the PRD yet.

BRD:
---
Problem: Going through each customer comment and categorising it is a real pain
point which takes almost 3 hours every week. We receive open-ended reviews from
multiple sources and someone on the team manually reads each one and puts it into
a category. This process is tedious, inconsistent, and takes time away from
actual analysis work.

What we want: AI should analyse the comments and categorise them automatically.
We also want to understand the sentiment. Right now all of this is done in Excel.

Data: CSV exports from Excel and Zykrr.
Desired outcome: Save the 3 hours spent on manual categorisation every week.
---
```

Answer Claude's questions. Make decisions. If you are unsure, decide anyway — you own this PRD.

---

## Step 2 — Generate the PRD

Once Claude has asked all its questions and you've answered, paste this:

```
Good. Now write a complete PRD based on our conversation. Include:

1. Problem Statement (1 paragraph, crisp)
2. User Persona (who uses this tool, what they need)
3. Feature List with acceptance criteria (each feature should have 2-3 testable criteria)
4. Data model (what fields does a "review" have after analysis?)
5. API contract (list all endpoints with request/response shape)
6. Tech stack recommendation with justification
7. Out of scope (what are we NOT building?)
8. Definition of Done (how do we know the tool is complete?)

Be specific. This PRD will be used to generate an OpenAPI spec and test suite.
```

---

## Step 3 — Save your PRD

Ask Claude to save the PRD as `PRD.md` in your project root:

```
Save this PRD to a file called PRD.md in the current directory.
```

---

## You're ready for Phase 1 when:
- [ ] `PRD.md` exists in your project root
- [ ] You can clearly answer: "What are the 4-5 API endpoints I need to build?"
- [ ] You have decided on a backend stack (ask Claude to recommend one if unsure)

**Move to `prompts/01-project-scaffold.md`**
