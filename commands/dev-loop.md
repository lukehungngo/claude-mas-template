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
  ├─ 2. Plan ─── Skill(skill: "superpowers:writing-plans") → docs/superpowers/plans/
  │
  ├─ 3. Design (if has_ui: true) ─── Agent(subagent_type: "mas:ui-ux-designer:ui-ux-designer")
  │
  ├─ 4. Execute (flat dispatch — you are the orchestrator)
  │       ├─ Route tasks from plan → Engineer / Researcher / Bug-Fixer
  │       ├─ Batch Engineer dispatch (up to MAX_PARALLEL concurrent)
  │       ├─ Batch Reviewer dispatch (TASKS_PER_REVIEWER per reviewer)
  │       ├─ Handle verdicts — APPROVED → done, BLOCKED → Bug-Fixer → re-review
  │       └─ Reflect Agent — evaluate branch against original requirement
  │
  ├─ 5. Verify ─── Skill(skill: "verification")
  ├─ 5.5 Report ─── Delivery report → docs/superpowers/reports/
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

**Check for existing brainstorm:** If `$ARGUMENTS` references a brainstorm doc (e.g., `docs/brainstorms/2026-04-15-topic.md`), read it first. The brainstorm contains the decomposed problem, assumptions challenged, and solution direction — use it as the primary input for the plan.

If no brainstorm exists and the requirement is vague, tell the human to run `/mas:brainstorm` first. Do NOT invoke `superpowers:brainstorming` — use `/mas:brainstorm` which applies first principles decomposition.

**Write the plan:**

```
Skill(skill: "superpowers:writing-plans")
```

This produces a structured implementation plan with tasks, file paths, verification commands, and dependency order. The plan saved to `docs/superpowers/plans/` is the source of truth for execution. The skill explores the codebase and clarifies requirements as needed — no separate exploration or clarification step.

**Do NOT use EnterPlanMode / PlanMode.** Use the `superpowers:writing-plans` skill which follows a specific template.

**IMPORTANT: Ignore the plan's execution handoff.** The plan header says "Use superpowers:subagent-driven-development." Do NOT invoke that skill. The dev-loop dispatches MAS agents directly (`mas:engineer:engineer`, `mas:reviewer:reviewer`, etc.) — those have specialized system prompts (TDD enforcement, deviation taxonomy, two-phase review) that generic superpowers agents lack. The plan is used for WHAT to build. The dev-loop controls HOW to execute.

- Interactive: present plan to human for approval before proceeding.
- `--auto`: approve plan automatically and proceed.

**GATE:** The plan exists in `docs/superpowers/plans/` with tasks, file paths, and verification commands.

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

#### Phase 1 — Route

Read the approved plan from Step 2. For each task in the plan, determine routing using the routing table below. Dispatch agents with the task content from the plan directly — do NOT create separate task spec files.

#### Routing Table

| Task Type | Route |
|-----------|-------|
| Novel approach needed | Researcher → Differential Reviewer (max 3 rounds) → Engineer |
| Known pattern exists | Engineer directly |
| Bug fix from review | Bug-Fixer |
| UI component (`has_ui: true`) | UI/UX Designer → Engineer |
| Refactor / cleanup | Engineer directly |

**Task Size → Pipeline Variant:**

Every task in the plan has a `size` field. Use it to select the pipeline variant before dispatching:

| Size | Pipeline | Skipped Steps |
|------|----------|---------------|
| `micro` | Engineer → quick review | No researcher. Reviewer `depth: quick`. Skip reflect (`echo "micro task" > docs/reports/.reflect-skipped`). Skip delivery report. |
| `standard` | Full pipeline | Nothing skipped. |
| `complex` | Researcher → Differential Reviewer → Engineer → deep review → reflect | Nothing skipped. Reviewer `depth: deep`. |

**Applying size:**
- Read each task's `size` field before dispatch. If absent, treat as `standard`.
- `micro` quick-review: set `depth: quick` in the reviewer prompt.
- `complex`: always run Research Convergence Protocol (template #7) regardless of routing table.

**Novel task criteria** (if ANY apply, route to Researcher):
1. No existing implementation of this pattern in the codebase
2. Algorithm/approach not yet used in this project
3. New system boundary the codebase hasn't interfaced with before
4. Competing approaches with non-obvious trade-offs
5. Similar task failed in a prior session (check `docs/reports/`)

If in doubt, route to Researcher.

**Novel routing pre-screen:** Before routing to Researcher, ask: "Can this task be solved with a 30-minute codebase read + one web search?" If yes — the answer is *discoverable*, not novel — route directly to Engineer and save research budget. Reserve Researcher for tasks where the *approach itself* is non-obvious and competing options have real trade-offs.

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

**Between-batch gate (BLOCKING):** Before dispatching the next engineer batch, verify all previous tasks are reviewed. Track dispatched engineer count and completed review count in-memory. If reviews < results: **STOP. Do not dispatch the next engineer batch.** Return to Phase 2C and dispatch reviewers for the unreviewed tasks. Only proceed when reviews equal results.

##### Phase 2C — Batch Reviewer Dispatch

Split completed tasks into groups of TASKS_PER_REVIEWER. Dispatch 1 reviewer per group. Each reviewer receives the tasks from the plan AND engineer results for its group. Dispatch up to MAX_PARALLEL reviewers concurrently.

Track `review_cycle` per task, starting at 0.

##### Phase 2D — Handle Verdicts

Read all review verdicts from `docs/reports/TASK-{id}-review.md`. For each task:

- **APPROVED** → done
- **APPROVED WITH CHANGES** → done (non-blocking)
- **BLOCKED** → increment `review_cycle`, then:
  - If `review_cycle < 2` → dispatch Bug-Fixer (template #5), then re-review that task only (use individual template #4)
  - If `review_cycle >= 2` → STOP. Write escalation to `docs/reports/TASK-{id}-escalation.md`. Present to human.

If CROSS_TASK_REVIEW is enabled (see Runtime Configuration), dispatch a cross-task integration reviewer after all individual reviews pass (template #8, Step 5).

##### Phase 2E — Reflect (DISPATCH EXACTLY ONCE)

**This agent runs ONCE per dev-loop execution.** Not once per task, not once per batch — once total, after ALL reviews are complete. In audited sessions, this agent was dispatched 2-14 times. That is wrong.

Trigger condition: ALL of these must be true before dispatching:
1. All tasks from the plan have been dispatched to engineers
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

  ## Completed Tasks
  {paste all tasks from the plan}

  ## Research Proposals (if applicable)
  {paste approved research proposals, or "N/A — no research phase"}

  ## Working Directory
  {worktree path}

  ## Spec Name
  {plan filename without extension, e.g. 2026-04-19-auth-feature}

  ## Output
  Write your report to docs/reports/{spec_name}-reflect-report.md
  Issue verdict: PROCEED / REVISE / REJECT / ESCALATE
  """
)
```

> **Intentional reflect skip:** If reflect is genuinely not needed (e.g., documentation-only changes, exploratory spike with no implementation decisions), create `docs/reports/.reflect-skipped` with a one-line reason before ending the session:
> ```bash
> echo "documentation update only — no implementation decisions to evaluate" > docs/reports/.reflect-skipped
> ```
> The `validate-pipeline.sh` Stop hook will accept this and exit 0 instead of blocking.

Read the verdict from `docs/reports/{spec_name}-reflect-report.md`. Handle as follows:

- **PROCEED** → continue to Step 5.
- **REVISE** → extract remediation tasks from the reflect report's identified gaps. Loop back to Phase 2A to implement them. **Max 1 remediation cycle** — if the second reflect verdict is still REVISE, escalate to human.
- **REJECT** → STOP. Present the reflect report to the human. Do not proceed to Step 5.
- **ESCALATE** → STOP. Present the reflect report to the human. Do not proceed to Step 5.

---

**Pre-Step 5 check:** Verify that:
1. Engineers were dispatched (you made Agent() calls with `mas:engineer:engineer`)
2. Reviewers were dispatched (you made Agent() calls with `mas:reviewer:reviewer`)
3. All review verdicts are APPROVED or APPROVED WITH CHANGES
4. Reflect agent was dispatched (or `.reflect-skipped` exists)

If any condition is false, go back to Step 4 and dispatch the missing agents. Do NOT create result/review files manually.

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

**GATE:** `docs/reports/verification-{branch}.md` must exist before proceeding to Step 5.5.

---

### Step 5.5 — Delivery Report

Write a delivery report to `docs/superpowers/reports/YYYY-MM-DD-{branch-name}.md` that validates what was delivered against the plan.

The report must contain:

````markdown
# Delivery Report: {branch-name}

**Plan:** `docs/superpowers/plans/{plan-file}.md`
**Date:** {YYYY-MM-DD}
**Branch:** {branch-name}

## Task Delivery

| # | Task (from plan) | Status | Evidence |
|---|-----------------|--------|----------|
| 1 | {task description} | DONE / PARTIAL / SKIPPED | {what was implemented, or why skipped} |
| 2 | ... | ... | ... |

## Deviations from Plan

{List any changes made that were not in the original plan, or plan items that were modified during execution. "None" if plan was followed exactly.}

## Verification Summary

- Lint: {PASS/FAIL}
- Typecheck: {PASS/FAIL}
- Tests: {PASS/FAIL} ({count})

## Verdict

{DELIVERED / PARTIAL / FAILED}
````

**GATE:** `docs/superpowers/reports/` contains a delivery report for this branch.

---

> **CHECKPOINT ASSERTION — Step 6 is mandatory**
>
> You are about to skip the finishing-branch skill. **STOP.**
> You MUST call `Skill(skill: "finishing-branch")` which presents options to the human.
> Do not `git merge` or `git worktree remove` manually.

---

### PIPELINE SELF-AUDIT (mandatory before finishing)

- [ ] **Plan exists?** — Check `docs/superpowers/plans/` for the plan file.
- [ ] **Engineers dispatched?** — Confirm Agent() calls with `mas:engineer:engineer` in this session.
- [ ] **Reviewers dispatched?** — Confirm Agent() calls with `mas:reviewer:reviewer` in this session.
- [ ] **Reflect dispatched?** — `docs/reports/{spec_name}-reflect-report.md` exists (or `.reflect-skipped` with reason).
- [ ] **Delivery report exists?** — Check `docs/superpowers/reports/` for the delivery report.
- [ ] **Verification report exists?** — `docs/reports/verification-{branch}.md` exists.

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
- The plan and delivery report are the user-facing contract. Internal artifacts (docs/results/, docs/reports/TASK-*) are used during execution but cleaned up before merge.

For battle-tested lessons, see `rules/agent-workflow.md`.

## Agent Reference

| Agent | subagent_type | Role |
|-------|--------------|------|
| Engineer | `mas:engineer:engineer` | TDD implementation |
| Reviewer | `mas:reviewer:reviewer` | Two-stage review |
| Researcher | `mas:researcher:researcher` | Explores approaches |
| Differential Reviewer | `mas:differential-reviewer:differential-reviewer` | Stress-tests proposals |
| Bug-Fixer | `mas:bug-fixer:bug-fixer` | TDD fixes from reviewer reports |
| UI/UX Designer | `mas:ui-ux-designer:ui-ux-designer` | Design specs + HTML mockups (has_ui: true only) |
| Reflect Agent | `mas:reflect-agent:reflect-agent` | Product-architect evaluation |
| ~~Orchestrator~~ | ~~`orchestrator`~~ | DEPRECATED — routing logic is inline in Step 4 |

## Lessons Learned

See `rules/agent-workflow.md` for battle-tested lessons from real sessions. Key meta-lesson: **prose instructions get skipped — structural constraints (tool removal, file-existence gates, exact tool call syntax) are harder to bypass.**
