# Agent Dispatch Templates

This file contains all agent dispatch templates used by **Step 4 (Execute)** in the dev-loop. The dev-loop reads the relevant template, fills in placeholders, and dispatches the agent directly.

**How to use:** For each task, find the appropriate template below, replace all `{placeholder}` values with actual content, and dispatch via `Agent()`.

**Naming rule:** All agent `subagent_type` values use the `mas:` plugin prefix: `mas:{slug}:{slug}`. Never use bare names like `"engineer"` — always use `"mas:engineer:engineer"`. The templates below show the correct names; copy them exactly.

**Concurrency limit:** Max **5 concurrent agents** (platform limit). If dispatching more than 5 non-overlapping tasks, batch them in groups of 5 — wait for the current batch to complete before starting the next.

---

## Output Directory Convention

All agent outputs follow a structured directory layout. When dispatching an agent, tell it where to write. When dispatching a downstream agent, tell it where to **read** its upstream input.

| Directory | What Goes Here | Written By | Read By |
|-----------|---------------|------------|---------|
| `docs/design/` | UI/UX design specs (`TASK-{id}-design.md`), HTML mockups | UI/UX Designer | Engineer (implements against spec) |
| `docs/plans/` | Research proposals (`TASK-{id}-research-r{round}.md`) | Researcher | Differential Reviewer, Engineer |
| `docs/reports/` | Review reports, differential reviews, bugfix results, requirements validation reports, `reflect-report.md` | Reviewer, Differential Reviewer, Bug-Fixer, Reflect Agent | Dev-loop (Phase 3), Bug-Fixer, Engineer |
| `docs/results/` | Implementation results (`TASK-{id}-result.md`), self-reviews (`TASK-{id}-self-review.md`) | Engineer | Reviewer, Dev-loop |
| `docs/superpowers/plans/` | Implementation plans | superpowers:writing-plans | All agents |
| `docs/superpowers/reports/` | Delivery reports | Dev-loop, Bug-fix | Dev-loop |

---

## 1. Researcher Dispatch

```
Agent(
  subagent_type: "mas:researcher:researcher",
  prompt: """
  ## Task
  {paste the task from the plan}

  ## Round
  {N} of 3
  {If N > 1: paste prior proposals and differential reviews}

  ## Working Directory
  {worktree path}

  ## Output
  Write your proposal to docs/plans/TASK-{id}-research-r{N}.md
  """
)
```

---

## 2. Differential Reviewer Dispatch

```
Agent(
  subagent_type: "mas:differential-reviewer:differential-reviewer",
  prompt: """
  ## Research Proposal
  {paste proposal from docs/plans/TASK-{id}-research-r{N}.md}

  ## Round
  {N} of 3
  {If N > 1: paste prior proposals and differential reviews}

  ## Working Directory
  {worktree path}

  ## Output
  Write your review to docs/reports/TASK-{id}-differential-r{N}.md
  Issue verdict: PROCEED / REVISE / REJECT / ESCALATE
  """
)
```

---

## 3. Engineer Dispatch

```
Agent(
  subagent_type: "mas:engineer:engineer",
  prompt: """
  ## Task
  {paste the task from the plan}

  ## Research Proposal (if applicable)
  {paste approved proposal, or "N/A -- known pattern"}

  ## Design Spec (if applicable)
  {paste design spec path, or "N/A"}

  ## Skills (use these during implementation)
  - `Skill(skill: "se-principles")` — consult before designing types/interfaces
  - `Skill(skill: "superpowers:test-driven-development")` — follow TDD: failing test first, then minimal code

  ## Pre-completion Gate (MANDATORY)
  Before writing your result file, you MUST:
  1. Run lint, typecheck, and ALL tests (not just new ones)
  2. Review your own diff for debug artifacts, TODOs, and commented-out code
  3. Write self-review to docs/results/TASK-{id}-self-review.md
  Skipping this gate is the #1 cause of review failures.

  ## Working Directory
  {worktree path}

  ## Output
  Write your result to docs/results/TASK-{id}-result.md
  """
)
```

---

## 4. Reviewer Dispatch

```
Agent(
  subagent_type: "mas:reviewer:reviewer",
  prompt: """
  depth: standard

  ## Task
  {paste the task from the plan}

  ## Engineer Result
  {paste from docs/results/TASK-{id}-result.md}

  ## Research Proposal (if applicable)
  {paste approved proposal, or "N/A"}

  ## Skills (use during review)
  - `Skill(skill: "se-principles")` — check design quality against SOLID, DRY, KISS
  - `Skill(skill: "reliability-review")` — check reliability, performance, and security (error handling, concurrency, N+1, input validation, timeouts, memory)
  - `Skill(skill: "property-based-testing")` — flag when property-based tests are needed (parsing, serialization, large input spaces)

  ## Duplication Audit
  Search the codebase for:
  - **Code duplication:** Same logic in multiple places? Extract shared utility.
  - **Intent duplication:** Multiple implementations of the same problem? Consolidate.
  - **Knowledge duplication:** Business rules, constants, config hardcoded in multiple locations? Single source of truth.

  ## Working Directory
  {worktree path}

  ## Output
  Write your review to docs/reports/TASK-{id}-review.md
  Issue verdict: APPROVED / APPROVED WITH CHANGES / BLOCKED
  """
)
```

---

## 5. Bug-Fixer Dispatch

```
Agent(
  subagent_type: "mas:bug-fixer:bug-fixer",
  prompt: """
  ## Reviewer Report
  {paste from docs/reports/TASK-{id}-review.md}

  ## Task
  {paste the task from the plan}

  ## Skills (use during bug fixing)
  - `Skill(skill: "superpowers:test-driven-development")` — reproduction test FIRST, then minimal fix
  - `Skill(skill: "superpowers:systematic-debugging")` — if root cause unclear after reproduction test

  ## Working Directory
  {worktree path}

  ## Output
  Write your result to docs/reports/TASK-{id}-bugfix-result.md
  """
)
```

---

## 6. UI/UX Designer Dispatch (has_ui: true only)

**Only dispatch this agent if `has_ui: true` in CLAUDE.md.** If `has_ui: false`, treat UI-related tasks as regular Engineer tasks.

```
Agent(
  subagent_type: "mas:ui-ux-designer:ui-ux-designer",
  prompt: """
  ## Task
  {paste the task from the plan}

  ## Working Directory
  {worktree path}

  ## Output
  Write design spec to docs/design/TASK-{id}-design.md
  Write HTML mockup to docs/design/TASK-{id}-mockup.html (if applicable)
  """
)
```

---

## 7. Research Convergence Protocol (max 3 rounds)

Use this protocol for tasks routed through the Researcher path. It ensures research converges before implementation begins.

```
Round N (N = 1, 2, or 3):
  1. Dispatch Researcher (template #1 above)
  2. Wait for proposal at docs/plans/TASK-{id}-research-r{N}.md
  3. Dispatch Differential Reviewer (template #2 above)
  4. Read verdict from docs/reports/TASK-{id}-differential-r{N}.md:
     - PROCEED -> exit loop, dispatch Engineer with approved proposal
     - REVISE (N < 3) -> continue to round N+1
     - REJECT (N < 3) -> continue to round N+1 (Researcher must pivot)
     - REJECT/REVISE (N = 3) -> ESCALATE to human
     - ESCALATE -> present all rounds to human, stop
```

---

## 8. Batch Engineer + Batch Review Dispatch

**This is the preferred dispatch method when executing multiple implementation tasks.** It maximizes throughput by dispatching engineers in parallel and grouping reviews. Use individual templates #3 and #4 only for edge cases (e.g., re-reviewing after a bug fix without re-running the engineer).

**Parameters:**
- `MAX_PARALLEL` — see Runtime Configuration in dev-loop (default 5). Never more than 5 agents simultaneously.
- `TASKS_PER_REVIEWER` — see Runtime Configuration in dev-loop (default 3). Each reviewer handles up to this many tasks.

### Step 1 — Batch Engineer Dispatch

Dispatch up to MAX_PARALLEL engineers in parallel for non-overlapping tasks. If you have more than 5 tasks, batch them in groups of 5 and wait for each group before starting the next.

```
# Dispatch all engineers in parallel (up to 5 at a time):

Agent(
  subagent_type: "mas:engineer:engineer",
  prompt: """
  ## Task
  {paste the task from the plan}

  ## Research Proposal (if applicable)
  {paste approved proposal, or "N/A -- known pattern"}

  ## Design Spec (if applicable)
  {paste design spec path, or "N/A"}

  ## Skills (use these during implementation)
  - `Skill(skill: "se-principles")` — consult before designing types/interfaces
  - `Skill(skill: "superpowers:test-driven-development")` — follow TDD: failing test first, then minimal code

  ## Working Directory
  {worktree path}

  ## Output
  Write your result to docs/results/TASK-{id1}-result.md
  """
)

Agent(
  subagent_type: "mas:engineer:engineer",
  prompt: """
  ## Task
  {paste the task from the plan}
  ... (same structure as above)

  ## Output
  Write your result to docs/results/TASK-{id2}-result.md
  """
)

# ... repeat for each task, up to MAX_PARALLEL (5) concurrent agents
```

### Step 2 — Wait and Read Results

Wait for all engineers to finish. Read each result file:

```
Read(file_path: "{worktree path}/docs/results/TASK-{id1}-result.md")
Read(file_path: "{worktree path}/docs/results/TASK-{id2}-result.md")
# ... read all result files
```

If any result file does not exist, that engineer dispatch failed -- investigate before proceeding. Do not continue to review until all engineers have succeeded or failures are understood.

### Step 3 — Batch Review Dispatch

Split tasks into groups of TASKS_PER_REVIEWER (default 3). Dispatch 1 reviewer per group. Each reviewer receives the tasks AND engineer results for its group.

```
# Group 1: tasks {id1}, {id2}, {id3}

Agent(
  subagent_type: "mas:reviewer:reviewer",
  prompt: """
  depth: standard

  ## Tasks to Review
  You are reviewing 3 tasks as a batch. Review each independently.

  ### Task 1: TASK-{id1}
  #### Task
  {paste the task from the plan}
  #### Engineer Result
  {paste from docs/results/TASK-{id1}-result.md}

  ### Task 2: TASK-{id2}
  #### Task
  {paste the task from the plan}
  #### Engineer Result
  {paste from docs/results/TASK-{id2}-result.md}

  ### Task 3: TASK-{id3}
  #### Task
  {paste the task from the plan}
  #### Engineer Result
  {paste from docs/results/TASK-{id3}-result.md}

  ## Research Proposals (if applicable)
  {paste approved proposals for any tasks that went through research, or "N/A"}

  ## Skills (use during review)
  - `Skill(skill: "se-principles")` — check design quality against SOLID, DRY, KISS
  - `Skill(skill: "reliability-review")` — check reliability, performance, and security (error handling, concurrency, N+1, input validation, timeouts, memory)
  - `Skill(skill: "property-based-testing")` — flag when property-based tests are needed (parsing, serialization, large input spaces)

  ## Duplication Audit
  Search the codebase for:
  - **Code duplication:** Same logic in multiple places? Extract shared utility.
  - **Intent duplication:** Multiple implementations of the same problem? Consolidate.
  - **Knowledge duplication:** Business rules, constants, config hardcoded in multiple locations? Single source of truth.

  ## Working Directory
  {worktree path}

  ## Output
  Write a separate review for each task:
  - docs/reports/TASK-{id1}-review.md
  - docs/reports/TASK-{id2}-review.md
  - docs/reports/TASK-{id3}-review.md
  Issue verdict per task: APPROVED / APPROVED WITH CHANGES / BLOCKED
  """
)

# Group 2: tasks {id4}, {id5} (dispatch in parallel with Group 1)
# ... same pattern, up to MAX_PARALLEL reviewer agents
```

### Step 4 — Handle Verdicts

Read all review verdicts:

```
Read(file_path: "{worktree path}/docs/reports/TASK-{id1}-review.md")
Read(file_path: "{worktree path}/docs/reports/TASK-{id2}-review.md")
# ... read all review files
```

For each task:

- **APPROVED** -- task is done
- **APPROVED WITH CHANGES** -- task is done (non-blocking suggestions noted)
- **BLOCKED** -- dispatch Bug-Fixer (template #5) for that specific task, then re-review that task only (use individual template #4)

### Step 5 — Cross-Task Review (optional)

If CROSS_TASK_REVIEW is enabled (see Runtime Configuration in dev-loop — varies by model), dispatch 1 holistic reviewer to check for cross-cutting concerns across all approved results.

```
Agent(
  subagent_type: "mas:reviewer:reviewer",
  prompt: """
  depth: standard

  ## Cross-Task Review
  You are performing a holistic review across all approved task results.
  Check for: duplication across tasks, integration gaps, pattern consistency.

  ## Approved Results
  {paste all approved TASK-{id}-result.md contents}

  ## Tasks
  {paste all tasks from the plan for context}

  ## Working Directory
  {worktree path}

  ## Output
  Write your cross-task review to docs/reports/cross-task-review.md
  Flag any issues that individual reviews may have missed.
  """
)
```

---

## 9. Reflect Agent Dispatch

**Dispatch at Phase 2E — after all task reviews (including cross-task review if applicable) are complete.** This agent evaluates whether the branch as a whole solves the original problem. It does not review code quality — that is the Reviewer's job.

```
Agent(
  subagent_type: "mas:reflect-agent:reflect-agent",
  prompt: """
  ## Original User Requirement
  {paste the original user requirement VERBATIM — do not paraphrase}

  ## Plan
  {paste the implementation plan from docs/superpowers/plans/}

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
