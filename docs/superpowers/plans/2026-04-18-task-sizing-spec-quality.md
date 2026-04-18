# Task Sizing + Precise Spec + Bug-Fixer Scope Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add task sizing (micro/standard/complex), precise spec fields (success_test, contract), and bug-fixer scope constraints to reduce BLOCKED rate and cut unnecessary dispatches by 40-60%.

**Architecture:** Four independent text edits to markdown files — task-spec template, dev-loop routing, bug-fixer agent, and validate-dispatch hook. All changes are structural enforcement (explicit fields + blocking rules), not prose guidance.

**Tech Stack:** Bash (tests/lint.sh), Markdown

---

## File Map

| File | Change |
|------|--------|
| `templates/task-spec.md` | Add `size`, `success_test`, `contract` fields; clarify `relevant_files` requires line ranges |
| `templates/dispatch-templates.md` | Update template #5 (bug-fixer) with scope constraints |
| `agents/bug-fixer/CLAUDE.md` | Add P0/P1-only scope, file allowlist, min-change, 5-read guard |
| `commands/dev-loop.md` | Add size-based pipeline variants to routing table |
| `commands/bootstrap.md` | Block `general` in validate-dispatch.sh template (~line 351) |
| `.claude/hooks/validate-dispatch.sh` | Block `general` in live repo hook |

All 4 tasks touch different files — **all parallel-safe**.

---

### Task 1: task-spec.md — Add size + precise spec fields

**size:** micro
**Files:** Modify `templates/task-spec.md:1-44`
**do_not_touch:** all other files
**success_test:** `grep -n "size:.*micro.*standard.*complex" templates/task-spec.md` → exits 0
**contract:** Add three new fields to the Meta and Context sections of the task spec template

- [ ] **Step 1: Write the failing verification**

```bash
grep -n "size:.*micro.*standard.*complex" templates/task-spec.md
# Expected: no output (field doesn't exist yet)
grep -n "success_test:" templates/task-spec.md
# Expected: no output
grep -n "contract:" templates/task-spec.md
# Expected: no output
```

- [ ] **Step 2: Replace templates/task-spec.md with the new version**

```markdown
# TASK-{id}: {title}

## Meta
- **id:** TASK-{id}
- **size:** micro | standard | complex
  - `micro` — 1 file, ≤20 lines, no new API surface → quick review, skip reflect + delivery report
  - `standard` — multi-file, known pattern → full pipeline
  - `complex` — novel algorithm, new boundary, competing trade-offs → researcher → deep review + reflect
- **type:** research | design | impl | review | bugfix
- **agent:** engineer | reviewer | researcher | differential-reviewer | bug-fixer | ui-ux-designer
- **status:** pending | in-progress | done | blocked
- **depends_on:** [TASK-xxx, ...]
- **parallel_safe:** true | false
- **priority:** P0 | P1 | P2

## Context
- **relevant_files:** [exact file paths WITH line ranges — e.g., `src/auth.ts:45-80`, `lib/utils.py:12-35`]
- **do_not_touch:** [adjacent files that MUST NOT be modified — be explicit]
- **reference_files:** [files to read for context only, not modify]
- **proposal:** [path to approved research proposal in `docs/plans/`, if applicable]
- **design_spec:** [path to approved design spec in `docs/design/`, if applicable — only for UI tasks]
- **success_test:** `{exact test command}` — assert `{specific value}` at `{file:line}`
  - Example: `pytest tests/auth_test.py::test_rate_limit_returns_429 -v` — assert response.status_code == 429
- **contract:** `{exact function/API signature}` → `{return type}` raises `{error types}`
  - Example: `def validate_token(token: str, secret: str) -> TokenPayload` raises `InvalidTokenError`

## Objective

{One paragraph max. What should be built/fixed/researched and why.}

## Acceptance Criteria

Each criterion MUST be a runnable shell command:

- [ ] `{{test-command}}` passes
- [ ] `{{lint-command}}` clean
- [ ] `{{typecheck-command}}` clean
- [ ] `{specific functional check}` — e.g., `curl localhost:8080/api/health | jq .status`

## Business Context

{Link to original requirement, OKR, issue, or user story. Why does this matter?}

## Output

Write result based on task type:
- **research** → `docs/plans/TASK-{id}-research-r{round}.md`
- **design** → `docs/design/TASK-{id}-design.md` + `docs/design/TASK-{id}-mockup.html`
- **impl** → `docs/results/TASK-{id}-result.md`
- **review** → `docs/reports/TASK-{id}-review.md`
- **bugfix** → `docs/reports/TASK-{id}-bugfix-result.md`
```

- [ ] **Step 3: Verify**

```bash
grep -n "size:.*micro.*standard.*complex" templates/task-spec.md
grep -n "success_test:" templates/task-spec.md
grep -n "contract:" templates/task-spec.md
grep -n "line ranges" templates/task-spec.md
bash tests/lint.sh 2>&1 | tail -5
# Expected: STATUS: PASS
```

- [ ] **Step 4: Commit**

```bash
git add templates/task-spec.md
git commit -m "feat: task-spec — add size, success_test, contract fields for precise dispatch"
```

---

### Task 2: dev-loop.md — Size-based pipeline routing

**size:** micro
**Files:** Modify `commands/dev-loop.md`
**do_not_touch:** all other files
**success_test:** `grep -n "Task Size.*Pipeline\|micro.*quick review" commands/dev-loop.md` → exits 0
**contract:** Add size routing table after `| Refactor / cleanup | Engineer directly |` line, before `**Novel task criteria**`

- [ ] **Step 1: Write the failing verification**

```bash
grep -n "Task Size.*Pipeline\|micro.*quick review" commands/dev-loop.md
# Expected: no output
```

- [ ] **Step 2: Find insertion point**

```bash
grep -n "Refactor / cleanup\|Novel task criteria" commands/dev-loop.md
# Note line numbers — insert BETWEEN these two lines
```

- [ ] **Step 3: Insert size routing table into commands/dev-loop.md**

After the line `| Refactor / cleanup | Engineer directly |`, insert:

```markdown

**Task Size → Pipeline Variant:**

Every task in the plan has a `size` field. Use it to select the pipeline variant before dispatching:

| Size | Pipeline | Skipped Steps |
|------|----------|---------------|
| `micro` | Engineer → quick review | No researcher. Reviewer `depth: quick`. Skip reflect (`echo "micro task" > docs/reports/.reflect-skipped`). Skip delivery report. |
| `standard` | Full pipeline | Nothing skipped. |
| `complex` | Researcher → Differential Reviewer → Engineer → deep review → reflect | Nothing skipped. Reviewer `depth: deep`. |

**Applying size:**
- Read each task's `size` field before dispatch. If absent, treat as `standard`.
- `micro` quick-review: set `depth: quick` in the reviewer prompt, model can be `haiku`.
- `complex`: always run Research Convergence Protocol (template #7) regardless of routing table.

```

- [ ] **Step 4: Verify**

```bash
grep -n "Task Size\|micro.*quick review\|skip reflect" commands/dev-loop.md | head -5
bash tests/lint.sh 2>&1 | tail -5
# Expected: STATUS: PASS
```

- [ ] **Step 5: Commit**

```bash
git add commands/dev-loop.md
git commit -m "feat: dev-loop — add size-based pipeline routing (micro/standard/complex)"
```

---

### Task 3: Bug-fixer scope constraints

**size:** micro
**Files:** Modify `agents/bug-fixer/CLAUDE.md`, Modify `templates/dispatch-templates.md:162-185`
**do_not_touch:** all other files
**success_test:** `grep -n "P0.*P1 only\|Minimum-change\|Allowed files" agents/bug-fixer/CLAUDE.md` → exits 0
**contract:** Add 4 bullet constraints to Non-negotiables in bug-fixer CLAUDE.md; replace dispatch template #5 body with scope-constrained version

- [ ] **Step 1: Write the failing verification**

```bash
grep -n "P0.*P1\|Minimum-change\|Allowed files\|Analysis Paralysis" agents/bug-fixer/CLAUDE.md
# Expected: no output

grep -n "Scope Constraints\|Allowed files\|lines-before" templates/dispatch-templates.md
# Expected: no output
```

- [ ] **Step 2: Edit agents/bug-fixer/CLAUDE.md — add to Non-negotiables**

After the line `- Run full test suite after each fix`, add these 4 lines:

```markdown
- Fix ONLY P0/P1 issues from the review report — P2/P3 are non-blocking, handled separately
- **File scope:** ONLY touch files listed in the dispatch's `allowed_files` list — treat everything else as `do_not_touch`
- **Minimum-change:** Fix the minimum lines necessary. Document "lines changed: N before → M after" in result.
- **Analysis Paralysis Guard:** After 5 Read/Grep/Glob calls without writing any file, stop reading. You already have the reviewer's file:line pointer — you need less context than an engineer, not more. Make the fix or document a specific blocker.
```

- [ ] **Step 3: Replace dispatch template #5 in templates/dispatch-templates.md**

Replace the block from `## 5. Bug-Fixer Dispatch` through the closing triple-backtick with:

````markdown
## 5. Bug-Fixer Dispatch

```
Agent(
  subagent_type: "mas:bug-fixer:bug-fixer",
  prompt: """
  ## Scope Constraints (read before anything else)
  - Fix ONLY the P0/P1 issues listed below. Ignore P2/P3.
  - Allowed files (ONLY touch these): {paste relevant_files from the BLOCKED task}
  - Do NOT touch: {paste do_not_touch from the original task}
  - Minimum-change: fix the minimum lines necessary. Note lines-before/lines-after in result.

  ## Reviewer Report — P0/P1 Issues Only
  {paste ONLY the P0 and P1 sections from docs/reports/TASK-{id}-review.md — strip P2/P3}

  ## Task
  {paste the task from the plan}

  ## Skills
  - `Skill(skill: "superpowers:test-driven-development")` — reproduction test FIRST, then minimal fix
  - `Skill(skill: "superpowers:systematic-debugging")` — if root cause unclear after reproduction test

  ## Working Directory
  {worktree path}

  ## Output
  Write your result to docs/reports/TASK-{id}-bugfix-result.md
  Include "Lines changed: N before → M after" in the Build Status section.
  """
)
```
````

- [ ] **Step 4: Verify**

```bash
grep -n "Minimum-change\|Allowed files\|Analysis Paralysis\|P0.*P1 only" agents/bug-fixer/CLAUDE.md | head -5
grep -n "Scope Constraints\|Allowed files\|lines-before\|lines-after" templates/dispatch-templates.md | head -5
bash tests/lint.sh 2>&1 | tail -5
# Expected: STATUS: PASS
```

- [ ] **Step 5: Commit**

```bash
git add agents/bug-fixer/CLAUDE.md templates/dispatch-templates.md
git commit -m "feat: bug-fixer — P0/P1-only scope, file allowlist, min-change constraint, read guard"
```

---

### Task 4: Block `general` agent in validate-dispatch.sh

**size:** micro
**Files:** Modify `.claude/hooks/validate-dispatch.sh`, Modify `commands/bootstrap.md` (~line 357)
**do_not_touch:** all other files
**success_test:** `grep -n "general.*is not a valid" .claude/hooks/validate-dispatch.sh` → exits 0
**contract:** Add `general` block after the orchestrator deprecation block in both files

- [ ] **Step 1: Write the failing verification**

```bash
grep -n "general.*is not a valid\|BLOCKED.*general" .claude/hooks/validate-dispatch.sh
# Expected: no output
grep -n "general.*is not a valid\|BLOCKED.*general" commands/bootstrap.md
# Expected: no output
```

- [ ] **Step 2: Find insertion point in both files**

```bash
grep -n "mas:orchestrator:orchestrator\|BLOCKED.*orchestrator" .claude/hooks/validate-dispatch.sh
grep -n "mas:orchestrator:orchestrator\|BLOCKED.*orchestrator" commands/bootstrap.md
# Note: insert the new block AFTER the closing `fi` of the orchestrator check in each file
```

- [ ] **Step 3: Edit .claude/hooks/validate-dispatch.sh**

After the orchestrator deprecation block's closing `fi`, add:

```bash
# Block general agent — use Explore (haiku) for discovery or a MAS specialist instead
if [ "$SUBAGENT_TYPE" = "general" ]; then
  _debug "BLOCKED general agent"
  cat <<'BLOCKED_MSG'
BLOCKED: 'general' is not a valid dispatch in the MAS pipeline.

Use a specific agent instead:
  Discovery / codebase search:  Agent(subagent_type: "Explore", model: "haiku")
  Implementation:                Agent(subagent_type: "mas:engineer:engineer")
  Code review:                   Agent(subagent_type: "mas:reviewer:reviewer")
  Research:                      Agent(subagent_type: "mas:researcher:researcher")
  Bug fix:                       Agent(subagent_type: "mas:bug-fixer:bug-fixer")
BLOCKED_MSG
  exit 2
fi
```

- [ ] **Step 4: Edit commands/bootstrap.md — same block in validate-dispatch.sh template**

Find the same location in bootstrap.md (the validate-dispatch.sh template section) and add the identical block after the orchestrator deprecation `fi`.

- [ ] **Step 5: Verify**

```bash
grep -n "general.*is not a valid" .claude/hooks/validate-dispatch.sh
grep -n "general.*is not a valid" commands/bootstrap.md
bash tests/lint.sh 2>&1 | tail -5
# Expected: STATUS: PASS
```

- [ ] **Step 6: Commit**

```bash
git add .claude/hooks/validate-dispatch.sh commands/bootstrap.md
git commit -m "feat: validate-dispatch — block general agent, suggest Explore or MAS specialist"
```
