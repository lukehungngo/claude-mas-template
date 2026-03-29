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
| 1 | {from PRD}  | MET / PARTIAL / MISSING |

{Include the Requirements Validation Report from the validation step if available.
If no validation was run, explicitly note: "Requirements validation was not performed."}

### Options
1. **Merge** — `git checkout main && git merge {branch}`
2. **Create PR** — `gh pr create --title "{title}" --body "{body}"`
3. **Keep branch** — Leave as-is for further work
4. **Discard** — `git branch -D {branch}`

Which would you like?
```

### Step 4 — Preserve Artifacts

**Only run this step if the human chose merge, PR, or keep.** If the human chose **discard**, skip directly to Step 5.

Before removing the worktree, copy audit and planning artifacts to the main branch so they survive cleanup.

```bash
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
ARCHIVE_DIR="docs/archive/${BRANCH_NAME}"

# Switch to main to write archive files
git stash --include-untracked 2>/dev/null
git checkout main

mkdir -p "${ARCHIVE_DIR}"

# Copy each artifact directory if it exists in the branch
for dir in docs/results docs/reports docs/tasks docs/plans docs/design; do
  # Restore directory content from the branch
  git checkout "${BRANCH_NAME}" -- "${dir}" 2>/dev/null && \
    mkdir -p "${ARCHIVE_DIR}/$(basename ${dir})" && \
    cp -R "${dir}/." "${ARCHIVE_DIR}/$(basename ${dir})/"
done

# Clean up: unstage and discard any branch files that leaked outside the archive dir
git reset HEAD -- docs/results docs/reports docs/tasks docs/plans docs/design 2>/dev/null
git checkout -- docs/results docs/reports docs/tasks docs/plans docs/design 2>/dev/null

# Stage ONLY the archive directory and commit
git add "${ARCHIVE_DIR}"
git commit -m "archive: preserve artifacts from ${BRANCH_NAME}"

# Return to the feature branch
git checkout "${BRANCH_NAME}"
git stash pop 2>/dev/null
```

Check:
- [ ] `docs/archive/{branch-name}/` exists on main with all available artifact directories
- [ ] No artifact directories were lost (results, reports, tasks, plans, design)
- [ ] Main branch has a clean commit with only the archived files

### Step 5 — Clean Up (after human chooses)

- If merge/PR: clean up worktree if used
- If discard: delete branch and worktree
- Move all tasks to `docs/tasks/done/`
- Remove worktree: `git worktree remove {path}`
