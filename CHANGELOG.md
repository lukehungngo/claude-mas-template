# Changelog

## [2.21.0] — 2026-04-18

### Task Sizing + Precise Spec + Bug-Fixer Scope Constraints

- **task-spec: `size` field** — Tasks now carry `size: micro | standard | complex` with inline routing annotations for each level (micro skips researcher + reflect + delivery report, complex forces researcher + deep review).
- **task-spec: `success_test` field** — Exact test command + specific assertion that proves the task is done. Replaces vague acceptance criteria.
- **task-spec: `contract` field** — Exact function/API signature with return type and raised errors. Gives engineer and reviewer a shared definition of done.
- **task-spec: line-ranged `relevant_files`** — Required format is now `file:start-end` (e.g., `src/auth.ts:45-80`), not bare file names.
- **dev-loop: size-based pipeline routing** — New `Task Size → Pipeline Variant` table after the routing table. micro → quick review + skip reflect/delivery report. standard → full pipeline. complex → Researcher → Differential Reviewer → Engineer → deep review + reflect.
- **bug-fixer: P0/P1-only scope** — Bug-fixer receives only P0/P1 issues from the review report; P2/P3 explicitly excluded.
- **bug-fixer: file allowlist** — Bug-fixer may only touch files listed in the dispatch's `allowed_files`. Everything else is `do_not_touch`.
- **bug-fixer: minimum-change constraint** — Must fix minimum lines necessary and document "lines changed: N before → M after" in result.
- **bug-fixer: 5-read Analysis Paralysis Guard** — After 5 Read/Grep/Glob calls without writing, stop reading and make the fix or document a specific blocker.
- **validate-dispatch: block `general` agent** — `general` now exits 2 with alternatives: Explore for discovery, MAS specialist for implementation/review/research/bugfix.

## [2.20.0] — 2026-04-18

### Researcher + Differential-Reviewer Hardening + Lint Fixes

- **researcher: underspecified bailout** — If the task spec has no success criteria, constraints, or scope, the Researcher stops immediately and raises a blocker instead of producing a low-confidence proposal.
- **researcher: source quality hierarchy** — Proposals now rank sources: RFCs/specs > academic papers > official repos > engineering blogs > general blog posts. Sources predating 2023 are flagged with a staleness warning.
- **researcher: Confidence field in proposal template** — Each proposal now includes `Confidence: HIGH/MEDIUM/LOW` with rationale. LOW confidence blocks the Differential Reviewer from issuing PROCEED.
- **researcher: Open Questions section** — Proposals include an Open Questions section after References. Non-empty section blocks Differential Reviewer from issuing PROCEED.
- **differential-reviewer: confidence gate** — PROCEED verdict blocked when researcher proposal carries LOW confidence.
- **differential-reviewer: open questions gate** — PROCEED verdict blocked when researcher proposal has unresolved open questions.
- **dev-loop: novel routing pre-screen** — Added criteria check before routing to Researcher to reduce unnecessary dispatches on tasks that clearly use known patterns.
- **tests/lint.sh: false-positive fixes** — Three lint checks updated: unprefixed-dispatch check now ignores echo/BAD-example lines; placeholder check now excludes `language-stack-*.md` (intentional bootstrap templates); orchestrator check now matches dispatch patterns only, not prose role descriptions. Line budgets updated for dev-loop (500) and bootstrap (720) to reflect intentional growth.

## [2.19.0] — 2026-04-17

### Reviewer Optimizations — Diff Classification + Conditional Skill Gates

- **reviewer: Phase 0 diff classification prepass** — Reviewer now runs `git diff --stat` before Phase A/B and classifies the change into docs/config/test-only/refactor/bugfix/feature. Each type routes to a reduced checklist, eliminating expensive checks on low-risk diffs.
- **reviewer: conditional skill gates** — `se-principles` skips for docs/config/test-only/bugfix and single-function fixes ≤ 20 lines. `reliability-review` only invokes when diff touches auth/IO/DB/HTTP keywords. `property-based-testing` only invokes for feature changes or algorithmic diffs.
- **dispatch templates: `change_class` auto-depth hints** — Reviewer dispatch templates #4 and #8 now accept `change_class` (feature/bugfix/refactor/config/test-only/docs/p0-fix). Reviewer auto-selects depth from this value, removing manual depth selection from dispatchers.

## [2.18.0] — 2026-04-17

### Reflect Agent Optimization + Stop Hook Loop Fix

- **reflect agent: scope boundary sharpened** — Reflect now checks *what* was built against the spec, not *why*. Engineer result narratives (`docs/results/`) removed from all dispatch points (agent CLAUDE.md, dispatch template #9, `commands/reflect.md`, dev-loop Phase 2E). The diff is sufficient; engineer reasoning is the Reviewer's domain.
- **reflect agent: Phase 2 reframed as scope-creep detection** — "Was this the simplest approach?" dropped entirely (Reviewer's job). Phase 2 now asks two questions only: is this change traceable to a requirement? does it stay within that requirement's scope?
- **reflect agent: fast path** — If Phase 1 shows all requirements COVERED and zero unmapped tasks, Phase 2 is a single-pass spot check rather than exhaustive audit. Estimated 60% token reduction on passing deliveries.
- **reflect agent: checklist condensed 17 → 8 items** — Decision Quality section removed. Feature-Level SRP merged. Architectural Fitness merged.
- **reflect agent: token budget instruction** — Always start with `git diff --stat`. If diff >500 lines, sample (first 50 lines per file) and flag it.
- **reflect agent: verdict-first report** — `## Verdict` now appears at the top of the output report so the orchestrator finds it without scrolling.
- **reflect agent: reinterpretation check** — Phase 1 now explicitly checks that each COVERED requirement matches the *literal intent*, not just nominally. Catches the most common silent failure mode.
- **fix: stop hook infinite loop** — `validate-pipeline.sh` used `exit 2` to block session end when reflect was missing. This created an infinite loop: hook blocks → Claude responds → session tries to stop → hook fires again. Changed to `exit 0` with a warning message. The hook still alerts on missing reflect, but no longer traps the session.
- **tests/lint.sh: regression guards** — Checks 13 and 14 added to lock in the reflect scope-boundary changes against future regression.

## [2.17.0] — 2026-04-17

### Brainstorm Smart Next-Step Suggestion

- **brainstorm: conditional primary suggestion in Step 4** — After saving the brainstorm, the command now emits a primary next-step suggestion tailored to the concluded output type. Root cause confirmed → `/mas:bug-fix`. Solution direction clear or idea validated YES → `/mas:dev-loop`. Framing/Answer/Idea-NO → no suggestion (human decides). Analysis of a hunch → conditional on whether a root cause or solution surfaced. Free-form fallback for cases that don't fit cleanly.
- **brainstorm: alternatives menu preserved** — The existing three-line `/mas:dev-loop` / `/mas:bug-fix` / "Or continue refining" menu is kept as a fallback beneath the primary suggestion. Change is additive.
- **Step 4 renamed** — "Save" → "Save and Suggest" to reflect new behavior. Contract table, Output Format, and Integration diagram are unchanged; the smart-suggestion logic reuses the existing input/output taxonomy as its decision keys (single source of truth).

## [2.16.0] — 2026-04-15

### Brainstorm Hardening + Chain Wiring

- **brainstorm: 8 input/output contract** — Context→Framing, Problem→Framing/Solution, Observation→Hypothesis/Root cause, Question→Answer, Idea→Validation, Hunch→Analysis, Constraints→Feasibility, Criteria→Evaluation/Confidence
- **brainstorm: 7 steps → 4** — Receive → First Principles → Deliver → Save. Removed gates, dead code, over-structured template.
- **brainstorm: Musk's 3-step framework** as the explicit foundation, removed redundant three questions
- **brainstorm: honest outputs** — problem may need reframing not just solving, observation may yield hypothesis not confirmed root cause
- **brainstorm → dev-loop → bug-fix chain wired** — brainstorm suggests next command with doc path; dev-loop and bug-fix read brainstorm doc as input for planning; dev-loop no longer references superpowers:brainstorming
- **bootstrap: .mcp.json added to .gitignore**

## [2.15.0] — 2026-04-15

### Added
- **`/mas:brainstorm` command** — First principles decomposition for turning vague observations, ideas, or problems into clear, actionable problem statements. 7-step process: receive input → challenge assumptions → decompose to fundamentals → discover real problem → build up from truths → save brainstorm → suggest next steps. Three questions applied at every step: can we break it down further? can we do it differently? can we remove something without breaking it? Standalone — no agents, no execution. Output saved to `docs/brainstorms/`.
- **`docs/brainstorms/` directory** — added to bootstrap mkdir for brainstorm artifacts

## [2.14.1] — 2026-04-15

### Fixed
- **dev-loop + bug-fix: block superpowers:subagent-driven-development** — Plan header says "Use superpowers:subagent-driven-development" which caused 3 sessions to bypass MAS agents. Both commands now explicitly say to ignore the plan's execution handoff and dispatch MAS agents directly.

## [2.14.0] — 2026-04-15

### Bug-Fix Pipeline — Plan Step + Hook Fix

- **bug-fix: added Step 4 (Plan)** — After debugging (Step 3), write a fix plan via `superpowers:writing-plans` before dispatching the Bug-Fixer. Plan becomes source of truth for both the fix and the delivery report. Bug-Fixer and Reviewer dispatch prompts now include the plan.
- **bug-fix: renumbered steps** — Clean integer steps 1-9 (was 1-7 with fractional 3.5 and 6.5). Pipeline: Clarify → Branch → Debug → Plan → Fix → Review → Verify → Report → Finish.
- **validate-pipeline.sh: fixed false-positive BLOCKED** — Plans persist on main after merge (plan-report contract), but the hook was using "plans exist" as "active pipeline" signal. Changed to "results or reviews exist" as the active pipeline detection. No more spurious blocks on session stop.

## [2.13.0] — 2026-04-15

### Plan-Report Contract

User-facing workflow simplified to: **spec → plan → report**. Internal pipeline plumbing (task specs, result files, review files) is no longer visible to the user.

#### dev-loop
- **Removed:** Phase 1 (Decompose) — no more `docs/tasks/pending/TASK-{id}.md` file management
- **Removed:** Phase 3 (Close & Holistic Check) — replaced by delivery report
- **Removed:** Artifact verification block checking for TASK-* files
- **Added:** Step 5.5 (Delivery Report) — validates delivery against the plan, saved to `docs/superpowers/reports/`
- **Changed:** Phase 1 is now "Route" — dispatches engineers directly from plan tasks
- **Changed:** Pipeline Self-Audit simplified to 6 checks (was 8 file-existence checks)
- **Changed:** Reflect Agent reads plan instead of task specs

#### bug-fix
- **Added:** Step 6.5 (Bug Fix Report) — structured report with bug, root cause, fix, review verdict, verification

#### finishing-branch
- **Changed:** Step 4 "Preserve Artifacts" → "Clean Up Internal Artifacts" — removes `docs/results/`, `docs/reports/`, `docs/tasks/`, `docs/design/` before merge. Only `docs/superpowers/plans/` and `docs/superpowers/reports/` persist.

#### bootstrap
- **Changed:** `docs/tasks/{pending,in-progress,done,blocked}` directories no longer created. `docs/superpowers/{plans,reports}` created instead.

#### dispatch-templates
- **Changed:** All templates reference plan tasks directly instead of `docs/tasks/pending/TASK-{id}.md` files
- **Removed:** `docs/tasks/` from Output Directory Convention table
- **Added:** `docs/superpowers/plans/` and `docs/superpowers/reports/` to Output Directory Convention table

## [2.12.2] — 2026-04-15

### Fixed
- **bootstrap: validate-dispatch.sh stub missing features** — Replaced 28-line stub with full 92-line production hook including debug logging (`~/.claude/hook-debug.log`), haiku model blocking for reviewer (depth-aware), and quick-reference error messages.
- **bootstrap: validate-skill.sh stub missing allowlist** — Replaced stub with full hook including `allowed-bare-skills.txt` check. Fixed MAS_SKILLS: removed `test-driven-development` (not a MAS skill), removed duplicates (`finishing-branch`, `subagent-driven-development`) already caught by SUPERPOWERS_SKILLS, added `obsidian`.
- **bootstrap: settings.json missing 4 of 6 hooks** — Added PostToolUse (lint.sh on Edit|Write), Stop (pre-stop-gate.sh + validate-pipeline.sh), and PreToolUse (suggest-compact.sh on Edit|Write|Bash). Bootstrapped projects now get all 6 hooks wired.
- **bootstrap: lint.sh and pre-stop-gate.sh were bare stubs** — Replaced with full templates including git-diff-based lint triggering and structured quality summary output.
- **bootstrap: suggest-compact.sh and validate-pipeline.sh not installed** — Now written inline by bootstrap and wired into settings.json Stop hooks.

## [2.12.1] — 2026-04-15

### Fixed
- **bootstrap writes `rules/` instead of `.claude/rules/`** — Language-stack files were written to `rules/language-stack.md` but Claude Code loads rules from `.claude/rules/`. Fixed all 21 path references across `commands/bootstrap.md`, `agents/engineer/CLAUDE.md`, and `agents/reviewer/CLAUDE.md`.

## [2.12.0] — 2026-04-15

### Added
- **`templates/local-inject.md`** — MAS pipeline overlay for team repos. Contains the Mandatory Workflow, Agent Routing Table, and Dispatch Rules without project-specific sections (build commands, code style, invariants). Installed to `~/.claude/projects/<path>/CLAUDE.md` so it loads alongside the team repo's own CLAUDE.md without modifying the shared repo.
- **`scripts/mas-local-install.sh`** — One-command installer for the local overlay. Usage: `mas-local-install.sh <project-dir> [--has-ui]`. Supports `--list` to show all installed projects and `--uninstall` to remove. Converts project paths to Claude Code's key format and writes to the correct `~/.claude/projects/` directory.

### Context
Audit of 456 sessions found 5 sessions in the last 2 days that referenced MAS workflows but dispatched all agents as generic `Agent()` without `subagent_type`. Root cause: team repos without CLAUDE.md MAS routing instructions. The local-inject approach fixes this without requiring changes to shared repos.

## [2.11.1] — 2026-04-14

### Fixed
- README: skill count updated 8 → 9 (obsidian added to list)
- bootstrap: `obsidian` added to `MAS_SKILLS` in validate-skill.sh template (hook enforcement)
- language-stack-rust: add `cargo fmt --check` as mandatory diagnostic, with fallback note

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
