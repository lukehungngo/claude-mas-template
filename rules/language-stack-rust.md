# Language Stack — Rust

<!-- BEGIN:auto-detected -->

## Rust

### Mandatory Diagnostic Commands

Run ALL of the following before committing or approving. A failure in any command is a P0 — do not proceed.

```bash
cargo check                         # Zero compile errors required
cargo clippy -- -D warnings         # Zero clippy warnings — warnings are errors
{{test-command}}                    # All tests must pass — resolve this from CLAUDE.md `{{test-command}}`; if not set, run `cargo test`
```

**Fallbacks:**
- If `cargo clippy` is not available: run `cargo check` twice and note clippy was skipped
- If `{{test-command}}` is still a literal placeholder (not yet substituted by bootstrap): **do NOT run it** — print a warning: `⚠️  test-command placeholder not resolved — skipping test step. Run /mas:bootstrap to fix.` and continue. Use `cargo test` as fallback.

**Clippy note:** `-- -D warnings` promotes all warnings to errors. If the project uses a custom `clippy.toml` or `#![allow(...)]` attributes in lib.rs, those take precedence. Check `clippy.toml` at project root before running.

### Engineer Rules — Mandatory Before Committing

Before writing the result, run the diagnostic commands above. All must pass.

**Rust Non-Negotiables:**
- No `.unwrap()` or `.expect()` in non-test code without a `// SAFETY:` or `// INVARIANT:` comment explaining why it cannot panic
- No `unsafe` block without a `// SAFETY:` comment that proves the invariant the block relies on
- All public functions must have doc comments (`///`) explaining what they do and what errors they return
- Use `?` operator for error propagation — do not chain `.unwrap()` for control flow
- Prefer `thiserror` or `anyhow` for error types — do not use `Box<dyn Error>` as a public return type
- No `.clone()` on types that implement `Copy`, and no `.clone()` of large owned data without a justification comment

**Anti-Patterns — Auto-flag in self-review:**

| Pattern | Severity | Notes |
|---------|----------|-------|
| `.unwrap()` in non-test code without `// SAFETY:` | P1 | Panics in production — use `?` or handle the error explicitly |
| `.expect("some message")` without `// INVARIANT:` | P1 | Same as unwrap — the message doesn't make it safe |
| `unsafe` block without `// SAFETY:` comment | P0 | Undefined behaviour risk — must prove safety invariant |
| `std::mem::transmute` without `// SAFETY:` | P0 | Type punning — extremely dangerous |
| Blocking syscall inside `async fn` | P1 | Stalls the async executor — use `tokio::fs`, `tokio::time::sleep` |
| `.clone()` inside a hot loop on non-`Copy` types | P2 | Allocation per iteration — extract or use references |
| `panic!()` reachable from library code | P1 | Libraries must not panic — return `Result` instead |
| `unwrap_or_else(|_| panic!(...))` | P1 | Hidden panic — same as above |
| Unused `Result` (`let _ = risky_fn()`) | P1 | Silently drops errors — use `?` or log |
| `Box<dyn Error>` as public return type | P2 | Erases error type — use concrete error or `thiserror` |
| Hardcoded secrets or credentials | P0 | Never in source — use env vars |

### Reviewer Rules — Language-Specific Checks

**Step 1 of Phase B MUST include the diagnostic commands above. A review cannot be APPROVED if any diagnostic fails — this is a P0.**

**Language-Specific P0 Checks (always block):**
- `unsafe` block without `// SAFETY:` comment
- `std::mem::transmute` without `// SAFETY:` comment
- Hardcoded credentials, API keys, or secrets
- `panic!()` reachable from public library API

**Language-Specific P1 Checks (must fix):**
- `.unwrap()` or `.expect()` in non-test code without `// SAFETY:` or `// INVARIANT:` comment
- Blocking call inside `async fn` (file I/O, sleep, network — without `tokio::` equivalent)
- Unused `Result` silently dropped (`let _ = risky_fn()`)
- `panic!()` inside `impl` blocks callable from non-test code

**Language-Specific P2 Checks (should fix):**
- `.clone()` inside hot loops on non-`Copy` types
- `Box<dyn Error>` as public return type (prefer `thiserror` enum)
- Missing `///` doc comment on public function or type
- Unnecessary `.to_string()` / `.to_owned()` churn inside loops

<!-- END:auto-detected -->

## Project-Specific Rules

<!-- Add project-specific anti-patterns and rules below. This section is preserved on --update. -->
