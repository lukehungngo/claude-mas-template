# TASK-03: Create skills/obsidian.md

## Meta
- **id:** TASK-03
- **type:** impl
- **agent:** engineer
- **status:** pending
- **depends_on:** []
- **parallel_safe:** true
- **priority:** P1
- **routing:** Engineer directly — known pattern (new skill file, follows existing skill structure)

## Context
- **relevant_files:** [`skills/obsidian/SKILL.md` (create new — must create directory `skills/obsidian/` first)]
- **do_not_touch:** [`skills/verification/SKILL.md`, `skills/finishing-branch/SKILL.md`, `commands/bootstrap.md`]
- **reference_files:** [`skills/finishing-branch/SKILL.md`]
- **proposal:** N/A — known pattern

## Objective

Create `skills/obsidian/SKILL.md` (skills are directories containing `SKILL.md` — create the directory first). This is a skill that teaches Claude how to integrate Obsidian note-taking with the MAS dev-loop. The skill must:
- Start with YAML frontmatter (`name:` and `description:` fields)
- Document vault selection (obsidian-main / obsidian-eduquest / obsidian-vpbank) with a table showing which to use when
- List the core MCP tools with signatures (`obsidian_post_file`, `obsidian_put_file`, `obsidian_patch_file`, `obsidian_get_file`, `obsidian_simple_search`, `obsidian_list_vault_directory`)
- Define a folder convention for note organization (Claude Sessions/, Claude Plans/, Claude Decisions/, Claude Retrospectives/)
- Provide three note templates: Session Note, Plan Note, and ADR (Architecture Decision Record)
- Document a step-by-step Capture Workflow for saving session notes, saving plans, and searching
- List Common Mistakes to avoid
- End with Integration with dev-loop guidance prompting the user to save at session end

## Acceptance Criteria

- [ ] `ls skills/obsidian/SKILL.md` → file exists
- [ ] `head -4 skills/obsidian/SKILL.md` → shows `---`, `name: obsidian`, `description:`, `---` frontmatter
- [ ] `grep "obsidian-main\|obsidian-eduquest\|obsidian-vpbank" skills/obsidian/SKILL.md | wc -l` → at least 3 lines
- [ ] `grep "obsidian_post_file\|obsidian_put_file\|obsidian_patch_file\|obsidian_get_file\|obsidian_simple_search" skills/obsidian/SKILL.md | wc -l` → at least 5 lines (one per tool)
- [ ] `grep "Claude Sessions\|Claude Plans\|Claude Decisions" skills/obsidian/SKILL.md | wc -l` → at least 3 lines
- [ ] `grep "Session Note\|Plan Note\|ADR\|Architecture Decision" skills/obsidian/SKILL.md | wc -l` → at least 3 lines
- [ ] `grep "mcp__obsidian" skills/obsidian/SKILL.md` → at least one example showing the MCP tool call prefix

## Business Context

The user requested an Obsidian integration skill. Three Obsidian MCP servers are already configured (obsidian-main, obsidian-eduquest, obsidian-vpbank). This skill documents how to use them for session note capture within the dev-loop, giving agents and the user a standardized workflow for persisting knowledge.

## Output

Write result to `docs/results/TASK-03-result.md`
