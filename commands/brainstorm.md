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
| **Problem** — "X is broken" | **Solution** — how to fix it, built from fundamentals |
| **Observation** — "something feels off about X" | **Root cause** — what's actually wrong (or confirmation nothing is) |
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

If unclear, ask one question: "Is this something broken, something you noticed, something you're questioning, something you want to build, or something that feels off?"

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
- **Problem → Solution direction.** What to do, built from fundamentals. Not a plan — a direction.
- **Observation → Root cause.** What's actually happening and why. May conclude "nothing is wrong."
- **Question → Answer.** Yes, no, or "wrong question" with the right question identified.
- **Idea → Validation.** Worth doing or not, with reasoning. What's the real need underneath?
- **Hunch → Analysis.** Where the friction is, why it exists, what better looks like.
- **Constraints → Feasibility check.** What's possible within these bounds. What's not.
- **Criteria → Evaluation / Confidence.** How well the current direction meets these. Gaps identified.

Present to the human. Iterate until they're satisfied.

### Step 4 — Save

Write to `docs/brainstorms/YYYY-MM-DD-<topic>.md`. Suggest next steps without auto-invoking:

```
Brainstorm saved to docs/brainstorms/<file>.md

Next steps (your choice):
  /mas:dev-loop <description>  — implement as a feature
  /mas:bug-fix <description>   — fix as a bug
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
