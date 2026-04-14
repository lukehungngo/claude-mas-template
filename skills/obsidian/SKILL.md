---
name: obsidian
description: Integrate Obsidian note-taking with the MAS dev-loop. Save session notes, planning artifacts, decisions, and retrospectives to Obsidian vaults using MCP tools.
---

# Obsidian Integration

**Announce at start:** "I'm using the obsidian skill to save notes to Obsidian."

## When to Use This Skill

Use this skill when the user asks to:
- Save session notes, decisions, or retrospectives to Obsidian
- Capture a plan, task list, or architecture decision to a vault
- Link a dev-loop session to a knowledge base entry
- Recall or search prior session notes from Obsidian

## MCP Tool Reference

Three Obsidian vaults are available via MCP. Choose the correct one based on context:

| MCP Server | Vault | Use When |
|------------|-------|----------|
| `obsidian-main` | Main personal vault | Default — personal projects, general dev notes |
| `obsidian-eduquest` | EduQuest vault | eduquest project context |
| `obsidian-vpbank` | VPBank vault | vpbank project context |

**If the user hasn't specified a vault, use `obsidian-main` (the default).**

### Core Tools (prefix with the vault server name)

| Tool | Signature | Purpose |
|------|-----------|---------|
| `obsidian_post_file` | `(path, content)` | Create a new note (fails if file exists) |
| `obsidian_put_file` | `(path, content)` | Create or overwrite a note |
| `obsidian_patch_file` | `(path, content, mode)` | Append or prepend to an existing note |
| `obsidian_get_file` | `(path)` | Read a note |
| `obsidian_simple_search` | `(query)` | Full-text search across vault |
| `obsidian_list_vault_directory` | `(path)` | List files in a folder |

**Note:** All paths are relative to the vault root (e.g., `"Claude Sessions/2026-04-14-rust-obsidian.md"`).

## Vault Folder Convention

Use this folder structure when creating notes. Never create files at vault root.

```
Claude Sessions/          ← dev-loop session notes
Claude Plans/             ← plan documents from writing-plans
Claude Decisions/         ← ADRs and key decisions
Claude Retrospectives/    ← post-session lessons learned
```

## Note Templates

### Session Note (save at end of dev-loop)

File path: `Claude Sessions/YYYY-MM-DD-{branch-name}.md`

```markdown
# Session: {branch-name}

**Date:** YYYY-MM-DD
**Project:** {project name}
**Branch:** {branch name}

## Goal

{one sentence describing what was built}

## What Was Done

{bullet list of tasks completed — summarise engineer results}

## Key Decisions

{bullet list of non-obvious decisions made and why}

## Gotchas / Lessons

{anything that surprised you or should inform the next session}

## Files Changed

{list of files created or modified}
```

### Plan Note (save after writing-plans completes)

File path: `Claude Plans/YYYY-MM-DD-{feature-name}.md`

```markdown
# Plan: {feature name}

**Date:** YYYY-MM-DD
**Status:** In Progress | Completed | Abandoned

## Goal

{goal from plan header}

## Tasks

{paste the task list with checkboxes — omit code blocks, keep steps}

## Notes

{anything the plan didn't capture}
```

### Architecture Decision Record (ADR)

File path: `Claude Decisions/YYYY-MM-DD-{decision-title}.md`

```markdown
# ADR: {decision title}

**Date:** YYYY-MM-DD
**Status:** Accepted | Superseded | Rejected

## Context

{what problem prompted this decision}

## Decision

{what was decided}

## Rationale

{why this option over alternatives}

## Consequences

{what becomes easier or harder as a result}
```

## Capture Workflow

### Save a Session Note

1. Choose the correct vault (default: `obsidian-main`)
2. Build the file path: `Claude Sessions/YYYY-MM-DD-{branch-name}.md`
3. Check if the file exists:
   ```
   mcp__obsidian-main__obsidian_get_file(path="Claude Sessions/YYYY-MM-DD-{branch-name}.md")
   ```
   - If it exists → use `obsidian_patch_file` with `mode: "append"` to add new content
   - If it doesn't exist → use `obsidian_put_file` to create it
4. Fill in the session note template above
5. Confirm to the user: "Session note saved to `Claude Sessions/YYYY-MM-DD-{branch-name}.md` in {vault} vault."

### Save a Plan

1. After `superpowers:writing-plans` completes and saves to `docs/superpowers/plans/YYYY-MM-DD-{feature}.md`
2. Read the plan file
3. Create a plan note at `Claude Plans/YYYY-MM-DD-{feature}.md` using `obsidian_put_file`
4. Use the Plan Note template above — strip code blocks from task steps for readability

### Search Prior Notes

```
mcp__obsidian-main__obsidian_simple_search(query="{search term}")
```

Report results to the user as a bullet list with file paths and a one-line excerpt.

## Common Mistakes

- **Wrong vault:** Always confirm vault with user if project context is ambiguous
- **Root-level files:** Never create notes at vault root — always use a subfolder
- **Overwriting without checking:** Use `obsidian_get_file` first, then decide between `post`, `put`, or `patch`
- **Forgetting the date prefix:** All file names start with `YYYY-MM-DD-`

## Integration with dev-loop

At the end of a `/mas:dev-loop` session, ask the user:

> "Session complete. Would you like me to save a session note to Obsidian?"

If yes: follow the Save a Session Note workflow above. If the user specifies a vault name, use that; otherwise default to `obsidian-main`.
