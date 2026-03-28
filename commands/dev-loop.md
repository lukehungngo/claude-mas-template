---
description: Full development loop — ask, explore, plan, design, orchestrate (MAS), review, finish
---

# Development Loop (MAS)

Execute the full mandatory workflow for: $ARGUMENTS

## Mode

Check if `$ARGUMENTS` contains `--auto`. If yes → **autonomous mode** (no human checkpoints, run everything end-to-end). If no → **interactive mode** (pause for approval at key steps).

**`--auto` scope:** Skips human approval gates at Steps 1, 4, 5, and 9 only. It does NOT skip agent dispatches (Engineer, Reviewer, Bug-Fixer), review cycles, or verification. The full agent pipeline runs in both modes — `--auto` only removes the pauses where a human would say "yes, continue".

**What `--auto` does NOT mean:**

❌ **BAD** (what happened in 4/4 audited --auto sessions):
> "Requirements are clear and changes are well-scoped. I'll implement directly —
> no need for the orchestrator pipeline for these targeted changes."
> *Result: Skipped steps 3-9. Only worktree creation survived.*

✅ **GOOD** (correct --auto behavior):
> "Requirements are clear (`--auto` skips step 1 clarification). Creating worktree...
> Exploring codebase (step 3)... Writing plan (`--auto` auto-approves, step 4)...
> Routing tasks and dispatching agents (step 6) — Engineer, Reviewer, Bug-Fixer as needed...
> Running requirements validation (step 7)... Invoking verification skill (step 8)...
> Creating PR automatically (`--auto` skips human choice, step 9)."

`--auto` removes 4 human pauses. It does NOT remove 5 agent dispatches.

## Agent Pipeline

```
dev-loop (this command)
  │
  ├─ 1. Clarify ─── Skill(skill: "ask-questions")
  ├─ 2. Branch ─── git worktree
  ├─ 3. Explore ─── Agent(subagent_type: "Explore")
  ├─ 4. Plan ─── Skill(skill: "writing-plans")
  │
  ├─ 5. Design (if has_ui: true) ─── Agent(subagent_type: "mas:ui-ux-designer:ui-ux-designer")
  │
  ├─ 6. Orchestrate (flat dispatch — you are the orchestrator)
  │       │
  │       ├─ Phase 1: Decompose plan → task specs in docs/tasks/pending/
  │       ├─ Phase 2: Route & dispatch agents directly (templates in templates/dispatch-templates.md)
  │       │     ├─ Novel tasks → Researcher ↔ Differential Reviewer (max 3 rounds) → Engineer
  │       │     └─ Known tasks → Engineer directly
  │       ├─ Phase 3: Review each task (Reviewer → Bug-Fixer if BLOCKED, max 2 cycles)
  │       └─ Phase 4: Verify acceptance criteria → move to docs/tasks/done/
  │
  ├─ 7. Validate ─── Agent(subagent_type: "mas:reviewer:reviewer")
  │       └─ GAPS FOUND? ──→ loop back to 6 (max 3 cycles)
  ├─ 8. Verify ─── Skill(skill: "verification")
  └─ 9. Finish ─── Skill(skill: "finishing-branch")
```

## Steps

### Step 1 — Clarify

```
Skill(skill: "ask-questions")
```

If the requirement has any ambiguity, this skill will surface questions before proceeding. If crystal clear, skip to step 2.

- `--auto`: skip clarification, assume requirements are complete as given.

**GATE:** Requirement is clarified (or `--auto` skips this step). Do NOT proceed to step 2 with unresolved ambiguities.

---

### Step 2 — Branch

Create an isolated workspace:

```bash
git worktree add -b feature/{{name}} .worktrees/{{name}}
cd .worktrees/{{name}}
```

Verify clean baseline: `{{test-command}}` must pass.

**GATE:** You are in the worktree directory and baseline tests pass. Do NOT proceed if tests fail.

---

### Step 3 — Explore

Scan the codebase for relevant patterns, existing implementations, and integration points before planning.

```
Agent(
  subagent_type: "Explore",
  prompt: """
  Explore the codebase to understand:
  1. Existing patterns relevant to: {requirement summary}
  2. Files and modules that will be affected
  3. Integration points and dependencies
  4. Test patterns used in this area of the codebase

  Working directory: {worktree path}

  Return a structured summary containing:
  - Relevant files and their purpose
  - Existing patterns to reuse
  - Potential integration challenges
  """
)
```

This is a lightweight, read-only step. Its output feeds into the Plan step.

**GATE:** You have a codebase exploration summary. Do NOT plan without understanding the existing code.

---

### Step 4 — Plan

```
Skill(skill: "writing-plans")
```

This produces a structured implementation plan with TASK-{id} entries, exact file paths, verification commands, and dependency graphs.

**Do NOT use EnterPlanMode / PlanMode.** PlanMode is a different mechanism — it produces freeform text, NOT the structured TASK-{id} breakdown required here. The `writing-plans` skill follows a specific template with exact file paths, verification commands, and dependency graphs.

- Interactive: present plan to human for approval before proceeding.
- `--auto`: approve plan automatically and proceed.

**GATE:** The plan contains `TASK-` entries with file paths and verification commands. If not, the plan is incomplete — do NOT proceed.

---

### Step 5 — Design (if `has_ui: true`)

Before implementation, dispatch the **UI/UX Designer agent** to produce design specs for any UI-related tasks in the plan.

```
Agent(
  subagent_type: "mas:ui-ux-designer:ui-ux-designer",
  prompt: """
  You are the UI/UX Designer for this development session.

  ## PRD / Requirement
  {paste the original requirement}

  ## Approved Plan
  {paste the approved implementation plan from step 4}

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

- Interactive: present design specs to human for approval before proceeding.
- `--auto`: approve designs automatically and proceed.
- If `has_ui: false`: skip this step entirely.

**GATE:** Design specs exist in `docs/design/` for all UI tasks (or `has_ui: false` and step is skipped). Do NOT implement UI tasks without design specs.

---

> **CHECKPOINT ASSERTION — You are the orchestrator, not the implementer**
>
> You are about to write production code yourself. **STOP.**
> This happened in 5/5 audited sessions — the main session always implemented directly.
> For each task in the plan, you MUST dispatch an agent via `Agent()`.
> Read the dispatch template from `templates/dispatch-templates.md`.
> If you are about to call Write or Edit on a source file — you are violating the pipeline.
> Your job: route tasks, dispatch agents, track review cycles, verify results.

### Step 6 — Orchestrate

You are the orchestrator. Your job is to **route and dispatch**, not implement. Do NOT use Write/Edit on production code. Only agents write code. For each dispatch, read the relevant template from `templates/dispatch-templates.md` first. Write a routing decision log entry before each dispatch.

#### Phase 1 — Decompose

Read the approved plan from Step 4. For each TASK-{id} entry:

1. Create a task spec in `docs/tasks/pending/TASK-{id}.md` using the template at `.claude/templates/task-spec.md`
2. Determine routing using the routing table below
3. Write a `routing:` decision log line in the task spec (e.g., `routing: "novel — no existing pattern for X"` or `routing: "known — reuses pattern from src/X.ts"`)

#### Routing Table

| Task Type | Route |
|-----------|-------|
| Novel approach needed | Researcher -> Differential Reviewer (max 3 rounds) -> Engineer |
| Known pattern exists | Engineer directly |
| Bug fix from review | Bug-Fixer |
| UI component (`has_ui: true`) | UI/UX Designer -> Engineer |
| Refactor / cleanup | Engineer directly |

**Novel task criteria** (if ANY apply, route to Researcher):
1. No existing implementation of this pattern in the codebase
2. Algorithm/approach not yet used in this project
3. New system boundary the codebase hasn't interfaced with before
4. Competing approaches with non-obvious trade-offs
5. Similar task failed in a prior session (check `docs/reports/`)

If in doubt, route to Researcher. The cost of unnecessary research is low; the cost of skipping research is 6 bug-fix rounds (observed in S1).

#### Phase 2 — Route & Dispatch

For each task, dispatch the appropriate agent directly using templates from `templates/dispatch-templates.md`.

1. Read the relevant dispatch template from `templates/dispatch-templates.md`
2. Fill in all `{placeholder}` values with actual content
3. Dispatch via `Agent()`
4. For novel tasks, follow the **Research Convergence Protocol** (template #7 in dispatch-templates.md)

**Parallel execution:** Check `relevant_files` across tasks. No overlap -> dispatch simultaneously. Overlap -> sequential in dependency order.

#### Phase 3 — Review

Track `review_cycle` per task, starting at 0.

After each Engineer completes:
1. Dispatch Reviewer (use template #4 from `templates/dispatch-templates.md`)
2. Read verdict from `docs/reports/TASK-{id}-review.md`:
   - **APPROVED** -> Phase 4
   - **APPROVED WITH CHANGES** -> Phase 4 (changes are non-blocking)
   - **BLOCKED** -> increment `review_cycle`, then:
     - If `review_cycle < 2` -> dispatch Bug-Fixer (template #5), then re-dispatch Reviewer
     - If `review_cycle >= 2` -> STOP. Write escalation to `docs/reports/TASK-{id}-escalation.md`. Move task to `docs/tasks/blocked/`. Present escalation to human.

#### Phase 4 — Verify & Close

1. Read the task spec's acceptance criteria
2. Read the Engineer's result file (`docs/results/TASK-{id}-result.md`)
3. Read the Reviewer's report (`docs/reports/TASK-{id}-review.md`) — verify verdict is APPROVED or APPROVED WITH CHANGES
4. If all pass -> move task to `docs/tasks/done/`
5. If any fail -> identify which agent should fix, re-dispatch

**GATE:** `docs/tasks/done/` is non-empty (tasks were completed). All tasks have been routed, dispatched, reviewed, and closed. Do NOT proceed if any tasks are in `docs/tasks/blocked/` — present escalations to the human first.

**Artifact Verification (mandatory — run these commands before Step 7):**

Before proceeding, you MUST run ALL of these commands. If ANY fails, you bypassed the pipeline — go back to Step 6.

```bash
# 1. Task specs were created (Phase 1 happened)
ls docs/tasks/done/*.md 2>/dev/null || ls docs/tasks/pending/*.md 2>/dev/null

# 2. Engineer result files exist (agents were dispatched, not main session)
ls docs/results/TASK-*-result.md

# 3. Review reports exist (reviewer was dispatched after each engineer)
ls docs/reports/TASK-*-review.md
```

**Why this works:** `docs/results/TASK-*-result.md` files are written ONLY by Engineer agents (per `agents/engineer/CLAUDE.md` Phase 5). `docs/reports/TASK-*-review.md` files are written ONLY by Reviewer agents. If the main session implemented code directly without dispatching agents, these files do not exist and the gate fails.

**If the gate fails:**
1. Do NOT create these files manually to satisfy the gate — that is fraud
2. Go back to Step 6 Phase 2 and dispatch the appropriate agents
3. If Agent() calls genuinely fail, report to the human before proceeding

---

> **CHECKPOINT ASSERTION — Step 7 is mandatory**
>
> You are about to skip requirements validation. **STOP.**
> This happened in 5/5 audited sessions — no session ever dispatched a reviewer for holistic validation.
> The Reviewer MUST be dispatched via `Agent(subagent_type: "mas:reviewer:reviewer")` with the requirements validation prompt.
> Step 6 per-task reviews are NOT sufficient — this step checks all tasks together deliver the PRD.

### Step 7 — Validate Requirements

Holistic PRD validation. Step 6's per-task reviews checked individual tasks, but this step checks that **all tasks together deliver what the PRD asked for**.

```
Agent(
  subagent_type: "mas:reviewer:reviewer",
  prompt: """
  You are performing a REQUIREMENTS VALIDATION — not a per-task code review.

  ## Original PRD / Requirement
  {paste the original requirement from step 1}

  ## Approved Plan
  {paste the approved plan from step 4}

  ## Step 6 Completion Report
  {paste the task completion summary from step 6 — list of tasks, their status, review verdicts}

  ## Instructions
  For EACH functional requirement in the PRD:
  1. Trace through the implemented code to verify it exists
  2. Run any relevant commands to confirm behavior
  3. Mark as: IMPLEMENTED / PARTIALLY IMPLEMENTED / MISSING

  Then check cross-cutting concerns:
  - Do the implemented tasks integrate correctly with each other?
  - Are there PRD requirements that fell between task boundaries?
  - Are edge cases mentioned in the PRD handled?
  - Does the overall system behavior match what was specified?

  ## Output
  Write your report to docs/reports/requirements-validation-r{remediation_cycle}.md
  (r0 = initial validation, r1 = after 1st remediation, etc.)

  ### Requirement Coverage
  | # | Requirement | Status | Evidence |
  |---|-------------|--------|----------|
  | 1 | {from PRD}  | IMPLEMENTED / PARTIALLY / MISSING | {file:line or command output} |

  ### Cross-Cutting Concerns
  - [PASS/FAIL] {concern} — {evidence}

  ### Gaps
  {List any requirements not fully met}

  ### Verdict
  ALL MET / GAPS FOUND / CRITICAL GAPS
  """
)
```

**On verdict (Remediation Loop — max 3 cycles):**

Track `remediation_cycle` starting at 0. After each validation:

- **ALL MET** → exit loop, proceed to step 8.
- **GAPS FOUND** (and `remediation_cycle < 3`):
  1. Increment `remediation_cycle`.
  2. Interactive: present gap list to human, ask "Remediate automatically? (y/n)". If no → escalate.
  3. `--auto`: proceed without asking.
  4. Perform remediation via flat dispatch (see below).
  5. After remediation completes → re-run this Validate step (step 7).
- **GAPS FOUND** (and `remediation_cycle >= 3`) → escalate to human with all validation reports (`r0` through `r3`).
- **CRITICAL GAPS** → stop and escalate to human immediately, regardless of cycle count.

**Remediation via Flat Dispatch (used on GAPS FOUND retry):**

On GAPS FOUND, perform remediation using the same Step 6 process:

1. **Decompose gaps into tasks:** For each gap in the validation report, create a new task spec (TASK-{next-id}) in `docs/tasks/pending/` targeting the specific gap.
2. **Route & dispatch:** Apply the routing table from Step 6. Read dispatch templates from `templates/dispatch-templates.md`. Dispatch agents for each remediation task.
3. **Review:** After each Engineer completes, dispatch Reviewer. Handle BLOCKED verdicts with Bug-Fixer (max 2 cycles).
4. **Close:** Verify acceptance criteria, move to `docs/tasks/done/`.

Focus ONLY on the gaps listed in the validation report. Do NOT re-implement already-completed tasks.

This is remediation cycle {remediation_cycle} of 3. If you cannot close a gap, report it so the next validation can track persistent issues.

After remediation completes → re-run the Validate step (step 7) above.

**GATE:** A validation report exists at `docs/reports/requirements-validation-r*.md` with verdict ALL MET. Do NOT proceed to step 8 without passing validation.

---

> **CHECKPOINT ASSERTION — Step 8 is mandatory**
>
> You are about to skip verification. **STOP.**
> This happened in 5/5 audited sessions — 0 invoked the verification skill.
> Running tests via raw Bash does NOT satisfy this step.
> You MUST call `Skill(skill: "verification")` which writes `docs/reports/verification-{branch}.md`.
> The GATE checks for this file — raw test output alone will not pass.

### Step 8 — Verify

```
Skill(skill: "verification")
```

Final technical checks:

- All tests pass
- Lint clean
- Typecheck clean
- No debug artifacts

**GATE:** `docs/reports/verification-{branch}.md` must exist before proceeding to step 9. `Skill(skill: "verification")` writes this file — raw Bash test output alone does NOT satisfy this gate. Do NOT proceed without the file.

---

> **CHECKPOINT ASSERTION — Step 9 is mandatory**
>
> You are about to skip the finishing-branch skill. **STOP.**
> This happened in 5/5 audited sessions — all worktrees were manually merged and cleaned.
> You MUST call `Skill(skill: "finishing-branch")` which presents options to the human.
> Do not `git merge` or `git worktree remove` manually.

---

### PIPELINE SELF-AUDIT (mandatory before finishing)

Before proceeding to Step 9, verify each item with evidence. Self-assessment is not sufficient — check for artifacts.

- [ ] **Routing decision log exists?** — Check `docs/tasks/pending/` or `docs/tasks/done/` for task specs containing `routing:` lines. If no routing decisions were logged, Phase 1 was skipped.
- [ ] **Engineer agents dispatched?** — Check `docs/results/` for TASK-*-result.md files. These are ONLY written by Engineer agents. If none exist, you implemented code directly — violation.
- [ ] **Reviewer issued verdict?** — Check `docs/reports/` for TASK-*-review.md files. Read the verdict line. If no review files exist, no reviewer was dispatched.
- [ ] **Bug-Fixer handled blocks?** — If any review verdict is BLOCKED, check for TASK-*-bugfix-result.md in `docs/reports/`. If none exist and you fixed it yourself, this is a violation.
- [ ] **Verification report exists?** — Run: `test -f docs/reports/verification-{branch}.md && grep "Verdict:" docs/reports/verification-{branch}.md`. File must exist AND contain Build, Code, Spec, Regression sections.
- [ ] **Requirements validation passed?** — Run: `test -f docs/reports/requirements-validation-r*.md && grep "ALL MET" docs/reports/requirements-validation-r*.md`. Must return a match.

**If any check fails:** You violated the pipeline. Do NOT proceed to Step 9. Go back to the first failed step and execute it properly.

**This is not optional.** In 5/5 audited sessions, zero completed the full pipeline. You are being explicitly asked to break that pattern.

### Step 9 — Finish

```
Skill(skill: "finishing-branch")
```

- Interactive: present options (merge/PR/keep/discard).
- `--auto`: create PR automatically.
- Include the Requirements Validation Report in the branch summary so the human sees coverage before deciding.

---

## Agent Reference

All agents use **`mas:` plugin prefix**:

| Agent                 | subagent_type           | Role                                                                                             |
| --------------------- | ----------------------- | ------------------------------------------------------------------------------------------------ |
| ~~Orchestrator~~      | ~~`orchestrator`~~                              | DEPRECATED — routing logic is now inline in Step 6. Agent preserved for future use if nested dispatch becomes reliable. |
| Engineer              | `mas:engineer:engineer`                         | TDD implementation, writes to `docs/results/`. Uses Write/Edit for code, Bash only for commands. |
| Reviewer              | `mas:reviewer:reviewer`                         | Two-stage review, writes to `docs/reports/`                                                      |
| Researcher            | `mas:researcher:researcher`                     | Explores approaches, writes to `docs/plans/`                                                     |
| Differential Reviewer | `mas:differential-reviewer:differential-reviewer` | Stress-tests proposals, writes to `docs/reports/`                                                |
| Bug-Fixer             | `mas:bug-fixer:bug-fixer`                       | TDD fixes from reviewer reports, writes to `docs/reports/`                                       |
| UI/UX Designer        | `mas:ui-ux-designer:ui-ux-designer`             | Design specs + HTML mockups, writes to `docs/design/`                                            |

## Rules

- TDD is non-negotiable at every step
- The dev-loop owns all agent dispatch via flat dispatch — route tasks per the routing table in Step 6, dispatch agents directly. Do NOT write production code yourself.
- All agents use `mas:` plugin prefix (e.g., `mas:engineer:engineer`)
- Every task gets reviewed (spec compliance + code quality) via Step 6 Phase 3
- Requirements validation (step 7) is mandatory — never skip it
- Stop on P0/P1 issues — do not proceed until fixed (`--auto`: dispatch Bug-Fixer automatically, escalate after 2 failed cycles)
- Max 2 review cycles per task before escalating
- Max 3 remediation cycles for requirements gaps before escalating
- `--auto` still respects TDD, reviews, validation, and quality gates — it only skips human checkpoints
- `--auto` retries up to 3 remediation cycles on GAPS FOUND before escalating
- If any task is escalated to docs/tasks/blocked/ or requirements validation finds CRITICAL GAPS, present them to the human before proceeding
- Do NOT use EnterPlanMode / PlanMode — use Skill(skill: "writing-plans") for structured plans
- Do NOT dispatch Explorer agents ad-hoc — codebase exploration happens in step 3 only
- Each step has a GATE — do NOT skip gates
- Artifact gates are load-bearing enforcement — `docs/results/TASK-*-result.md` and `docs/reports/TASK-*-review.md` MUST exist before Step 7. These files are only created by dispatched agents, not by the main session. Do NOT create them manually.

## Lessons Learned (from battle testing)

These rules exist because every one of these failures happened in real sessions. Do not repeat them.

| #   | Failure                                         | What happened                                                                                                                                                                | Fix applied                                                                                           |
| --- | ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| 1   | **Skills never invoked**                        | 0/5 sessions called Skill tool. Steps said "use X skill" — model skipped them all.                                                                                           | Every step now shows exact `Skill(skill: "X")` call.                                                  |
| 2   | **Orchestrator did everything inline**          | Orchestrator used Bash (70 calls in S1) instead of dispatching agents. Zero Agent tool calls.                                                                                | Bash removed from Orchestrator's tool list (now deprecated). Flat dispatch eliminates the problem — dev-loop dispatches agents directly. |
| 3   | **Engineer used Bash for code**                 | 0 Write/Edit calls. All code written via `cat <<EOF`, `echo`, `sed`.                                                                                                         | Engineer CLAUDE.md now bans Bash for file writes with BAD/GOOD examples.                              |
| 4   | **Researcher/Differential Reviewer never used** | Model always classified tasks as "known pattern" and went straight to Engineer. Researcher used once reactively (agent #17 of 19). Differential Reviewer: 0 dispatches ever. | Orchestrator now requires routing decision log with justification. Novel task criteria made explicit. |
| 5   | **PlanMode replaced writing-plans**             | 3/5 sessions used EnterPlanMode instead of the skill. PlanMode produces freeform text, not structured TASK-{id} breakdown.                                                   | Explicit ban on PlanMode. Step 4 shows exact Skill call.                                              |
| 6   | **No cycle limit enforcement**                  | S1 had 6 bug-fix rounds (spec says max 2). No counter, no stop mechanism.                                                                                                    | Orchestrator Phase 3 now tracks `review_cycle` per task with hard stop at 2.                          |
| 7   | **Explorer agents dispatched ad-hoc**           | 4/5 sessions dispatched Explorer as first step — not in pipeline.                                                                                                            | Formalized as step 3 (Explore). Banned ad-hoc exploration elsewhere.                                  |
| 8   | **Verification step always skipped**            | 0/5 sessions called verification skill. Tests were run via raw Bash but structured checklist never triggered.                                                                | Step 8 shows exact Skill call with GATE check.                                                        |

**The meta-lesson:** Prose instructions get skipped. Structural constraints (removing tools, requiring exact tool call syntax, adding file-existence gates) are harder to bypass than rules that say "you MUST".
