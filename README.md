# Claude Code Multi-Agent System Template

A production-grade template for building any project with Claude Code's multi-agent system. Extracted from [AgentWall](https://github.com/anthropics/agentwall)'s battle-tested configuration.

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| **Agents** | 7 | orchestrator, engineer, reviewer, researcher, differential-reviewer, bug-fixer, ui-ux-designer (conditional) |
| **Skills** | 13 | 8 core workflow skills + 5 extended engineering skills |
| **Rules** | 4 | honesty-first, severity-discipline, architecture invariants, meta-rules guide |
| **Commands** | 4 | bootstrap, dev-loop, new-feature, release |
| **Hooks** | 2 | PostToolUse lint, Stop quality gate |
| **Templates** | 2 | task-spec, review-report |

## Install

### Option A: One command (recommended)

From your project root:

```bash
# 1. Copy the template into your repo
git clone https://github.com/anthropics/claude-mas-template /tmp/claude-mas-template
cp -r /tmp/claude-mas-template/.claude .
cp /tmp/claude-mas-template/CLAUDE.md .
cp /tmp/claude-mas-template/.gitignore .gitignore.mas
rm -rf /tmp/claude-mas-template

# 2. Let Claude do the rest
claude "/bootstrap"
```

That's it. The `/bootstrap` command auto-detects your stack, fills in all placeholders, configures hooks, and reports what's left for you to customize.

### Option B: Manual setup

```bash
# Copy files
cp -r claude-mas-template/.claude /path/to/your-project/
cp claude-mas-template/CLAUDE.md /path/to/your-project/

# Find and replace all placeholders
grep -r '{{' .claude/ CLAUDE.md

# Make hooks executable
chmod +x .claude/hooks/*.sh

# Validate
claude "/dev-loop Add a hello world function"
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
your-project/
├── CLAUDE.md                              # Project context (customize)
├── .claude/
│   ├── settings.json                      # Permissions + hooks
│   ├── agents/
│   │   ├── orchestrator/CLAUDE.md         # Routes tasks to agents
│   │   ├── engineer/CLAUDE.md             # Implements with TDD
│   │   ├── reviewer/CLAUDE.md             # Two-phase code review
│   │   ├── researcher/CLAUDE.md           # Explores approaches
│   │   ├── differential-reviewer/CLAUDE.md # Stress-tests proposals
│   │   ├── bug-fixer/CLAUDE.md            # TDD bug fixes
│   │   └── ui-ux-designer/CLAUDE.md       # Component specs & a11y (has_ui: true)
│   ├── commands/
│   │   ├── bootstrap.md                   # Auto-detect stack, fill placeholders
│   │   ├── dev-loop.md                    # Full development workflow
│   │   ├── new-feature.md                 # Scaffold new feature
│   │   └── release.md                     # Release checklist
│   ├── hooks/
│   │   ├── lint.sh                        # Auto-lint on file edit
│   │   └── pre-stop-gate.sh              # Quality summary on stop
│   ├── rules/
│   │   ├── honesty-first.md               # Metrics integrity
│   │   ├── severity-discipline.md         # Severity classification
│   │   ├── architecture.md                # Architecture invariants
│   │   └── meta-rules-guide.md            # How to write new rules
│   ├── skills/
│   │   ├── ask-questions/SKILL.md
│   │   ├── writing-plans/SKILL.md
│   │   ├── executing-plans/SKILL.md
│   │   ├── subagent-driven-development/
│   │   │   ├── SKILL.md
│   │   │   ├── implementer-prompt.md
│   │   │   ├── spec-reviewer-prompt.md
│   │   │   └── code-quality-reviewer-prompt.md
│   │   ├── test-driven-development/SKILL.md
│   │   ├── requesting-code-review/
│   │   │   ├── SKILL.md
│   │   │   └── code-reviewer.md
│   │   ├── receiving-code-review/SKILL.md
│   │   ├── finishing-branch/SKILL.md
│   │   ├── verification/SKILL.md
│   │   ├── systematic-debugging/SKILL.md
│   │   ├── property-based-testing/SKILL.md
│   │   ├── se-principles/SKILL.md
│   │   └── differential-review/SKILL.md
│   └── templates/
│       ├── task-spec.md
│       └── review-report.md
```

## Example Commands

```bash
# Full development loop
claude "/dev-loop Add user authentication with JWT"

# Scaffold a new feature
claude "/new-feature rate-limiting middleware"

# Use a specific agent
claude --agent engineer "Implement TASK-003: Add rate limiting"

# Use a skill directly
claude "Use the writing-plans skill to plan: migrate to PostgreSQL"

# Release
claude "/release v1.2.0"
```

## License

MIT
