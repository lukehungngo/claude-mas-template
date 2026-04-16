# Brainstorm Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**IMPORTANT: Ignore the execution handoff above. Dispatch MAS agents directly.**

**Goal:** Create `/mas:brainstorm` command implementing first principles decomposition per spec at `docs/brainstorms/2026-04-15-mas-brainstorm-command.md`.

**Architecture:** Single command file + bootstrap wiring. No agents, no skills — pure command.

---

### Task 1: Create commands/brainstorm.md

**Files:**
- Create: `commands/brainstorm.md`
- Reference: `docs/brainstorms/2026-04-15-mas-brainstorm-command.md` (the spec)

Write the command following the spec's flow (Steps 1-7), three questions, input classification examples, output artifact template, and integration notes. Use the same markdown command format as existing commands (dev-loop.md, bug-fix.md).

### Task 2: Wire bootstrap + version bump

**Files:**
- Modify: `commands/bootstrap.md` — add `docs/brainstorms` to mkdir
- Modify: `.claude-plugin/plugin.json` — bump to 2.15.0
- Modify: `.claude-plugin/marketplace.json` — bump to 2.15.0
- Modify: `CHANGELOG.md` — add entry
- Modify: `README.md` — update command count 5 → 6, add brainstorm to list
