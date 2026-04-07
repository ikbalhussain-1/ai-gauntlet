# Why Claude Won't Hallucinate Today

This is the most important document in the kit. It explains the design principle behind the entire session workflow, and why the approach you are about to follow results in working, correct software — not AI guesswork.

---

## What hallucination actually is

AI hallucination is not randomness. It is not stupidity. It is **gap-filling**.

When an AI model encounters an undefined or under-constrained space, it fills the gap with the most plausible answer it can generate. Most of the time, that answer looks correct. Sometimes it is subtly wrong. Occasionally it is confidently wrong about something important.

The mistake most developers make is treating this as a Claude problem. It is not. It is a **specification problem**.

When you say "build me a login page," you have left an enormous number of decisions undefined: what fields, what validation, what error states, what happens on success, what the API expects, what the URL structure is. Claude fills all of those gaps — and the more gaps there are, the more chances there are for a plausible-but-wrong answer to slip through.

The solution is not to trust Claude less. The solution is to **close the gaps**.

---

## The gap-closing strategy

This session uses five layers of specification, each one closing a specific category of gap.

### Layer 1 — The PRD closes requirement gaps

The BRD you start with is ambiguous. That ambiguity would propagate into every decision Claude makes downstream — API design, data model, UI layout, feature scope — unless you resolve it first.

**Prompt 00** uses Claude to interrogate the BRD and force you to make decisions. The PRD it produces is a contract: these features, these acceptance criteria, this scope, nothing else. Claude cannot hallucinate features you did not ask for if the PRD says what you did ask for.

### Layer 2 — The OpenAPI spec closes API contract gaps

Once you have a PRD, you define the full API contract before writing a single line of implementation. Every endpoint, every request schema, every response shape is specified in `openapi.yaml`.

This matters because the most common source of frontend-backend integration bugs is an implicit assumption about the API shape. When that shape is explicit, Claude cannot make it up.

### Layer 3 — Tests written first close implementation correctness gaps

In traditional development, you write code and then hope it is correct. In this session, you write tests first — and those tests describe exactly what correct looks like.

When Claude implements the backend, it has a clear definition of done: all tests pass. If Claude generates code that does not match the spec, the tests fail immediately and Claude fixes it. You never review logic — you review green vs red.

**This is the anti-hallucination mechanism.** Claude cannot hallucinate a working implementation when working implementations are defined by passing tests.

### Layer 4 — Wireframes close UI design gaps

"Build a dashboard" is an open invitation for Claude to make dozens of visual decisions you may or may not agree with. Stitch wireframes close every one of those decisions before you write a component.

The wireframe is a visual contract. Claude does not decide what goes where — it matches an image. There is no room for a plausible-but-wrong layout interpretation.

### Layer 5 — Structured JSON output closes response format gaps

When Claude processes reviews and returns analysis, the format of that response matters. If Claude decides the field is called `category` instead of `theme`, your frontend breaks silently. If it returns a string instead of an array for `key_phrases`, your parsing logic fails.

The AI output contract in `CLAUDE.md` specifies the exact JSON shape:
```json
{"theme": "...", "sentiment": "...", "key_phrases": ["...", "..."]}
```

Combined with `response_format` or explicit JSON prompting in the API call, Claude has no room to deviate. The response format is not a suggestion — it is a constraint.

---

## What this means in practice

By the time you run the scoring script at the end of the session, every part of your system will have been built against a specification:

| Component | What constrains it |
|-----------|-------------------|
| Features | PRD with acceptance criteria |
| API shape | OpenAPI spec |
| Implementation correctness | Passing pytest/jest tests |
| UI layout | Stitch wireframes |
| UI correctness | Chrome MCP QA checklist |
| AI output format | Structured JSON contract |

At no point in this workflow does Claude operate in an unconstrained space. The gaps have been filled — not by Claude's best guess, but by decisions you made explicitly.

**That is why the approach works. Not because Claude is perfect. Because you removed the conditions under which imperfection propagates.**

---

## The right mental model

Stop thinking about AI as a tool you use. Start thinking about AI as a team member you brief.

A well-briefed team member — given a clear spec, clear acceptance criteria, and clear visual references — produces good work. A poorly-briefed one produces plausible-sounding work that may or may not be what you wanted.

Your job in this session is not to type code. Your job is to brief Claude clearly, layer by layer, until the specification leaves no room for ambiguity.

That is Stage 6 development. That is what you are learning today.

---

## One more thing

At some point today, a test will fail. A QA checklist item will be red. The eval will miss a review.

Do not ask a human. Do not Google. Do not read the code.

Paste the failure into Claude and say: **"Fix this."**

Watch how it diagnoses the problem, identifies the gap in its own output, and corrects it — against the spec you defined. That feedback loop, running automatically, is more reliable than manual code review. It is what separates Stage 6 from Stage 3.

Trust the process. Trust the tests. The tests cannot lie.
