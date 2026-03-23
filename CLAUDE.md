# {{PROJECT_NAME}}

{{One paragraph describing what this project does.}}

## Build & Test

```bash
{{install-command}}           # dev install
{{test-command}}              # run tests
{{lint-command}}              # lint
{{format-command}}            # format
{{typecheck-command}}         # type check
{{build-command}}             # build
```

## Code Style

- {{Language version, e.g. Python 3.10+, TypeScript 5.x, Go 1.22}}
- {{Key libraries and versions, e.g. Pydantic v2, Zod, etc.}}
- {{Testing framework, e.g. pytest, vitest, go test}}
- {{Linter/formatter, e.g. Ruff, ESLint+Prettier, golangci-lint}}

## Project Type

- **has_ui:** {{true | false}} <!-- Set to true if this project has a user interface (web, mobile, desktop). When true, the UI/UX Designer agent is activated in the pipeline. When false, all UI routing is skipped. -->

## Architecture Invariants

These are non-negotiable — violating any of these is a P0:

1. **{{Invariant 1}}** — {{Why it matters}}
2. **{{Invariant 2}}** — {{Why it matters}}
3. **{{Invariant 3}}** — {{Why it matters}}

## Core Flow

```
{{Describe your system's main data flow}}
  → {{step 1}}
  → {{step 2}}
  → {{step 3}}
  → {{step 4}}
```

## Key Gotchas

- **{{Gotcha 1}}** — {{How to handle it}}
- **{{Gotcha 2}}** — {{How to handle it}}

## Mandatory Workflow

Before any implementation, you MUST follow this workflow. No code changes until the plan is reviewed and approved.

### The Pipeline

1. **Brainstorm first** — `Skill(skill: "ask-questions")` — Refine rough ideas through questions, explore alternatives, present design for validation.
2. **Create isolated workspace** — git worktree on a new branch, run project setup, verify clean test baseline.
3. **Explore the codebase** — `Agent(subagent_type: "Explore")` — Scan for relevant patterns, existing implementations, integration points before planning.
4. **Write the plan** — `Skill(skill: "writing-plans")` — Break work into bite-sized tasks (2-5 min each). Do NOT use EnterPlanMode.
5. **Design first (if `has_ui: true`)** — `Agent(subagent_type: "ui-ux-designer")` — Component specs, state mapping, interaction flows, accessibility checklist.
6. **Orchestrate** — `Agent(subagent_type: "orchestrator")` — PM dispatches Researcher, Engineer, Reviewer, Bug-Fixer. Orchestrator has no Bash — it can only read and dispatch agents.
7. **Validate requirements** — `Agent(subagent_type: "reviewer")` — Holistic PRD check. Loops back to step 6 on GAPS FOUND (max 3 cycles).
8. **Verify** — `Skill(skill: "verification")` — All tests pass, lint clean, typecheck clean, no debug artifacts.
9. **Finish the branch** — `Skill(skill: "finishing-branch")` — Verify tests pass, present options (merge/PR/keep/discard), clean up worktree.
