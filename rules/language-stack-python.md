# Language Stack — Python

<!-- BEGIN:auto-detected -->

## Python

### Mandatory Diagnostic Commands

Run ALL of the following before committing or approving. A failure in any command is a P0 — do not proceed.

```bash
mypy .          # Zero type errors required (if mypy is installed)
ruff check .    # Zero lint warnings required (preferred over flake8)
{{test-command}} # All tests must pass
```

**Fallbacks:**
- If `mypy` is not installed: `python -m mypy .` or skip with a note in the result
- If `ruff` is not installed: `flake8 .` or `pylint src/`
- If neither linter is installed: run `python -m py_compile $(find . -name "*.py" | grep -v __pycache__)` and print a warning

### Engineer Rules — Mandatory Before Committing

Before writing the result, run the diagnostic commands above. All must pass.

**Python Non-Negotiables:**
- No bare `except:` — always catch specific exceptions (`except ValueError:`, `except (IOError, OSError):`)
- No mutable default arguments (`def foo(items=[])` → use `None` and assign inside)
- No f-string SQL queries — use parameterized queries (`cursor.execute("SELECT * FROM t WHERE id = %s", (id,))`)
- Use context managers for file/connection/network operations (`with open(...) as f:`)
- Type annotations required on all public functions and class methods

**Anti-Patterns — Auto-flag in self-review:**

| Pattern | Severity | Notes |
|---------|----------|-------|
| `except:` (bare, no exception type) | P1 | Catches SystemExit and KeyboardInterrupt — use `except Exception:` at minimum |
| `except Exception: pass` | P1 | Silently swallows errors — always log or re-raise |
| Mutable default argument `def f(x=[])` | P1 | Shared state across calls — use `x=None` |
| f-string in SQL query | P0 | SQL injection — use parameterized queries |
| `eval(user_input)` or `exec(user_input)` | P0 | Remote code execution — never |
| `os.system()` with user input | P0 | Shell injection — use `subprocess.run` with list args |
| `subprocess.shell=True` with user input | P0 | Shell injection — same as above |
| N+1 queries in loops (ORM) | P1 | Use `select_related`/`prefetch_related` (Django) or `joinedload` (SQLAlchemy) |
| `print()` in production code | P2 | Use `logging` module |
| Missing `__all__` on public modules | P3 | Optional — define public API explicitly |

### Reviewer Rules — Language-Specific Checks

**Step 1 of Phase B MUST include the diagnostic commands above. A review cannot be APPROVED if any diagnostic fails — this is a P0.**

**Language-Specific P0 Checks (always block):**
- f-string, `%`-format, or `.format()` used in SQL query string
- `eval()` or `exec()` with user-controlled input
- `os.system()` or `subprocess.run(shell=True)` with user input
- Hardcoded credentials, API keys, or secrets

**Language-Specific P1 Checks (must fix):**
- Bare `except:` (no exception type specified)
- `except Exception: pass` (silent swallow)
- Mutable default argument
- Missing context manager for file/DB/network operations
- N+1 queries in loops

**Language-Specific P2 Checks (should fix):**
- Missing type annotations on public functions
- `print()` statements in non-script code (use `logging`)
- String concatenation to build file paths (use `pathlib.Path`)
- Missing `__all__` on public module interface

<!-- END:auto-detected -->

## Project-Specific Rules

<!-- Add project-specific anti-patterns and rules below. This section is preserved on --update. -->
