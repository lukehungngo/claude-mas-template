# Plan: Agent Efficiency Optimization

**Date:** 2026-05-16
**Branch:** main (working tree, no worktree — small additive edit set)
**Target version:** 2.26.0

## Requirement

From the 30-day session audit (2,879 sessions, ~$48,954 spend):

- 0.0% parallel tool use (3 of 69,596 turns)
- 43.3% redundant Reads (~5,500 wasted reads)
- 57.7% Bash share — heavy shell-as-thinking
- Opus inheritance burned $8,232 in a single 6.3-day session
- Skill adoption only 3.6% of sessions

The `/mas:loop` command was hardened in v2.25.0 (subagents pinned to Sonnet, redundant reads killed at the dispatch boundary, cost/time gate added). This plan extends those gains into each MAS **agent definition** so the discipline holds regardless of which command dispatched them.

## Scope

Apply uniform "Tool Discipline" guidance to all active MAS agents; archive the deprecated orchestrator; add small targeted boundary/skill hints to researcher and engineer.

## Tasks

### TASK-01 — Tool Discipline → engineer
**Goal:** Engineer enforces batching, no-redoing reads, file-op tool discipline, model tier.
**File:** `agents/engineer/CLAUDE.md`
**Acceptance:** Section `## Tool Discipline` exists; lists 4 rules (batch, no re-Read, Read/Edit not cat/sed, Sonnet tier).

### TASK-02 — Tool Discipline → bug-fixer
**Goal:** Same discipline block, full variant.
**File:** `agents/bug-fixer/CLAUDE.md`
**Acceptance:** `## Tool Discipline` section present.

### TASK-03 — Tool Discipline + boundary → researcher
**Goal:** Add discipline block; restrict Write to `docs/plans/`, `docs/research/`; surface model tier (Sonnet default, Opus optional for novel synthesis).
**File:** `agents/researcher/CLAUDE.md`
**Acceptance:** Discipline section + explicit Write allow-list + model tier note.

### TASK-04 — Tool Discipline → reviewer
**Goal:** Full discipline block. Reviewer already has model floor in Dispatch Contract; do not duplicate.
**File:** `agents/reviewer/CLAUDE.md`
**Acceptance:** `## Tool Discipline` present.

### TASK-05 — Tool Discipline → reflect-agent (read-only variant)
**Goal:** Read-only discipline (batch reads, Bash for `git diff` only, Sonnet tier). Drop Edit/Write line.
**File:** `agents/reflect-agent/CLAUDE.md`
**Acceptance:** Section present; explicitly notes read-only role.

### TASK-06 — Tool Discipline → differential-reviewer (read-only variant)
**Goal:** Same read-only variant.
**File:** `agents/differential-reviewer/CLAUDE.md`
**Acceptance:** Section present.

### TASK-07 — Tool Discipline → ui-ux-designer
**Goal:** Full discipline block; Write/Edit allowed because designer writes design specs.
**File:** `agents/ui-ux-designer/CLAUDE.md`
**Acceptance:** Section present.

### TASK-08 — Archive orchestrator
**Goal:** Orchestrator is marked DEPRECATED in its own header (replaced by flat dispatch). Move to `docs/archive/agents/orchestrator/CLAUDE.md` so the plugin no longer ships 2,679 tokens of dead system prompt.
**Files:** `agents/orchestrator/` → `docs/archive/agents/orchestrator/`
**Acceptance:** `agents/orchestrator/` does not exist; `docs/archive/agents/orchestrator/CLAUDE.md` exists with the same content; CHANGELOG notes the move.

### TASK-09 — Skill-routing hint → engineer
**Goal:** Add one sentence in engineer's process: before writing tests/patterns from scratch, check available Skills (TDD, language-specific patterns).
**File:** `agents/engineer/CLAUDE.md`
**Acceptance:** Hint present in Process or Non-negotiables section.

### TASK-10 — Bump version + CHANGELOG
**Goal:** Bump `2.25.0` → `2.26.0` in `plugin.json` + `marketplace.json`; add CHANGELOG entry summarizing the agent-level changes.
**Files:** `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `CHANGELOG.md`

### TASK-11 — Verify
**Goal:** Confirm all 7 active agents have `## Tool Discipline`; orchestrator gone from `agents/`; CHANGELOG and versions consistent.

## Tool Discipline Block (canonical text)

**Full variant** (engineer, bug-fixer, researcher, reviewer, ui-ux-designer):

```markdown
## Tool Discipline

- **Batch independent tool calls** — multiple Reads / Greps / Bash status checks in one assistant message, not sequential turns.
- **Don't re-Read a file you just Edited** — the harness tracks file state; re-reads waste tokens and time.
- **File ops via Read / Edit / Write / Grep / Glob** — never `cat`, `sed`, `awk`, `head`, `tail` via Bash. Bash is for git, build, test, and shell-only commands.
- **Model tier:** Designed for Sonnet. Opus is wasteful for this role unless the dispatcher passes `model: "opus"` with a documented reason.
```

**Read-only variant** (reflect-agent, differential-reviewer):

```markdown
## Tool Discipline

- **Batch independent tool calls** — multiple Reads / Greps / git commands in one assistant message, not sequential turns.
- **Don't re-Read the same file** within a single review pass — the harness tracks state.
- **You are read-only** — no Write, no Edit. Bash is for `git diff`, `git log`, and similar inspection only.
- **Model tier:** Designed for Sonnet.
```

## Risk

Low. All edits are additive (new section); no removal of existing guardrails. Orchestrator was already marked DEPRECATED in its own preamble and is not invoked by any current command.

## Out of scope

- Compressing existing agent personas (token bloat reduction) — separate effort.
- Splitting reviewer into quick/standard/deep agents — separate effort.
- Adding Sonnet/Haiku routing to `/loop` autonomous mode (separate skill, separate plugin).
