# Implementation Plan: Agent & Dev-Loop Improvements from Session Reports

## Goal

Fix the structural gaps identified across 4 real-world sessions that cause pipeline bypass, skipped steps, and inaccurate routing metrics — unblocking the community release gate.

## Tasks

### TASK-001: Bound `--auto` scope in `dev-loop.md`
- **Agent:** engineer
- **Files:** `commands/dev-loop.md`
- **Approach:** In the `## Mode` section, add an explicit constraint: `--auto` skips human approval gates (Steps 1, 4, 5, 9) only. It does NOT skip Orchestrator, Reviewer, or Bug-Fixer. Add the same note inline at Step 6 header. Evidence: S3 feedback_v4 used `--auto` and dispatched Engineers directly without Orchestrator, skipping per-task reviews.
- **Tests:** N/A (doc change)
- **Verify:** `grep -A3 "autonomous mode" commands/dev-loop.md | grep -q "does NOT skip"`
- **Depends on:** none
- **Est:** 3 min

### TASK-002: Add file-existence gate to verification step in `dev-loop.md`
- **Agent:** engineer
- **Files:** `commands/dev-loop.md`
- **Approach:** Replace the current Step 8 GATE (which only says "All checks pass") with a hard file-existence requirement: `docs/reports/verification-{branch}.md` must exist before step 9. Add that `Skill(skill: "verification")` writes this file as part of its output, and raw Bash test output alone does NOT satisfy this gate. Evidence: verification was skipped in 100% of sessions (0/9) because raw `pnpm test` was accepted as sufficient.
- **Tests:** N/A (doc change)
- **Verify:** `grep -q "verification-{branch}" commands/dev-loop.md`
- **Depends on:** none
- **Est:** 3 min

### TASK-003: Add verification output file to `verification` skill
- **Agent:** engineer
- **Files:** `skills/verification/SKILL.md`
- **Approach:** Add a final section `## Output` that instructs Claude to write a `docs/reports/verification-{branch}.md` file after all checks pass, with a summary of each checklist item's status. This creates the artifact that TASK-002's gate requires.
- **Tests:** N/A (doc change)
- **Verify:** `grep -q "docs/reports/verification" skills/verification/SKILL.md`
- **Depends on:** TASK-002
- **Est:** 3 min

### TASK-004: Add Researcher routing checklist to Orchestrator
- **Agent:** engineer
- **Files:** `agents/orchestrator/CLAUDE.md`
- **Approach:** In the Phase 2 "Novel task criteria" section, replace the current 3-item list with a more explicit checklist including: task has no existing implementation in codebase, involves choosing between 2+ competing approaches, touches a system boundary not yet used, or has failed in a prior session (check `docs/reports/`). Add: "If in doubt, route to Researcher — cost of unnecessary research is low; cost of skipping research is 6 bug-fix rounds (observed in S1)."
- **Tests:** N/A (doc change)
- **Verify:** `grep -q "failed in a prior session" agents/orchestrator/CLAUDE.md`
- **Depends on:** none
- **Est:** 3 min

### TASK-005: Document skill interruption recovery in long-running skills
- **Agent:** engineer
- **Files:** `skills/systematic-debugging/SKILL.md`, `skills/test-driven-development/SKILL.md`
- **Approach:** Add a one-line note at the top of each skill: "If interrupted, re-invoke with the same arguments — this skill is idempotent." Evidence: `/systematic-debugging` was invoked and interrupted twice in S3, then silently abandoned with no resume path.
- **Tests:** N/A (doc change)
- **Verify:** `grep -q "idempotent" skills/systematic-debugging/SKILL.md && grep -q "idempotent" skills/test-driven-development/SKILL.md`
- **Depends on:** none
- **Est:** 2 min

## Dependency Graph

```
TASK-001 (--auto scope)        ─┐
TASK-004 (researcher routing)   ├─ independent, parallel safe
TASK-005 (interruption)        ─┘

TASK-002 (verification gate) → TASK-003 (verification output file)
```

## Risk Assessment

- All changes are documentation edits to `.md` files — no code, no tests, zero risk of regression
- TASK-002 + TASK-003 must stay in order: the gate references the artifact, the artifact must be defined before the gate makes sense to users
