# TASK-01: Create rules/language-stack-rust.md

## Meta
- **id:** TASK-01
- **type:** impl
- **agent:** engineer
- **status:** pending
- **depends_on:** []
- **parallel_safe:** true
- **priority:** P1
- **routing:** Engineer directly — known pattern (mirrors language-stack-typescript.md and language-stack-python.md)

## Context
- **relevant_files:** [`rules/language-stack-rust.md` (create new)]
- **do_not_touch:** [`rules/language-stack-typescript.md`, `rules/language-stack-python.md`, `commands/bootstrap.md`]
- **reference_files:** [`rules/language-stack-typescript.md`, `rules/language-stack-python.md`]
- **proposal:** N/A — known pattern

## Objective

Create `rules/language-stack-rust.md` following the exact same structure as the existing TypeScript and Python templates. This file will be copied by bootstrap into user project `rules/language-stack.md` when a `Cargo.toml` is detected. It must have `<!-- BEGIN:auto-detected -->` / `<!-- END:auto-detected -->` markers, a Mandatory Diagnostic Commands section with cargo commands, Engineer Rules with Rust-specific non-negotiables and an anti-pattern table, and Reviewer Rules with P0/P1/P2 checks.

## Acceptance Criteria

- [ ] `grep -c "BEGIN:auto-detected\|END:auto-detected" rules/language-stack-rust.md` → outputs `2`
- [ ] `grep -c "Mandatory Diagnostic Commands\|Engineer Rules\|Reviewer Rules\|Project-Specific Rules" rules/language-stack-rust.md` → outputs `4`
- [ ] `grep "cargo check\|cargo clippy\|cargo test\|{{test-command}}" rules/language-stack-rust.md` → all 4 appear
- [ ] `grep "P0\|P1\|P2" rules/language-stack-rust.md | wc -l` → at least 10 lines (anti-pattern table + reviewer checks)
- [ ] `grep "unsafe\|unwrap\|SAFETY" rules/language-stack-rust.md | wc -l` → at least 6 lines

## Business Context

The bootstrap Step 1b currently falls through to a "no template" path for Rust projects. Adding this template enables automatic language-stack rule injection for Rust projects — matching the TypeScript and Python coverage shipped in v2.10.0.

## Output

Write result to `docs/results/TASK-01-result.md`
