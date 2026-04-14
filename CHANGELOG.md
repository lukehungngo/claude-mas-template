# Changelog

## [2.11.0] — 2026-04-14

### Added
- **`rules/language-stack-rust.md`** — Rust language-stack template: `cargo check` + `cargo clippy -- -D warnings` + test diagnostics; engineer non-negotiables (no `.unwrap()` without `// SAFETY:`, no `unsafe` without comment); anti-pattern table with P0/P1/P2 severity; reviewer checks matching severity levels.
- **Bootstrap Rust detection** — `Cargo.toml` detected in Step 1b. Single-stack Rust copies `language-stack-rust.md`; Rust + TypeScript multi-stack assembles a combined file with Backend (Rust) and Frontend (TypeScript) sections.
- **`skills/obsidian/SKILL.md`** — Obsidian MCP integration skill: vault selection (`obsidian-main` / `obsidian-eduquest` / `obsidian-vpbank`), note templates (session, plan, ADR), capture workflow for dev-loop sessions, and search.

## [2.10.2] — 2026-04-12

### Fixed
- bootstrap: use `|` delimiter in sed to handle test commands containing `/` (e.g. `pytest --cov=src/`)
- bootstrap: add macOS vs Linux `sed -i` usage note
- bootstrap: add explicit notice for JavaScript-only stack (no template available)
- bootstrap: replace `\n` escape notation in multi-stack instructions with explicit prose
- reviewer: restructure Phase B step 1.5 as sub-bullet under step 1 (cleaner numbering)
- language-stack-typescript: add `tsc` fallback note and `{{test-command}}` placeholder guard
- language-stack-python: add `{{test-command}}` placeholder guard and promote P3 → P2 severity

## [2.10.1] — 2026-04-12

### Fixed

- **ESLint v9 compatibility** in `rules/language-stack-typescript.md` — `--ext` flag was removed in ESLint v9 (now default). Template now shows version-aware commands and recommends `npm run lint` when defined.
- **`{{test-command}}` substitution** — Bootstrap Step 1b now runs a `sed` pass after copying the template, resolving `{{test-command}}` with the detected test command. Mirrors the substitution already done for CLAUDE.md.
- **Bootstrap Step 7 report** — Now lists `rules/language-stack.md: written` so users know language diagnostics are active.

## [2.10.0] — 2026-04-12

### Language-Specific Hardening — Python + TypeScript

Bootstrap-injected language context with no new agents. When you run `/mas:bootstrap`, it detects your stack and writes `rules/language-stack.md`. Every subsequent engineer and reviewer dispatch reads it automatically.

#### Bootstrap
- **Step 1b** — Detects TypeScript (`tsconfig.json`), Python (`pyproject.toml` / `requirements.txt` / `setup.py`), multi-stack (both), or unsupported stacks (Go, Rust). Copies the matching template to `rules/language-stack.md`.
- **Multi-stack support** — Single `rules/language-stack.md` with `## Backend (Python)` and `## Frontend (TypeScript)` sections, wrapped in `<!-- BEGIN/END:auto-detected -->` markers.
- **`--update` behavior** — Re-running `bootstrap --update` regenerates the auto-detected section while preserving user-edited `## Project-Specific Rules`.

#### Language Templates
- **`rules/language-stack-typescript.md`** — Diagnostics: `tsc --noEmit` + `eslint src/ --ext .ts,.tsx`. Anti-patterns: `as any` (P1), `async/forEach` (P1), `eval()` / `innerHTML` / SQL concat (P0). Reviewer P0/P1/P2 checks.
- **`rules/language-stack-python.md`** — Diagnostics: `mypy .` + `ruff check .`. Anti-patterns: bare `except:` (P1), mutable defaults (P1), f-string SQL (P0), `eval()`/`exec()` (P0). Reviewer P0/P1/P2 checks.

#### Engineer
- Phase 4 Pre-completion: if `rules/language-stack.md` exists, run all Mandatory Diagnostic Commands before writing the result.

#### Reviewer
- Phase B Step 1: if `rules/language-stack.md` exists, run all Mandatory Diagnostic Commands — failure is P0 regardless of other findings.
- Phase B Step 1.5 (new): apply language-specific anti-pattern checks from `rules/language-stack.md`.

---

## [2.9.0] — 2026-04-11

### Identity Sharpening — Engineer + Reviewer

The MAS template's unique value is structural enforcement over prose guidance. This release closes the gaps real session data exposed (37 reviews, 27 sessions audited).

#### Reviewer
- **Depth protocol**: Three review depths (quick/standard/deep) with model floor per depth. Controller picks depth; hook enforces floor. Replaces the binary "block haiku" approach with a protocol that mirrors how senior engineers actually delegate review work.
- **Machine-readable frontmatter**: YAML header in every `docs/reports/TASK-*-review.md` — verdict, depth, model, finding counts, reviewed_at, commit. Enables `mas-audit.py` to measure review quality automatically.

#### Engineer
- **Deviation taxonomy**: 4-rule protocol for auto-fix vs stop. Rule 1: auto-fix bugs. Rule 2: auto-fix missing safety. Rule 3: stop for ambiguous requirements. Rule 4: stop for architectural changes. Replaces "treat all ambiguity as a blocker."
- **Analysis paralysis guard**: 5+ reads without a write forces a decision. Eliminates token-burning read loops.
- **Stub tracker**: Pre-completion scan for unwired components (unregistered routes, unwired services). Catches the "wrote the file but didn't register it" class of error before review.

#### Hook
- `validate-dispatch.sh`: Reviewer depth enforcement — haiku blocked for standard/deep depth, allowed for quick depth.
- `templates/dispatch-templates.md`: All reviewer dispatch templates now include `depth: standard` field.

---

## [2.8.0] — 2026-04-11

### Added

- **validate-skill.sh allowlist** — `$CLAUDE_PROJECT_DIR/.claude/hooks/allowed-bare-skills.txt` lets projects exempt custom skill names from blocking. Add bare names one per line.
- **validate-pipeline.sh sentinel** — `docs/reports/.reflect-skipped` escape hatch for intentional partial sessions. File must contain a non-empty reason; the Stop hook exits 0 with the reason printed instead of blocking.
- **Between-batch review gate** in `commands/dev-loop.md` Phase 2B — Explicit check before each new engineer batch: `ls docs/reports/TASK-*-review.md | wc -l` must equal `ls docs/results/TASK-*-result.md | wc -l`. If reviews < results, block the next engineer batch. Addresses 52% reviewer rate gap.
- **Debug logging** in `validate-dispatch.sh` — All hook decisions logged to `~/.claude/hook-debug.log` with timestamps, TOOL_NAME, subagent type, and ALLOWED/BLOCKED decision.
- **`.claude/scripts/audit-hook-firing.sh`** — Reads debug log, reports allowed/blocked counts, block rate, blocked agent types by frequency, and consecutive-retry patterns (model retrying bare names after block).

### Changed

- `commands/bootstrap.md` — validate-skill.sh write instructions now include allowlist note.
- `commands/dev-loop.md` — Between-batch gate in Phase 2B; reflect-skip sentinel documented in Phase 2E; review count invariant note updated.

---

## [2.7.0] — 2026-04-06

### Added

- **`validate-skill.sh` hook** — PreToolUse hook that blocks bare superpowers/MAS skill names. Enforces `superpowers:writing-plans` over `writing-plans`, `mas:verification` over `verification`, etc.
- **Reflect once-only guard** in `validate-dispatch.sh` — Blocks re-dispatch of `mas:reflect-agent:reflect-agent` when `docs/reports/reflect-report.md` already exists.

### Changed

- **`validate-pipeline.sh` upgraded to blocking** — When a full pipeline ran (results + reviews exist) but `docs/reports/reflect-report.md` is missing, session end is now blocked (exit 2) instead of warned (exit 0).
- **`commands/bootstrap.md`** — Now installs `validate-dispatch.sh` and `validate-skill.sh` in user projects, fixing naming drift in externally bootstrapped repos.

### Removed

- **`agents/orchestrator/`** removed from plugin distribution — Was deprecated in v2.0, now physically absent from the plugin. Still exists in the template repo for reference.

---

## [2.6.0] — 2026-04-06

### Added

- **Pipeline validation Stop hook** (`hooks/validate-pipeline.sh`) — Structurally blocks session end without required artifacts (`docs/results/`, `docs/reports/`). Prevents silent skips of the verification gate.
- **Context compaction suggester hook** (`hooks/suggest-compact.sh`) — Warns when context window exceeds 70% and suggests `/compact` before the model degrades. Addresses context-overflow-induced errors.
- **Lesson #25: Pipeline enforcement gap** — Documents the root cause of agents bypassing verification: prose rules fail, structural constraints (hooks) work.

### Changed

- **README updated** — Hook count updated from 2 to 4 to reflect new operational hooks.

---

## [2.0.0] — 2026-03-29

### Breaking Changes

- **Pipeline reduced from 9 steps to 6** — Removed Clarify (absorbed into Plan), Explore (absorbed into Plan), and Validate Requirements (absorbed into Execute Phase 4). Steps 7/8/9 renumbered to 5/6.
- **Orchestrator agent deprecated** — Flat dispatch architecture: dev-loop dispatches agents directly at Level 0. Orchestrator-as-subagent failed because Agent tool is unavailable at Level 1 nesting.
- **Bootstrap no longer copies files locally** — Agents, skills, and commands are provided by the plugin. Bootstrap only detects stack, fills CLAUDE.md, creates hooks and directories.
- **All agent dispatches use `mas:` plugin prefix** — e.g., `mas:engineer:engineer` instead of `engineer`. Unprefixed commands require local install via git clone.

### Added

- **Flat dispatch in Step 4 (Execute)** — Dev-loop directly routes and dispatches agents using routing table + dispatch templates. Includes Phase 1 (decompose), Phase 2 (route & dispatch), Phase 3 (review cycles), Phase 4 (close + holistic check).
- **Artifact verification gate** — `docs/results/TASK-*-result.md` and `docs/reports/TASK-*-review.md` must exist before Step 5. Structurally prevents main session from implementing directly.
- **`reliability-review` skill** — 9-section checklist: error handling, resource cleanup, concurrency, unbounded operations, N+1 queries, input validation, security, timeout/retry, memory/performance.
- **Duplication audit in Reviewer Phase B** — Checks for code, intent, and knowledge duplication across the codebase.
- **Tier 1 static analysis** (`tests/lint.sh`) — 12 automated checks, 15 assertions. Run after every commit.
- **Tier 2 routing tests** (`tests/routing.md`) — 22 test cases across 6 categories with scoring rubric.
- **Checkpoint assertions** — Anti-bypass blocks before Steps 4, 5, 6 referencing real audit data.
- **BAD/GOOD example pairs** — Concrete wrong vs right `--auto` behavior in dev-loop and bug-fix.
- **Pipeline self-audit checklist** — Evidence-based verification before finishing.
- **Lessons learned document** (`docs/lesson_learn/2026-03-28.md`) — 12 lessons from audit session.

### Changed

- **Reviewer Phase B expanded to 9 checks** — Added reliability-review skill, property-based-testing skill, and duplication audit.
- **Dispatch templates include skill references** — Engineer (se-principles, TDD), Reviewer (se-principles, reliability-review, property-based-testing), Bug-Fixer (TDD, systematic-debugging).
- **Rules reduced 46%** — 191 → ~103 rules. Removed duplicates, restatements, and agent-inherited rules.
- **agent-workflow.md compressed** — 218 → 57 lines. 15 narratives → summary table.
- **dev-loop.md reduced 38%** — 492 → 303 lines. Fewer steps, no duplicate rules/lessons.
- **Bootstrap report** updated to reference `/mas:` prefixed commands.

### Removed

- **`rules/architecture.md`** — Template with placeholders, not universal. Use CLAUDE.md Architecture Invariants section instead.
- **Orchestrator dispatch templates from orchestrator CLAUDE.md** — Stripped to pointer. Canonical templates in `templates/dispatch-templates.md`.
- **"Does NOT Do" restatements** — 14 items across 6 agents that just negated their own non-negotiables.
- **dev-loop Lessons Learned table** — Replaced with reference to `rules/agent-workflow.md`.
- **dev-loop Rules section bloat** — 15 rules → 4 (11 restated inline gates/checkpoints).

### Fixed

- All stale Orchestrator references across active files
- Unprefixed `subagent_type` references → `mas:` prefix
- `.claude/templates/` stale paths → `templates/`
- README counts (commands: 4, rules: 4, templates: 3)
- README file tree accuracy
- Severity table duplication in reviewer → reference to severity-discipline.md

## [1.3.0] — 2026-03-27

- Initial battle-tested release with 7 agents, 13 skills, 9-step pipeline
