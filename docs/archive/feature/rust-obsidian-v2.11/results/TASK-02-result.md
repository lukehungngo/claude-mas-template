## TASK-02 Result

### Summary

Added Rust stack detection and template wiring to `commands/bootstrap.md` Step 1b. Three targeted edits were made:

1. **Detection rules list** — Added `Cargo.toml` → Rust stack detected and `Rust + TypeScript detected` multi-stack entry alongside existing TypeScript, JavaScript, Python, and Go rules.

2. **Action block** — Inserted `Single-stack Rust` (cp command) and `Multi-stack Rust + TypeScript` (assembled file with Backend Rust + Frontend TypeScript sections, mirroring Python+TypeScript structure) immediately before the sed resolution block.

3. **Fallback example** — Removed Rust from `(e.g., Go, Rust)` since Rust now has a template; now reads `(e.g., Go)`.

### Files Modified

- `commands/bootstrap.md` — 3 edits, +37 lines net

### Tests Added

0 — this task is a documentation edit with no code logic.

### Acceptance Criteria

All six criteria pass:
- `grep -n "Cargo.toml" commands/bootstrap.md | wc -l` → 4
- `grep "Single-stack Rust" commands/bootstrap.md` → present
- `grep "Rust + TypeScript" commands/bootstrap.md` → present
- `grep "language-stack-rust.md" commands/bootstrap.md` → present
- `grep "Backend (Rust)" commands/bootstrap.md` → present
- TypeScript, JavaScript, Python, Go, Rust all present in stack detected/multi-stack lines

### Deviations

None.

### Concerns / Follow-ups

- `language-stack-rust.md` is referenced but marked `do_not_touch` in this task — it must exist in the plugin cache for the `cp` command to work at runtime. Verify the file exists before the next release.
