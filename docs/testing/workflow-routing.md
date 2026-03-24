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
- `/dev-loop` — full MAS pipeline (ask → explore → plan → orchestrate → validate → finish)
- `/bootstrap` — stack detection + placeholder fill
- `/release` — release checklist
- `/new-feature` — scaffold new feature
- `ask-questions` skill — clarification before implementation
- `writing-plans` skill — structured plan creation
- `tdd` skill — test-driven implementation
- `systematic-debugging` skill — root cause investigation
- `verification` skill — pre-merge checks
- `finishing-branch` skill — branch wrap-up
- `requesting-code-review` skill — dispatch code review
- `receiving-code-review` skill — process review feedback
- `differential-review` skill — stress-test a proposal

**Correct?** — `YES` / `NO` / `PARTIAL` (right pipeline but skipped a step)

---

## Test Log

| # | Date | User Prompt / Command | Expected Workflow | Actual Workflow Invoked | Correct? | Notes |
|---|------|-----------------------|-------------------|-------------------------|----------|-------|
|   |      |                       |                   |                         |          |       |

---

## Summary

| Metric | Value |
|--------|-------|
| Total sessions logged | 0 |
| Correct | 0 |
| Partial | 0 |
| Incorrect | 0 |
| **Accuracy** | **—** |
| Release gate met? | NO (need ≥ 10 sessions, ≥ 80% accuracy) |

---

## Failure Patterns

Document repeated failures here so they can be fixed in the workflow files before community release.

| # | Prompt pattern | Was routed to | Should route to | Root cause | Fix applied |
|---|---------------|--------------|----------------|------------|-------------|
|   |               |              |                |            |             |
