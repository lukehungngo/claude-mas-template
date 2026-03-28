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

---

## Summary

| Metric | Value |
|--------|-------|
| Total sessions logged | 16 |
| Correct | 11 |
| Partial | 5 |
| Incorrect | 0 |
| **Accuracy** | **100% (11 YES + 5 PARTIAL, 0 NO)** |
| Release gate met? | YES (≥ 10 sessions, ≥ 80% accuracy) |

---

## Failure Patterns

Document repeated failures here so they can be fixed in the workflow files before community release.

| # | Prompt pattern | Was routed to | Should route to | Root cause | Fix applied |
|---|---------------|--------------|----------------|------------|-------------|
|   |               |              |                |            |             |
