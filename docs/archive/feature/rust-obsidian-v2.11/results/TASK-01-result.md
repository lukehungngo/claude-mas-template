## TASK-01 Result

### Summary

Created `rules/language-stack-rust.md` following the exact same structure as the TypeScript and Python templates. The file is ready to be copied by bootstrap into a user project's `rules/language-stack.md` when a `Cargo.toml` is detected.

### Files Modified

- `rules/language-stack-rust.md` — created (77 lines)

### Tests Added

0 — this task produces a documentation/template file. Acceptance criteria verified via grep commands (all passed).

### Acceptance Criteria

| Check | Command | Result |
|-------|---------|--------|
| BEGIN/END markers | `grep -c "BEGIN:auto-detected\|END:auto-detected"` | 2 (PASS) |
| Section headers | `grep -c "Mandatory Diagnostic Commands\|Engineer Rules\|Reviewer Rules\|Project-Specific Rules"` | 4 (PASS) |
| cargo commands | `grep "cargo check\|cargo clippy\|cargo test\|{{test-command}}"` | All 4 present (PASS) |
| P0/P1/P2 lines | `grep "P0\|P1\|P2" | wc -l` | 16 >= 10 (PASS) |
| unsafe/unwrap/SAFETY | `grep "unsafe\|unwrap\|SAFETY" | wc -l` | 11 >= 6 (PASS) |

### Deviations

None. The file matches the content specified in the task instructions exactly.

### Concerns / Follow-ups

None.
