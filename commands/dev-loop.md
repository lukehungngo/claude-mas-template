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

## Runtime Configuration

Detect the current model from system prompt context and set dispatch parameters accordingly. These parameters govern Phase 2 (Batch Execute & Review) parallelism and review density.

| Parameter | opus | sonnet | haiku |
|-----------|------|--------|-------|
| MAX_PARALLEL | 3 | 5 | 5 |
| TASKS_PER_REVIEWER | 5 | 3 | 2 |
| CROSS_TASK_REVIEW | no | if >3 tasks | always |

- **MAX_PARALLEL** — max agents dispatched concurrently in Phase 2A/2C.
- **TASKS_PER_REVIEWER** — how many tasks a single reviewer handles before rotating (Phase 2B/2C).
- **CROSS_TASK_REVIEW** — whether to run a cross-task integration review after individual reviews (Phase 2D).

**At no point should more than 5 agents of any type be running simultaneously.** This is a platform limit. It applies across ALL phases — engineers, reviewers, researchers, bug-fixers, designers all count toward this cap.

### Rate Limit Handling

If you receive a rate limit error ("You've hit your limit"):
1. **STOP dispatching new agents immediately** — do not queue more work
2. **Note the reset time** from the error message
3. **Report to human:** "Rate limited. Reset at {time}. {N} tasks pending. Resume then?"
4. In `--auto` mode: wait for reset, then resume from the last incomplete batch

**Prevention:** Use `model: "haiku"` for Explore agents and simple codebase searches. Reserve Opus/Sonnet tokens for Engineer, Reviewer, and Researcher agents.

```
Agent(
  subagent_type: "Explore",
  model: "haiku",
  prompt: "..."
)
```

### Connection Errors

If you receive connection errors (ConnectionRefused, FailedToOpenSocket):
1. Wait 30 seconds and retry once
2. If retry fails, report to human: "API connection failed. Check network."
3. Do NOT continue dispatching agents during connection failures

## Agent Pipeline

```
dev-loop (this command)
  │
  ├─ 1. Branch ─── git worktree
  ├─ 2. Plan ─── Skill(skill: "superpowers:writing-plans")
  │
  ├─ 3. Design (if has_ui: true) ─── Agent(subagent_type: "mas:ui-ux-designer:ui-ux-designer")
  │
  ├─ 4. Execute (flat dispatch — you are the orchestrator)
  │       │
  │       ├─ Phase 1: Decompose plan → task specs in docs/tasks/pending/
  │       ├─ Phase 2: Batch Execute & Review
  │       │     ├─ 2A: Batch Engineer dispatch (up to MAX_PARALLEL concurrent)
  │       │     ├─ 2B: Wait for all results, read engineer outputs
  │       │     ├─ 2C: Batch Reviewer dispatch (TASKS_PER_REVIEWER tasks per reviewer)
  │       │     ├─ 2D: Handle verdicts — APPROVED → done, BLOCKED → Bug-Fixer → re-review
  │       │     ├─ 2E: Reflect Agent — evaluate branch against original requirement
  │       │     Novel tasks → Researcher ↔ Differential Reviewer (max 3 rounds) before 2A
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

**Pre-planning brainstorm (if requirement is ambiguous or open-ended):**

If the requirement could be solved multiple ways, or the scope is unclear, brainstorm first:

```
Skill(skill: "superpowers:brainstorming")
```

Skip this if the requirement is already specific and scoped (e.g., "fix the login button" or "add pagination to /api/users"). Use it when the requirement is broad (e.g., "improve the auth system" or "add analytics").

**Then write the plan:**

```
Skill(skill: "superpowers:writing-plans")
```

This produces a structured implementation plan with TASK-{id} entries, exact file paths, verification commands, and dependency graphs. The skill explores the codebase and clarifies requirements as needed — no separate exploration or clarification step.

**Do NOT use EnterPlanMode / PlanMode.** Use the `superpowers:writing-plans` skill which follows a specific template.

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

> **DISPATCH NAMING — Copy these exactly. Do NOT simplify or abbreviate.**
>
> | BAD (will break routing) | GOOD (copy this) |
> |--------------------------|-------------------|
> | `Agent(subagent_type: "engineer", ...)` | `Agent(subagent_type: "mas:engineer:engineer", ...)` |
> | `Agent(subagent_type: "reviewer", ...)` | `Agent(subagent_type: "mas:reviewer:reviewer", ...)` |
> | `Agent(subagent_type: "bug-fixer", ...)` | `Agent(subagent_type: "mas:bug-fixer:bug-fixer", ...)` |
> | `Agent(subagent_type: "researcher", ...)` | `Agent(subagent_type: "mas:researcher:researcher", ...)` |
> | `Agent(subagent_type: "differential-reviewer", ...)` | `Agent(subagent_type: "mas:differential-reviewer:differential-reviewer", ...)` |
> | `Agent(subagent_type: "ui-ux-designer", ...)` | `Agent(subagent_type: "mas:ui-ux-designer:ui-ux-designer", ...)` |
> | `Agent(subagent_type: "reflect-agent", ...)` | `Agent(subagent_type: "mas:reflect-agent:reflect-agent", ...)` |
> | `Skill(skill: "mas:verification")` | `Skill(skill: "verification")` |
> | `Skill(skill: "mas:finishing-branch")` | `Skill(skill: "finishing-branch")` |
> | `Skill(skill: "writing-plans")` | `Skill(skill: "superpowers:writing-plans")` |
> | `Skill(skill: "mas:writing-plans")` | `Skill(skill: "superpowers:writing-plans")` |

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

> **Deprecated agents — do NOT dispatch:**
> - `mas:orchestrator:orchestrator` — Deprecated since v2.0. The dev-loop (this command) IS the orchestrator. Never dispatch this agent.

> **Optional ECC escalation agents** — use when MAS agents need language-specific help:
>
> | Situation | ECC Agent | When to Use |
> |-----------|-----------|-------------|
> | Build fails after engineer dispatch | `everything-claude-code:build-error-resolver` | Engineer result reports build failure, before dispatching bug-fixer |
> | TypeScript/JS review needed | `everything-claude-code:typescript-reviewer` | Reviewer flags TS-specific issues beyond its expertise |
> | Python review needed | `everything-claude-code:python-reviewer` | Reviewer flags Python-specific issues |
> | Go review needed | `everything-claude-code:go-reviewer` | Reviewer flags Go-specific issues |
> | Rust review needed | `everything-claude-code:rust-reviewer` | Reviewer flags Rust-specific issues |
> | Security concern found | `everything-claude-code:security-reviewer` | Reviewer flags auth, crypto, or injection patterns |
>
> **These are NOT replacements for MAS agents.** They are specialist consultants. The MAS reviewer still owns the verdict.

#### Phase 2 — Batch Execute & Review

Dispatch engineers in batches, then review in batches. This aligns with the model's natural batching behavior and maximizes throughput. Use **template #8 (Batch Engineer + Batch Review Dispatch)** from `templates/dispatch-templates.md` as the preferred dispatch method.

**Review count invariant:** Expected reviews = Expected engineer dispatches. Track both counts. If counts diverge at any point, you skipped reviews — STOP and fix before continuing. This is enforced by the between-batch gate in Phase 2B — check result/review counts before each new engineer batch, not only at end-of-pipeline.

##### Phase 2A — Batch Engineer Dispatch

1. For novel tasks, complete the **Research Convergence Protocol** (template #7 in dispatch-templates.md) BEFORE dispatching the engineer.
2. Dispatch up to MAX_PARALLEL engineers concurrently for non-overlapping tasks. If tasks exceed MAX_PARALLEL, batch them in groups — wait for each group to finish before starting the next.
3. Check `relevant_files` across tasks. Overlapping files → those tasks must run in separate batches (sequential). Non-overlapping → same batch (parallel).

##### Phase 2B — Wait and Read Results

Wait for all engineers in the current batch to finish. Read each result file at `docs/results/TASK-{id}-result.md`. If any result file does not exist, that engineer dispatch failed — investigate before proceeding. Do not continue to review until all engineers have succeeded or failures are understood.

**Between-batch gate (BLOCKING):** Before dispatching the next engineer batch, verify all previous tasks are reviewed:

```bash
BATCH_RESULTS=$(ls docs/results/TASK-*-result.md 2>/dev/null | wc -l | tr -d ' ')
BATCH_REVIEWS=$(ls docs/reports/TASK-*-review.md 2>/dev/null | wc -l | tr -d ' ')
echo "Results: $BATCH_RESULTS | Reviews: $BATCH_REVIEWS"
```

If `BATCH_REVIEWS < BATCH_RESULTS`: **STOP. Do not dispatch the next engineer batch.** Return to Phase 2C and dispatch reviewers for the unreviewed tasks. Only proceed when reviews equal results.

##### Phase 2C — Batch Reviewer Dispatch

Split completed tasks into groups of TASKS_PER_REVIEWER. Dispatch 1 reviewer per group. Each reviewer receives the task specs AND engineer results for its group. Dispatch up to MAX_PARALLEL reviewers concurrently.

Track `review_cycle` per task, starting at 0.

##### Phase 2D — Handle Verdicts

Read all review verdicts from `docs/reports/TASK-{id}-review.md`. For each task:

- **APPROVED** → Phase 3
- **APPROVED WITH CHANGES** → Phase 3 (non-blocking)
- **BLOCKED** → increment `review_cycle`, then:
  - If `review_cycle < 2` → dispatch Bug-Fixer (template #5), then re-review that task only (use individual template #4)
  - If `review_cycle >= 2` → STOP. Write escalation to `docs/reports/TASK-{id}-escalation.md`. Move to `docs/tasks/blocked/`. Present to human.

If CROSS_TASK_REVIEW is enabled (see Runtime Configuration), dispatch a cross-task integration reviewer after all individual reviews pass (template #8, Step 5).

##### Phase 2E — Reflect (DISPATCH EXACTLY ONCE)

**This agent runs ONCE per dev-loop execution.** Not once per task, not once per batch — once total, after ALL reviews are complete. In audited sessions, this agent was dispatched 2-14 times. That is wrong.

Trigger condition: ALL of these must be true before dispatching:
1. Every task in `docs/tasks/` is in `done/` or `blocked/` (no pending/in-progress)
2. Every `docs/results/TASK-*-result.md` has a corresponding `docs/reports/TASK-*-review.md`
3. All review verdicts are APPROVED or APPROVED WITH CHANGES (no unresolved BLOCKED)
4. Cross-task review is complete (if CROSS_TASK_REVIEW is enabled)

If ANY condition is false, you are not ready for reflect. Go back to Phase 2D.

Dispatch the **Reflect Agent** to evaluate whether the branch as a whole delivers the original requirement. Use **template #9 (Reflect Agent Dispatch)** from `templates/dispatch-templates.md`. This agent counts toward the 5-agent concurrency cap (1 agent).

```
Agent(
  subagent_type: "mas:reflect-agent:reflect-agent",
  prompt: """
  ## Original User Requirement
  {paste the original user requirement VERBATIM — do not paraphrase}

  ## Completed Task Specs
  {paste all task specs from docs/tasks/done/}

  ## Engineer Results
  {paste all engineer results from docs/results/TASK-{id}-result.md}

  ## Research Proposals (if applicable)
  {paste approved research proposals, or "N/A — no research phase"}

  ## Working Directory
  {worktree path}

  ## Output
  Write your report to docs/reports/reflect-report.md
  Issue verdict: PROCEED / REVISE / REJECT / ESCALATE
  """
)
```

> **Intentional reflect skip:** If reflect is genuinely not needed (e.g., documentation-only changes, exploratory spike with no implementation decisions), create `docs/reports/.reflect-skipped` with a one-line reason before ending the session:
> ```bash
> echo "documentation update only — no implementation decisions to evaluate" > docs/reports/.reflect-skipped
> ```
> The `validate-pipeline.sh` Stop hook will accept this and exit 0 instead of blocking.

Read the verdict from `docs/reports/reflect-report.md`. Handle as follows:

- **PROCEED** → continue to Phase 3.
- **REVISE** → extract remediation tasks from the reflect report's identified gaps. Create new task specs in `docs/tasks/pending/` for each gap. Loop back to Phase 2A to implement them. **Max 1 remediation cycle** — if the second reflect verdict is still REVISE, escalate to human.
- **REJECT** → STOP. Present the reflect report to the human. Do not proceed to Phase 3.
- **ESCALATE** → STOP. Present the reflect report to the human. Do not proceed to Phase 3.

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

# 4. Review count check (engineer count must equal reviewer count)
echo "Engineer results: $(ls docs/results/TASK-*-result.md 2>/dev/null | wc -l | tr -d ' ')"
echo "Review reports:   $(ls docs/reports/TASK-*-review.md 2>/dev/null | wc -l | tr -d ' ')"
# If these numbers differ, reviews were skipped — go back to Phase 2.

# 5. Self-review files exist (engineer self-reviewed before submitting)
ls docs/results/TASK-*-self-review.md

# 6. Reflect report exists (Reflect Agent evaluated branch against requirement)
ls docs/reports/reflect-report.md
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
- [ ] **Review count matches?** — Engineer result count = Review report count. If not, reviews were skipped.
- [ ] **Bug-Fixer handled blocks?** — If any review verdict is BLOCKED, check for TASK-*-bugfix-result.md.
- [ ] **Self-review files exist?** — Check `docs/results/` for TASK-*-self-review.md files.
- [ ] **Reflect report exists?** — `docs/reports/reflect-report.md` must exist with a PROCEED/REVISE/REJECT/ESCALATE verdict.
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
- Do NOT use EnterPlanMode / PlanMode — use `Skill(skill: "superpowers:writing-plans")`
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
| Reflect Agent | `mas:reflect-agent:reflect-agent` | Product-architect evaluation, writes to `docs/reports/` |
| ~~Orchestrator~~ | ~~`orchestrator`~~ | DEPRECATED — routing logic is inline in Step 4 |

## Lessons Learned

See `rules/agent-workflow.md` for battle-tested lessons from real sessions. Key meta-lesson: **prose instructions get skipped — structural constraints (tool removal, file-existence gates, exact tool call syntax) are harder to bypass.**
