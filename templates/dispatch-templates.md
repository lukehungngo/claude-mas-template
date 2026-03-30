# Agent Dispatch Templates

This file contains all agent dispatch templates used by **Step 4 (Execute)** in the dev-loop. The dev-loop reads the relevant template, fills in placeholders, and dispatches the agent directly.

**How to use:** For each task, find the appropriate template below, replace all `{placeholder}` values with actual content, and dispatch via `Agent()`.

**Concurrency limit:** Max **5 concurrent agents** (platform limit). If dispatching more than 5 non-overlapping tasks, batch them in groups of 5 — wait for the current batch to complete before starting the next.

---

## Output Directory Convention

All agent outputs follow a structured directory layout. When dispatching an agent, tell it where to write. When dispatching a downstream agent, tell it where to **read** its upstream input.

| Directory | What Goes Here | Written By | Read By |
|-----------|---------------|------------|---------|
| `docs/design/` | UI/UX design specs (`TASK-{id}-design.md`), HTML mockups | UI/UX Designer | Engineer (implements against spec) |
| `docs/plans/` | Research proposals (`TASK-{id}-research-r{round}.md`) | Researcher | Differential Reviewer, Engineer |
| `docs/reports/` | Review reports, differential reviews, bugfix results, requirements validation reports | Reviewer, Differential Reviewer, Bug-Fixer | Dev-loop, Bug-Fixer, Engineer |
| `docs/results/` | Implementation results (`TASK-{id}-result.md`), self-reviews (`TASK-{id}-self-review.md`) | Engineer | Reviewer, Dev-loop |
| `docs/tasks/pending/` | Task specs awaiting dispatch | Dev-loop | All agents (their assigned task) |
| `docs/tasks/in-progress/` | Task specs currently being worked | Dev-loop | -- |
| `docs/tasks/done/` | Completed task specs | Dev-loop | -- |
| `docs/tasks/blocked/` | Blocked task specs | Dev-loop | -- |

---

## 1. Researcher Dispatch

```
Agent(
  subagent_type: "mas:researcher:researcher",
  prompt: """
  ## Task Spec
  {paste full task spec from docs/tasks/pending/TASK-{id}.md}

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
  ## Task Spec
  {paste full task spec from docs/tasks/pending/TASK-{id}.md}

  ## Research Proposal (if applicable)
  {paste approved proposal, or "N/A -- known pattern"}

  ## Design Spec (if applicable)
  {paste design spec path, or "N/A"}

  ## Skills (use these during implementation)
  - `Skill(skill: "se-principles")` — consult before designing types/interfaces
  - `Skill(skill: "test-driven-development")` — follow TDD: failing test first, then minimal code

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
  ## Task Spec
  {paste full task spec}

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

  ## Task Spec
  {paste full task spec}

  ## Skills (use during bug fixing)
  - `Skill(skill: "test-driven-development")` — reproduction test FIRST, then minimal fix
  - `Skill(skill: "systematic-debugging")` — if root cause unclear after reproduction test

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
  ## Task Spec
  {paste full task spec}

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
  ## Task Spec
  {paste full task spec from docs/tasks/pending/TASK-{id1}.md}

  ## Research Proposal (if applicable)
  {paste approved proposal, or "N/A -- known pattern"}

  ## Design Spec (if applicable)
  {paste design spec path, or "N/A"}

  ## Skills (use these during implementation)
  - `Skill(skill: "se-principles")` — consult before designing types/interfaces
  - `Skill(skill: "test-driven-development")` — follow TDD: failing test first, then minimal code

  ## Working Directory
  {worktree path}

  ## Output
  Write your result to docs/results/TASK-{id1}-result.md
  """
)

Agent(
  subagent_type: "mas:engineer:engineer",
  prompt: """
  ## Task Spec
  {paste full task spec from docs/tasks/pending/TASK-{id2}.md}
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

Split tasks into groups of TASKS_PER_REVIEWER (default 3). Dispatch 1 reviewer per group. Each reviewer receives the task specs AND engineer results for its group.

```
# Group 1: tasks {id1}, {id2}, {id3}

Agent(
  subagent_type: "mas:reviewer:reviewer",
  prompt: """
  ## Tasks to Review
  You are reviewing 3 tasks as a batch. Review each independently.

  ### Task 1: TASK-{id1}
  #### Task Spec
  {paste full task spec for TASK-{id1}}
  #### Engineer Result
  {paste from docs/results/TASK-{id1}-result.md}

  ### Task 2: TASK-{id2}
  #### Task Spec
  {paste full task spec for TASK-{id2}}
  #### Engineer Result
  {paste from docs/results/TASK-{id2}-result.md}

  ### Task 3: TASK-{id3}
  #### Task Spec
  {paste full task spec for TASK-{id3}}
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
  ## Cross-Task Review
  You are performing a holistic review across all approved task results.
  Check for: duplication across tasks, integration gaps, pattern consistency.

  ## Approved Results
  {paste all approved TASK-{id}-result.md contents}

  ## Task Specs
  {paste all task specs for context}

  ## Working Directory
  {worktree path}

  ## Output
  Write your cross-task review to docs/reports/cross-task-review.md
  Flag any issues that individual reviews may have missed.
  """
)
```
