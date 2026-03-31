---
description: Focused bug-fix loop — debug, fix with TDD, review, verify, finish
---

# Bug-Fix Loop (MAS)

Fix a bug for: $ARGUMENTS

## Mode

Check if `$ARGUMENTS` contains `--auto`. If yes → **autonomous mode** (no human checkpoints, run everything end-to-end). If no → **interactive mode** (pause for approval at key steps).

**`--auto` scope:** Skips human approval gates at Steps 1 and 7 only. It does NOT skip the Bug-Fixer, Reviewer, or verification. The full pipeline runs in both modes.

**What `--auto` does NOT mean:**

❌ **BAD** (what happened in 3/3 audited --auto bug-fix sessions):
> "The bug is clear. I'll debug and fix it directly — no need to dispatch
> a bug-fixer agent for something this straightforward."
> *Result: No bug-fixer dispatched. No reproduction test. No reviewer. No verification.*

✅ **GOOD** (correct --auto behavior):
> "Bug is clear (`--auto` skips step 1 clarification). Creating worktree...
> Running systematic-debugging skill (step 3)... Dispatching Bug-Fixer agent (step 4)...
> Bug-Fixer writes reproduction test first, then minimal fix...
> Dispatching Reviewer (step 5)... Invoking verification skill (step 6)...
> Creating PR automatically (`--auto` skips human choice, step 7)."

`--auto` removes 2 human pauses. It does NOT remove 3 agent dispatches.

## Agent Pipeline

```
bug-fix (this command)
  │
  ├─ 1. Clarify ─── Skill(skill: "ask-questions")
  ├─ 2. Branch ─── git worktree
  ├─ 3. Debug ─── Skill(skill: "superpowers:systematic-debugging")
  ├─ 4. Fix ─── Agent(subagent_type: "mas:bug-fixer:bug-fixer")
  │
  ├─ 5. Review ─── Agent(subagent_type: "mas:reviewer:reviewer")
  │       └─ BLOCKED? ──→ Agent(subagent_type: "mas:bug-fixer:bug-fixer") (max 2 cycles)
  │
  ├─ 6. Verify ─── Skill(skill: "verification")
  └─ 7. Finish ─── Skill(skill: "finishing-branch")
```

## Steps

### Step 1 — Clarify

```
Skill(skill: "ask-questions")
```

Clarify the bug before touching code:
- What is the exact symptom? (error message, wrong output, crash)
- How to reproduce it? (steps, input, environment)
- What is the expected vs actual behavior?
- Is there a specific file/line already identified?

- `--auto`: skip clarification, treat `$ARGUMENTS` as complete bug description.

**GATE:** Bug is reproducible and understood. Do NOT proceed to Step 2 with "it sometimes fails" or no reproduction steps.

---

### Step 2 — Branch

Create an isolated workspace:

```bash
git worktree add -b fix/{{bug-name}} .worktrees/{{bug-name}}
cd .worktrees/{{bug-name}}
```

Verify clean baseline: `{{test-command}}` must pass.

**GATE:** You are in the worktree directory and baseline tests pass. If baseline already fails, document which tests were already failing before your fix — do NOT proceed as if they are yours to fix unless explicitly in scope.

---

### Step 3 — Debug

If the root cause is not already identified:

```
Skill(skill: "superpowers:systematic-debugging")
```

This skill produces a confirmed root cause with a reproduction test. Skip only if the caller has already identified the exact file:line and cause.

**GATE:** Root cause is identified and a failing reproduction test exists. Do NOT dispatch Bug-Fixer without knowing exactly what is broken.

> **CHECKPOINT ASSERTION — Bug-Fixer agent is mandatory**
>
> You are about to fix this bug yourself. **STOP.**
> This happened in 3/3 audited bug-fix sessions — the main session debugged and fixed code directly every time.
> The Bug-Fixer agent MUST be dispatched via `Agent(subagent_type: "mas:bug-fixer:bug-fixer")`.
> You are the pipeline controller, NOT the implementer.
> The Bug-Fixer enforces: reproduction test FIRST, minimal fix, scope discipline.
> If you are about to call Edit or Write on production code — you are violating the pipeline.

> **FALLBACK — If Agent() tool call fails:**
>
> If the Bug-Fixer dispatch fails (tool unavailable, error, timeout):
> 1. Do NOT silently fall back to fixing the bug yourself
> 2. Report the failure to the human: "Bug-Fixer dispatch failed: {error}"
> 3. Ask the human: "Should I retry, or proceed with manual fix under your supervision?"
> 4. If human approves manual fix: document it in the self-audit as a known deviation

---

### Step 4 — Fix

Dispatch the Bug-Fixer with the reproduction test and root cause:

```
Agent(
  subagent_type: "mas:bug-fixer:bug-fixer",
  prompt: """
  ## Bug Description
  {paste bug description from Step 1}

  ## Root Cause
  {paste root cause from Step 3}

  ## Reproduction Test
  {paste the failing test from Step 3}

  ## Working Directory
  {worktree path}

  ## Output
  Write your result to docs/reports/bugfix-result.md
  """
)
```

- Interactive: present the Bug-Fixer's result to human before reviewing.
- `--auto`: proceed directly to Step 5.

**GATE:** `docs/reports/bugfix-result.md` exists and reports all tests passing. Do NOT proceed if the Bug-Fixer reports unresolved failures.

> **CHECKPOINT ASSERTION — Reviewer is mandatory after every fix**
>
> You are about to skip the review. **STOP.**
> In audited sessions, only 1/6 implementations got a reviewer dispatch.
> The Reviewer MUST be dispatched via `Agent(subagent_type: "mas:reviewer:reviewer")` after the Bug-Fixer completes.
> If the Reviewer issues BLOCKED, dispatch Bug-Fixer again (max 2 cycles).

---

### Step 5 — Review

Dispatch the Reviewer to verify the fix is correct and doesn't introduce new issues:

```
Agent(
  subagent_type: "mas:reviewer:reviewer",
  prompt: """
  ## Bug Description
  {paste bug description}

  ## Root Cause
  {paste root cause}

  ## Bug-Fixer Result
  {paste from docs/reports/bugfix-result.md}

  ## Working Directory
  {worktree path}

  ## Output
  Write your review to docs/reports/bugfix-review.md
  Issue verdict: APPROVED / APPROVED WITH CHANGES / BLOCKED
  """
)
```

**On verdict (Review Loop — max 2 cycles):**

Track `review_cycle` starting at 0. After each review:

- **APPROVED / APPROVED WITH CHANGES** → exit loop, proceed to Step 6.
- **BLOCKED** (and `review_cycle < 2`):
  1. Increment `review_cycle`.
  2. Interactive: show blocking issues to human, ask "Re-fix automatically? (y/n)". If no → escalate.
  3. `--auto`: re-dispatch Bug-Fixer with the review report, then re-run this step.
- **BLOCKED** (and `review_cycle >= 2`) → stop and escalate to human. Do NOT dispatch a 3rd fix cycle.

**GATE:** `docs/reports/bugfix-review.md` exists with verdict APPROVED or APPROVED WITH CHANGES. Do NOT proceed with a BLOCKED verdict.

> **CHECKPOINT ASSERTION — Verification is mandatory**
>
> You are about to skip verification. **STOP.**
> This happened in 5/5 audited sessions — 0 invoked the verification skill.
> You MUST call `Skill(skill: "verification")` which writes `docs/reports/verification-{branch}.md`.
> The GATE checks for this file — raw test output alone will not pass.

---

### Step 6 — Verify

```
Skill(skill: "verification")
```

**GATE:** `docs/reports/verification-{branch}.md` exists with verdict PASS. Do NOT proceed to Step 7 without this file.

---

### PIPELINE SELF-AUDIT (mandatory before finishing)

Before proceeding to Step 7, verify each item with evidence. Self-assessment is not sufficient — check for artifacts.

- [ ] **Bug-Fixer dispatched?** — Scroll up and confirm an `Agent(subagent_type: "mas:bug-fixer:bug-fixer")` tool call exists in this conversation. If you fixed the bug via Write/Edit yourself, this is a violation.
- [ ] **Reproduction test written first?** — Check the Bug-Fixer's result file in `docs/reports/` for a reproduction test entry. If no test is listed, the reproduction-test-first requirement was bypassed.
- [ ] **Reviewer issued verdict?** — Check `docs/reports/` for a review file with a verdict line. If no review file exists, no reviewer was dispatched.
- [ ] **Bug-Fixer handled blocks?** — If review verdict is BLOCKED, check for a second bugfix-result file. If none exists and you fixed it yourself, this is a violation.
- [ ] **Verification report exists?** — Run: `test -f docs/reports/verification-{branch}.md && grep "Verdict:" docs/reports/verification-{branch}.md`. File must exist AND contain Build, Code, Spec, Regression sections.

**If any check fails:** You violated the pipeline. Do NOT proceed to Step 7. Go back to the first failed step and execute it properly. If an Agent() call failed, follow the FALLBACK guidance above.

**This is not optional.** In 3/3 audited bug-fix sessions, zero dispatched the bug-fixer agent. You are being explicitly asked to break that pattern.

### Step 7 — Finish

```
Skill(skill: "finishing-branch")
```

- Interactive: present options (merge/PR/keep/discard).
- `--auto`: create PR automatically.
- Include the bugfix review report in the branch summary.

---

## Rules

- Use `/mas:dev-loop` for feature work, not `/mas:bug-fix` — this command is for focused bug fixes only.

For agent-specific rules (TDD, scope discipline, reproduction-test-first), see the agent CLAUDE.md files. For battle-tested lessons, see `rules/agent-workflow.md`.

## When to Use `/mas:bug-fix` vs `/mas:dev-loop`

| Use `/mas:bug-fix` | Use `/mas:dev-loop` |
|---------------|----------------|
| Known regression, clear symptom | New feature or behaviour change |
| Single root cause, targeted fix | Multiple tasks with dependencies |
| Fix scoped to 1-3 files | Requires Researcher or design step |
| Reviewer report already exists | Full planning needed |
