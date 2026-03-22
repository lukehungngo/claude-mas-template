---
description: Bootstrap MAS Template — auto-detect stack, fill placeholders, configure hooks
---

# Bootstrap MAS Template

Install and configure the Claude Multi-Agent System for this repo. $ARGUMENTS

## Steps

1. **Detect stack** — Read `package.json`, `go.mod`, `pyproject.toml`, `Cargo.toml`, `Gemfile`, or `pom.xml` to identify:
   - Language and version
   - Test command (e.g., `npm test`, `pytest`, `go test ./...`)
   - Lint command (e.g., `eslint src/`, `ruff check .`, `golangci-lint run`)
   - Typecheck command (e.g., `tsc --noEmit`, `mypy .`, `go vet ./...`)
   - Build command (e.g., `npm run build`, `go build ./...`)
   - Format command (e.g., `prettier --write .`, `ruff format .`, `gofmt -w .`)
   - Key libraries and versions
   - Whether this project has a UI (`has_ui`): true if frontend framework detected (React, Vue, Svelte, Next.js, Angular, Flutter, SwiftUI, etc.)

2. **Replace all `{{placeholders}}`** across every file in `.claude/` and `CLAUDE.md`:
   - `{{PROJECT_NAME}}` → repo name or directory name
   - `{{description}}` / `{{one-line description}}` → infer from README, package.json description, or ask
   - `{{install-command}}` → detected install command
   - `{{test-command}}` → detected test command
   - `{{lint-command}}` → detected lint command
   - `{{format-command}}` → detected format command
   - `{{typecheck-command}}` → detected typecheck command
   - `{{build-command}}` → detected build command
   - `{{your tech stack}}` → detected language + key libraries
   - `{{true | false}}` for `has_ui` → detected from framework
   - Leave `{{Invariant X}}`, `{{Gotcha X}}`, and core flow placeholders as-is (project-specific, human fills these)

3. **Fix hooks** — Update `lint.sh` and `pre-stop-gate.sh` with the detected lint/test commands. Run `chmod +x .claude/hooks/*.sh`.

4. **Create task directories:**
   ```bash
   mkdir -p tasks/{pending,in-progress,done,blocked}
   ```

5. **Verify** — Run:
   ```bash
   grep -r '{{' .claude/ CLAUDE.md --include='*.md' --include='*.sh' --include='*.json' | grep -v 'Invariant\|Gotcha\|step\|Describe your'
   ```
   If any non-intentional placeholders remain, fill them.

6. **Report** — Print a summary:
   ```
   MAS Template bootstrapped for: {project name}
   Stack: {language} + {framework}
   has_ui: {true/false}
   Agents: 7 (6 active + ui-ux-designer conditional)
   Remaining TODOs: Fill Architecture Invariants, Core Flow, Key Gotchas in CLAUDE.md
   ```
