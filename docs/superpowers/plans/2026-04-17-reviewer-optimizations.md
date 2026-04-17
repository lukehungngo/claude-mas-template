# Reviewer Optimizations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement three backtested reviewer optimizations: diff classification prepass, conditional skill gates, and change_class auto-depth hints from orchestrator.

**Architecture:** Two files change independently. `agents/reviewer/CLAUDE.md` gets a Phase 0 section (diff classification) and conditional guards on skill invocations. `templates/dispatch-templates.md` gets a `change_class` field in reviewer dispatch templates (#4 and #8) with an auto-depth mapping table.

**Tech Stack:** Markdown edits only. Test suite: `bash tests/lint.sh` (static analysis). No runnable code.

**Baseline note:** The baseline `tests/lint.sh` has 3 pre-existing failures (bootstrap.md echo false positive, language-stack `{{test-command}}` placeholders, conceptual "orchestrator" word in engineer agent). Do NOT fix these — they are out of scope. Verify our changes do not introduce new failures beyond the pre-existing 3.

---

### Task 1: Add diff classification prepass + conditional skill gates to reviewer

**Files:**
- Modify: `agents/reviewer/CLAUDE.md`

This task adds two things:
1. A **Phase 0** section (change classification) that runs before Phase A/B. The reviewer greps `git diff --stat` to classify the change, then maps classification to depth and skip list.
2. **Conditional guards** on the three skill invocations in Phase B (se-principles, reliability-review, property-based-testing).

- [ ] **Step 1: Read the current file**

```bash
cat agents/reviewer/CLAUDE.md
```

- [ ] **Step 2: Add Phase 0 section**

Insert the following new section between the "## Dispatch Contract" section (ends at line ~28) and the "## Persona" section.

Add after the line `If depth is not specified, treat as \`standard\`.`:

```markdown

---

## Phase 0 — Change Classification (run before Phase A and Phase B)

Before reading any files or running builds, classify the diff to eliminate wasted work.

```bash
git diff --stat HEAD~1 HEAD
```

Apply this table. Use the **first row that matches**:

| Classification | Match criteria | Effect |
|---|---|---|
| `docs` | All changed files are `.md`, `.txt`, README, CHANGELOG, or docs/ | Skip Phase B entirely. Phase A only. depth → quick. |
| `config` | Only JSON, YAML, TOML, `.env`, manifest, or lock files changed | depth → quick |
| `test-only` | Only test files changed (test_*.py, *.test.ts, *_test.go, spec/, __tests__/) | Skip Phase A+B. Verify test quality (correctness, coverage of edge cases) only. |
| `refactor` | No new public APIs, no new external calls, no new files — moves/renames/restructures only | Skip `reliability-review` and security checks in Phase B |
| `bugfix` | Targeted fix ≤ 3 files, no new architecture | Skip architecture invariant check. Skip `property-based-testing` unless diff contains `for`, `while`, loop, or algorithm keywords. |
| `feature` | New capabilities, new APIs, or new files | Full Phase B |

If classification is unclear or `change_class` was provided by the dispatcher, use the dispatcher's value. If no classification applies cleanly, treat as `feature`.

If `change_class` was specified in the dispatch prompt, map it to depth using this table and skip the git stat grep:

| change_class | depth |
|---|---|
| docs | quick |
| config | quick |
| test | quick |
| bugfix | standard |
| refactor | standard |
| feature | standard |
| p0-fix | deep |
```

- [ ] **Step 3: Add conditional guards to skill invocations in Phase B**

Find the Phase B section. Locate items 4, 5, and 7 which contain skill invocations. Replace them with the conditional versions below.

Replace item 4 (design quality):
```markdown
4. **Design quality** *(skip for `docs`, `config`, `test-only`, `bugfix`; also skip if change is a single-function fix ≤ 20 lines)*: Check against SE principles:
   ```
   Skill(skill: "se-principles")
   ```
```

Replace item 5 (reliability & performance):
```markdown
5. **Reliability & performance** *(skip for `docs`, `config`, `test-only`, `refactor`; for other types, only invoke if diff touches any of: auth, token, password, session, database, db, query, SELECT, INSERT, UPDATE, http, fetch, request, socket, file system, upload, open(), read(), write(), user input)*: Check error handling, concurrency, N+1, security, timeouts:
   ```
   Skill(skill: "reliability-review")
   ```
```

Replace item 7 (test coverage / property-based testing):
```markdown
7. **Test coverage:** Every new function/method has a test? Edge cases covered? Flag when property-based tests are needed *(skip `property-based-testing` skill for `bugfix`, `refactor`, `docs`, `config`; only invoke for `feature` or when diff contains parsing, serialization, loops, recursive functions, or large input space operations)*:
   ```
   Skill(skill: "property-based-testing")
   ```
```

- [ ] **Step 4: Verify file is well-formed**

```bash
head -50 agents/reviewer/CLAUDE.md
grep -n "Phase 0\|Phase A\|Phase B" agents/reviewer/CLAUDE.md
grep -n "se-principles\|reliability-review\|property-based-testing" agents/reviewer/CLAUDE.md
```

Expected: Phase 0 appears before Phase A, all 3 skill names still present with conditional notes.

- [ ] **Step 5: Run lint and verify no new failures**

```bash
bash tests/lint.sh 2>&1
```

Expected: Same 3 pre-existing failures (bootstrap echo, language-stack placeholders, engineer orchestrator reference). No new failures introduced.

- [ ] **Step 6: Commit**

```bash
git add agents/reviewer/CLAUDE.md
git commit -m "feat: add diff classification prepass and conditional skill gates to reviewer"
```

---

### Task 2: Add change_class auto-depth hints to dispatch templates

**Files:**
- Modify: `templates/dispatch-templates.md`

This task adds `change_class` field to reviewer dispatch templates #4 (single reviewer) and #8 (batch reviewer), along with a dispatch guidance note so orchestrators know what values to pass.

- [ ] **Step 1: Read the current file**

```bash
grep -n "depth: standard\|change_class\|## 4. Reviewer\|## 8. Batch" templates/dispatch-templates.md
```

- [ ] **Step 2: Update template #4 (single Reviewer Dispatch)**

Find template #4 which starts with `## 4. Reviewer Dispatch`. The template currently starts with `depth: standard`. Replace the opening of the template body with:

Replace:
```
  depth: standard

  ## Task
```

With:
```
  depth: {standard | quick | deep — or omit and let reviewer auto-classify from change_class}
  change_class: {feature | bugfix | refactor | config | test | docs | p0-fix}

  ## Task
```

Also add a dispatch guidance note immediately before the template code block (after the ` ``` ` opening line of the template header):

Add before the `Agent(` line:
```markdown
**Dispatcher guidance:** Set `change_class` based on the task type. The reviewer maps it to depth automatically:
- `docs` / `config` / `test` → quick (Phase B skipped or minimal)
- `bugfix` / `refactor` / `feature` → standard
- `p0-fix` → deep

If you know the exact depth needed, set `depth` explicitly — it overrides `change_class`.
```

- [ ] **Step 3: Update template #8 (Batch Reviewer Dispatch)**

Find template #8's batch review dispatch section (Step 3 — Batch Review Dispatch). It contains a reviewer prompt starting with `depth: standard`. Apply the same replacement:

Replace in the batch template:
```
  depth: standard

  ## Tasks to Review
```

With:
```
  depth: {standard | quick | deep — or omit and let reviewer auto-classify from change_class}
  change_class: {feature | bugfix | refactor | config | test | docs | p0-fix}
  change_class_per_task: {if tasks in the batch have different types, specify per task id, e.g. "TASK-01: docs, TASK-02: feature"}

  ## Tasks to Review
```

- [ ] **Step 4: Verify templates still parseable and complete**

```bash
grep -n "depth:\|change_class" templates/dispatch-templates.md
grep -c "mas:reviewer:reviewer" templates/dispatch-templates.md
```

Expected: `depth:` appears in both templates, `change_class` appears in both, `mas:reviewer:reviewer` count unchanged (still 2+ occurrences from templates #4 and #8).

- [ ] **Step 5: Run lint and verify no new failures**

```bash
bash tests/lint.sh 2>&1
```

Expected: Same 3 pre-existing failures only.

- [ ] **Step 6: Commit**

```bash
git add templates/dispatch-templates.md
git commit -m "feat: add change_class auto-depth hints to reviewer dispatch templates"
```

---

## Verification

After both tasks complete:

```bash
bash tests/lint.sh 2>&1
grep -n "Phase 0" agents/reviewer/CLAUDE.md
grep -n "change_class" templates/dispatch-templates.md agents/reviewer/CLAUDE.md
```

Expected:
- lint: same 3 pre-existing failures, no new ones
- Phase 0 present in reviewer
- change_class present in both dispatch templates
