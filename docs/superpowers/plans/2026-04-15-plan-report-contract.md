# Plan-Report Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Simplify dev-loop and bug-fix to the user's mental model: spec → plan → [internal work] → report. Remove task tracking overhead. Add delivery report step. Clean up internal artifacts before merge.

**Architecture:** The plan (written by superpowers:writing-plans) and the delivery report (written after execution) are the only artifacts that persist on main. Internal plumbing (docs/tasks/, docs/results/, docs/reports/TASK-*) is ephemeral — used during execution, cleaned up before merge. Both dev-loop and bug-fix follow this contract.

**Tech Stack:** Markdown (command docs, skill docs)

---

### File Map

| File | Action | What Changes |
|------|--------|--------------|
| `commands/dev-loop.md` | Major rewrite | Remove Phase 1 (task decompose), remove docs/tasks/ references, remove artifact gates checking TASK-* files, add Step 5.5 (delivery report), add cleanup in finishing-branch |
| `commands/bug-fix.md` | Add report step | Add delivery report step before finish |
| `skills/finishing-branch/SKILL.md` | Update cleanup | Replace archive step with cleanup of internal artifacts, keep plan + report |
| `CLAUDE.md` | Update Step 4 | Remove docs/tasks/ from directory creation |
| `commands/bootstrap.md` | Update Step 4 | Remove docs/tasks/ directories from mkdir |
| `templates/dispatch-templates.md` | Update output dirs | Remove docs/tasks/ references, simplify |

---

### Task 1: Rewrite dev-loop.md — remove task tracking, add delivery report

**Files:**
- Modify: `commands/dev-loop.md`

Key changes:

**Step 2 (Plan):** Remove reference to "TASK-{id} entries". The plan is written by superpowers:writing-plans which has its own format. The plan is the source of truth — no separate task specs.

**Step 4 (Execute):** 
- Remove Phase 1 (Decompose) — no more creating docs/tasks/pending/TASK-{id}.md files
- Phase 2A: Engineers get dispatched with plan task content directly (not task spec files)
- Phase 2B: Results still go to docs/results/ (internal, cleaned up later)
- Phase 2C: Reviewers still review (internal, cleaned up later)
- Phase 2D: Handle verdicts inline — no more moving files between dirs
- Phase 2E: Reflect stays but simplified — reads plan, not task specs
- Remove Phase 3 (Close & Holistic Check) — replaced by delivery report
- Remove artifact verification block that checks for TASK-* files

**Add Step 5.5 — Delivery Report (after verify, before finish):**
Write a report to `docs/superpowers/reports/YYYY-MM-DD-{branch-name}.md` that:
1. References the plan file path
2. For each task in the plan: DONE / PARTIAL / SKIPPED with evidence
3. Lists any deviations from the plan
4. Includes verification results summary
5. Overall verdict: DELIVERED / PARTIAL / FAILED

**Pipeline Self-Audit:** Simplify — remove TASK-* file checks, keep "were agents dispatched?" and "does delivery report exist?"

- [ ] Step 1: Remove Phase 1 (Decompose) from Step 4
- [ ] Step 2: Update Phase 2A — dispatch engineers with plan task content, not task spec files
- [ ] Step 3: Simplify Phase 2E (Reflect) — reference plan instead of task specs
- [ ] Step 4: Remove Phase 3 (Close & Holistic Check)
- [ ] Step 5: Remove artifact verification block (the TASK-* file checks)
- [ ] Step 6: Add Step 5.5 — Delivery Report
- [ ] Step 7: Simplify Pipeline Self-Audit
- [ ] Step 8: Update Agent Pipeline diagram
- [ ] Step 9: Update Rules section — remove "artifact gates" reference

---

### Task 2: Update bug-fix.md — add delivery report

**Files:**
- Modify: `commands/bug-fix.md`

Add a delivery report step between Step 6 (Verify) and Step 7 (Finish). The report for bug-fix is simpler:
1. Bug description (from Step 1)
2. Root cause (from Step 3)  
3. Fix applied (from Bug-Fixer result)
4. Review verdict (from Step 5)
5. Verification status (from Step 6)

Save to `docs/superpowers/reports/YYYY-MM-DD-{branch-name}.md`.

Also update the Pipeline Self-Audit to check for the delivery report.

- [ ] Step 1: Add delivery report step (new Step 6.5)
- [ ] Step 2: Update Pipeline Self-Audit to include delivery report check
- [ ] Step 3: Update Agent Pipeline diagram to show report step

---

### Task 3: Update finishing-branch skill — cleanup internal artifacts

**Files:**
- Modify: `skills/finishing-branch/SKILL.md`

Replace the current Step 4 (Preserve Artifacts) which archives everything to `docs/archive/`. New behavior:
- Plan (`docs/superpowers/plans/`) — KEEP (already on branch, survives merge)
- Report (`docs/superpowers/reports/`) — KEEP (already on branch, survives merge)
- Internal artifacts (`docs/results/`, `docs/reports/`, `docs/tasks/`, `docs/design/`) — DELETE before merge
- Remove Step 5 reference to "Move all tasks to docs/tasks/done/"

- [ ] Step 1: Replace Step 4 (Preserve Artifacts) with cleanup step
- [ ] Step 2: Remove task-related references from Step 5

---

### Task 4: Update CLAUDE.md template + bootstrap directory creation

**Files:**
- Modify: `CLAUDE.md`
- Modify: `commands/bootstrap.md` (Step 4 only)

Remove `docs/tasks/{pending,in-progress,done,blocked}` from:
- CLAUDE.md: if it references docs/tasks anywhere
- bootstrap.md Step 4: the mkdir command

Keep `docs/{design,plans,reports,results}` in bootstrap (still used internally during execution).
Add `docs/superpowers/{plans,reports}` to bootstrap mkdir.

- [ ] Step 1: Update bootstrap.md Step 4 mkdir commands
- [ ] Step 2: Check CLAUDE.md for docs/tasks references

---

### Task 5: Update dispatch-templates.md — remove task spec references

**Files:**
- Modify: `templates/dispatch-templates.md`

The dispatch templates currently reference `docs/tasks/pending/TASK-{id}.md` as input. Update to reference plan tasks directly instead. Remove the Output Directory Convention table entries for `docs/tasks/`.

- [ ] Step 1: Update Output Directory Convention table
- [ ] Step 2: Update engineer dispatch template — input from plan, not task spec
- [ ] Step 3: Update reviewer dispatch template — reference plan tasks
- [ ] Step 4: Update reflect dispatch template — reference plan, not task specs

---

### Task 6: Version bump + CHANGELOG

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`  
- Modify: `CHANGELOG.md`

Bump to v2.13.0 (minor — feature change to workflow).

- [ ] Step 1: Bump versions
- [ ] Step 2: Write CHANGELOG entry
