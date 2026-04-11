# Claude Code Multi-Agent System Template

Opinionated multi-agent system for Claude Code, extracted from real production usage and hardened through data — not theory.

Install this plugin and your Claude Code sessions get 7 specialized agents, structural quality enforcement via hooks, and protocols that encode senior engineering judgment into rules the system can't rationalize away.

## What Makes This Different

Most AI coding tools give you guidelines. This gives you enforcement.

**Structural hooks that block bad decisions:**
- Bare agent name (`engineer` instead of `mas:engineer:engineer`) → blocked at shell level
- Reviewer dispatched on Haiku for a standard review → blocked, must use sonnet+
- Reflect agent skipped after full pipeline ran → session blocked at stop
- Same skill invoked bare without namespace → blocked

**Protocols earned from real session data (37 reviews, 27 sessions audited):**
- Engineer deviation taxonomy: 4-rule auto-fix vs stop protocol — not "treat all ambiguity as a blocker"
- Reviewer depth modes (quick/standard/deep) with model floor per depth — controller picks depth, hook enforces minimum model
- Between-batch review gate: enforces 1:1 engineer:reviewer ratio before next batch starts
- Analysis paralysis guard: 5+ reads without a write forces a decision
- Stub tracker: pre-completion scan for unwired routes and services
- Reflect-once constraint: delivery evaluation runs exactly once per dev-loop

**Business alignment in review — not just code quality:**
The reviewer runs two phases. Phase A verifies intent: did we build what was actually asked? Phase B is the technical audit. Most tools skip Phase A entirely.

**Works as a hardening layer on top of Superpowers:**
If you use `superpowers:subagent-driven-development`, you can specify `mas:engineer:engineer` and `mas:reviewer:reviewer` as your subagent types. You get the MAS protocols + hook enforcement regardless of which skill triggered the dispatch. The hooks fire at the Claude Code layer — no skill can bypass them.

---

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| **Agents** | 7 | engineer, reviewer, researcher, differential-reviewer, bug-fixer, reflect-agent, ui-ux-designer |
| **Skills** | 8 | ask-questions, subagent-driven-development, verification, finishing-branch, se-principles, reliability-review, property-based-testing, differential-review |
| **Rules** | 4 | honesty-first, severity-discipline, meta-rules guide, agent workflow lessons |
| **Commands** | 5 | bootstrap, dev-loop, bug-fix, reflect, release |
| **Hooks** | 6 | lint (PostToolUse), compaction suggester (PreToolUse), quality gate (Stop), pipeline validator (Stop), dispatch name enforcer (PreToolUse:Agent), skill name enforcer (PreToolUse:Skill) |
| **Templates** | 3 | task-spec, review-report (with YAML frontmatter), dispatch-templates |

---

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and logged in

---

## Install

### Option A: Claude Code Plugin (recommended)

```bash
claude plugin marketplace add lukehungngo/claude-mas-template
claude plugin install mas@luke-plugins

# Required dependency
claude plugin install superpowers@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
```

Then bootstrap your project:

```bash
claude "/mas:bootstrap"
```

Fill the remaining TODOs in `CLAUDE.md` (Architecture Invariants, Core Flow, Key Gotchas) to complete setup.

> **One-shot autonomous run:**
> ```bash
> claude --dangerously-skip-permissions "/mas:dev-loop --auto Build a complete CRUD API for products"
> ```

**Update:**

```bash
claude plugin marketplace update luke-plugins
claude plugin update mas@luke-plugins
claude "/mas:bootstrap --update"
```

The `--update` flag smart-merges the new plugin version:
- **Overwrites** framework files (agents, skills, commands, templates)
- **Re-applies** your project's placeholder values
- **Never touches** `CLAUDE.md`, `settings.json`, or user-owned files
- **Asks before overwriting** customized hooks
- **Adds** new agents or skills from the update

**Uninstall:**

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

Local install gives unprefixed commands (`/dev-loop`, `/bootstrap`, etc.).

</details>

---

## Using with Superpowers

If you already use `superpowers:subagent-driven-development`, MAS agents slot in directly as the subagent types. You get the specialized prompts and enforced protocols without switching workflows.

**Hardened engineer dispatch:**
```
Agent(
  subagent_type: "mas:engineer:engineer",
  model: "sonnet",
  prompt: "..."
)
```

The engineer gets: TDD iron law, deviation taxonomy (auto-fix bugs/safety, stop for architecture), analysis paralysis guard, stub scan before declaring done.

**Hardened reviewer dispatch:**
```
Agent(
  subagent_type: "mas:reviewer:reviewer",
  model: "sonnet",
  prompt: "depth: standard\n\nReview TASK-{id}..."
)
```

The reviewer gets: two-phase review (business alignment + technical audit), P0/P1/P2/P3 severity with machine-readable YAML output, depth-aware behavior (quick/standard/deep).

**What the hooks enforce regardless of which skill dispatched the agent:**
- `mas:reviewer:reviewer` with `model: haiku` and no `depth: quick` → blocked
- Bare `engineer` or `reviewer` instead of namespaced `mas:engineer:engineer` → blocked
- `mas:reflect-agent:reflect-agent` dispatched twice in same session → blocked

The hooks fire at the Claude Code layer. Superpowers, MAS dev-loop, or direct `--agent` calls all go through the same enforcement.

---

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
                          └──────┬──────┘
                                 │
                          ┌──────┴──────┐
                          │Reflect Agent │  (once per dev-loop, enforced by hook)
                          └─────────────┘

  * UI/UX Designer only active when has_ui: true in CLAUDE.md
```

---

## Workflow Pipeline

```
1. BRANCH         →  Isolated git worktree, verify clean baseline
2. PLAN           →  Explore codebase, clarify requirements, bite-sized tasks
3. DESIGN (UI)*   →  Component specs, states, a11y  (* only if has_ui: true)
4. EXECUTE (TDD)  →  Flat dispatch to agents, RED-GREEN-REFACTOR
                      Between-batch gate: reviews must match engineers before next batch
5. VERIFY         →  Artifact gate, tests pass, lint clean, no debug artifacts
6. FINISH         →  Present options (merge/PR/keep/discard), cleanup worktree
```

---

## Usage

### Commands

```bash
claude "/mas:bootstrap"                                                    # Set up project
claude "/mas:dev-loop Add user authentication with JWT"                    # Full pipeline
claude "/mas:dev-loop --auto Build a complete CRUD API for products"       # Autonomous mode
claude "/mas:bug-fix Fix: login returns 401 when password has special chars"
claude "/mas:reflect check against docs/specs/auth-spec.md"
claude "/mas:release v1.2.0"
```

### Skills (type inside Claude Code chat)

```
/mas:ask-questions I need to add OAuth2 support
/mas:subagent-driven-development Execute the migration plan
/mas:verification
/mas:finishing-branch
/mas:systematic-debugging Users get 500 on /api/payments
/mas:property-based-testing Test the URL parser
/mas:differential-review Review the caching strategy proposal
/mas:se-principles Should I use inheritance or composition here?
/mas:reliability-review Review the payment processing module
```

### Direct Agent Dispatch

Use specific agents without the full pipeline:

```bash
# Engineer — strict TDD, deviation taxonomy, stub scan
claude --agent mas:engineer:engineer "Implement TASK-003: Add rate limiting middleware"

# Reviewer — two-phase review (intent + technical), P0-P3 severity, YAML output
claude --agent mas:reviewer:reviewer "depth: standard — Review the recent changes in src/auth/"

# Bug-Fixer — write failing test first, then fix
claude --agent mas:bug-fixer:bug-fixer "Fix: login returns 401 when password has special chars"

# Researcher — explore approaches before committing to implementation
claude --agent mas:researcher:researcher "What are the best options for real-time notifications?"

# Differential Reviewer — adversarial stress-test of proposals
claude --agent mas:differential-reviewer:differential-reviewer "Stress-test the Redis caching proposal"

# Reflect Agent — was the original intent actually delivered?
claude --agent mas:reflect-agent:reflect-agent "Evaluate branch against requirement: Add JWT auth"

# UI/UX Designer — component specs, state mapping, a11y checklist
claude --agent mas:ui-ux-designer:ui-ux-designer "Design the settings page layout"
```

### Example Workflows

**Full pipeline — one command:**
```bash
claude "/mas:dev-loop --auto Implement WebSocket support for real-time updates"
```

**With Superpowers subagent-driven-development:**
```
/superpowers:writing-plans Plan: add pagination to all list endpoints
# → use mas:engineer:engineer and mas:reviewer:reviewer as subagent types for hardened execution
/superpowers:subagent-driven-development Execute the pagination plan
```

**Debug → fix → review:**
```
/mas:systematic-debugging Why are emails not sending?
/mas:bug-fix Fix the SMTP timeout
/mas:requesting-code-review Review the email fix
```

---

## Reviewer Depth Protocol

The reviewer supports three depth modes. Specify in the prompt — the hook enforces minimum model per depth:

| Depth | What it does | Model floor | Use for |
|-------|-------------|-------------|---------|
| `depth: quick` | grep-only pattern scan, no full reads | any | Renames, config tweaks, doc changes |
| `depth: standard` | Full per-file reads, complete Phase B | sonnet | All implementation tasks (default) |
| `depth: deep` | Cross-file analysis, call graph tracing, adversarial pass | sonnet (opus preferred) | P0 fixes, cross-cutting changes, final branch review |

If depth is not specified, the reviewer defaults to `standard`.

---

## Review Report Format

Every review report includes machine-readable YAML frontmatter:

```yaml
---
task_id: TASK-006
title: "Add rate limiting middleware"
verdict: APPROVED_WITH_CHANGES
depth: standard
model: "claude-sonnet-4-6"
findings:
  p0: 0
  p1: 0
  p2: 2
  p3: 1
business_alignment: PASS
build_status: PASS
reviewed_at: "2026-04-12T10:00:00"
commit: "abc1234"
---
```

This enables automated quality measurement via `mas-audit.py` — block rate, P0 find rate, model used per review, thin-review detection.

---

## Acknowledgments

Includes skills adapted from [Obra Superpowers](https://github.com/obra/superpowers) (MIT License).

## License

MIT
