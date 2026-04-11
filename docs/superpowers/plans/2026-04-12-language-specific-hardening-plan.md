# Language-Specific Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Python and TypeScript language-aware diagnostics and anti-pattern enforcement to MAS engineer + reviewer agents, via bootstrap-injected rules (no new agents, no prompt changes).

**Architecture:** Bootstrap detects the language stack once and writes `rules/language-stack.md`. Engineer and reviewer agents read `rules/` via existing rules-loading behavior — language hardening applies automatically. No new agents, no changes to dispatch.

**Tech Stack:** Bash (bootstrap detection), Markdown (rules template), two agent CLAUDE.md edits.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `commands/bootstrap.md` | Add Step 1b — detect language, write `rules/language-stack.md` |
| Create | `rules/language-stack-typescript.md` | TypeScript template content (diagnostics + anti-patterns) |
| Create | `rules/language-stack-python.md` | Python template content (diagnostics + anti-patterns) |
| Modify | `agents/engineer/CLAUDE.md` | Add language diagnostics step to Phase 4 |
| Modify | `agents/reviewer/CLAUDE.md` | Add language diagnostics + anti-pattern check to Phase B Step 1 |

---

## Task 1: Bootstrap — Language Detection and `rules/language-stack.md` Generation

**Files:**
- Modify: `commands/bootstrap.md` — extend Step 1 and add new Step 1b

### What to add

After the existing Step 1 detection block in `commands/bootstrap.md`, insert a new **Step 1b — Write language-stack rules** section that:
1. Identifies the primary language(s)
2. Copies the matching template from the plugin cache to `rules/language-stack.md`
3. Handles multi-stack (Python backend + TypeScript frontend) with separate sections

- [ ] **Step 1: Read bootstrap.md to confirm insertion point**

Read `commands/bootstrap.md`. The section ends at Step 7. You will insert a new sub-step "Step 1b" between Step 1 (detect stack) and Step 2 (create/update CLAUDE.md). Confirm the exact text surrounding "### Step 2 — Create or update CLAUDE.md" which is your insertion anchor.

- [ ] **Step 2: Write the Step 1b section into bootstrap.md**

In `commands/bootstrap.md`, find the line:

```
### Step 2 — Create or update CLAUDE.md
```

Insert the following block BEFORE that line (add a blank line separator):

```markdown
### Step 1b — Write language-stack rules

Based on detection from Step 1, determine which language stack template(s) to use:

**Detection rules:**
- `tsconfig.json` present → TypeScript stack detected
- `package.json` present (no tsconfig.json) → JavaScript stack detected
- `pyproject.toml` OR `requirements.txt` OR `setup.py` present → Python stack detected
- `go.mod` present → Go stack detected (no template yet — skip)
- Both Python + TypeScript detected → multi-stack project

**For each detected language, copy the template from the plugin cache:**

```bash
PLUGIN_DIR=$(ls -d ~/.claude/plugins/cache/luke-plugins/mas/*/ 2>/dev/null | sort -V | tail -1)
mkdir -p rules
```

**Single-stack TypeScript:**
```bash
cp "$PLUGIN_DIR/rules/language-stack-typescript.md" rules/language-stack.md
```

**Single-stack Python:**
```bash
cp "$PLUGIN_DIR/rules/language-stack-python.md" rules/language-stack.md
```

**Multi-stack (Python + TypeScript):**

Create `rules/language-stack.md` with two sections:

```markdown
# Language Stack

This project has multiple language stacks. Each section below defines the rules for that layer.

---

<!-- BEGIN:auto-detected -->
[paste content of language-stack-python.md here as "## Backend (Python)" section]
[paste content of language-stack-typescript.md here as "## Frontend (TypeScript)" section]
<!-- END:auto-detected -->

## Project-Specific Rules

<!-- Add project-specific anti-patterns and rules below. This section is preserved on --update. -->
```

**If no language template exists for the detected stack** (Go, Rust, etc.):
- Create `rules/language-stack.md` with only a `## Project-Specific Rules` section
- Print: `ℹ️  No language-stack template for {language} yet. Created rules/language-stack.md with an empty Project-Specific Rules section for manual additions.`

**`--update` behavior:**

If `rules/language-stack.md` already exists and `$ARGUMENTS` contains `--update`:
- Regenerate the `<!-- BEGIN:auto-detected -->` ... `<!-- END:auto-detected -->` block (overwrite with fresh template)
- Preserve everything outside those markers (especially `## Project-Specific Rules`)
- If the file has no markers (hand-written), print a warning and skip overwrite:
  ```
  ⚠️  rules/language-stack.md exists without auto-detection markers. Skipping overwrite — edit manually.
  ```

**Report:**
```
Language stack: {detected stack(s)}
rules/language-stack.md: written
```
```

- [ ] **Step 3: Verify the insertion is syntactically correct**

Read `commands/bootstrap.md` and confirm:
- Step 1b appears after Step 1 and before Step 2
- The code blocks are properly fenced
- No placeholder text was accidentally left in

- [ ] **Step 4: Commit**

```bash
cd /Users/soh/working/ai/claude-mas-template
git add commands/bootstrap.md
git commit -m "feat: add Step 1b to bootstrap — language stack detection and rules/language-stack.md generation"
```

---

## Task 2: TypeScript Rules Template

**Files:**
- Create: `rules/language-stack-typescript.md`

This file is the TypeScript template that bootstrap copies. It must be fully self-contained — no placeholders.

- [ ] **Step 1: Write the TypeScript template**

Create `rules/language-stack-typescript.md` with this exact content:

```markdown
# Language Stack — TypeScript

<!-- BEGIN:auto-detected -->

## TypeScript

### Mandatory Diagnostic Commands

Run ALL of the following before committing or approving. A failure in any command is a P0 — do not proceed.

```bash
tsc --noEmit                          # Zero type errors required
eslint src/ --ext .ts --max-warnings 0  # Zero lint warnings required
{{test-command}}                       # All tests must pass
```

If `eslint` is not installed, fall back to: `npx eslint src/ --ext .ts`
If `src/` does not exist, use the directory where TypeScript source lives (check `tsconfig.json` → `include` or `rootDir`).

### Engineer Rules — Mandatory Before Committing

Before writing the result, run the diagnostic commands above. All must pass.

**TypeScript Non-Negotiables:**
- No `any` type without an explicit justification comment (`// justification: ...`)
- All async functions must have error handling (try/catch or `.catch()`)
- Prefer `Promise.all()` over sequential `await` for independent async operations
- All API boundaries must validate input using Zod (or project's schema library)
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

**Step 1 of Phase B MUST include diagnostic commands (see above). A review cannot be APPROVED if any diagnostic fails — this is a P0.**

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
```

- [ ] **Step 2: Verify the file was created**

Run:
```bash
wc -l /Users/soh/working/ai/claude-mas-template/rules/language-stack-typescript.md
```
Expected: ~70+ lines

- [ ] **Step 3: Commit**

```bash
cd /Users/soh/working/ai/claude-mas-template
git add rules/language-stack-typescript.md
git commit -m "feat: add TypeScript language-stack rules template"
```

---

## Task 3: Python Rules Template

**Files:**
- Create: `rules/language-stack-python.md`

- [ ] **Step 1: Write the Python template**

Create `rules/language-stack-python.md` with this exact content:

```markdown
# Language Stack — Python

<!-- BEGIN:auto-detected -->

## Python

### Mandatory Diagnostic Commands

Run ALL of the following before committing or approving. A failure in any command is a P0 — do not proceed.

```bash
mypy .                  # Zero type errors required (if mypy is installed)
ruff check .            # Zero lint warnings required (preferred over flake8)
{{test-command}}        # All tests must pass
```

**Fallbacks:**
- If `mypy` is not installed: `python -m mypy .` or skip with a note in the result
- If `ruff` is not installed: `flake8 .` or `pylint src/`
- If neither is installed: print warning and run `python -m py_compile $(find . -name "*.py" | grep -v __pycache__)`

### Engineer Rules — Mandatory Before Committing

Before writing the result, run the diagnostic commands above. All must pass.

**Python Non-Negotiables:**
- No bare `except:` — always catch specific exceptions (`except ValueError:`, `except (IOError, OSError):`)
- No mutable default arguments (`def foo(items=[])` — use `None` and assign inside)
- No f-string SQL queries — use parameterized queries (`cursor.execute("SELECT * FROM t WHERE id = %s", (id,))`)
- Use context managers for file/connection operations (`with open(...) as f:`)
- Type annotations required on all public functions and class methods

**Anti-Patterns — Auto-flag in self-review:**

| Pattern | Severity | Notes |
|---------|----------|-------|
| `except:` (bare, no exception type) | P1 | Catches SystemExit and KeyboardInterrupt — use `except Exception:` minimum |
| `except Exception: pass` | P1 | Silently swallows errors |
| Mutable default argument `def f(x=[])` | P1 | Shared state across calls — use `x=None` |
| f-string in SQL query | P0 | SQL injection — use parameterized queries |
| `eval(user_input)` | P0 | Remote code execution — never |
| `os.system()` with user input | P0 | Shell injection — use `subprocess.run` with list args |
| Missing `__all__` on public modules | P3 | Optional — define public API explicitly |
| N+1 queries in loops (ORM) | P1 | Use `select_related`/`prefetch_related` (Django) or `.options(joinedload())` (SQLAlchemy) |
| `print()` in production code | P2 | Use `logging` module |

### Reviewer Rules — Language-Specific Checks

**Step 1 of Phase B MUST include diagnostic commands (see above). A review cannot be APPROVED if any diagnostic fails — this is a P0.**

**Language-Specific P0 Checks (always block):**
- f-string or `%`-format or `.format()` in SQL query string
- `eval()` or `exec()` with user-controlled input
- `os.system()` / `subprocess.shell=True` with user input
- Hardcoded credentials, API keys, or secrets

**Language-Specific P1 Checks (must fix):**
- Bare `except:` (no exception type specified)
- `except Exception: pass` (silent swallow)
- Mutable default argument
- Missing context manager for file/DB/network operations
- N+1 queries in loops

**Language-Specific P2 Checks (should fix):**
- Missing type annotations on public functions
- `print()` statements (use `logging`)
- Missing `__all__` on public module interface
- String concatenation to build file paths (use `pathlib.Path`)

<!-- END:auto-detected -->

## Project-Specific Rules

<!-- Add project-specific anti-patterns and rules below. This section is preserved on --update. -->
```

- [ ] **Step 2: Verify the file was created**

```bash
wc -l /Users/soh/working/ai/claude-mas-template/rules/language-stack-python.md
```
Expected: ~70+ lines

- [ ] **Step 3: Commit**

```bash
cd /Users/soh/working/ai/claude-mas-template
git add rules/language-stack-python.md
git commit -m "feat: add Python language-stack rules template"
```

---

## Task 4: Engineer Agent — Language Diagnostics Step

**Files:**
- Modify: `agents/engineer/CLAUDE.md` — add one bullet to Phase 4 Pre-completion

### What to add

The engineer already runs lint, typecheck, and tests in Phase 4. We need one additional step: read `rules/language-stack.md` and run the language-specific diagnostic commands if that file exists.

- [ ] **Step 1: Read agents/engineer/CLAUDE.md Phase 4 block**

Read `agents/engineer/CLAUDE.md` lines 131–176. Confirm the Phase 4 Pre-completion block ends with the stub scan instructions and the note "If you find an unwired component...". The next line after the stub scan block is "**If any check fails, fix it now.**" — this is your insertion anchor.

- [ ] **Step 2: Insert language diagnostics step into Phase 4**

In `agents/engineer/CLAUDE.md`, find the exact text:

```
**If any check fails, fix it now.** Do not proceed to Phase 5 with known issues — this is the #1 cause of bug-fix cycles (25-30% of engineer outputs need bug-fixing).
```

Replace it with:

```
- [ ] **Language diagnostics:** If `rules/language-stack.md` exists in the project, read it and run ALL commands listed under "Mandatory Diagnostic Commands". All must pass before writing the result. Log any failures under "Deviations" in your result.

**If any check fails, fix it now.** Do not proceed to Phase 5 with known issues — this is the #1 cause of bug-fix cycles (25-30% of engineer outputs need bug-fixing).
```

- [ ] **Step 3: Verify the edit**

Read `agents/engineer/CLAUDE.md` lines 170–185 and confirm the language diagnostics bullet appears immediately before "If any check fails".

- [ ] **Step 4: Commit**

```bash
cd /Users/soh/working/ai/claude-mas-template
git add agents/engineer/CLAUDE.md
git commit -m "feat: add language diagnostics step to engineer Phase 4 pre-completion"
```

---

## Task 5: Reviewer Agent — Language Diagnostics + Anti-Pattern Check

**Files:**
- Modify: `agents/reviewer/CLAUDE.md` — extend Phase B Step 1 and add Step 1.5

### What to add

Two additions to Phase B:
1. **Step 1 extension** — after running lint/typecheck/tests, also run language-specific diagnostics from `rules/language-stack.md`
2. **Step 1.5 (new)** — apply language-specific anti-pattern checks from `rules/language-stack.md`

- [ ] **Step 1: Read agents/reviewer/CLAUDE.md Phase B block**

Read `agents/reviewer/CLAUDE.md`. Find the Phase B section. Step 1 currently reads:

```
1. **Build check:** Run `{{lint-command}}` + `{{typecheck-command}}` + `{{test-command}}`
```

This is your replacement anchor. The step ends at the next numbered item (Step 2: **Diff review:**).

- [ ] **Step 2: Replace Phase B Step 1 with extended version**

In `agents/reviewer/CLAUDE.md`, find the exact text:

```
1. **Build check:** Run `{{lint-command}}` + `{{typecheck-command}}` + `{{test-command}}`
```

Replace it with:

```
1. **Build check:** Run `{{lint-command}}` + `{{typecheck-command}}` + `{{test-command}}`

   **Language diagnostics:** If `rules/language-stack.md` exists, read it and run ALL commands listed under "Mandatory Diagnostic Commands". A review cannot be APPROVED if any diagnostic command fails — this is a P0 regardless of other findings.

1.5. **Language-specific anti-pattern checks:** If `rules/language-stack.md` exists, apply the checks listed under "Reviewer Rules — Language-Specific Checks". Add any findings to the appropriate P0/P1/P2 section of the report.
```

- [ ] **Step 3: Verify the edit**

Read `agents/reviewer/CLAUDE.md` Phase B section (lines ~58–85) and confirm:
- Step 1 now includes the language diagnostics note
- Step 1.5 appears as a new numbered step before Step 2 (Diff review)
- No other steps were modified

- [ ] **Step 4: Commit**

```bash
cd /Users/soh/working/ai/claude-mas-template
git add agents/reviewer/CLAUDE.md
git commit -m "feat: add language diagnostics and anti-pattern checks to reviewer Phase B"
```

---

## Self-Review

**Spec coverage check** (against `docs/superpowers/plans/2026-04-12-language-specific-hardening-proposal.md`):

| Proposal item | Task |
|---------------|------|
| T1: bootstrap.md — language detection + write rules/language-stack.md | Task 1 |
| T2: rules/language-stack.md — Python template | Task 3 |
| T3: rules/language-stack.md — TypeScript template | Task 2 |
| T4: agents/engineer/CLAUDE.md — add language diagnostics step to Phase 4 | Task 4 |
| T5: agents/reviewer/CLAUDE.md — add language diagnostics + anti-pattern instruction to Phase B | Task 5 |
| Multi-stack: separate sections in one file | Task 1 (bootstrap handles via BEGIN/END markers) |
| --update behavior: preserve Project-Specific Rules | Task 1 (bootstrap Step 1b --update logic) |
| Bootstrap --update: regenerate auto-detected, preserve custom | Task 1 |
| Custom anti-patterns section | Templates (both include Project-Specific Rules section) |

**Placeholder scan:** No TBD, TODO, or "implement later" in any task. Each step contains exact file paths and exact text to insert.

**Type consistency:** `rules/language-stack.md` is the runtime file in the project (generated by bootstrap). `rules/language-stack-typescript.md` and `rules/language-stack-python.md` are the templates in the plugin (source of truth). Bootstrap copies and constructs the runtime file. Both agents reference `rules/language-stack.md` consistently.

**One gap identified and added:** The proposal mentions optional hook enforcement (validate-dispatch.sh warning if diagnostics not evidenced). This was intentionally excluded as the proposal marked it "optional but recommended" and scoped v1 to the 5 tasks. Add to a follow-up if needed.
