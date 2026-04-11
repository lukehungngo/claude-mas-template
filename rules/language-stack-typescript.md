# Language Stack — TypeScript

<!-- BEGIN:auto-detected -->

## TypeScript

### Mandatory Diagnostic Commands

Run ALL of the following before committing or approving. A failure in any command is a P0 — do not proceed.

```bash
tsc --noEmit                            # Zero type errors required
eslint src/ --ext .ts --max-warnings 0  # Zero lint warnings required
{{test-command}}                        # All tests must pass
```

If `eslint` is not installed, fall back to: `npx eslint src/ --ext .ts`
If `src/` does not exist, use the directory where TypeScript source lives (check `tsconfig.json` → `include` or `rootDir`).

### Engineer Rules — Mandatory Before Committing

Before writing the result, run the diagnostic commands above. All must pass.

**TypeScript Non-Negotiables:**
- No `any` type without an explicit justification comment (`// justification: ...`)
- All async functions must have error handling (try/catch or `.catch()`)
- Prefer `Promise.all()` over sequential `await` for independent async operations
- All API boundaries must validate input using Zod (or the project's schema library)
- Exported functions must have explicit return type annotations

**Anti-Patterns — Auto-flag in self-review:**

| Pattern | Severity | Notes |
|---------|----------|-------|
| `as any` | P1 | Flag unless justification comment present |
| `!` non-null assertion without null guard | P1 | Use optional chaining or explicit null check |
| `==` instead of `===` | P2 | Use strict equality always |
| `async` function inside `.forEach()` | P1 | Fire-and-forget anti-pattern; use `for...of` or `Promise.all` |
| `useEffect` with missing dependency array | P1 | React only; triggers infinite loops |
| `console.log` in production code | P2 | Remove before committing |
| `eval()` or `new Function()` with user input | P0 | Security — never allowed |
| `innerHTML` with unsanitized content | P0 | XSS — use textContent or sanitize |
| SQL string concatenation (not parameterized) | P0 | Injection — use prepared statements |

### Reviewer Rules — Language-Specific Checks

**Step 1 of Phase B MUST include the diagnostic commands above. A review cannot be APPROVED if any diagnostic fails — this is a P0.**

**Language-Specific P0 Checks (always block):**
- `eval()` or `new Function()` with user input
- `innerHTML` with unsanitized content
- SQL string concatenation (not parameterized)
- Hardcoded credentials in source

**Language-Specific P1 Checks (must fix):**
- `any` type without justification comment
- Unhandled promise rejection (floating promise, missing `.catch()`)
- `async/forEach` anti-pattern
- Missing `await` on async call in critical path
- API endpoint accepts unvalidated user input

**Language-Specific P2 Checks (should fix):**
- `==` instead of `===`
- `!` non-null assertion without guard
- Sequential awaits that could be `Promise.all`
- Missing return type annotation on exported functions

<!-- END:auto-detected -->

## Project-Specific Rules

<!-- Add project-specific anti-patterns and rules below. This section is preserved on --update. -->
