# The Problem

> This is the original business requirement as submitted by the team. It is intentionally brief and ambiguous — just like real work. Your first task is to use Claude to turn this into a proper PRD before writing a single line of code.

---

## Business Requirement Document (BRD)

**Submitted by:** Avinash Bamboria, BA — Customer Experience Team
**Date:** 02 April
**Priority:** P2
**Frequency:** Weekly
**Current time spent:** ~3 hours/week

---

### Problem Statement

Going through each customer comment and categorising it is a real pain point which takes almost 3 hours every week. We receive open-ended reviews from multiple sources and someone on the team manually reads each one and puts it into a category. This process is tedious, inconsistent, and takes time away from actual analysis work.

### What We Want

AI should analyse the comments and categorise them automatically. We also want to understand the sentiment. Right now all of this is done in Excel.

### Systems Involved

Excel, Zykrr

### Data Types

Excel (CSV exports of reviews)

### Desired Outcome

Save the 3 hours spent on manual categorisation every week. The output should be structured and ready for decision-making.

---

## Your First Task

Before building anything, open Claude Code and use the prompt in `prompts/00-brd-to-prd.md` to turn this BRD into a full PRD.

The PRD you produce will define exactly what you build. Own it.

---

## Sample Data

A CSV of 30 sample reviews is available at `data/sample-reviews.csv`. This is what the team would upload every week.
