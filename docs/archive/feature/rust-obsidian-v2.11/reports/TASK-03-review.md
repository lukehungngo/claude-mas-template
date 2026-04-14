---
task_id: TASK-03
title: "Create skills/obsidian/SKILL.md"
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
reviewed_at: "2026-04-14T17:05:35"
commit: "9b168948a611aeccd7400814bf88ed6cc3fffd58"
---

## Review: TASK-03 — Create skills/obsidian/SKILL.md

### Business Alignment

- [PASS] `ls skills/obsidian/SKILL.md` → file exists
- [PASS] `head -4` → `---`, `name: obsidian`, `description: ...`, `---` (4-line frontmatter correct)
- [PASS] Vault names ≥ 3 lines → 8 occurrences (obsidian-main, obsidian-eduquest, obsidian-vpbank all present)
- [PASS] Tool names ≥ 5 lines → 12 occurrences across 6 distinct tools
- [PASS] Folder names ≥ 3 lines → 12 occurrences across 4 distinct folders
- [PASS] Template types ≥ 3 lines → 8 occurrences (Session Note, Plan Note, ADR all present)
- [PASS] `mcp__obsidian` prefix example present (2 example calls shown)

### Build Status

PASS — Markdown document, no compilation. All 7 acceptance criteria pass. File is 181 lines, well within the 800-line ceiling.

### P0 — Blockers

None.

### P1 — Must Fix

None.

### P2 — Should Fix

**skills/obsidian/SKILL.md (Save a Plan workflow, step 3)** — The "Save a Plan" workflow uses `obsidian_put_file` without first checking if the file exists, unlike the "Save a Session Note" workflow which checks existence before deciding between `put_file` and `patch_file`. If a plan note already exists (re-run of writing-plans on the same feature + date), `put_file` silently overwrites it. The Session Note workflow explicitly guards against this; the Plan Note workflow should do the same: call `obsidian_get_file` first, and if the file exists, use `patch_file` with `mode: "append"` instead.

**skills/obsidian/SKILL.md (MCP Tool Reference table)** — The tool reference table documents the tool names as `obsidian_post_file`, `obsidian_put_file`, etc., with a note "prefix with the vault server name." However, the actual MCP call syntax shown in the Capture Workflow uses the double-underscore convention (`mcp__obsidian-main__obsidian_get_file`). The table column is labelled "Tool" but does not show the full call syntax with prefix — a reader must mentally combine the server name + tool name to produce the actual call. Consider showing one full example call in the table header row or adding a dedicated "Call syntax" column. This is a usability gap that could cause agents to call the tool incorrectly.

### P3 — Optional

**skills/obsidian/SKILL.md:179** — The "Integration with dev-loop" section uses a Markdown blockquote (`> "Session complete..."`) for the prompt string. This is a minor formatting choice but it differs from how the "Announce at start" string is formatted at the top of the file (bold text inline). Consistent formatting across both announcement strings would read more cleanly.

### Verdict

APPROVED_WITH_CHANGES

### Summary

The skill is well-structured, all acceptance criteria pass, and the coverage of vaults, tools, folder conventions, and templates is solid. The capture workflow shows good reliability thinking (existence-check before put/patch for session notes). Two P2 issues are worth fixing before heavy use: the Plan workflow skips the existence-check that protects against silent overwrites, and the MCP tool reference table does not show the full call syntax that an agent would actually execute. Neither blocks merging but both create real friction at runtime.
