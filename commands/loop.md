---
description: Lean 3-phase pipeline — plan, implement+review (batched), finish. No research convergence, no mandatory reflect phase, no size routing.
---

# Loop (MAS)

Implement: $ARGUMENTS

## What This Is

A lightweight alternative to `/mas:dev-loop`. Same agent quality (engineer + reviewer + bug-fixer), 60% less orchestration overhead. Use this by default. Use `/mas:dev-loop` when you need the research convergence protocol, reflect agent, or design phase.

| | loop | dev-loop |
|-|------|----------|
| Worktree | ✓ | ✓ |
| Plan | ✓ simple | ✓ full superpowers skill |
| Research Convergence | opt-in only | default for novel tasks |
| Engineer + Reviewer | ✓ | ✓ |
| Bug-Fixer | ✓ | ✓ |
| Reflect Agent | folded into reviewer | separate phase |
| Size-based routing | ✗ | ✓ |
| Cross-task review | ✗ | opt-in |
| Delivery report | ✗ | ✓ |
| Verify | ✓ | ✓ |

## Anti-Pattern (what NOT to do)

❌ **BAD:**
> "The requirement is clear. I'll implement it directly — the loop is overkill for this."
> *Result: No worktree. No engineer. No reviewer. No verification.*

✅ **GOOD:**
> "Creating worktree... Writing plan... Dispatching engineer for TASK-01... Dispatching reviewer... Verdicts APPROVED. Running verification. Presenting options."

**The loop is not overkill. Direct implementation skips review and verification.**

---

## Phase 1 — Branch + Plan

### 1a. Create worktree

```bash
git worktree add -b feature/{{name}} .worktrees/{{name}}
```

Work from the worktree for all file operations.

**GATE:** Baseline passes (run `{{test-command}}` if defined in CLAUDE.md).

### 1b. Write plan

**If `$ARGUMENTS` references a brainstorm doc** — read it. Use it as the primary input.

**If requirement is vague** — tell the user to run `/mas:brainstorm` first. Do NOT proceed with ambiguous scope.

Write a plan directly (no external skill needed):

```markdown
# Plan: {slug}

## Requirement
{verbatim from $ARGUMENTS}

## Tasks

### TASK-01: {description}
**Goal:** {what this achieves}
**Files:** {relevant file paths}
**Acceptance:** {what done looks like — 1-2 lines}

### TASK-02: ...
```

Save to `docs/superpowers/plans/YYYY-MM-DD-{slug}.md`.

Present plan to user for approval.

**GATE:** Plan exists. User approved (or `--auto`).

---

## Phase 2 — Implement + Review

### 2a. Dispatch engineers (batch, max 5 concurrent)

For each task, dispatch one engineer:

```
Agent(
  subagent_type: "mas:engineer:engineer",
  prompt: """
  ## Task
  {task description from plan}

  ## Goal
  {task goal}

  ## Relevant Files
  {file paths}

  ## Acceptance Criteria
  {what done looks like}

  ## Working Directory
  {worktree path}

  ## Output
  Write your result to docs/results/TASK-{id}-result.md
  """,
  isolation: "worktree"
)
```

Wait for ALL engineers in the batch to finish before dispatching reviewers. If a result file does not exist after an engineer returns, that dispatch failed — re-dispatch before proceeding.

### 2b. Dispatch reviewers (batch, max 3 tasks each)

For each task, dispatch one reviewer:

```
Agent(
  subagent_type: "mas:reviewer:reviewer",
  prompt: """
  ## Task
  {task description}

  ## Acceptance Criteria
  {what done looks like}

  ## Requirement Coverage Check
  Original requirement: {paste verbatim from plan}
  Does this task's implementation address the requirement? Flag any gaps.

  ## Working Directory
  {worktree path}

  ## Output
  Write your report to docs/reports/TASK-{id}-review.md
  Verdict: APPROVED / APPROVED WITH CHANGES / BLOCKED
  """,
  isolation: "worktree"
)
```

> **The requirement coverage check above replaces the reflect agent.** Reviewers check both code quality AND whether the implementation addresses the stated requirement.

### 2c. Handle verdicts

For each reviewer verdict:

| Verdict | Action |
|---------|--------|
| APPROVED | Continue |
| APPROVED WITH CHANGES | Apply the changes directly if minor; dispatch Bug-Fixer if non-trivial |
| BLOCKED | Dispatch Bug-Fixer for P0/P1 issues only (see bug-fix command for constraints) |

**Bug-Fixer dispatch (if needed):**

```
Agent(
  subagent_type: "mas:bug-fixer:bug-fixer",
  prompt: """
  ## Issues to Fix (P0/P1 only)
  {paste P0/P1 issues from review report}

  ## Allowed Files
  {files the engineer touched — bug-fixer may only modify these}

  ## Working Directory
  {worktree path}

  ## Output
  Write result to docs/results/TASK-{id}-bugfix-result.md
  """,
  isolation: "worktree"
)
```

After bug-fixer: re-dispatch reviewer for that task. Max 2 review cycles per task. If still BLOCKED after cycle 2 — escalate to human.

### 2d. Opt-in research (before engineering, for genuinely novel tasks)

If a task requires external API research, library selection, or architectural decisions with real unknowns — dispatch researcher first:

```
Agent(
  subagent_type: "mas:researcher:researcher",
  prompt: """
  ## Task
  {task requiring research}

  ## Question
  {specific unknown — not "research this topic" but "which approach for X given constraints Y"}

  ## Working Directory
  {worktree path}

  ## Output
  Write proposal to docs/plans/TASK-{id}-research.md
  """,
  isolation: "worktree"
)
```

Read the proposal. If the approach is clear, dispatch engineer. If still uncertain, dispatch differential-reviewer. This is opt-in — most tasks do not need it.

**GATE (before Phase 3):**
- [ ] Every TASK has a `docs/results/TASK-{id}-result.md`
- [ ] Every TASK has a `docs/reports/TASK-{id}-review.md`
- [ ] All verdicts are APPROVED or APPROVED WITH CHANGES
- [ ] No unresolved BLOCKED verdicts

---

## Phase 3 — Finish

### 3a. Verify

```
Skill(skill: "verification")
```

Tests pass, lint clean, typecheck clean, no debug artifacts.

**GATE:** `docs/reports/verification-{branch}.md` exists.

### 3b. Present options

```
Skill(skill: "finishing-branch")
```

Present: merge / create PR / keep branch / discard. Wait for human choice.

---

## Pipeline Self-Audit

Before Phase 3, confirm:

- [ ] Engineers dispatched? (`docs/results/TASK-*-result.md` exists for each task)
- [ ] Reviewers dispatched? (`docs/reports/TASK-*-review.md` exists for each task)
- [ ] All verdicts resolved?
- [ ] Verification run?

If any is false — go back and dispatch the missing step. Do NOT proceed with gaps.
