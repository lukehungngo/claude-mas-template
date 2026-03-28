# Agent Dispatch Templates

This file contains all agent dispatch templates used by **Step 6 (Orchestrate)** in the dev-loop. The dev-loop reads the relevant template, fills in placeholders, and dispatches the agent directly.

**How to use:** For each task, find the appropriate template below, replace all `{placeholder}` values with actual content, and dispatch via `Agent()`.

---

## Output Directory Convention

All agent outputs follow a structured directory layout. When dispatching an agent, tell it where to write. When dispatching a downstream agent, tell it where to **read** its upstream input.

| Directory | What Goes Here | Written By | Read By |
|-----------|---------------|------------|---------|
| `docs/design/` | UI/UX design specs (`TASK-{id}-design.md`), HTML mockups | UI/UX Designer | Engineer (implements against spec) |
| `docs/plans/` | Research proposals (`TASK-{id}-research-r{round}.md`) | Researcher | Differential Reviewer, Engineer |
| `docs/reports/` | Review reports, differential reviews, bugfix results, requirements validation reports | Reviewer, Differential Reviewer, Bug-Fixer | Dev-loop, Bug-Fixer, Engineer |
| `docs/results/` | Implementation results (`TASK-{id}-result.md`) | Engineer | Reviewer, Dev-loop |
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
  - `Skill(skill: "property-based-testing")` — flag when property-based tests are needed (parsing, serialization, large input spaces)

  ## Reliability & Performance Checklist
  Check each area. Flag violations as P1 (likely issue) or P2 (potential issue):
  - **Error handling:** Are errors caught and handled at system boundaries? No swallowed exceptions? Fail-fast on invalid state?
  - **Resource cleanup:** Are connections, file handles, timers closed/released? Check try/finally or equivalent patterns.
  - **Concurrency:** Race conditions? Shared mutable state without synchronization? Deadlock potential?
  - **Unbounded operations:** Any loops/queries without limits? Pagination missing on list endpoints? Unbounded retries?
  - **N+1 queries:** Database queries inside loops? Missing joins or batch fetches?
  - **Input validation:** User input validated at system boundary? Size limits? Type checks?
  - **Security:** Injection risks (SQL, XSS, command)? Auth checks on protected operations? Secrets in code/logs?
  - **Timeout/retry:** External calls have timeouts? Retry with backoff? Circuit breaker for cascading failures?
  - **Memory:** Large objects held unnecessarily? Streaming vs loading entire payload? Cache eviction?

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
