---
description: Reflect on delivery — check if the branch solves the right problem against a spec or requirement
---

# Reflect (MAS)

Evaluate delivery for: $ARGUMENTS

## Mode

Check if `$ARGUMENTS` contains `--auto`. If yes → autonomous (skip human checkpoint at the end). If no → interactive (present findings and ask what to do).

## What This Does

Dispatches the Reflect Agent to compare the current branch diff against the original requirement/spec. Checks:
- **Requirement coverage** — does every requirement map to implemented work?
- **Scope alignment** — is there scope creep or drift?
- **Feature-level SRP** — does each change do ONE thing?
- **Decision quality** — is each decision the simplest approach?

This command works **standalone** — it does not require a dev-loop. Use it:
- After manual work (no dev-loop involved)
- After multiple dev-loop runs on the same branch
- As a pre-merge gate before PR/merge
- To validate a branch against a spec file

## Step 1 — Identify the Requirement

The requirement comes from `$ARGUMENTS`. It can be:

1. **Inline text:** `/reflect check that we implemented all auth endpoints from the spec`
2. **File reference:** `/reflect @docs/specs/auth-spec.md` or `/reflect check against docs/plans/v4-master-plan.md`
3. **Branch description:** `/reflect` with no args → read the branch name + recent commit messages to infer intent

If the requirement is a file reference, read the file. If inline, use verbatim. If no args, construct context from:
```bash
git log main..HEAD --oneline
git diff main...HEAD --stat
```

## Step 2 — Gather Context

```bash
# Branch diff
git diff main...HEAD --stat
git diff main...HEAD

# Task artifacts (if they exist from a dev-loop)
ls docs/tasks/done/*.md 2>/dev/null
ls docs/results/TASK-*-result.md 2>/dev/null
```

If task specs and results exist, include them. If not (manual work, no dev-loop), the Reflect Agent works from the branch diff alone.

## Step 3 — Dispatch Reflect Agent

```
Agent(
  subagent_type: "mas:reflect-agent:reflect-agent",
  prompt: """
  ## Original User Requirement
  {requirement text — verbatim from step 1}

  ## Completed Task Specs (if available)
  {paste from docs/tasks/done/ or "N/A — no task specs, this was manual work"}

  ## Engineer Results (if available)
  {paste from docs/results/ or "N/A — no engineer results, this was manual work"}

  ## Branch Diff Stats
  {paste git diff main...HEAD --stat}

  ## Working Directory
  {current directory or worktree path}

  ## Output
  Write your report to docs/reports/reflect-report.md
  Issue verdict: PROCEED / REVISE / REJECT / ESCALATE
  """
)
```

## Step 4 — Present Results

Read `docs/reports/reflect-report.md` and present to the user.

| Verdict | Action |
|---------|--------|
| **PROCEED** | "Delivery aligned with requirement. Safe to merge/PR." |
| **REVISE** | Present the gaps. Ask: "Want me to create tasks to fix these gaps?" If yes, create task specs. |
| **REJECT** | Present what was built vs what should have been built. Ask for human direction. |
| **ESCALATE** | Present the ambiguity. Ask for human clarification. |

- Interactive: present findings and ask what to do.
- `--auto` + PROCEED: report and done.
- `--auto` + REVISE: create remediation tasks automatically.
- `--auto` + REJECT/ESCALATE: always stop for human input regardless of --auto.
