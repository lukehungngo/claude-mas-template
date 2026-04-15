---
name: finishing-branch
description: Use after all tasks are complete to verify, present options, and clean up the branch
---

# Finishing a Development Branch

## Overview

Final verification, present options to human, clean up.

## Process

### Step 1 — Final Verification

```
Skill(skill: "verification")
```

If any check fails → fix before proceeding.

### Step 2 — Review the Diff

```bash
git diff main...HEAD --stat    # Files changed summary
git log main..HEAD --oneline   # Commits in this branch
```

Check:
- [ ] No unintended file changes
- [ ] No debug prints or TODOs
- [ ] No `.env` or secrets committed
- [ ] Commit messages are meaningful

### Step 3 — Present Options to Human

```markdown
## Branch Complete: {branch-name}

### Summary
{2-3 sentences on what was built}

### Changes
- {X} files changed, {Y} insertions, {Z} deletions
- {N} new tests added

### Build Status
- Lint: PASS
- Typecheck: PASS
- Tests: PASS ({total})

### Requirements Coverage
| # | Requirement | Status |
|---|-------------|--------|
| 1 | {from plan}  | MET / PARTIAL / MISSING |

{Include the Requirements Validation Report from the validation step if available.
If no validation was run, explicitly note: "Requirements validation was not performed."}

### Options
1. **Merge** — `git checkout main && git merge {branch}`
2. **Create PR** — `gh pr create --title "{title}" --body "{body}"`
3. **Keep branch** — Leave as-is for further work
4. **Discard** — `git branch -D {branch}`

Which would you like?
```

### Step 4 — Clean Up Internal Artifacts

Only run this step if the human chose merge, PR, or keep. If discard, skip to Step 5.

Before merging, remove internal pipeline artifacts that are not part of the user-facing contract. Only the plan and delivery report persist.

**Keep (user-facing contract):**
- `docs/superpowers/plans/` — the implementation plan
- `docs/superpowers/reports/` — the delivery report

**Remove (internal pipeline plumbing):**
```bash
rm -rf docs/results/ docs/reports/ docs/tasks/ docs/design/
git add -A docs/
git commit -m "chore: clean up internal pipeline artifacts"
```

Check:
- [ ] `docs/superpowers/plans/` exists with the plan file
- [ ] `docs/superpowers/reports/` exists with the delivery report
- [ ] `docs/results/`, `docs/reports/`, `docs/tasks/`, `docs/design/` are gone

### Step 5 — Clean Up (after human chooses)

- If merge/PR: clean up worktree if used
- If discard: delete branch and worktree
- Remove worktree: `git worktree remove {path}`
