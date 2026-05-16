# Archived Agents

Agents preserved here for historical reference. They are **not** part of the active plugin distribution and must not be dispatched.

## Why archive instead of delete?

- Decisions captured in their headers remain useful when reviewing past architectural choices.
- The dispatch-guard hook still blocks invocations by name (`mas:orchestrator:orchestrator`), so the agent's full text stays available for grep-ability.

## Contents

### `orchestrator/`

Deprecated since v2.0. Replaced by flat dispatch from `commands/dev-loop.md` and `commands/loop.md`. The runtime Agent tool is not available to Level 1 subagents, so the orchestrator pattern (orchestrator dispatches workers) does not work in Claude Code as of 2026-03-28.

If Claude Code later supports nested Agent dispatch reliably, this file can be revived and updated.

## Re-activation

If you ever revive an archived agent:

1. Move the directory back to `agents/<name>/`.
2. Remove the dispatch-guard for it in `.claude/hooks/validate-dispatch.sh` (if present).
3. Update routing tables in `templates/local-inject.md` and the commands that should dispatch it.
4. Bump plugin version + CHANGELOG.
