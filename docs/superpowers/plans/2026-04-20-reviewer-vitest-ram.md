# Reviewer Vitest RAM Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop N parallel reviewers from each spawning an independent vitest process; run the build/test suite once before reviewer dispatch and pass the result in.

**Architecture:** Three coordinated markdown edits. The reviewer gains a skip condition (use pre-supplied results, do not re-run). The dispatch templates gain a `## Build Results` field. The dev-loop Phase 2C gains a pre-dispatch build step that fills that field and aborts to Bug-Fixer on failure. No new files. No executable code.

**Tech Stack:** Markdown. Test suite: `bash tests/lint.sh` (static analysis). Baseline: 16 passed, 0 failed.

---

### Task 1: Reviewer — add build-results skip condition

**Files:**
- Modify: `agents/reviewer/CLAUDE.md` (around line 95)

Current Phase B item 1:
```
1. **Build check:** Run `{{lint-command}}` + `{{typecheck-command}}` + `{{test-command}}`

   - **Language diagnostics:** ...
   - **Language-specific anti-pattern checks:** ...
```

- [ ] **Step 1: Read the current file**

```bash
grep -n "Build check" agents/reviewer/CLAUDE.md
```

Expected: one line, around line 95.

- [ ] **Step 2: Replace Phase B item 1 with skip-aware version**

Find this exact text:
```
1. **Build check:** Run `{{lint-command}}` + `{{typecheck-command}}` + `{{test-command}}`
```

Replace with:
```markdown
1. **Build check:** If a `## Build Results` section is present in this prompt, use those results — **do NOT re-run** `{{lint-command}}`, `{{typecheck-command}}`, or `{{test-command}}`. Re-running wastes RAM (parallel reviewers each spawning vitest = OOM) and produces no new information. If `## Build Results` is absent, run `{{lint-command}}` + `{{typecheck-command}}` + `{{test-command}}` and record the results yourself.
```

- [ ] **Step 3: Verify**

```bash
grep -n "do NOT re-run\|Build Results" agents/reviewer/CLAUDE.md
```

Expected: both terms appear.

- [ ] **Step 4: Run lint**

```bash
bash tests/lint.sh 2>&1 | tail -4
```

Expected: `16 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add agents/reviewer/CLAUDE.md
git commit -m "fix: reviewer — skip test re-run when Build Results are pre-supplied"
```

---

### Task 2: Dispatch templates — add Build Results field to reviewer prompts

**Files:**
- Modify: `templates/dispatch-templates.md`

Two locations:
- Template #4 (individual reviewer): add `## Build Results` field before `## Working Directory`
- Template #8 batch reviewer (Step 3): add `## Build Results` field before `## Working Directory`

- [ ] **Step 1: Find the two insertion points**

```bash
grep -n "## Working Directory" templates/dispatch-templates.md
```

Expected: multiple matches. The two we care about are inside the reviewer prompt blocks (template #4 around line 150, and template #8 batch reviewer around line 353).

- [ ] **Step 2: Add Build Results field to template #4**

Find this exact text in template #4 (individual reviewer):
```
  ## Working Directory
  {worktree path}

  ## Output
  Write your review to docs/reports/TASK-{id}-review.md
  Issue verdict: APPROVED / APPROVED WITH CHANGES / BLOCKED
```

Replace with:
```
  ## Build Results (pre-run by dev-loop — do NOT re-run)
  - Lint: {PASS | FAIL}
  - Typecheck: {PASS | FAIL | N/A}
  - Tests: {PASS (N total) | FAIL — paste first failing line}

  ## Working Directory
  {worktree path}

  ## Output
  Write your review to docs/reports/TASK-{id}-review.md
  Issue verdict: APPROVED / APPROVED WITH CHANGES / BLOCKED
```

- [ ] **Step 3: Add Build Results field to template #8 batch reviewer**

Find this exact text in template #8 (batch reviewer, Step 3):
```
  ## Working Directory
  {worktree path}

  ## Output
  Write a separate review for each task:
  - docs/reports/TASK-{id1}-review.md
  - docs/reports/TASK-{id2}-review.md
  - docs/reports/TASK-{id3}-review.md
  Issue verdict per task: APPROVED / APPROVED WITH CHANGES / BLOCKED
```

Replace with:
```
  ## Build Results (pre-run by dev-loop — do NOT re-run)
  - Lint: {PASS | FAIL}
  - Typecheck: {PASS | FAIL | N/A}
  - Tests: {PASS (N total) | FAIL — paste first failing line}

  ## Working Directory
  {worktree path}

  ## Output
  Write a separate review for each task:
  - docs/reports/TASK-{id1}-review.md
  - docs/reports/TASK-{id2}-review.md
  - docs/reports/TASK-{id3}-review.md
  Issue verdict per task: APPROVED / APPROVED WITH CHANGES / BLOCKED
```

- [ ] **Step 4: Verify both insertions**

```bash
grep -n "Build Results.*pre-run" templates/dispatch-templates.md
```

Expected: exactly 2 matches (one for template #4, one for template #8).

- [ ] **Step 5: Run lint**

```bash
bash tests/lint.sh 2>&1 | tail -4
```

Expected: `16 passed, 0 failed`.

- [ ] **Step 6: Commit**

```bash
git add templates/dispatch-templates.md
git commit -m "fix: dispatch templates — add Build Results field to reviewer prompt templates #4 and #8"
```

---

### Task 3: Dev-loop — run build once before reviewer dispatch

**Files:**
- Modify: `commands/dev-loop.md` (Phase 2C, around line 285)

Current Phase 2C text:
```
##### Phase 2C — Batch Reviewer Dispatch

Split completed tasks into groups of TASKS_PER_REVIEWER. Dispatch 1 reviewer per group. Each reviewer receives the tasks from the plan AND engineer results for its group. Dispatch up to MAX_PARALLEL reviewers concurrently.
```

- [ ] **Step 1: Find the insertion point**

```bash
grep -n "Phase 2C\|Batch Reviewer Dispatch" commands/dev-loop.md
```

Expected: the Phase 2C header line.

- [ ] **Step 2: Add build pre-run step at the top of Phase 2C**

Find this exact text:
```
##### Phase 2C — Batch Reviewer Dispatch

Split completed tasks into groups of TASKS_PER_REVIEWER. Dispatch 1 reviewer per group. Each reviewer receives the tasks from the plan AND engineer results for its group. Dispatch up to MAX_PARALLEL reviewers concurrently.
```

Replace with:
```markdown
##### Phase 2C — Batch Reviewer Dispatch

**Build pre-run (run once — do NOT skip):** Before dispatching any reviewer, run the build suite once and capture the result:

```bash
{{lint-command}} && {{typecheck-command}} && {{test-command}}
```

- Record: Lint (PASS/FAIL), Typecheck (PASS/FAIL or N/A), Tests (PASS N total / FAIL + first failing line).
- **If any command fails → do NOT dispatch reviewers.** Route the failing task(s) to Bug-Fixer (template #5) first. Fix the build before reviewing.
- **If all pass → fill in `## Build Results` in every reviewer prompt** (templates #4 and #8). Reviewers will skip re-running the suite.

Split completed tasks into groups of TASKS_PER_REVIEWER. Dispatch 1 reviewer per group. Each reviewer receives the tasks from the plan AND engineer results for its group. Dispatch up to MAX_PARALLEL reviewers concurrently.
```

- [ ] **Step 3: Verify**

```bash
grep -n "Build pre-run\|do NOT dispatch reviewers" commands/dev-loop.md
```

Expected: both terms appear.

- [ ] **Step 4: Run lint**

```bash
bash tests/lint.sh 2>&1 | tail -4
```

Expected: `16 passed, 0 failed` (dev-loop.md line-count warning may appear but is pre-existing).

- [ ] **Step 5: Commit**

```bash
git add commands/dev-loop.md
git commit -m "fix: dev-loop — run build once before reviewer batch dispatch, pass results via Build Results field"
```

---

## Verification

After all three tasks:

```bash
bash tests/lint.sh 2>&1 | tail -4
grep -n "do NOT re-run\|Build Results" agents/reviewer/CLAUDE.md
grep -n "Build Results.*pre-run" templates/dispatch-templates.md
grep -n "Build pre-run\|do NOT dispatch reviewers" commands/dev-loop.md
```

All four commands must return hits. Lint must show `16 passed, 0 failed`.
