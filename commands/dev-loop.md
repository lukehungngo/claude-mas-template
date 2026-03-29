---
description: Full development loop — plan, design, execute (MAS), verify, finish
---

# Development Loop (MAS)

Execute the full mandatory workflow for: $ARGUMENTS

## Mode

Check if `$ARGUMENTS` contains `--auto`. If yes → **autonomous mode** (no human checkpoints, run everything end-to-end). If no → **interactive mode** (pause for approval at key steps).

**`--auto` scope:** Skips human approval gates at Steps 2 and 6 only. It does NOT skip agent dispatches (Engineer, Reviewer, Bug-Fixer), review cycles, or verification. The full agent pipeline runs in both modes.

**What `--auto` does NOT mean:**

❌ **BAD** (what happened in 4/4 audited --auto sessions):
> "Requirements are clear and changes are well-scoped. I'll implement directly —
> no need for the agent pipeline for these targeted changes."
> *Result: Skipped the entire pipeline. Only worktree creation survived.*

✅ **GOOD** (correct --auto behavior):
> "Requirements are clear. Creating worktree (step 1)...
> Writing plan (`--auto` auto-approves, step 2)...
> Dispatching agents per routing table (step 4) — Engineer, Reviewer, Bug-Fixer as needed...
> Running verification (step 5)... Creating PR automatically (`--auto`, step 6)."

`--auto` removes 2 human pauses. It does NOT remove agent dispatches.

## Agent Pipeline

```
dev-loop (this command)
  │
  ├─ 1. Branch ─── git worktree
  ├─ 2. Plan ─── Skill(skill: "writing-plans")
  │
  ├─ 3. Design (if has_ui: true) ─── Agent(subagent_type: "mas:ui-ux-designer:ui-ux-designer")
  │
  ├─ 4. Execute (flat dispatch — you are the orchestrator)
  │       │
  │       ├─ Phase 1: Decompose plan → task specs in docs/tasks/pending/
  │       ├─ Phase 2: Atomic Execute & Review (per task: Engineer → Reviewer → Bug-Fixer if BLOCKED)
  │       │     ├─ Novel tasks → Researcher ↔ Differential Reviewer (max 3 rounds) → [atomic pair]
  │       │     └─ Known tasks → [atomic pair] directly
  │       │     └─ atomic pair = Engineer dispatch + Reviewer dispatch (never split)
  │       └─ Phase 3: Verify all tasks done + holistic requirements check
  │
  ├─ 5. Verify ─── Artifact gate + Skill(skill: "verification")
  └─ 6. Finish ─── Skill(skill: "finishing-branch")
```

## Steps

### Step 1 — Branch

Create an isolated workspace:

```bash
git worktree add -b feature/{{name}} .worktrees/{{name}}
cd .worktrees/{{name}}
```

Verify clean baseline: `{{test-command}}` must pass.

**GATE:** You are in the worktree directory and baseline tests pass. Do NOT proceed if tests fail.

---

### Step 2 — Plan

```
Skill(skill: "writing-plans")
```

This produces a structured implementation plan with TASK-{id} entries, exact file paths, verification commands, and dependency graphs. The skill explores the codebase and clarifies requirements as needed — no separate exploration or clarification step.

**Do NOT use EnterPlanMode / PlanMode.** Use the `writing-plans` skill which follows a specific template.

- Interactive: present plan to human for approval before proceeding.
- `--auto`: approve plan automatically and proceed.

**GATE:** The plan contains `TASK-` entries with file paths and verification commands. If not, the plan is incomplete — do NOT proceed.

---

### Step 3 — Design (if `has_ui: true`)

Before implementation, dispatch the **UI/UX Designer agent** to produce design specs for any UI-related tasks in the plan.

```
Agent(
  subagent_type: "mas:ui-ux-designer:ui-ux-designer",
  prompt: """
  You are the UI/UX Designer for this development session.

  ## PRD / Requirement
  {paste the original requirement}

  ## Approved Plan
  {paste the approved implementation plan from step 2}

  ## Working Directory
  {worktree path}

  ## Instructions
  For each UI-related task in the plan:
  1. Produce component specs (props, states, variants)
  2. Define state mapping (what data drives each component)
  3. Design interaction flows (user actions → state changes → UI updates)
  4. Write accessibility checklist (ARIA roles, keyboard nav, focus management)
  5. Create HTML wireframe mockups where helpful

  Write all design specs to docs/design/ using the naming convention:
  - docs/design/TASK-{id}-design.md for each task

  ## Output
  Return a summary of all design specs produced, listing:
  - Task ID → design spec path
  - Key design decisions made
  - Any questions or ambiguities that need human input
  """
)
```

- Interactive: present design specs to human for approval.
- `--auto`: approve designs automatically.
- If `has_ui: false`: skip this step entirely.

**GATE:** Design specs exist in `docs/design/` for all UI tasks (or `has_ui: false` and step is skipped).

---

> **CHECKPOINT ASSERTION — You are the orchestrator, not the implementer**
>
> You are about to write production code yourself. **STOP.**
> This happened in 5/5 audited sessions — the main session always implemented directly.
> For each task in the plan, you MUST dispatch an agent via `Agent()`.
> Read the dispatch template from `templates/dispatch-templates.md`.
> If you are about to call Write or Edit on a source file — you are violating the pipeline.
> Your job: route tasks, dispatch agents, track review cycles, verify results.

### Step 4 — Execute

You are the orchestrator. Your job is to **route and dispatch**, not implement. Do NOT use Write/Edit on production code. Only agents write code. For each dispatch, read the relevant template from `templates/dispatch-templates.md` first. Write a routing decision log entry before each dispatch.

#### Phase 1 — Decompose

Read the approved plan from Step 2. For each TASK-{id} entry:

1. Create a task spec in `docs/tasks/pending/TASK-{id}.md` using the template at `templates/task-spec.md`
2. Determine routing using the routing table below
3. Write a `routing:` decision log line in the task spec

#### Routing Table

| Task Type | Route |
|-----------|-------|
| Novel approach needed | Researcher → Differential Reviewer (max 3 rounds) → Engineer |
| Known pattern exists | Engineer directly |
| Bug fix from review | Bug-Fixer |
| UI component (`has_ui: true`) | UI/UX Designer → Engineer |
| Refactor / cleanup | Engineer directly |

**Novel task criteria** (if ANY apply, route to Researcher):
1. No existing implementation of this pattern in the codebase
2. Algorithm/approach not yet used in this project
3. New system boundary the codebase hasn't interfaced with before
4. Competing approaches with non-obvious trade-offs
5. Similar task failed in a prior session (check `docs/reports/`)

If in doubt, route to Researcher.

#### Phase 2 — Atomic Execute & Review

**Every engineer dispatch MUST be immediately followed by a reviewer dispatch on the same task before proceeding to the next task.** This is not optional. Engineer + Reviewer is one atomic unit — never split them.

**Review count invariant:** Expected reviews = Expected engineer dispatches. Track both counts. If counts diverge at any point, you skipped reviews — STOP and fix before continuing.

```
Per task, the atomic sequence is:
  1. Dispatch Engineer (template from templates/dispatch-templates.md)
  2. Wait for engineer result at docs/results/TASK-{id}-result.md
  3. Dispatch Reviewer on the SAME task (template from templates/dispatch-templates.md)
  4. Read verdict from docs/reports/TASK-{id}-review.md
  5. If BLOCKED → Bug-Fixer cycle (see below)
  6. Only after verdict is APPROVED or APPROVED WITH CHANGES → move to next task
```

**The atomic constraint means:** Do NOT batch all engineers first and reviewers second. Do NOT proceed to the next task until the current task has both an engineer result AND a reviewer verdict.

For each task:

1. Read the relevant dispatch template
2. Fill in all `{placeholder}` values with actual content
3. Dispatch Engineer via `Agent()`
4. Wait for result, then immediately dispatch Reviewer via `Agent()` on the same task
5. For novel tasks, complete the **Research Convergence Protocol** (in dispatch-templates.md) BEFORE the atomic engineer+reviewer pair

Track `review_cycle` per task, starting at 0.

After each Reviewer verdict:
- **APPROVED** → Phase 3
- **APPROVED WITH CHANGES** → Phase 3 (non-blocking)
- **BLOCKED** → increment `review_cycle`, then:
  - If `review_cycle < 2` → dispatch Bug-Fixer, then re-dispatch Reviewer (still within this task's atomic unit)
  - If `review_cycle >= 2` → STOP. Write escalation to `docs/reports/TASK-{id}-escalation.md`. Move to `docs/tasks/blocked/`. Present to human.

**Parallel execution of atomic pairs:** Check `relevant_files` across tasks. No overlap → dispatch atomic pairs in parallel (each pair is still internally sequential: engineer then reviewer). Overlap → fully sequential. **Max 5 concurrent agents** (platform limit) — since each atomic pair uses 1 agent at a time, you can run up to 5 pairs in parallel if files don't overlap. Wait for the current batch to finish before starting the next.

#### Phase 3 — Close & Holistic Check

1. For each task: read acceptance criteria, engineer result, reviewer report. If all pass → move to `docs/tasks/done/`
2. **Holistic requirements check:** After all tasks are done, verify: do these tasks TOGETHER deliver what was asked? Check for gaps between task boundaries, missed edge cases, integration issues. If gaps found → create new tasks and loop back to Phase 1 (max 2 remediation cycles).

**GATE:** `docs/tasks/done/` is non-empty. All tasks reviewed and closed. No unresolved escalations.

---

**Artifact Verification (mandatory — run these commands before Step 5):**

Before proceeding, you MUST run ALL of these commands. If ANY fails, you bypassed the pipeline — go back to Step 4.

**Review count check:** Count `docs/results/TASK-*-result.md` files and `docs/reports/TASK-*-review.md` files. Expected reviews = expected engineer dispatches. If counts diverge, you skipped reviews.

```bash
# 1. Task specs were created (Phase 1 happened)
ls docs/tasks/done/*.md 2>/dev/null || ls docs/tasks/pending/*.md 2>/dev/null

# 2. Engineer result files exist (agents were dispatched, not main session)
ls docs/results/TASK-*-result.md

# 3. Review reports exist (reviewer was dispatched after each engineer)
ls docs/reports/TASK-*-review.md

# 4. Atomic pair count check (engineer count must equal reviewer count)
echo "Engineer results: $(ls docs/results/TASK-*-result.md 2>/dev/null | wc -l | tr -d ' ')"
echo "Review reports:   $(ls docs/reports/TASK-*-review.md 2>/dev/null | wc -l | tr -d ' ')"
# If these numbers differ, reviews were skipped — go back to Phase 2.

# 5. Self-review files exist (engineer self-reviewed before submitting)
ls docs/results/TASK-*-self-review.md
```

**Why this works:** `docs/results/TASK-*-result.md` files are written ONLY by Engineer agents. `docs/reports/TASK-*-review.md` files are written ONLY by Reviewer agents. If the main session implemented directly, these files don't exist and the gate fails.

**If the gate fails:**
1. Do NOT create these files manually — that is fraud
2. Go back to Step 4 Phase 2 and dispatch agents
3. If Agent() calls fail, report to the human before proceeding

---

> **CHECKPOINT ASSERTION — Step 5 is mandatory**
>
> You are about to skip verification. **STOP.**
> This happened in 5/5 audited sessions — 0 invoked the verification skill.
> You MUST call `Skill(skill: "verification")` which writes `docs/reports/verification-{branch}.md`.

### Step 5 — Verify

```
Skill(skill: "verification")
```

Final technical checks: all tests pass, lint clean, typecheck clean, no debug artifacts.

**GATE:** `docs/reports/verification-{branch}.md` must exist before proceeding to Step 6.

---

> **CHECKPOINT ASSERTION — Step 6 is mandatory**
>
> You are about to skip the finishing-branch skill. **STOP.**
> You MUST call `Skill(skill: "finishing-branch")` which presents options to the human.
> Do not `git merge` or `git worktree remove` manually.

---

### PIPELINE SELF-AUDIT (mandatory before finishing)

Before proceeding to Step 6, verify each item with evidence.

- [ ] **Routing decision log exists?** — Check `docs/tasks/pending/` or `docs/tasks/done/` for task specs with `routing:` lines.
- [ ] **Engineer agents dispatched?** — Check `docs/results/` for TASK-*-result.md files.
- [ ] **Reviewer issued verdict?** — Check `docs/reports/` for TASK-*-review.md files.
- [ ] **Atomic pair count matches?** — Engineer result count = Review report count. If not, reviews were skipped.
- [ ] **Bug-Fixer handled blocks?** — If any review verdict is BLOCKED, check for TASK-*-bugfix-result.md.
- [ ] **Self-review files exist?** — Check `docs/results/` for TASK-*-self-review.md files.
- [ ] **Verification report exists?** — `docs/reports/verification-{branch}.md` must exist.

**If any check fails:** Go back to the first failed step.

### Step 6 — Finish

```
Skill(skill: "finishing-branch")
```

- Interactive: present options (merge/PR/keep/discard).
- `--auto`: create PR automatically.

---

## Rules

- The dev-loop owns all agent dispatch via flat dispatch — route tasks per the routing table, dispatch agents directly. Do NOT write production code yourself.
- All agents use `mas:` plugin prefix (e.g., `mas:engineer:engineer`)
- Do NOT use EnterPlanMode / PlanMode — use `Skill(skill: "writing-plans")`
- Artifact gates are load-bearing enforcement — `docs/results/TASK-*-result.md` and `docs/reports/TASK-*-review.md` MUST exist before Step 5. Do NOT create them manually.

For battle-tested lessons, see `rules/agent-workflow.md`.

## Agent Reference

| Agent | subagent_type | Role |
|-------|--------------|------|
| Engineer | `mas:engineer:engineer` | TDD implementation, writes to `docs/results/` |
| Reviewer | `mas:reviewer:reviewer` | Two-stage review, writes to `docs/reports/` |
| Researcher | `mas:researcher:researcher` | Explores approaches, writes to `docs/plans/` |
| Differential Reviewer | `mas:differential-reviewer:differential-reviewer` | Stress-tests proposals, writes to `docs/reports/` |
| Bug-Fixer | `mas:bug-fixer:bug-fixer` | TDD fixes from reviewer reports |
| UI/UX Designer | `mas:ui-ux-designer:ui-ux-designer` | Design specs + HTML mockups (has_ui: true only) |
| ~~Orchestrator~~ | ~~`orchestrator`~~ | DEPRECATED — routing logic is inline in Step 4 |

## Lessons Learned

See `rules/agent-workflow.md` for battle-tested lessons from real sessions. Key meta-lesson: **prose instructions get skipped — structural constraints (tool removal, file-existence gates, exact tool call syntax) are harder to bypass.**
