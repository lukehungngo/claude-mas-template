---
description: First principles decomposition — turn any input into a clear, actionable output
---

# Brainstorm (MAS)

First principles decomposition for: $ARGUMENTS

## Foundation

Elon Musk's 3-step first principles framework:

1. **Identify and challenge assumptions** — What do we assume is true? Why?
2. **Break down to fundamentals** — What are the basic truths we're sure of?
3. **Build up from scratch** — Reconstruct a solution from those truths, not from analogy

> "Boil things down to the most fundamental truths and say 'OK, what are we sure is true?' And then reason up from there." — Elon Musk

## Input → Output Contract

| You bring | You get |
|-----------|---------|
| **Context** — background, situation, landscape | **Framing** — how to think about this, what matters |
| **Problem** — "X is broken" | **Framing / Solution direction** — might reframe the problem itself, or provide a solution built from fundamentals |
| **Observation** — "something feels off about X" | **Hypothesis / Root cause** — what might be wrong, or confirmed root cause if evidence supports it |
| **Question** — "should we even have X?" | **Answer** — yes/no with reasoning from first principles |
| **Idea** — "what if we built X?" | **Validation** — is this worth doing? what's the real need? |
| **Hunch** — "X feels too heavy" | **Analysis** — where exactly, why, and what would better look like |
| **Constraints** — "we can't use X, budget is Y" | **Feasibility check** — what's possible within these bounds |
| **Criteria** — "it needs to handle X, Y, Z" | **Evaluation / Confidence** — how well does the current direction meet these? |

## Flow

```
brainstorm (this command)
  │
  ├─ Step 1 — Receive input and identify which type
  ├─ Step 2 — First principles (challenge → decompose → build up)
  ├─ Step 3 — Deliver the output matching the input type
  └─ Step 4 — Save and suggest next steps
```

## Steps

### Step 1 — Receive Input

Accept whatever the human brings. Identify the input type from the contract table above.

If unclear, ask up to one clarifying question. If still ambiguous, proceed with best-effort classification and state your assumptions explicitly — the human can correct.

### Step 2 — First Principles

Apply Musk's 3 steps:

**Challenge assumptions.** For each belief surfaced:
- Why do we think this is true?
- What evidence do we have?
- What if the opposite were true?

List assumptions as CONFIRMED (evidence exists) or QUESTIONED (no evidence).

**Decompose to fundamentals.** Break down into smallest components. For each:
- What is actually true? (not assumed — true)
- What is the fundamental constraint?

Keep asking "why" until hitting bedrock — a truth that can't be decomposed further.

**Build up from truths.** Take the fundamentals and construct the output from the ground up. Not from analogy. Not from "how others do it."

### Step 3 — Deliver

Based on the input type, deliver the promised output:

- **Context → Framing.** How to think about this. What matters, what doesn't.
- **Problem → Framing / Solution direction.** Might reframe the problem before solving. Or provide direction built from fundamentals.
- **Observation → Hypothesis / Root cause.** What might be wrong (hypothesis) or what is wrong (root cause, if evidence confirms it).
- **Question → Answer.** Yes, no, or "wrong question" with the right question identified.
- **Idea → Validation.** Worth doing or not, with reasoning. What's the real need underneath?
- **Hunch → Analysis.** Where the friction is, why it exists, what better looks like.
- **Constraints → Feasibility check.** What's possible within these bounds. What's not.
- **Criteria → Evaluation / Confidence.** How well the current direction meets these. Gaps identified.

Present to the human. Iterate until they're satisfied.

### Step 4 — Save and Suggest

Write the brainstorm to `docs/brainstorms/YYYY-MM-DD-<topic>.md`.

Then, based on the concluded output type, print a **primary suggestion** plus the **alternatives menu**. Do not auto-invoke — human decides.

**Pick the primary suggestion using this table:**

| Concluded output | Primary suggestion |
|------------------|--------------------|
| Root cause confirmed (evidence supports it) | `/mas:bug-fix fix <root cause> — see docs/brainstorms/<file>.md` |
| Hypothesis only (root cause not yet confirmed) | Investigate further to confirm the hypothesis, then `/mas:bug-fix` |
| Solution direction is clear and actionable | `/mas:dev-loop implement <solution> — see docs/brainstorms/<file>.md` |
| Idea validated YES (worth building) | `/mas:dev-loop implement <idea> — see docs/brainstorms/<file>.md` |
| Idea validated NO (not worth building) | Stop. Refine scope or pick a different idea. |
| Answer to a question (yes/no) | Usually none — human decides what to do with the answer. |
| Framing for context | None — analytical only. Proceed with your own next action. |
| Analysis of a hunch | If root cause surfaced → `/mas:bug-fix`. If solution direction clear → `/mas:dev-loop`. Otherwise refine. |
| Feasibility check on constraints | Situational — depends on whether the path is feasible. |
| Evaluation against criteria | Depends on identified gaps — address gaps first, then `/mas:dev-loop` if cleared. |

If none of the rows fit cleanly, suggest the most relevant next action in plain language (e.g., "gather more data on X", "prototype the risky part first", "defer until Y is decided").

**Print format:**

```
Brainstorm saved to docs/brainstorms/<file>.md

Suggested next step:
  <primary suggestion from the table above>

Alternatives (your choice):
  /mas:dev-loop implement brainstorm at docs/brainstorms/<file>.md
  /mas:bug-fix fix based on brainstorm at docs/brainstorms/<file>.md
  Or continue refining.
```

## Output Format

```markdown
# Brainstorm: <topic>

**Date:** YYYY-MM-DD
**Input type:** Context / Problem / Observation / Question / Idea / Hunch / Constraints / Criteria
**Input:** <what the human brought — verbatim>

## Assumptions

| Assumption | Status | Evidence |
|-----------|--------|----------|
| ... | CONFIRMED / QUESTIONED | ... |

## Fundamentals

<Components broken down, truths identified, constraints stated>

## Output

<The deliverable: framing / solution / root cause / answer / validation / analysis / feasibility check / evaluation>

## Next Steps

<Suggested commands or further investigation>
```

## What This Command Does NOT Do

- No worktree, no agents, no code changes — purely analytical
- Does not invoke `superpowers:brainstorming` or `superpowers:writing-plans`
- Does not auto-invoke any next command — human decides

## Integration

```
/mas:brainstorm → brainstorm doc → human decision
                                    │
                                    ├─ /mas:dev-loop
                                    ├─ /mas:bug-fix
                                    └─ nothing (brainstorm was enough)
```
