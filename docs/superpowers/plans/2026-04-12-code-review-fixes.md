# Code Review Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all Important and Minor issues found in the code review of the language-specific hardening feature (v2.10.0–v2.10.1).

**Architecture:** Four files need touching: `commands/bootstrap.md` (sed delimiter, sed platform note, JS stack notice, multi-stack \n notation), `agents/reviewer/CLAUDE.md` (step 1.5 renumbering), `rules/language-stack-typescript.md` (guard clause + tsc fallback), `rules/language-stack-python.md` (guard clause + P3 severity fix). All changes are prose/markdown edits — no code compilation required.

**Tech Stack:** Markdown, bash snippets embedded in prose, git.

---

## Files to Modify

| File | Changes |
|------|---------|
| `commands/bootstrap.md` | Fix sed delimiter; add macOS/Linux sed note; add JS-stack explicit notice; fix multi-stack `\n` escapes |
| `agents/reviewer/CLAUDE.md` | Restructure step 1.5 as sub-bullet under step 1 |
| `rules/language-stack-typescript.md` | Add `{{test-command}}` guard clause; add `tsc` fallback note |
| `rules/language-stack-python.md` | Add `{{test-command}}` guard clause; fix P3 → P2 severity |

---

## Task 1: Fix sed delimiter and add platform note in bootstrap.md

**Files:**
- Modify: `commands/bootstrap.md` (lines 123–129)

**Context:** The current sed command uses `/` as delimiter. If `DETECTED_TEST_COMMAND` contains a `/` (e.g., `pytest --cov=src/`), sed treats it as a delimiter and breaks. Also, `sed -i ''` is macOS/BSD only — Linux needs `sed -i`.

- [ ] **Step 1: Open bootstrap.md and locate the sed block**

  The block to change is around line 123–129:
  ```
  ```bash
  # Resolve {{test-command}} in the generated file
  # Use the test command detected in Step 1
  sed -i '' 's/{{test-command}}/'"${DETECTED_TEST_COMMAND}"'/g' rules/language-stack.md
  ```

  Replace `${DETECTED_TEST_COMMAND}` with the actual test command from Step 1 (e.g., `npm test`, `pytest`, `go test ./...`). If no test command was detected, leave `{{test-command}}` as-is with a printed warning.
  ```

- [ ] **Step 2: Replace that block with the fixed version**

  New content:
  ````
  ```bash
  # Resolve {{test-command}} in the generated file
  # Use the test command detected in Step 1
  # Use | as delimiter to handle test commands that contain / (e.g. pytest --cov=src/)
  # macOS/BSD: sed -i ''   Linux: sed -i   — use whichever matches the current OS
  sed -i '' 's|{{test-command}}|'"${DETECTED_TEST_COMMAND}"'|g' rules/language-stack.md   # macOS
  # sed -i 's|{{test-command}}|'"${DETECTED_TEST_COMMAND}"'|g' rules/language-stack.md    # Linux (uncomment if needed)
  ```

  Replace `${DETECTED_TEST_COMMAND}` with the actual test command from Step 1 (e.g., `npm test`, `pytest`, `go test ./...`). If no test command was detected, leave `{{test-command}}` as-is with a printed warning.
  ````

- [ ] **Step 3: Verify the edit looks correct**

  Run:
  ```bash
  grep -n "sed\|delimiter\|macOS\|Linux" commands/bootstrap.md
  ```
  Expected: lines with `sed -i ''` using `|` delimiter, and a comment about macOS/Linux.

- [ ] **Step 4: Commit**

  ```bash
  git add commands/bootstrap.md
  git commit -m "fix: use | delimiter in sed to handle / in test commands, add macOS/Linux note"
  ```

---

## Task 2: Add explicit JS-stack notice in bootstrap.md

**Files:**
- Modify: `commands/bootstrap.md` (lines 92–141)

**Context:** When `package.json` is detected but no `tsconfig.json` exists (JavaScript-only project), the current code has no template and falls silently through to the "no template" path. Users get an empty Project-Specific Rules section with no explanation. We need to add an explicit notice for JS-only projects.

- [ ] **Step 1: Locate the "If no template exists" block**

  Find the section around line 139–141:
  ```
  **If no template exists for the detected stack** (e.g., Go, Rust):
  - Create `rules/language-stack.md` containing only a `## Project-Specific Rules` section
  - Print: `ℹ️  No language-stack template for {language} yet. Created rules/language-stack.md with an empty Project-Specific Rules section.`
  ```

- [ ] **Step 2: Add a JavaScript-specific branch before the generic "no template" block**

  Insert before the "If no template exists" block:
  ```
  **Single-stack JavaScript (package.json, no tsconfig.json):**
  - Create `rules/language-stack.md` containing only a `## Project-Specific Rules` section
  - Print:
    ```
    ℹ️  JavaScript (no TypeScript) detected — no language-stack template available yet.
        Created rules/language-stack.md with an empty Project-Specific Rules section.
        Consider adding TypeScript, or populate the Project-Specific Rules section manually
        with your ESLint and test commands.
    ```
  ```

- [ ] **Step 3: Verify the edit**

  ```bash
  grep -n "JavaScript (no TypeScript)\|Single-stack JavaScript" commands/bootstrap.md
  ```
  Expected: a line with the new JS-only branch.

- [ ] **Step 4: Commit**

  ```bash
  git add commands/bootstrap.md
  git commit -m "fix: add explicit notice for JavaScript-only stack (no TypeScript template available)"
  ```

---

## Task 3: Fix multi-stack \n notation in bootstrap.md

**Files:**
- Modify: `commands/bootstrap.md` (lines 131–137)

**Context:** The multi-stack construction instructions use `\n` escape notation inline in quoted strings (e.g., `"# Language Stack\n\nThis project..."`). An LLM executing this as prose may interpret `\n` literally instead of as a newline, producing malformed output. We need to replace this with unambiguous prose instructions.

- [ ] **Step 1: Locate the multi-stack block**

  Find lines 131–137:
  ```
  **Multi-stack (Python + TypeScript):** Create `rules/language-stack.md` as follows:
  1. Write header: `# Language Stack\n\nThis project has multiple language stacks. Each section below defines the rules for that layer.\n\n---\n`
  2. Write: `<!-- BEGIN:auto-detected -->\n`
  3. Write: `## Backend (Python)\n\n` then append the full contents...
  4. Write: `\n## Frontend (TypeScript)\n\n` then append...
  5. Write: `\n<!-- END:auto-detected -->\n`
  6. Write: `\n## Project-Specific Rules\n\n<!-- Add project-specific... -->\n`
  ```

- [ ] **Step 2: Replace the multi-stack block with explicit prose (no \n escapes)**

  Replace with:
  ````
  **Multi-stack (Python + TypeScript):** Create `rules/language-stack.md` with the following structure. Write each section as a separate block — use actual newlines, not `\n` escape sequences:

  ```
  # Language Stack

  This project has multiple language stacks. Each section below defines the rules for that layer.

  ---

  <!-- BEGIN:auto-detected -->

  ## Backend (Python)

  [full contents of $PLUGIN_DIR/rules/language-stack-python.md, starting from the <!-- BEGIN:auto-detected --> line — skip the # Language Stack — Python title line]

  ## Frontend (TypeScript)

  [full contents of $PLUGIN_DIR/rules/language-stack-typescript.md, starting from the <!-- BEGIN:auto-detected --> line — skip the # Language Stack — TypeScript title line]

  <!-- END:auto-detected -->

  ## Project-Specific Rules

  <!-- Add project-specific anti-patterns and rules below. This section is preserved on --update. -->
  ```
  ````

- [ ] **Step 3: Verify the edit**

  ```bash
  grep -n "\\\\n\|escape" commands/bootstrap.md | head -10
  ```
  Expected: no more `\n` inside quoted strings in the multi-stack section.

- [ ] **Step 4: Commit**

  ```bash
  git add commands/bootstrap.md
  git commit -m "fix: replace \\n escape notation in multi-stack instructions with explicit prose"
  ```

---

## Task 4: Restructure step 1.5 in reviewer/CLAUDE.md

**Files:**
- Modify: `agents/reviewer/CLAUDE.md` (lines 60–64)

**Context:** Phase B currently has steps numbered `1`, `1.5`, `2`, `3`... The fractional step is non-standard, confusing to markdown renderers, and may be silently skipped by reviewer agents. The language diagnostics (current step 1) and anti-pattern checks (current step 1.5) are both part of the same "language-stack" gate — they should be sub-bullets under step 1.

- [ ] **Step 1: Locate Phase B step 1 and 1.5**

  Current content (lines 60–64):
  ```
  1. **Build check:** Run `{{lint-command}}` + `{{typecheck-command}}` + `{{test-command}}`

     **Language diagnostics:** If `rules/language-stack.md` exists, read it and run ALL commands listed under "Mandatory Diagnostic Commands". A review cannot be APPROVED if any diagnostic command fails — this is a P0 regardless of other findings.

  1.5. **Language-specific anti-pattern checks:** If `rules/language-stack.md` exists, apply the checks listed under "Reviewer Rules — Language-Specific Checks". Add any findings to the appropriate P0/P1/P2 section of the report.
  ```

- [ ] **Step 2: Replace with restructured sub-bullets**

  New content:
  ```
  1. **Build check:** Run `{{lint-command}}` + `{{typecheck-command}}` + `{{test-command}}`

     - **Language diagnostics:** If `rules/language-stack.md` exists, read it and run ALL commands listed under "Mandatory Diagnostic Commands". A review cannot be APPROVED if any diagnostic command fails — this is a P0 regardless of other findings.
     - **Language-specific anti-pattern checks:** If `rules/language-stack.md` exists, apply the checks listed under "Reviewer Rules — Language-Specific Checks". Add any findings to the appropriate P0/P1/P2 section of the report.
  ```

- [ ] **Step 3: Verify that step 2 still follows correctly**

  ```bash
  grep -n "^[0-9]\+\." agents/reviewer/CLAUDE.md | head -20
  ```
  Expected: clean `1.`, `2.`, `3.`, ... sequence with no `1.5.`.

- [ ] **Step 4: Commit**

  ```bash
  git add agents/reviewer/CLAUDE.md
  git commit -m "fix: restructure step 1.5 as sub-bullet under step 1 in reviewer Phase B"
  ```

---

## Task 5: Add {{test-command}} guard clause and tsc fallback to TypeScript template

**Files:**
- Modify: `rules/language-stack-typescript.md` (lines 9–19)

**Context:** Two issues:
1. If bootstrap's sed step is skipped (plugin cache not found, or model doesn't execute it), the template retains the literal `{{test-command}}` string. An agent that sees this must not try to run it — it would silently fail or confuse the shell.
2. The Python template has explicit fallback instructions for when `mypy`/`ruff` aren't installed. The TypeScript template has no fallback for when `tsc` isn't installed (pure-JS repo, monorepo root without local TS install, etc.).

- [ ] **Step 1: Locate the Mandatory Diagnostic Commands block in the TypeScript template**

  Current content (lines 7–20):
  ```markdown
  ### Mandatory Diagnostic Commands

  Run ALL of the following before committing or approving. A failure in any command is a P0 — do not proceed.

  ```bash
  tsc --noEmit                            # Zero type errors required
  # Lint — version-aware:
  # ESLint v8: eslint src/ --ext .ts,.tsx --max-warnings 0
  # ESLint v9+ (flat config): eslint src/ --max-warnings 0
  # Auto-detect: npx eslint --version | grep -q "^v9\|^v10" && npx eslint src/ --max-warnings 0 || npx eslint src/ --ext .ts,.tsx --max-warnings 0
  {{test-command}}                        # All tests must pass — resolve this from CLAUDE.md `{{test-command}}`; if not set, run the test command from your project context
  ```
  ```

- [ ] **Step 2: Replace with guarded + fallback version**

  New content for the Mandatory Diagnostic Commands section:
  ````markdown
  ### Mandatory Diagnostic Commands

  Run ALL of the following before committing or approving. A failure in any command is a P0 — do not proceed.

  ```bash
  tsc --noEmit                            # Zero type errors required
  # Lint — version-aware:
  # ESLint v8: eslint src/ --ext .ts,.tsx --max-warnings 0
  # ESLint v9+ (flat config): eslint src/ --max-warnings 0
  # Auto-detect: npx eslint --version | grep -q "^v9\|^v10" && npx eslint src/ --max-warnings 0 || npx eslint src/ --ext .ts,.tsx --max-warnings 0
  {{test-command}}                        # All tests must pass — resolve this from CLAUDE.md `{{test-command}}`; if not set, run the test command from your project context
  ```

  **Fallbacks:**
  - If `tsc` is not installed locally: run `npx tsc --noEmit` or skip with a note in the result
  - If `{{test-command}}` is still a literal placeholder (not yet substituted by bootstrap): **do NOT run it** — print a warning: `⚠️  test-command placeholder not resolved — skipping test step. Run /mas:bootstrap to fix.` and continue.
  ````

- [ ] **Step 3: Verify the edit**

  ```bash
  grep -n "placeholder\|tsc.*not installed\|Fallbacks" rules/language-stack-typescript.md
  ```
  Expected: lines with the fallback note and placeholder guard.

- [ ] **Step 4: Commit**

  ```bash
  git add rules/language-stack-typescript.md
  git commit -m "fix: add tsc fallback note and {{test-command}} guard clause to TypeScript template"
  ```

---

## Task 6: Add {{test-command}} guard clause and fix P3 severity in Python template

**Files:**
- Modify: `rules/language-stack-python.md` (lines 12–18 and the anti-pattern table)

**Context:** Two issues:
1. Same guard clause needed as TypeScript template — if `{{test-command}}` was not substituted by bootstrap, an agent must not run it literally.
2. The anti-pattern table has a `P3` severity level (`Missing __all__ on public modules`) which doesn't appear in the reviewer checks section and is undefined in any severity legend. The reviewer's report format uses P0/P1/P2. Promote P3 → P2 and add it to the P2 reviewer checks (it's already in P2 there — just harmonize the table).

- [ ] **Step 1: Locate the Mandatory Diagnostic Commands block**

  Current content (lines 12–21):
  ```markdown
  ### Mandatory Diagnostic Commands

  Run ALL of the following before committing or approving. A failure in any command is a P0 — do not proceed.

  ```bash
  mypy .          # Zero type errors required (if mypy is installed)
  ruff check .    # Zero lint warnings required (preferred over flake8)
  {{test-command}} # All tests must pass — resolve this from CLAUDE.md `{{test-command}}`; if not set, run the test command from your project context
  ```

  **Fallbacks:**
  - If `mypy` is not installed: `python -m mypy .` or skip with a note in the result
  - If `ruff` is not installed: `flake8 .` or `pylint src/`
  - If neither linter is installed: run `python -m compileall . -q` and print a warning
  ```

- [ ] **Step 2: Add placeholder guard to the Fallbacks section**

  Replace the Fallbacks block with:
  ```markdown
  **Fallbacks:**
  - If `mypy` is not installed: `python -m mypy .` or skip with a note in the result
  - If `ruff` is not installed: `flake8 .` or `pylint src/`
  - If neither linter is installed: run `python -m compileall . -q` and print a warning
  - If `{{test-command}}` is still a literal placeholder (not yet substituted by bootstrap): **do NOT run it** — print a warning: `⚠️  test-command placeholder not resolved — skipping test step. Run /mas:bootstrap to fix.` and continue.
  ```

- [ ] **Step 3: Fix P3 → P2 in the anti-pattern table**

  Find the row:
  ```
  | Missing `__all__` on public modules | P3 | Optional — define public API explicitly |
  ```

  Replace with:
  ```
  | Missing `__all__` on public modules | P2 | Optional — define public API explicitly |
  ```

- [ ] **Step 4: Verify both edits**

  ```bash
  grep -n "P3\|placeholder\|guard\|__all__" rules/language-stack-python.md
  ```
  Expected: no `P3` rows; `__all__` shows `P2`; placeholder guard present.

- [ ] **Step 5: Commit**

  ```bash
  git add rules/language-stack-python.md
  git commit -m "fix: add {{test-command}} guard clause and promote P3 to P2 in Python template"
  ```

---

## Task 7: Bump version and update CHANGELOG

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `CHANGELOG.md`

**Context:** These are polish fixes (no new features). Bump patch version from v2.10.1 → v2.10.2.

- [ ] **Step 1: Check current version**

  ```bash
  grep '"version"' .claude-plugin/plugin.json
  ```
  Expected: `"version": "2.10.1"`

- [ ] **Step 2: Bump version in plugin.json and marketplace.json**

  In `.claude-plugin/plugin.json`, change:
  ```json
  "version": "2.10.1"
  ```
  to:
  ```json
  "version": "2.10.2"
  ```

  In `.claude-plugin/marketplace.json`, same change.

- [ ] **Step 3: Add CHANGELOG entry**

  At the top of `CHANGELOG.md` (after the header), add:
  ```markdown
  ## [2.10.2] — 2026-04-12

  ### Fixed
  - bootstrap: use `|` delimiter in sed to handle test commands containing `/` (e.g. `pytest --cov=src/`)
  - bootstrap: add macOS vs Linux `sed -i` usage note
  - bootstrap: add explicit notice for JavaScript-only stack (no template available)
  - bootstrap: replace `\n` escape notation in multi-stack instructions with explicit prose
  - reviewer: restructure Phase B step 1.5 as sub-bullet under step 1 (cleaner numbering)
  - language-stack-typescript: add `tsc` fallback note and `{{test-command}}` placeholder guard
  - language-stack-python: add `{{test-command}}` placeholder guard and promote P3 → P2 severity
  ```

- [ ] **Step 4: Commit**

  ```bash
  git add .claude-plugin/plugin.json .claude-plugin/marketplace.json CHANGELOG.md
  git commit -m "chore: bump version to v2.10.2"
  ```

---

## Self-Review

**Spec coverage:**
- Issue 1 (sed delimiter) → Task 1 ✓
- Issue 2 (JS stack silent) → Task 2 ✓
- Issue 3 (test-command guard) → Tasks 5 & 6 ✓
- Issue 4 (step 1.5 numbering) → Task 4 ✓
- Issue 5 (sed -i macOS-only) → Task 1 ✓ (combined with delimiter fix)
- Issue 6 (P3 undefined) → Task 6 ✓
- Issue 7 (tsc fallback missing) → Task 5 ✓
- Issue 8 (multi-stack \n notation) → Task 3 ✓

**Placeholder scan:** No TBD, no vague instructions. All edits show exact before/after text.

**Consistency:** No cross-task type/naming conflicts (all edits are independent markdown changes).
