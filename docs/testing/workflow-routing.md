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

## Pipeline Effectiveness Evaluation (2026-03-29)

### Metrics Framework

| Metric | What It Measures | Ideal | Warning |
|--------|-----------------|-------|---------|
| **Review coverage** | reviewers / engineers | ≥ 50% | < 25% means engineers ship unreviewed |
| **Rework rate** | bug-fixers / (engineers + bug-fixers) | 5–15% | 0% = reviews not catching issues or not reviewing; > 25% = quality problem |
| **Pipeline compliance** | steps completed out of 4 (worktree, plan, verify, finish) | 4/4 | < 3/4 = steps being skipped |
| **Agent-driven ratio** | MAS agent dispatches / total messages | > 3% | < 1% = main session doing the work, not agents |
| **User corrections** | times user said "no/stop/wrong/redo" | low | high = pipeline not meeting expectations |

### v2.0+ Session Scores

| Session | Review Coverage | Rework Rate | Pipeline Compliance | Agent-Driven Ratio | User Corrections | Grade |
|---------|----------------|-------------|---------------------|--------------------|------------------|-------|
| mas-template/5ddcde80 | 27% (10/37) | 0% (0/37) | **4/4** | 7.0% | 1 | **A** — only session hitting all 4 pipeline steps |
| claude-devtools/b9fc5b5e | 18% (8/45) | 8% (4/49) | 1/4 | 4.2% | 5 | **B** — high throughput, healthy rework, but skipped plan/verify/finish |
| dana-desktop/e7b59d40 | 0% (0/7) | 0% (0/7) | 0/4 | 1.9% | 3 | **C** — agents dispatched but no review cycle, no pipeline structure |
| dana-ontologies/30e3f2d6 | N/A (no eng) | N/A | 0/4 | 0.7% | 0 | **N/A** — ad-hoc agent use, not a pipeline session |
| mas-template-2/c81e5695 | N/A (no eng) | N/A | 1/4 | 0.4% | 1 | **N/A** — research/design session, no implementation |

### v1.x vs v2.0+ Comparison

| Metric | v1.x avg (3 sessions) | v2.0+ avg (3 impl sessions) | Delta |
|--------|----------------------|----------------------------|-------|
| Engineer dispatches | 3.7 | 30 | **+8x** |
| Review coverage | 9% | 15% | +6pp |
| Rework rate | 3% | 3% | same |
| Pipeline compliance | 1.3/4 | 1.7/4 | +0.4 |
| Agent-driven ratio | 1.1% | 4.4% | **+4x** |
| User corrections/session | 2.0 | 3.0 | +1.0 |

### Key Findings

**What's working well:**
1. **Agent dispatch volume is 8x higher in v2.0+** — the pipeline is successfully delegating work to agents instead of the main session doing it
2. **Rework rate at 8%** (devtools session) is healthy — reviews are catching real issues and bug-fixer is resolving them
3. **One session achieved 4/4 pipeline compliance** (mas-template/5ddcde80) — proving the full pipeline is achievable

**What needs improvement:**
1. **Review coverage averages 15%** — target is ≥ 50%. Most engineer dispatches go unreviewed. The pipeline instructions say "review each task" but it's not happening consistently
2. **Pipeline compliance averages 1.7/4** — plan, verify, and finish steps get skipped in most sessions. Only 1/5 sessions hit all 4 steps
3. **Artifact persistence is weak** — worktree cleanup deletes `docs/results/` and `docs/reports/`, making post-hoc auditing impossible. Only 3 TASK-*-result.md files survive across all projects
4. **No session produced a verification report** that survived cleanup — `docs/reports/verification-*.md` exists in 0 projects

### Recommended Actions

| Priority | Issue | Fix |
|----------|-------|-----|
| **P0** | Review coverage too low | Add enforcement: dev-loop should refuse to proceed to Phase 4 (Close) if any task lacks a TASK-*-review.md |
| **P1** | Artifacts lost on worktree cleanup | Copy `docs/reports/` and `docs/results/` to main branch before worktree removal in finishing-branch skill |
| **P1** | Pipeline steps skipped | Add mandatory checkpoints that halt with a clear error if plan/verify/finish skills weren't invoked |
| **P2** | No effectiveness tracking in-session | Add a pipeline summary artifact (`docs/reports/pipeline-metrics.md`) that the dev-loop writes at Step 6, capturing review coverage, rework rate, and compliance |
