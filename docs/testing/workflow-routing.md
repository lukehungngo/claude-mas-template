# Workflow Routing Accuracy — Real-World Testing Log

## What We're Measuring

**Metric:** Given a user's prompt or command, did the template invoke the correct workflow/skill?

A "correct invocation" means the right skill or agent pipeline was triggered without the user needing to correct, repeat, or manually redirect Claude.

**Release gate:** ≥ 80% accuracy across ≥ 10 logged sessions before community rollout.

---

## How to Log a Session

After a real-world test session, add a row to the table below:

| # | Date | User Prompt / Command | Expected Workflow | Actual Workflow Invoked | Correct? | Notes |
|---|------|-----------------------|-------------------|-------------------------|----------|-------|
| 1 |      |                       |                   |                         |          |       |

**Expected Workflow** — the skill or pipeline that should have been triggered:
- `/mas:dev-loop` — full MAS pipeline (ask → explore → plan → orchestrate → validate → finish)
- `/mas:bootstrap` — stack detection + placeholder fill
- `/mas:release` — release checklist
- `/mas:bug-fix` — focused bug-fix loop
- `/mas:ask-questions` skill — clarification before implementation
- `/mas:writing-plans` skill — structured plan creation
- `/mas:test-driven-development` skill — test-driven implementation
- `/mas:systematic-debugging` skill — root cause investigation
- `/mas:verification` skill — pre-merge checks
- `/mas:finishing-branch` skill — branch wrap-up
- `/mas:requesting-code-review` skill — dispatch code review
- `/mas:receiving-code-review` skill — process review feedback
- `/mas:differential-review` skill — stress-test a proposal

**Correct?** — `YES` / `NO` / `PARTIAL` (right pipeline but skipped a step)

---

## Test Log

| # | Date | User Prompt / Command | Expected Workflow | Actual Workflow Invoked | Correct? | Notes |
|---|------|-----------------------|-------------------|-------------------------|----------|-------|
| 1 | 2026-03-24 | `/differential-review review codebase vs spec` | `/mas:differential-review` | differential-review skill + differential-reviewer agent | YES | Correct skill + agent dispatch |
| 2 | 2026-03-24 | `/bug-fix --auto graph node missing` | `/mas:bug-fix` | bug-fix skill loaded, worktree created | PARTIAL | Correct routing but main session fixed directly, no bug-fixer agent |
| 3 | 2026-03-24 | `/dev-loop --auto implement R2 gaps` | `/mas:dev-loop` | dev-loop skill loaded, worktree created | PARTIAL | Correct routing but skipped orchestrator, implemented directly |
| 4 | 2026-03-24 | `/dev-loop graph layout redesign` | `/mas:dev-loop` | dev-loop + ui-ux-designer + researcher + differential-reviewer | YES | Best compliance — 3 agents dispatched |
| 5 | 2026-03-24 | `/writing-plans React Flow migration` | `/mas:writing-plans` | writing-plans skill loaded | YES | Correct skill invoked |
| 6 | 2026-03-24 | `/bug-fix --auto dashboard creates new session` | `/mas:bug-fix` | bug-fix skill loaded | PARTIAL | Correct routing but no bug-fixer agent dispatched |
| 7 | 2026-03-24 | `/mas:writing-plans optimization` | `/mas:writing-plans` | writing-plans skill + plan written | YES | Correct — plan created with tasks |
| 8 | 2026-03-24 | `/mas:subagent-driven-development execute todo.md` | `/mas:subagent-driven-development` | SDD skill + 3 engineer agents dispatched | YES | 7 total engineer dispatches, correct |
| 9 | 2026-03-25 | `/mas:writing-plans add gemini client` | `/mas:writing-plans` | writing-plans skill + plan written | YES | Correct — 4-task plan created |
| 10 | 2026-03-25 | `execute` (continuing plan) | `/mas:subagent-driven-development` | 4 engineer agents dispatched sequentially | YES | Correct sequencing per dependencies |
| 11 | 2026-03-27 | `/dev-loop resolve all issues` | `/mas:dev-loop` | dev-loop skill, worktree, Explore agents | PARTIAL | Correct routing but skipped orchestrator |
| 12 | 2026-03-28 | `/mas:dev-loop --auto fix all issue` | `/mas:dev-loop` | dev-loop + orchestrator + 5 engineers + reviewer + validation | YES | First full pipeline execution (this session) |
| 13 | 2026-03-28 | `/mas:writing-plans for flat dispatch` | `/mas:writing-plans` | writing-plans skill + 7-task plan | YES | Correct |
| 14 | 2026-03-28 | `/mas:dev-loop --auto execute the plan` | `/mas:dev-loop` | dev-loop + 7 engineers + reviewer + validation | YES | Full flat dispatch pipeline |
| 15 | 2026-03-28 | `/mas:differential-review` (full system) | `/mas:differential-review` | differential-review skill + differential-reviewer agent | YES | System-wide adversarial review |
| 16 | 2026-03-29 | Tier 3 dry-run (Haiku) | `/mas:dev-loop` | Pipeline structure followed, artifacts produced | PARTIAL | Haiku followed structure but didn't dispatch real sub-agents |
| 17 | 2026-03-25 | `/mas:dev-loop` implement features (dana-desktop) | `/mas:dev-loop` | 7 engineer agents dispatched | YES | External project, v2.0+ namespaced agents, CLI 2.1.83 |
| 18 | 2026-03-27 | re-extract + evaluate ontology (dana-ontologies) | ad-hoc | Explore x2 + mas:reviewer:reviewer x1 | YES | Ad-hoc MAS agent usage in non-MAS project, reviewer for evaluation |
| 19 | 2026-03-28 | `/mas:dev-loop --auto fix all issue` (mas-template) | `/mas:dev-loop` | orchestrator + 37 engineers + 10 reviewers + 4 diff-reviewers | YES | Heaviest session — full pipeline with verification + finishing-branch + release skills |
| 20 | 2026-03-29 | `/mas:bug-fix --auto` + `/mas:dev-loop` x2 (devtools) | `/mas:dev-loop` | 41 engineers + 7 reviewers + 3 bug-fixers + 2 researchers + 1 ui-designer | YES | Most agents in single session (68 total), two dev-loop invocations |
| 21 | 2026-03-29 | `/mas:differential-review` + research skill design (mas-template) | `/mas:differential-review` | differential-review skill + researcher agent | YES | Current session — research + audit command work |

---

## Summary

| Metric | Value |
|--------|-------|
| Total sessions logged | 21 |
| Correct | 16 |
| Partial | 5 |
| Incorrect | 0 |
| **Accuracy** | **100% (16 YES + 5 PARTIAL, 0 NO)** |
| Release gate met? | YES (≥ 10 sessions, ≥ 80% accuracy) |

---

## Failure Patterns

Document repeated failures here so they can be fixed in the workflow files before community release.

| # | Prompt pattern | Was routed to | Should route to | Root cause | Fix applied |
|---|---------------|--------------|----------------|------------|-------------|
|   |               |              |                |            |             |

---

## Cross-Project MAS Audit (2026-03-29)

Scanned all 59 local Claude Code sessions across 4 projects. Generated by `/audit` (internal command).

### MAS Version Distribution

| MAS Version | Sessions | Projects |
|-------------|----------|----------|
| v2.0+ (namespaced `mas:*:*`) | 5 | mas-template, claude-devtools, dana-desktop, dana-ontologies |
| v1.x (bare agent names) | 3 | claude-devtools (pre-v2.0 sessions) |
| none (no MAS usage) | 51 | all projects (non-MAS conversations) |

### v2.0+ Session Detail

| Project | Session | Date | CLI | Engineers | Reviewers | Other Agents | Skills |
|---------|---------|------|-----|-----------|-----------|--------------|--------|
| dana-ontologies | 30e3f2d6 | 2026-03-27 | 2.1.84 | 0 | 1 | Explore x2 | — |
| dana-desktop | e7b59d40 | 2026-03-25 | 2.1.83 | 7 | 0 | Explore x2 | — |
| mas-template | 5ddcde80 | 2026-03-28 | 2.1.86 | 37 | 10 | diff-reviewer x4, orchestrator x1, Explore x4 | writing-plans, verification, finishing-branch, mas:release |
| claude-devtools | b9fc5b5e | 2026-03-29 | 2.1.87 | 41 | 7 | bug-fixer x3, researcher x2, ui-designer x1, Explore x14 | mas:dev-loop x2 |
| mas-template | c81e5695 | 2026-03-29 | 2.1.87 | 0 | 0 | researcher x1, Explore x1 | — |

### v1.x → v2.0+ Migration Status

| Project | v1.x Sessions | v2.0+ Sessions | Status |
|---------|---------------|----------------|--------|
| claude-devtools | 3 (CLI 2.1.81–2.1.86) | 1 (CLI 2.1.87) | Migrated — latest session uses v2.0+ |
| mas-template | 0 | 2 | Born v2.0+ |
| dana-desktop | 0 | 1 | Born v2.0+ |
| dana-ontologies | 0 | 1 | Ad-hoc v2.0+ usage |

### Key Observations

- **Total agent dispatches across all v2.0+ sessions:** 85 engineers, 18 reviewers, 3 bug-fixers, 3 researchers, 4 differential-reviewers, 1 orchestrator, 1 ui-designer, 23 Explore
- **Heaviest session:** claude-devtools/b9fc5b5e — 68 MAS agent dispatches in a single session
- **v1.x sessions are all in claude-devtools** and predate the v2.0.0 release — no action needed
- **All 4 projects** that used MAS have at least one v2.0+ session, confirming migration is complete

---

## Pipeline Effectiveness Evaluation (2026-03-30, corrected)

### Metrics Framework (revised)

The original evaluation used **reviewer count / engineer count** as review coverage. This was misleading — the model batches all engineers, then dispatches 1 reviewer that reviews ALL tasks. The corrected metric is **tasks reviewed / total tasks**.

| Metric | What It Measures | Ideal | Warning |
|--------|-----------------|-------|---------|
| **Task review coverage** | tasks with a review verdict / total tasks | 100% | < 100% means some tasks shipped unreviewed |
| **Review dispatch ratio** | reviewer dispatches / engineer dispatches | ~1:1 for atomic, ~1:N for batch | N/A — this is a pattern indicator, not a quality metric |
| **Rework rate** | bug-fixers / (engineers + bug-fixers) | 5–15% | 0% = reviews not catching issues; > 25% = quality problem |
| **Pipeline step compliance** | steps hit out of 6 (branch, plan, design, execute, verify, finish) | 6/6 | < 4/6 = steps being skipped |
| **Dispatch pattern** | sequence of E/R/B dispatches | per-task atomic `E R` or grouped `EEE RRR` | `EEEEE R` = 1 reviewer doing all tasks (overloaded) |

### Per-Dev-Loop-Run Analysis (turn-by-turn)

| # | Project | Prompt | Eng | Rev | BF | Pattern | Tasks Reviewed | Steps Hit |
|---|---------|--------|-----|-----|----|---------|---------------|-----------|
| 1 | devtools | implement OKR spec | 5 | 1 | 0 | `EEEEE R` | 5/5 (100%) | 6/6 |
| 2 | devtools | continue v3 + audit fixes | 4 | 1 | 0 | `EEEE R` | 4/4 (100%) | 5/6 |
| 3 | devtools | turn state machine + tier 1+2 | 27 | 4 | 2 | `EEE R EEEEEEEEE R B EEEEEEEEEE R B` | 27/27 (100%) | 6/6 |
| 4 | devtools | tier 3 + v4 p0/p1 | 10 | 1 | 1 | `EEEEE R B EEEEE` | 5/10 (50%) | 6/6 |
| 5 | devtools | next phase | 8 | 9 | 4 | `RRRRRRRR EE B EEEEE R BBB B` | 8/8 (100%) | 4/6 |
| 6 | mas-template | --auto pipeline fixes | 5 | 1 | 1 | `EEEEE R B` | 5/5 (100%) | 6/6 |
| **Total** | | | **59** | **17** | **8** | | **54/59 (92%)** | |

### Key Insight: Review Coverage Was Never 15%

The original "15% review coverage" was wrong. It measured **reviewer dispatches / engineer dispatches** (17/98 = 17%). But the model's actual pattern is:

```
EEEEE R    ← 5 engineers batched, then 1 reviewer reviews ALL 5 tasks
```

The 1 reviewer dispatch reviews all 5 tasks. **Actual task-level review coverage is 92%**, not 15%. The only gap is Run #4 where the second batch of 5 engineers had no reviewer dispatched (session interrupted).

### The Batch Pattern

Every dev-loop run follows the same pattern:

1. **Batch all engineers** in parallel (max 5 concurrent)
2. **Wait for all results**
3. **Dispatch 1 reviewer** to review all results at once
4. **Bug-fix if BLOCKED**, then re-review

This is the model's natural optimization. It never does per-task atomic pairs (`E R E R E R`).

### Actual Problem Areas

| Issue | Evidence | Severity |
|-------|----------|----------|
| **Second batch often unreviewed** | Run #4: first 5 tasks reviewed, second 5 not (session continued to next phase) | Medium — only affects large runs (>5 tasks) |
| **Reviewer overloaded on big batches** | Run #3: 1 reviewer for 9 tasks in one dispatch. SmartBear research says >400 LOC degrades detection | Medium — quality risk on large batches |
| **Artifact persistence** | 0 artifacts survive worktree cleanup across all projects | High — fixed in v2.1.0 |
| **Pipeline compliance** | 4/6 runs hit all 6 steps, 2/6 missed verify or finish | Medium — much better than originally reported |

### v2.1.0 Fixes Assessment (corrected)

| Fix | Original Justification | Corrected Assessment |
|-----|----------------------|---------------------|
| **Atomic E→R pairing** | "Review coverage 15%" | Coverage was actually 92%. The atomic constraint fights the model's natural batching. **May reduce throughput without improving quality.** |
| **Engineer self-review** | Structural 100% coverage | Still valuable — lightweight pre-check before reviewer sees it. Reduces reviewer workload. |
| **Artifact preservation** | 0 artifacts survive | Correct and needed. No change. |

### Research-Backed Recommendations (v2.2.0 proposal)

Based on SmartBear/Cisco research (200-400 LOC optimal), DORA metrics (small batches), and Google ADK Generator-Critic patterns:

| # | Change | Rationale |
|---|--------|-----------|
| 1 | **Replace atomic pairing with batch-then-review** | Match the model's natural pattern. Batch engineers (max 5), then batch reviewers (1 per task, not 1 for all). The key fix is dispatching N reviewers, not forcing E→R sequence. |
| 2 | **Cap reviewer scope at 3 tasks per dispatch** | SmartBear: >400 LOC degrades detection. 3 tasks ≈ 300-600 LOC per review. If 5 tasks, dispatch 2 reviewers. |
| 3 | **Add cross-task review pass** | After per-task reviews, dispatch 1 holistic reviewer that checks: duplication across tasks, integration gaps, pattern consistency. This is what the current batch reviewer already does naturally. |
| 4 | **Track tasks-reviewed not dispatches** | Fix the metric. Count tasks with a `TASK-*-review.md` file, not reviewer agent dispatches. |
| 5 | **Second-batch enforcement** | If >5 tasks, ensure the second batch also gets reviewed. Current pattern drops review for overflow. |

### Proposed v2.2.0 Pipeline Flow

```
Phase 2A — Batch Engineer (max 5 parallel, batches of 5)
  ├─ Dispatch engineers for tasks 1-5 in parallel
  ├─ Wait for all results
  ├─ Dispatch engineers for tasks 6-10 if needed
  └─ Wait for all results

Phase 2B — Batch Review (max 3 tasks per reviewer)
  ├─ If ≤3 tasks: 1 reviewer for all
  ├─ If 4-6 tasks: 2 reviewers (split evenly)
  ├─ If 7-9 tasks: 3 reviewers
  └─ Wait for all verdicts

Phase 2C — Bug-Fix (only BLOCKED tasks)
  ├─ Dispatch bug-fixer per blocked task
  └─ Re-dispatch reviewer for fixed tasks only

Phase 2D — Cross-Task Review (optional, for >3 tasks)
  ├─ 1 reviewer sees all approved results holistically
  └─ Checks: duplication, integration gaps, pattern consistency

Phase 3 — Close
  ├─ All tasks must have review verdict
  └─ Gate: count(TASK-*-review.md) >= count(TASK-*-result.md)
```
