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

For each task, dispatch one engineer. **Default to Sonnet** — Opus is rarely necessary for engineering work and is 5× more expensive.

```
Agent(
  subagent_type: "mas:engineer:engineer",
  model: "sonnet",
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

  ## File Operations
  Use Read, Edit, Write, Grep, Glob for file work. Do NOT use Bash for `cat`, `sed`, `awk`, `head`, `tail` — Bash is for git, build, test, and shell-only operations.

  ## Output
  1. Write your result to docs/results/TASK-{id}-result.md (audit trail).
  2. Return a ≤200-word summary as your final message — the orchestrator passes it directly to the reviewer to avoid redundant reads.
  """
)
```

Already inside a worktree from Phase 1a — do NOT pass `isolation: "worktree"` to subagents (double-isolates).

Wait for ALL engineers in the batch to finish before dispatching reviewers. Capture each engineer's returned summary; if the result file is missing after the engineer returns, that dispatch failed — re-dispatch before proceeding.

### 2b. Dispatch reviewers (batch, max 3 tasks each)

For each task, dispatch one reviewer. **Default to Sonnet** — reviewers don't need Opus depth.

```
Agent(
  subagent_type: "mas:reviewer:reviewer",
  model: "sonnet",
  prompt: """
  ## Task
  {task description}

  ## Acceptance Criteria
  {what done looks like}

  ## Engineer Summary
  {paste engineer's returned summary verbatim — do NOT make the reviewer re-read the result file}

  ## Requirement Coverage Check
  Original requirement: {paste verbatim from plan}
  Does this task's implementation address the requirement? Flag any gaps.

  ## Working Directory
  {worktree path}

  ## Output
  1. Write your report to docs/reports/TASK-{id}-review.md (audit trail).
  2. Return verdict + headline findings (≤150 words) as your final message.
  Verdict: APPROVED / APPROVED WITH CHANGES / BLOCKED
  """
)
```

Do NOT pass `isolation: "worktree"` — already inside a worktree from Phase 1a.

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
  model: "sonnet",
  prompt: """
  ## Issues to Fix (P0/P1 only)
  {paste P0/P1 issues from review report}

  ## Allowed Files
  {files the engineer touched — bug-fixer may only modify these}

  ## Working Directory
  {worktree path}

  ## File Operations
  Use Read, Edit, Write — NOT Bash `cat`/`sed`/`awk` for file mutation.

  ## Output
  1. Write result to docs/results/TASK-{id}-bugfix-result.md (audit trail).
  2. Return a ≤150-word summary of what changed and why.
  """
)
```

Do NOT pass `isolation: "worktree"` — already inside a worktree from Phase 1a.

After bug-fixer: re-dispatch reviewer for that task. Max 2 review cycles per task. If still BLOCKED after cycle 2 — escalate to human.

### 2c-bis. Cost / time gate (mandatory check between batches)

Before dispatching the next batch of engineers or reviewers, verify:

- [ ] Wall-clock since plan approval < 4h, AND
- [ ] Cumulative Opus messages across all dispatches < 200, AND
- [ ] No single task has hit BLOCKED twice

If any condition fails — STOP and ask the user before continuing. Long autonomous runs on Opus are the dominant cost-leak observed in real usage. A 4h gate prevents 6-day runaway sessions.

> If the parent session is on Opus and most subagents are also Opus, every dispatch multiplies cost. Subagent model defaults above (Sonnet) prevent this — verify the dispatches you actually issued specify `model: "sonnet"`.

### 2d. Opt-in research (before engineering, for genuinely novel tasks)

If a task requires external API research, library selection, or architectural decisions with real unknowns — dispatch researcher first. Research benefits from deeper reasoning, so Opus is reasonable here (but Sonnet is usually sufficient).

```
Agent(
  subagent_type: "mas:researcher:researcher",
  model: "sonnet",
  prompt: """
  ## Task
  {task requiring research}

  ## Question
  {specific unknown — not "research this topic" but "which approach for X given constraints Y"}

  ## Working Directory
  {worktree path}

  ## Output
  1. Write proposal to docs/plans/TASK-{id}-research.md.
  2. Return a ≤200-word summary of the recommended approach + key trade-offs.
  """
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
