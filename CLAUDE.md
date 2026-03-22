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

- **has_ui:** {{true | false}}  <!-- Set to true if this project has a user interface (web, mobile, desktop). When true, the UI/UX Designer agent is activated in the pipeline. When false, all UI routing is skipped. -->

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

1. **Brainstorm first** (`/ask-questions`) — Refine rough ideas through questions, explore alternatives, present design for validation.
2. **Create isolated workspace** (git worktree) — Create isolated workspace on a new branch, run project setup, verify clean test baseline.
3. **Write the plan** (`/writing-plans`) — Break work into bite-sized tasks (2-5 min each). Every task has exact file paths, complete code, verification steps.
4. **Design first (if `has_ui: true`)** — For UI tasks, the UI/UX Designer produces component specs, state mapping, interaction flows, and accessibility checklist before any code is written.
5. **Execute the plan** (`/subagent-driven-development`) — Dispatch fresh subagent per task with two-stage review (spec compliance, then code quality).
6. **TDD during implementation** (`/test-driven-development`) — Enforce RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit.
7. **Review between tasks** (`/requesting-code-review`) — Review against plan, report issues by severity. Critical issues block progress.
8. **Finish the branch** (`/finishing-branch`) — Verify tests pass, present options (merge/PR/keep/discard), clean up worktree.
