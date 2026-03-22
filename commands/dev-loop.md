---
description: Full development loop — ask, plan, implement (TDD), review, finish
---

# Development Loop

Execute the full mandatory workflow for: $ARGUMENTS

## Mode

Check if `$ARGUMENTS` contains `--auto`. If yes → **autonomous mode** (no human checkpoints, run everything end-to-end). If no → **interactive mode** (pause for approval at key steps).

## Steps

1. **Clarify** — Use `ask-questions` skill. If the requirement has any ambiguity, ask before proceeding. If crystal clear, skip to step 2.
   - `--auto`: skip clarification, assume requirements are complete as given.

2. **Branch** — Create an isolated workspace:
   ```bash
   git worktree add -b feature/{{name}} ../worktrees/{{name}}
   cd ../worktrees/{{name}}
   ```
   Verify clean baseline: `{{test-command}}` must pass.

3. **Plan** — Use `writing-plans` skill to create an implementation plan with bite-sized tasks (2-5 min each).
   - Interactive: present plan to human for approval before proceeding.
   - `--auto`: approve plan automatically and proceed.

4. **Execute** — Use `subagent-driven-development` skill (or `executing-plans` if no subagent support):
   - Dispatch Engineer per task
   - Two-stage review (spec compliance + code quality)
   - TDD enforced on every task
   - `--auto`: on BLOCKED, auto-dispatch Bug-Fixer and retry (max 2 cycles), then skip task if still blocked.

5. **Verify** — Use `verification` skill for final checks:
   - All tests pass
   - Lint clean
   - Typecheck clean
   - No debug artifacts

6. **Finish** — Use `finishing-branch` skill.
   - Interactive: present options (merge/PR/keep/discard).
   - `--auto`: create PR automatically.

## Rules

- TDD is non-negotiable at every step
- Every task gets reviewed (spec compliance + code quality)
- Stop on P0/P1 issues — do not proceed until fixed (`--auto`: auto-fix via Bug-Fixer, skip after 2 failed cycles)
- Max 2 review cycles per task before escalating
- `--auto` still respects TDD, reviews, and quality gates — it only skips human checkpoints
