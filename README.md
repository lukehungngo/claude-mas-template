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
claude plugin install mas@luke-plugins
```

Then bootstrap your project:

```bash
claude "/mas:bootstrap"
```

Update later:

```bash
claude plugin update mas
```

### Option B: Clone Multi Agent System into your current Repository

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

### Plugin Commands (available immediately after install)

```bash
/mas:bootstrap    # Auto-detect stack, fill placeholders, configure hooks
/mas:dev-loop     # Full development loop — ask → plan → implement → review → finish
/mas:new-feature  # Scaffold a new feature
/mas:release      # Release checklist
```

### Skills (available after bootstrap)

Once `/mas:bootstrap` copies the MAS into your project's `.claude/`, all skills work without prefix:

```bash
/ask-questions            # Clarify requirements before coding
/writing-plans            # Create a detailed implementation plan
/subagent-driven-development  # Execute plan with subagents (two-stage review)
/executing-plans          # Execute plan in batches with human checkpoints
/test-driven-development  # TDD — RED-GREEN-REFACTOR
/requesting-code-review   # Dispatch a structured code review
/receiving-code-review    # Process reviewer feedback and fix issues
/finishing-branch         # Verify, merge/PR/keep/discard, cleanup
/verification             # Final checklist before declaring done
/systematic-debugging     # Debug when root cause is unclear
/property-based-testing   # Edge-case-heavy testing
/differential-review      # Stress-test a research proposal
/se-principles            # Reference for design decisions
```

### Direct Agent Usage (available after bootstrap)

```bash
claude --agent orchestrator "Build a complete CRUD API for products"
claude --agent engineer "Implement TASK-003: Add rate limiting middleware"
claude --agent reviewer "Review the changes in src/auth/"
claude --agent researcher "What are the best options for real-time notifications?"
claude --agent differential-reviewer "Stress-test the Redis caching proposal"
claude --agent bug-fixer "Fix: login returns 401 when password has special chars"
claude --agent ui-ux-designer "Design the settings page layout"
```

### Combining Workflows

```bash
# Full pipeline: ask → worktree → plan → implement (TDD) → review → finish
/dev-loop Implement WebSocket support for real-time updates

# Plan then execute with subagents
/writing-plans Plan: add pagination to all list endpoints
/subagent-driven-development Execute the pagination plan

# Debug → fix → review
/systematic-debugging Why are emails not sending?
claude --agent bug-fixer "Fix: SMTP connection timeout in email service"
/requesting-code-review Review the email fix
```

## Acknowledgments

Includes skills adapted from [Obra Superpowers](https://github.com/obra/superpowers) (MIT License).

## License

MIT
