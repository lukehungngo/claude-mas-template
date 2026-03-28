# Claude Code Multi-Agent System Template

Install this plugin and Claude Code becomes a team of 7 AI agents that plan, code, review, and ship for you — with built-in TDD, code review, and quality gates.

Extracted from [AgentWall](https://github.com/anthropics/agentwall)'s battle-tested configuration.

## What's Included

| Component     | Count | Description                                                                                                  |
| ------------- | ----- | ------------------------------------------------------------------------------------------------------------ |
| **Agents**    | 7     | orchestrator, engineer, reviewer, researcher, differential-reviewer, bug-fixer, ui-ux-designer (conditional) |
| **Skills**    | 13    | 8 core workflow skills + 5 extended engineering skills                                                       |
| **Rules**     | 4     | honesty-first, severity-discipline, meta-rules guide, agent workflow lessons                                 |
| **Commands**  | 4     | bootstrap, dev-loop, bug-fix, release                                                                        |
| **Hooks**     | 2     | PostToolUse lint, Stop quality gate                                                                          |
| **Templates** | 3     | task-spec, review-report, dispatch-templates                                                                  |

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and logged in

## Install

### Option A: Claude Code Plugin (recommended)

1. Add the marketplace and install — two commands in your terminal:

```bash
claude plugin marketplace add lukehungngo/claude-mas-template
claude plugin install mas@luke-plugins
```

2. Then bootstrap your project:

```bash
claude "/mas:bootstrap"
```

3. Continue to fill the remaining suggested TODOs (Architecture Invariants, Core Flow, Key Gotchas) in `CLAUDE.md` and `.claude/rules/*` to complete the setup.

> **Try one-shot prompt (bypass all permissions):**
>
> ```bash
> claude --dangerously-skip-permissions "/mas:dev-loop --auto Build a complete CRUD API for products"
> ```

Update plugin:

```bash
claude plugin marketplace update luke-plugins     # refresh marketplace cache
claude plugin update mas@luke-plugins             # update to latest version
claude "/mas:bootstrap --update"                  # sync new agents/skills into your project
```

The `--update` flag smart-merges the new plugin version into your project:

- **Overwrites** framework files (agents, skills, commands, templates) with new versions
- **Re-applies** your project's placeholder values (test commands, project name, etc.)
- **Never touches** your `CLAUDE.md`, `settings.json`, or other user-owned files
- **Asks before overwriting** hooks if you've made custom changes
- **Skips customized rules** by default (no placeholders = user-owned). Use `--force-rules` to override per file
- **Adds** any new agents or skills introduced in the update

Uninstall:

```bash
claude plugin uninstall mas
claude plugin marketplace remove luke-plugins
```

<details>
<summary><strong>Option B: Manual install (git clone)</strong></summary>

For users who want to customize agents/skills locally. Local install gives **unprefixed** commands (`/dev-loop`, `/bootstrap`, etc.).

```bash
git clone https://github.com/lukehungngo/claude-mas-template /tmp/mas
mkdir -p .claude
cp -r /tmp/mas/agents /tmp/mas/commands /tmp/mas/skills /tmp/mas/hooks /tmp/mas/rules /tmp/mas/templates .claude/
cp /tmp/mas/.claude/settings.json .claude/
cp /tmp/mas/CLAUDE.md .
rm -rf /tmp/mas

claude "/bootstrap"
```

</details>

## Agent Architecture

```
                     ┌──────────┐
                     │ dev-loop │  Flat dispatch — drives the pipeline directly
                     └────┬─────┘
                          │
    ┌────────────┬────────┼────────┬─────────────┐
    │            │        │        │             │
    ▼            ▼        ▼        ▼             ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐
│Researcher│ │UI/UX     │ │Engineer  │ │Bug-Fixer │ │Diff.Reviewer │
│          │ │Designer* │ │          │ │          │ │(adversarial) │
└────┬─────┘ └────┬─────┘ └──────────┘ └──────────┘ └──────────────┘
     │             │             ▲
     │             └─────────────┤ (design spec → impl)
     └───────────────────────────┤ (research → impl)
                                 │
                          ┌──────┴──────┐
                          │   Reviewer   │
                          └─────────────┘

  * UI/UX Designer only active when has_ui: true in CLAUDE.md
```

## Workflow Pipeline

```
1. ASK QUESTIONS  →  Clarify requirements
2. GIT WORKTREE   →  Isolated branch
3. WRITE PLAN     →  Bite-sized tasks (2-5 min each)
4. DESIGN (UI)*   →  Component specs, states, a11y  (* only if has_ui: true)
5. EXECUTE (TDD)  →  Subagent per task, RED-GREEN-REFACTOR
6. REVIEW         →  Two-phase (business + technical)
7. FINISH         →  Verify, merge/PR, cleanup
```

## File Structure

```
claude-mas-template/
├── .claude-plugin/
│   ├── plugin.json                        # Plugin metadata
│   └── marketplace.json                   # Self-hosted marketplace manifest
├── .claude/
│   └── settings.json                      # Permissions + hooks (for git clone)
├── CLAUDE.md                              # Project context template (customize)
├── agents/
│   ├── orchestrator/CLAUDE.md             # Routes tasks to agents
│   ├── engineer/CLAUDE.md                 # Implements with TDD
│   ├── reviewer/CLAUDE.md                 # Two-phase code review
│   ├── researcher/CLAUDE.md               # Explores approaches
│   ├── differential-reviewer/CLAUDE.md    # Stress-tests proposals
│   ├── bug-fixer/CLAUDE.md                # TDD bug fixes
│   └── ui-ux-designer/CLAUDE.md           # Component specs & a11y (has_ui: true)
├── commands/
│   ├── bootstrap.md                       # Auto-detect stack, fill placeholders
│   ├── bug-fix.md                         # Focused bug-fix loop
│   ├── dev-loop.md                        # Full development workflow
│   └── release.md                         # Release checklist
├── hooks/
│   ├── lint.sh                            # Auto-lint on file edit
│   └── pre-stop-gate.sh                   # Quality summary on stop
├── rules/
│   ├── honesty-first.md                   # Metrics integrity
│   ├── severity-discipline.md             # Severity classification
│   ├── meta-rules-guide.md                # How to write new rules
│   └── agent-workflow.md                  # Lessons learned from battle testing
├── skills/
│   ├── ask-questions/SKILL.md
│   ├── writing-plans/SKILL.md
│   ├── executing-plans/SKILL.md
│   ├── subagent-driven-development/
│   │   ├── SKILL.md
│   │   ├── implementer-prompt.md
│   │   ├── spec-reviewer-prompt.md
│   │   └── code-quality-reviewer-prompt.md
│   ├── test-driven-development/SKILL.md
│   ├── requesting-code-review/
│   │   ├── SKILL.md
│   │   └── code-reviewer.md
│   ├── receiving-code-review/SKILL.md
│   ├── finishing-branch/SKILL.md
│   ├── verification/SKILL.md
│   ├── systematic-debugging/SKILL.md
│   ├── property-based-testing/SKILL.md
│   ├── se-principles/SKILL.md
│   └── differential-review/SKILL.md
└── templates/
    ├── task-spec.md
    ├── review-report.md
    └── dispatch-templates.md
```

## Usage

### Plugin Commands (available immediately after install)

Run in your terminal:

```bash
claude "/mas:bootstrap"
claude "/mas:dev-loop Add user authentication with JWT"
claude "/mas:bug-fix Fix: login returns 401 when password has special chars"
claude "/mas:release v1.2.0"

# Non-stop autonomous mode — skips all human checkpoints
claude "/mas:dev-loop Add user authentication with JWT --auto"
```

### Skills

All 13 skills are available via the `mas:` prefix. Open Claude Code (`claude` in terminal), then type these inside the chat:

```
/mas:ask-questions I need to add OAuth2 support
/mas:writing-plans Plan: migrate database to PostgreSQL
/mas:subagent-driven-development Execute the migration plan
/mas:executing-plans Execute the migration plan
/mas:test-driven-development Implement the rate limiter module
/mas:requesting-code-review Review the auth middleware changes
/mas:receiving-code-review Fix issues from the review report
/mas:finishing-branch
/mas:verification
/mas:systematic-debugging Users get 500 on /api/payments
/mas:property-based-testing Test the URL parser
/mas:differential-review Review the caching strategy proposal
/mas:se-principles Should I use inheritance or composition here?
```

### Direct Agent Usage

You don't always need the full `dev-loop` pipeline. You can bypass the Orchestrator and directly "hire" specific specialized plugin agents from your terminal for targeted tasks.

**When to use which agent:**

*   **The Engineer (TDD Implementation)**
    Use when you have a clear task and want it built with strict Test-Driven Development.
    ```bash
    claude --agent mas:engineer:engineer "Implement TASK-003: Add rate limiting middleware"
    ```

*   **The Bug-Fixer (Surgical Fixes)**
    Use when you have a specific bug. It will write a failing test to reproduce it, then fix the code without touching adjacent features.
    ```bash
    claude --agent mas:bug-fixer:bug-fixer "Fix: login returns 401 when password has special chars"
    ```

*   **The Reviewer (Harsh Code Review)**
    Use before opening a PR. It performs a two-phase review (business alignment + technical audit) and flags P0/P1 blockers.
    ```bash
    claude --agent mas:reviewer:reviewer "Review the recent changes in src/auth/"
    ```

*   **The Researcher (Exploration & Trade-offs)**
    Use when you need to figure out *how* to build something before actually writing code.
    ```bash
    claude --agent mas:researcher:researcher "What are the best options for real-time notifications in our stack?"
    ```

*   **The Differential Reviewer (Adversarial Stress-Test)**
    Use to stress-test a proposed architecture or research plan. It actively tries to find reasons why your idea will fail in production.
    ```bash
    claude --agent mas:differential-reviewer:differential-reviewer "Stress-test the Redis caching proposal in docs/plans/TASK-001.md"
    ```

*   **The UI/UX Designer (Component Specs & A11y)**
    Use when you need a structured design spec, state mapping, and accessibility checklist before building a frontend component.
    ```bash
    claude --agent mas:ui-ux-designer:ui-ux-designer "Design the settings page layout and interaction flow"
    ```

> **Note:** The Orchestrator agent is deprecated. For large epics, use `dev-loop` which dispatches agents directly via flat dispatch.

> **Pro-tip for uninterrupted runs:**
> If you trust the agent and want to grab a coffee while it works, append `--dangerously-skip-permissions` to bypass the prompts asking for permission to run tests or edit files.
> ```bash
> claude --dangerously-skip-permissions --agent mas:engineer:engineer "Refactor the database pool"
> ```

### Example Workflows

**1. Full pipeline — run in terminal, one command does everything:**

```bash
claude "/mas:dev-loop --auto Implement WebSocket support for real-time updates"
```

**2. Plan then execute — open Claude Code, type in chat:**

```
/mas:writing-plans Plan: add pagination to all list endpoints
/mas:subagent-driven-development Execute the pagination plan
```

**3. Debug, fix, review — open Claude Code, type in chat:**

```
/mas:systematic-debugging Why are emails not sending?
/mas:bug-fix Fix the SMTP timeout
/mas:requesting-code-review Review the email fix
```

## Acknowledgments

Includes skills adapted from [Obra Superpowers](https://github.com/obra/superpowers) (MIT License).

## License

MIT
