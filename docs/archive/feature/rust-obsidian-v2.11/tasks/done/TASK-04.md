# TASK-04: Bump version to v2.11.0 and update CHANGELOG

## Meta
- **id:** TASK-04
- **type:** impl
- **agent:** engineer
- **status:** pending
- **depends_on:** []
- **parallel_safe:** true
- **priority:** P2
- **routing:** Engineer directly — known pattern (version bump, same as prior releases)

## Context
- **relevant_files:** [`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `CHANGELOG.md`]
- **do_not_touch:** [`rules/`, `skills/`, `commands/`, `agents/`]
- **reference_files:** [`CHANGELOG.md`]
- **proposal:** N/A — known pattern

## Objective

Bump the plugin version from `2.10.2` to `2.11.0` in both plugin manifest files, and prepend a `## [2.11.0] — 2026-04-14` entry to CHANGELOG.md. This is a **minor** release (new features: Rust template, bootstrap Rust detection, Obsidian skill). The CHANGELOG entry must list all three additions.

## Acceptance Criteria

- [ ] `grep '"version"' .claude-plugin/plugin.json` → shows `"version": "2.11.0"`
- [ ] `grep '"version"' .claude-plugin/marketplace.json` → shows `"version": "2.11.0"`
- [ ] `head -5 CHANGELOG.md | grep "2.11.0"` → version entry is at the top
- [ ] `grep "language-stack-rust\|Rust detection\|obsidian" CHANGELOG.md` → all three features mentioned

## Business Context

User explicitly requested a minor version bump (not patch) for this release. Minor bump is appropriate since we're adding new capabilities (Rust template, new skill).

## CHANGELOG Entry to Add

Prepend after the `# Changelog` header (line 1), before `## [2.10.2]`:

```markdown
## [2.11.0] — 2026-04-14

### Added
- **`rules/language-stack-rust.md`** — Rust language-stack template: `cargo check` + `cargo clippy -- -D warnings` + test diagnostics; engineer non-negotiables (no `.unwrap()` without `// SAFETY:`, no `unsafe` without comment); anti-pattern table with P0/P1/P2 severity; reviewer checks matching severity levels.
- **Bootstrap Rust detection** — `Cargo.toml` detected in Step 1b. Single-stack Rust copies `language-stack-rust.md`; Rust + TypeScript multi-stack assembles a combined file with Backend (Rust) and Frontend (TypeScript) sections.
- **`skills/obsidian.md`** — Obsidian MCP integration skill: vault selection (`obsidian-main` / `obsidian-eduquest` / `obsidian-vpbank`), note templates (session, plan, ADR), capture workflow for dev-loop sessions, and search.

```

## Output

Write result to `docs/results/TASK-04-result.md`
