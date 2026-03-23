# Claude Code Multi-Agent System Template

Install this plugin and Claude Code becomes a team of 7 AI agents that plan, code, review, and ship for you — with built-in TDD, code review, and quality gates.

Extracted from [AgentWall](https://github.com/anthropics/agentwall)'s battle-tested configuration.

## What's Included

| Component     | Count | Description                                                                                                  |
| ------------- | ----- | ------------------------------------------------------------------------------------------------------------ |
| **Agents**    | 7     | orchestrator, engineer, reviewer, researcher, differential-reviewer, bug-fixer, ui-ux-designer (conditional) |
| **Skills**    | 13    | 8 core workflow skills + 5 extended engineering skills                                                       |
| **Rules**     | 4     | honesty-first, severity-discipline, architecture invariants, meta-rules guide                                |
| **Commands**  | 4     | bootstrap, dev-loop, new-feature, release                                                                    |
| **Hooks**     | 2     | PostToolUse lint, Stop quality gate                                                                          |
| **Templates** | 2     | task-spec, review-report                                                                                     |

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and logged in

## Install

### Option A: Claude Code Plugin (recommended)

Add the marketplace and install — two commands in your terminal:

```bash
claude plugin marketplace add lukehungngo/claude-mas-template
claude plugin install mas@luke-plugins
```

Then bootstrap your project:

```bash
claude "/mas:bootstrap"
```

Continue to fill the remaining suggested TODOs (Architecture Invariants, Core Flow, Key Gotchas in `CLAUDE.md`) to complete the setup.

> **Then try one-shot prompt (bypass all permissions):**
>
> ```bash
> claude --dangerously-skip-permissions "/dev-loop Build a complete CRUD API for products"
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
                    ┌─────────────┐
                    │ Orchestrator │  Decomposes, dispatches, verifies
                    └──────┬──────┘
                           │
     ┌─────────────┬───────┼───────┬─────────────┐
     │             │       │       │             │
     ▼             ▼       ▼       ▼             ▼
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
│   ├── dev-loop.md                        # Full development workflow
│   ├── new-feature.md                     # Scaffold new feature
│   └── release.md                         # Release checklist
├── hooks/
│   ├── lint.sh                            # Auto-lint on file edit
│   └── pre-stop-gate.sh                   # Quality summary on stop
├── rules/
│   ├── honesty-first.md                   # Metrics integrity
│   ├── severity-discipline.md             # Severity classification
│   ├── architecture.md                    # Architecture invariants
│   └── meta-rules-guide.md               # How to write new rules
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
    └── review-report.md
```

## Usage

### Plugin Commands (available immediately after install)

Run in your terminal:

```bash
claude "/mas:bootstrap"
claude "/mas:dev-loop Add user authentication with JWT"
claude "/mas:new-feature rate-limiting middleware"
claude "/mas:release v1.2.0"

# Non-stop autonomous mode — skips all human checkpoints
claude "/mas:dev-loop Add user authentication with JWT --auto"
```

### Skills (available after bootstrap)

After `/mas:bootstrap` copies files into your `.claude/`, all 13 skills work **without prefix**.

Open Claude Code (`claude` in terminal), then type these inside the chat:

```
/ask-questions I need to add OAuth2 support
/writing-plans Plan: migrate database to PostgreSQL
/subagent-driven-development Execute the migration plan
/executing-plans Execute the migration plan
/test-driven-development Implement the rate limiter module
/requesting-code-review Review the auth middleware changes
/receiving-code-review Fix issues from the review report
/finishing-branch
/verification
/systematic-debugging Users get 500 on /api/payments
/property-based-testing Test the URL parser
/differential-review Review the caching strategy proposal
/se-principles Should I use inheritance or composition here?
```

### Direct Agent Usage (available after bootstrap)

Run in your terminal:

```bash
claude --agent orchestrator "Build a complete CRUD API for products"
claude --dangerously-skip-permissions --agent orchestrator "Build a complete CRUD API for products" # for by pass all permission
claude --agent engineer "Implement TASK-003: Add rate limiting middleware"
claude --agent reviewer "Review the changes in src/auth/"
claude --agent researcher "What are the best options for real-time notifications?"
claude --agent differential-reviewer "Stress-test the Redis caching proposal"
claude --agent bug-fixer "Fix: login returns 401 when password has special chars"
claude --agent ui-ux-designer "Design the settings page layout"
```

### Example Workflows

**1. Full pipeline — run in terminal, one command does everything:**

```bash
claude "/mas:dev-loop --auto Implement WebSocket support for real-time updates" # Run from plugin

or

claude "/dev-loop --auto Implement WebSocket support for real-time updates" # Run from local project
```

**2. Plan then execute — open Claude Code, type in chat:**

```
/writing-plans Plan: add pagination to all list endpoints
/subagent-driven-development Execute the pagination plan
```

**3. Debug, fix, review — open Claude Code, type in chat:**

```
/systematic-debugging Why are emails not sending?
Tell the bug-fixer agent to fix the SMTP timeout
/requesting-code-review Review the email fix
```

## Acknowledgments

Includes skills adapted from [Obra Superpowers](https://github.com/obra/superpowers) (MIT License).

## License

MIT
