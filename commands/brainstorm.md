---
description: First principles decomposition — turn observations, ideas, or problems into clear, actionable problem statements
---

# Brainstorm (MAS)

First principles decomposition for: $ARGUMENTS

## Foundation

Elon Musk's 3-step first principles framework:

1. **Identify and challenge assumptions** — What do we assume is true? Why?
2. **Break down to fundamentals** — What are the basic truths we're sure of?
3. **Build up from scratch** — Reconstruct a solution from those truths, not from analogy

> "Boil things down to the most fundamental truths and say 'OK, what are we sure is true?' And then reason up from there." — Elon Musk

This command applies that framework. Every step below maps to one of these three moves.

## Flow

```
brainstorm (this command)
  │
  ├─ Step 1 — Receive input
  │     Classify and handle whatever the human brings.
  │
  ├─ Step 2 — Challenge assumptions
  │     Surface beliefs, test against evidence.
  │
  ├─ Step 3 — Decompose to fundamentals
  │     Break down to smallest true components.
  │
  ├─ Step 4 — Discover the real problem (or not)
  │     Three outcomes: PROBLEM FOUND / PROBLEM CONFIRMED / NO PROBLEM
  │
  ├─ Step 5 — Build up from truths (if problem exists)
  │     Construct solution from fundamentals, not analogy.
  │
  ├─ Step 6 — Save brainstorm
  │     Write to docs/brainstorms/YYYY-MM-DD-<topic>.md
  │
  └─ Step 7 — Suggest next steps (don't auto-invoke)
        Present options. Human decides.
```

## Three Questions (applied at every step)

These are the first principles check. Apply them continuously throughout the brainstorm — not just at one step:

1. **Can we break it down further?** — If yes, we haven't hit bedrock yet.
2. **Can we do it differently?** — If we're copying a pattern, challenge why.
3. **Can we remove something without breaking it?** — Simplest solution that works.

Every step should circle back to these. If you can still answer "yes" to question 1, keep decomposing.

## Steps

### Step 1 — Receive Input

Accept whatever the human brings. Classify the input and handle accordingly:

**Clear problem statement:**
> "bootstrap writes rules/ instead of .claude/rules/"

Acknowledge. Jump to Step 2 to challenge assumptions. Don't decompose what's already clear — validate it.

**Vague observation:**
> "something feels off about how hooks are wired"

Explore. Ask: What specifically feels off? What did you see that triggered this? When did you notice it?

**Question:**
> "should we even have task tracking?"

Reframe as investigation. What is task tracking supposed to do? Is it doing that? What would happen without it?

**Idea / what-if:**
> "what if brainstorming was a first-class command?"

Ask why. What's missing today? What would change if this existed? Who benefits?

**Hunch / friction:**
> "the dev-loop feels too heavy"

Measure. Where exactly is the friction? Which step? What would "not heavy" look like?

**GATE:** Input is classified into one of the five types above and you have enough context to proceed. If the input is too vague even for the "vague observation" path, ask the human to say more before continuing.

---

### Step 2 — Challenge Assumptions

For each claim or belief surfaced in Step 1:

- "Why do we think this is true?"
- "What evidence do we have?"
- "What if the opposite were true?"
- "Who told us this, and were they right?"

List assumptions explicitly. Mark each as:
- **CONFIRMED** — evidence exists
- **QUESTIONED** — no evidence, or contradicted by evidence

Apply the three questions: Can we break this assumption down further? Are we assuming this because everyone else does? Can we remove this assumption without breaking the argument?

**GATE:** At least one assumption is explicitly listed and marked CONFIRMED or QUESTIONED. Do NOT proceed to decomposition with zero assumptions surfaced — every input has hidden assumptions.

---

### Step 3 — Decompose to Fundamentals

Break down the subject into its smallest components. For each component:

- What is actually true about this? (not assumed, not hoped — true)
- What is the fundamental constraint?
- Can we break it down further?
- Can we remove it without breaking anything?

Use the Socratic method — keep asking "why" until hitting bedrock. Bedrock = a truth that can't be decomposed further without changing the domain.

Apply the three questions at each level of decomposition. If you can still break something down, you haven't reached fundamentals yet.

**GATE:** At least two components identified, each with a stated truth and constraint. If you only found one component, you haven't decomposed far enough.

---

### Step 4 — Discover the Real Problem (or Not)

Based on the decomposition, arrive at one of three outcomes:

**A) PROBLEM FOUND** — different from the original input.
"You thought the issue was X, but the real issue is Y."
Define Y precisely. This becomes the problem statement.

**B) PROBLEM CONFIRMED** — same as the original input.
"Your observation was correct. The problem is exactly X."
Sharpen the definition. Add constraints and scope.

**C) NO PROBLEM** — the observation doesn't lead to action.
"After decomposition, this works as designed. The assumption that it was wrong was itself wrong."
Document why. This is a valid and valuable outcome.

**GATE:** Outcome is explicitly stated as one of the three above (PROBLEM FOUND / PROBLEM CONFIRMED / NO PROBLEM). If you can't decide, you need more decomposition — go back to Step 3.

---

### Step 5 — Build Up from Truths (if problem exists)

**Skip this step if Step 4 outcome is NO PROBLEM.** Jump to Step 6.

DON'T: look at how others solve this, pick from options, reason by analogy.
DO: take the fundamental truths from Step 3 and construct a solution from those truths bottom-up.

Three questions on loop:
1. Can we break it down further?
2. Can we do it differently?
3. Can we remove something without breaking it?

Present the solution direction to the human. Iterate until they are satisfied. This is a conversation, not a one-shot answer.

**GATE:** Human has acknowledged the solution direction (or explicitly said "good enough, save it"). Do NOT save a brainstorm the human hasn't seen.

---

### Step 6 — Save Brainstorm

Write to: `docs/brainstorms/YYYY-MM-DD-<topic>.md`

Use the output artifact template defined below. The brainstorm document is the deliverable — it captures the full thinking process, not just the conclusion.

**GATE:** File exists at `docs/brainstorms/YYYY-MM-DD-<topic>.md` and contains all sections from the output artifact template.

---

### Step 7 — Suggest Next Steps (Don't Auto-Invoke)

Present the saved artifact path and suggest options. **Do NOT auto-invoke any command.** The human decides.

```
Brainstorm saved to docs/brainstorms/<file>.md

Next steps (your choice):
  /mas:dev-loop <description>  — implement as a feature
  /mas:bug-fix <description>   — fix as a bug
  Or continue refining the brainstorm.
```

If the outcome was NO PROBLEM, adjust the suggestions:

```
Brainstorm saved to docs/brainstorms/<file>.md

Outcome: No problem found. The observation was explored and decomposed.
The brainstorm document captures the reasoning.

No action needed — or continue exploring if something still feels off.
```

---

## Output Artifact Template

The brainstorm saved in Step 6 must follow this structure:

```markdown
# Brainstorm: <topic>

**Date:** YYYY-MM-DD
**Input:** <what the human brought — verbatim>
**Outcome:** PROBLEM FOUND / PROBLEM CONFIRMED / NO PROBLEM

## Assumptions Challenged

| # | Assumption | Status | Evidence |
|---|-----------|--------|----------|
| 1 | ... | CONFIRMED / QUESTIONED | ... |

## Decomposition

### Component: <name>
- **Truth:** ...
- **Constraint:** ...
- **Can remove?** yes/no — why

### Component: <name>
- **Truth:** ...
- ...

## Discovery

<What the real problem is (or why there isn't one)>

## Solution Direction (if applicable)

<Built from the truths above, not from analogy>

## Next Steps

<Suggested commands or further investigation>
```

## What This Command Does NOT Do

- **No worktree** — thinking, not executing
- **No agent dispatch** — human conversation, not pipeline
- **No plan writing** — that's the next command's job (`/mas:dev-loop`)
- **No code changes** — purely analytical
- **Does NOT invoke `superpowers:brainstorming`** — that skill uses collaborative dialogue and analogy-based proposals; first principles reasoning is fundamentally different
- **Does NOT invoke `superpowers:writing-plans`** — planning happens after brainstorming, as a separate step

## Integration

```
/mas:brainstorm → brainstorm doc → human decision
                                     │
                                     ├─ /mas:dev-loop (reads brainstorm as context)
                                     ├─ /mas:bug-fix (reads brainstorm as context)
                                     └─ nothing (brainstorm was enough)
```

dev-loop and bug-fix should check `docs/brainstorms/` for recent brainstorms related to the task and use them as input context for the plan.
