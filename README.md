# Claude Code Multi-Agent System Template

A production-grade template for building any project with Claude Code's multi-agent system. Extracted from [AgentWall](https://github.com/anthropics/agentwall)'s battle-tested configuration.

## What's Included


| Component     | Count | Description                                                                                                  |
| ------------- | ----- | ------------------------------------------------------------------------------------------------------------ |
| **Agents**    | 7     | orchestrator, engineer, reviewer, researcher, differential-reviewer, bug-fixer, ui-ux-designer (conditional) |
| **Skills**    | 13    | 8 core workflow skills + 5 extended engineering skills                                                       |
| **Rules**     | 4     | honesty-first, severity-discipline, architecture invariants, meta-rules guide                                |
| **Commands**  | 4     | bootstrap, dev-loop, new-feature, release                                                                    |
| **Hooks**     | 2     | PostToolUse lint, Stop quality gate                                                                          |
| **Templates** | 2     | task-spec, review-report                                                                                     |


## Install

### Option A: Claude Code Plugin (recommended)

Add the marketplace and install — two commands:

```bash
claude plugin marketplace add lukehungngo/claude-mas-template
claude plugin install claude-mas-template@luke-plugins
```

Then bootstrap your project:

```bash
claude "/bootstrap"
```

Update later:

```bash
claude plugin update claude-mas-template
```

### Option B: Git Clone

```bash
git clone https://github.com/lukehungngo/claude-mas-template /tmp/mas
mkdir -p .claude
cp -r /tmp/mas/agents /tmp/mas/commands /tmp/mas/skills /tmp/mas/hooks /tmp/mas/rules /tmp/mas/templates .claude/
cp /tmp/mas/.claude/settings.json .claude/
cp /tmp/mas/CLAUDE.md .
rm -rf /tmp/mas

claude "/bootstrap"
```

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

## All Commands

### Slash Commands (entry points)

```bash
# Bootstrap — auto-detect stack, fill placeholders, configure hooks
claude "/bootstrap"

# Full development loop — end-to-end: ask → plan → implement → review → finish
claude "/dev-loop Add user authentication with JWT"

# Scaffold a new feature
claude "/new-feature rate-limiting middleware"

# Release checklist
claude "/release v1.2.0"
```

### Skills (invoked via natural language or slash syntax)

```bash
# Clarify requirements before coding
claude "/ask-questions I need to add OAuth2 support"

# Create a detailed implementation plan
claude "/writing-plans Plan: migrate database from SQLite to PostgreSQL"

# Execute a plan with subagents (one agent per task, two-stage review)
claude "/subagent-driven-development Execute the migration plan"

# Execute a plan in batches with human checkpoints
claude "/executing-plans Execute the migration plan"

# TDD workflow — RED-GREEN-REFACTOR
claude "/test-driven-development Implement the rate limiter module"

# Request a structured code review
claude "/requesting-code-review Review the auth middleware changes"

# Process reviewer feedback and fix issues
claude "/receiving-code-review Fix issues from the review report"

# Finish a branch — verify tests, merge/PR/keep/discard, cleanup
claude "/finishing-branch"

# Final verification checklist before declaring done
claude "/verification"

# Debug a bug systematically when root cause is unclear
claude "/systematic-debugging Users get 500 on /api/payments"

# Property-based testing for edge-case-heavy code
claude "/property-based-testing Test the URL parser"

# Stress-test a research proposal before committing
claude "/differential-review Review the caching strategy proposal"

# Reference software engineering principles for design decisions
claude "/se-principles Should I use inheritance or composition here?"
```

### Direct Agent Usage

```bash
# Orchestrator — decomposes tasks, dispatches to other agents, verifies outcomes
claude --agent orchestrator "Build a complete CRUD API for products"

# Engineer — implements features with TDD, writes minimal code
claude --agent engineer "Implement TASK-003: Add rate limiting middleware"

# Reviewer — two-phase review (business alignment + technical audit)
claude --agent reviewer "Review the changes in src/auth/"

# Researcher — explores approaches, analyzes trade-offs, produces proposals
claude --agent researcher "What are the best options for real-time notifications?"

# Differential Reviewer — adversarial second opinion on proposals
claude --agent differential-reviewer "Stress-test the Redis caching proposal"

# Bug Fixer — TDD-focused, fixes exactly what's reported
claude --agent bug-fixer "Fix: login returns 401 when password has special chars"

# UI/UX Designer — component specs, interaction flows, accessibility (requires has_ui: true)
claude --agent ui-ux-designer "Design the settings page layout"
```

### Combining Workflows

```bash
# Full pipeline: ask → worktree → plan → implement (TDD) → review → finish
claude "/dev-loop Implement WebSocket support for real-time updates"

# Plan then execute with subagents
claude "/writing-plans Plan: add pagination to all list endpoints"
claude "/subagent-driven-development Execute the pagination plan"

# Debug → fix → review
claude "/systematic-debugging Why are emails not sending?"
claude --agent bug-fixer "Fix: SMTP connection timeout in email service"
claude "/requesting-code-review Review the email fix"
```

## Acknowledgments

Includes skills adapted from [Obra Superpowers](https://github.com/obra/superpowers) (MIT License).

## License

MIT