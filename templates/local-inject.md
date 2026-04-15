# MAS Pipeline (local overlay)

> This file is installed to `~/.claude/projects/<project-path>/CLAUDE.md` and loaded
> alongside the team repo's own CLAUDE.md. It adds MAS agent routing without modifying
> the shared repo. Install via: `scripts/mas-local-install.sh <project-dir>`

## Project Type

- **has_ui:** false <!-- Change to true if this project has a UI. Activates UI/UX Designer agent in the pipeline. -->

## Mandatory Workflow

Before any implementation, you MUST follow this workflow. No code changes until the plan is reviewed and approved.

### The Pipeline

1. **Create isolated workspace** — git worktree on a new branch, run project setup, verify clean test baseline.
2. **Write the plan** — `Skill(skill: "superpowers:writing-plans")` — Break work into bite-sized tasks (2-5 min each). Explores codebase and clarifies requirements as part of planning. Do NOT use EnterPlanMode.
3. **Design first (if `has_ui: true`)** — `Agent(subagent_type: "mas:ui-ux-designer:ui-ux-designer")` — Component specs, state mapping, interaction flows, accessibility checklist.
4. **Execute (flat dispatch)** — Apply routing table, dispatch agents directly via `Agent()`. Route novel tasks through Researcher -> Differential Reviewer -> Engineer. Known patterns go directly to Engineer. Batch engineers (max 5 concurrent), then batch reviewers (max 3 tasks each). Bug-Fixer if blocked. Reflect Agent checks delivery against original intent. Max 5 agents running simultaneously. Templates in `templates/dispatch-templates.md`.
5. **Verify** — `Skill(skill: "mas:verification")` — Artifact gate + all tests pass, lint clean, typecheck clean, no debug artifacts.
6. **Finish the branch** — `Skill(skill: "mas:finishing-branch")` — Verify tests pass, present options (merge/PR/keep/discard), clean up worktree.

### Agent Routing Table

**CRITICAL: Always use namespaced agent types. Never dispatch bare names like `"engineer"` or `"reviewer"`.**

| Task Type | Agent | `subagent_type` |
|-----------|-------|-----------------|
| Implementation | Engineer | `mas:engineer:engineer` |
| Code review | Reviewer | `mas:reviewer:reviewer` |
| Scope/intent check | Reflect Agent | `mas:reflect-agent:reflect-agent` |
| Bug fix from review | Bug-Fixer | `mas:bug-fixer:bug-fixer` |
| Novel/uncertain task | Researcher | `mas:researcher:researcher` |
| Stress-test proposal | Differential Reviewer | `mas:differential-reviewer:differential-reviewer` |
| UI/UX design | UI/UX Designer | `mas:ui-ux-designer:ui-ux-designer` |
| Task decomposition | Orchestrator | `mas:orchestrator:orchestrator` |

### Dispatch Rules

- Engineer writes code via TDD. Always pass: task spec, research proposal (if any), design spec (if any), worktree path.
- Reviewer does two-phase review (business alignment + technical audit). Always pass: task spec, engineer result, worktree path.
- Reflect Agent runs after all reviews complete. Checks whether the branch solves the original problem. Does NOT review code quality.
- Bug-Fixer fixes exactly what the reviewer flagged. No feature work, no adjacent refactoring.
- Researcher explores approaches for novel tasks. Max 3 rounds via Research Convergence Protocol.
- Differential Reviewer stress-tests research proposals. Issues PROCEED/REVISE/REJECT/ESCALATE.
