# TASK-02: Update bootstrap.md — Rust Detection in Step 1b

## Meta
- **id:** TASK-02
- **type:** impl
- **agent:** engineer
- **status:** pending
- **depends_on:** []
- **parallel_safe:** true
- **priority:** P1
- **routing:** Engineer directly — known pattern (markdown edit, same as prior bootstrap changes)

## Context
- **relevant_files:** [`commands/bootstrap.md`]
- **do_not_touch:** [`rules/language-stack-rust.md`, `rules/language-stack-typescript.md`, `rules/language-stack-python.md`]
- **reference_files:** [`commands/bootstrap.md`, `rules/language-stack-rust.md`]
- **proposal:** N/A — known pattern

## Objective

Edit `commands/bootstrap.md` Step 1b to add Rust detection. Currently `Cargo.toml` falls through to the "no template exists" path. Two edits are needed:

1. **Detection rules list** (around line 91–100): add `Cargo.toml` detection line and a `Rust + TypeScript` multi-stack entry.
2. **Action block** (before the `sed` resolution step): add a `Single-stack Rust` branch (cp command) and a `Multi-stack Rust + TypeScript` branch (assembles combined file with Backend Rust + Frontend TypeScript sections, same structure as Python+TypeScript multi-stack).

## Acceptance Criteria

- [ ] `grep -n "Cargo.toml" commands/bootstrap.md | wc -l` → at least 2 lines (detection rule + action branch)
- [ ] `grep "Single-stack Rust" commands/bootstrap.md` → line present
- [ ] `grep "Rust + TypeScript" commands/bootstrap.md` → line present
- [ ] `grep "language-stack-rust.md" commands/bootstrap.md` → line present (the cp command)
- [ ] `grep "Backend (Rust)" commands/bootstrap.md` → line present (multi-stack section header)
- [ ] `grep "stack detected\|multi-stack" commands/bootstrap.md | grep -v "^#"` → TypeScript, JavaScript, Python, Go, Rust entries all present

## Business Context

Without this change, Rust projects that run `/mas:bootstrap` get an empty `rules/language-stack.md` with no diagnostics. This wires up the template created in TASK-01 so bootstrap automatically injects Rust rules for Cargo projects.

## Output

Write result to `docs/results/TASK-02-result.md`
