---
description: Bootstrap MAS Template — auto-detect stack, fill CLAUDE.md, create directories, configure hooks
---

# Bootstrap MAS Template

Set up your project for the Claude Multi-Agent System. $ARGUMENTS

This command configures your project — agent, skill, and command files are NOT installed locally. They are provided by the MAS plugin and accessed via `/mas:` prefixed slash commands.

## What Bootstrap Does

1. Detects your tech stack (language, test/lint/build commands, has_ui)
2. Creates or updates CLAUDE.md with detected values
3. Creates hooks (.claude/hooks/lint.sh, .claude/hooks/pre-stop-gate.sh)
4. Creates output directories (docs/tasks/, docs/reports/, etc.)
5. Verifies no unfilled placeholders remain
6. Warns if no testing framework is detected

## What Bootstrap Does NOT Do

- Agent, skill, and command files are NOT installed locally
- They are provided by the MAS plugin — use `/mas:dev-loop`, `/mas:bug-fix`, etc.
- To customize an agent for this project, manually place it at `.claude/agents/{name}/CLAUDE.md`

## Steps

### Step 1 — Detect stack

Read `package.json`, `go.mod`, `pyproject.toml`, `Cargo.toml`, `Gemfile`, `pom.xml`, `build.gradle`, `build.gradle.kts`, or `settings.gradle` to identify:
- Language and version
- Test command (e.g., `npm test`, `pytest`, `go test ./...`)
- Lint command (e.g., `eslint src/`, `ruff check .`, `golangci-lint run`)
- Typecheck command (e.g., `tsc --noEmit`, `mypy .`, `go vet ./...`)
- Build command (e.g., `npm run build`, `go build ./...`)
- Format command (e.g., `prettier --write .`, `ruff format .`, `gofmt -w .`)
- Key libraries and versions
- Whether this project has a UI (`has_ui`): true if frontend framework detected (React, Vue, Svelte, Next.js, Angular, Flutter, SwiftUI, etc.)

#### Java / JVM Detection

**Detect build tool:**
- `pom.xml` → **Maven** (`mvn` or `./mvnw` if wrapper exists)
- `build.gradle` or `build.gradle.kts` → **Gradle** (`gradle` or `./gradlew` if wrapper exists)
- Prefer wrappers (`./mvnw`, `./gradlew`) over global installs — they pin the build tool version

**Detect Java version:**
- Maven: check `<maven.compiler.source>`, `<maven.compiler.release>`, or `<java.version>` in `pom.xml`
- Gradle: check `sourceCompatibility`, `targetCompatibility`, `jvmToolchain`, or `JavaLanguageVersion` in `build.gradle(.kts)`
- Fallback: run `java -version` and parse output

**Java < 17 (legacy):**

| Setting | Maven | Gradle |
|---------|-------|--------|
| `{{install-command}}` | `mvn dependency:resolve` (or `./mvnw`) | `gradle dependencies` (or `./gradlew`) |
| `{{test-command}}` | `mvn test` | `gradle test` |
| `{{lint-command}}` | `mvn checkstyle:check` (if checkstyle plugin exists) or `mvn verify -DskipTests` | `gradle checkstyleMain` (if checkstyle plugin exists) or `gradle check -x test` |
| `{{format-command}}` | `mvn com.coveo:fmt-maven-plugin:format` (if plugin exists) or `mvn spotless:apply` (if Spotless) | `gradle spotlessApply` (if Spotless) or `gradle googleJavaFormat` (if plugin exists) |
| `{{typecheck-command}}` | `mvn compile -DskipTests` (Java compiler IS the typechecker) | `gradle compileJava` |
| `{{build-command}}` | `mvn package -DskipTests` | `gradle build -x test` |
| Key libraries | Check `<dependencies>` in pom.xml — note Spring Boot, JUnit 4, Mockito, Lombok, etc. | Check `dependencies` block — same libraries |
| Testing framework | JUnit 4 (`junit:junit`), TestNG, or JUnit 5 (`junit-jupiter`) | Same |

**Java >= 17 (modern):**

| Setting | Maven | Gradle |
|---------|-------|--------|
| `{{install-command}}` | `./mvnw dependency:resolve` | `./gradlew dependencies` |
| `{{test-command}}` | `./mvnw test` | `./gradlew test` |
| `{{lint-command}}` | `./mvnw checkstyle:check` or `./mvnw spotless:check` | `./gradlew checkstyleMain` or `./gradlew spotlessCheck` |
| `{{format-command}}` | `./mvnw spotless:apply` | `./gradlew spotlessApply` |
| `{{typecheck-command}}` | `./mvnw compile -DskipTests` | `./gradlew compileJava` |
| `{{build-command}}` | `./mvnw package -DskipTests` | `./gradlew build -x test` |
| Key libraries | Spring Boot 3.x, JUnit 5, Mockito 5, Jakarta EE (not javax), records, sealed classes | Same |
| Testing framework | JUnit 5 (`junit-jupiter`) — JUnit 4 is rare in modern projects | Same |

**Key differences to detect:**
- `javax.*` imports → Java < 17 (EE 8). `jakarta.*` imports → Java >= 17 (EE 9+)
- Spring Boot 2.x → Java < 17 compatible. Spring Boot 3.x → requires Java 17+
- JUnit 4 (`@Test` from `org.junit`) → legacy. JUnit 5 (`@Test` from `org.junit.jupiter`) → modern
- If both JUnit 4 and 5 are present (vintage engine), note it as a gotcha

**UI detection for Java:**
- `has_ui: true` if: Thymeleaf, JSP/JSF, Vaadin, or frontend module with `package.json` detected
- `has_ui: false` if: pure REST API, gRPC service, CLI tool, batch job

### Step 1b — Write language-stack rules

Based on detection from Step 1, determine which language stack template(s) to use:

**Detection rules:**
- `tsconfig.json` present → TypeScript stack detected
- `package.json` present (no `tsconfig.json`) → JavaScript stack detected
- `pyproject.toml` OR `requirements.txt` OR `setup.py` present → Python stack detected
- `go.mod` present → Go stack detected (no template yet — will create file with Project-Specific Rules section only)
- `Cargo.toml` present → Rust stack detected
- Both Python + TypeScript detected → multi-stack project
- Rust + TypeScript detected (`Cargo.toml` + `tsconfig.json`) → multi-stack project

**Action based on detection:**

```bash
PLUGIN_DIR=$(ls -d ~/.claude/plugins/cache/luke-plugins/mas/*/ 2>/dev/null | sort -V | tail -1)
```

> If `$PLUGIN_DIR` is empty (plugin cache not found), print: `ERROR: MAS plugin cache not found — skipping language-stack.md generation.` and skip the rest of Step 1b.

```bash
mkdir -p .claude/rules
```

**Single-stack TypeScript:**
```bash
cp "$PLUGIN_DIR/rules/language-stack-typescript.md" .claude/rules/language-stack.md
```

**Single-stack Python:**
```bash
cp "$PLUGIN_DIR/rules/language-stack-python.md" .claude/rules/language-stack.md
```

**Single-stack Rust:**
```bash
cp "$PLUGIN_DIR/rules/language-stack-rust.md" .claude/rules/language-stack.md
```

**Multi-stack Rust + TypeScript:**

Create `.claude/rules/language-stack.md` with the following structure. Write each section as a separate block — use actual newlines, not `\n` escape sequences:

```
# Language Stack

This project has multiple language stacks. Each section below defines the rules for that layer.

---

<!-- BEGIN:auto-detected -->

## Backend (Rust)

[full contents of $PLUGIN_DIR/rules/language-stack-rust.md, starting from the <!-- BEGIN:auto-detected --> line — skip the # Language Stack — Rust title line]

## Frontend (TypeScript)

[full contents of $PLUGIN_DIR/rules/language-stack-typescript.md, starting from the <!-- BEGIN:auto-detected --> line — skip the # Language Stack — TypeScript title line]

<!-- END:auto-detected -->

## Project-Specific Rules

<!-- Add project-specific anti-patterns and rules below. This section is preserved on --update. -->
```

**After writing .claude/rules/language-stack.md** (whether copied or assembled), resolve `{{test-command}}` using the value detected in Step 1:

```bash
# Resolve {{test-command}} in the generated file
# Use the test command detected in Step 1
# Use | as delimiter to handle test commands that contain / (e.g. pytest --cov=src/)
# macOS/BSD: sed -i ''   Linux: sed -i   — use whichever matches the current OS
sed -i '' 's|{{test-command}}|'"${DETECTED_TEST_COMMAND}"'|g' .claude/rules/language-stack.md   # macOS
# sed -i 's|{{test-command}}|'"${DETECTED_TEST_COMMAND}"'|g' .claude/rules/language-stack.md    # Linux (uncomment if needed)
```

Replace `${DETECTED_TEST_COMMAND}` with the actual test command from Step 1 (e.g., `npm test`, `pytest`, `go test ./...`). If no test command was detected, leave `{{test-command}}` as-is with a printed warning.

**Multi-stack (Python + TypeScript):** Create `.claude/rules/language-stack.md` with the following structure. Write each section as a separate block — use actual newlines, not `\n` escape sequences:

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

**Single-stack JavaScript (package.json, no tsconfig.json):**
- Create `.claude/rules/language-stack.md` containing only a `## Project-Specific Rules` section
- Print:
  ```
  ℹ️  JavaScript (no TypeScript) detected — no language-stack template available yet.
      Created .claude/rules/language-stack.md with an empty Project-Specific Rules section.
      Consider adding TypeScript, or populate the Project-Specific Rules section manually
      with your ESLint and test commands.
  ```

**If no template exists for the detected stack** (e.g., Go):
- Create `.claude/rules/language-stack.md` containing only a `## Project-Specific Rules` section
- Print: `ℹ️  No language-stack template for {language} yet. Created .claude/rules/language-stack.md with an empty Project-Specific Rules section.`

**If no language is detected** (e.g., pure config repo): skip this step silently.

**`--update` behavior** (when `$ARGUMENTS` contains `--update` and `.claude/rules/language-stack.md` already exists):
- If the file contains `<!-- BEGIN:auto-detected -->` and `<!-- END:auto-detected -->` markers: regenerate only the content between those markers (overwrite with fresh template); preserve everything outside the markers (especially `## Project-Specific Rules`). For multi-stack projects, rebuild the full inner block using both templates, using the same construction logic as the initial write.
- If the file has no markers (hand-written): print warning and skip:
  ```
  ⚠️  .claude/rules/language-stack.md exists without auto-detection markers. Skipping overwrite — edit manually.
  ```

**Report at end of this step:**
```
Language stack: {detected stack(s)}
.claude/rules/language-stack.md: written  (or: skipped — no language detected)
```

### Step 2 — Create or update CLAUDE.md

If `CLAUDE.md` does NOT exist at project root:
- Copy the template from the plugin cache: `PLUGIN_DIR=$(ls -d ~/.claude/plugins/cache/luke-plugins/mas/*/ | sort -V | tail -1)`
- Copy `$PLUGIN_DIR/CLAUDE.md` to project root

Replace placeholders in `CLAUDE.md`:
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

### Step 3 — Create hooks

Create `.claude/hooks/` directory and write hook files with detected commands:

```bash
mkdir -p .claude/hooks
```

Write `lint.sh` with the detected lint command:
```bash
#!/bin/bash
{detected-lint-command}
```

Write `pre-stop-gate.sh` with the detected test command:
```bash
#!/bin/bash
{detected-test-command}
```

Write `validate-dispatch.sh` to block bare agent names at dispatch time:
```bash
#!/bin/bash
# PreToolUse hook: Validate Agent dispatch naming convention
INPUT=$(cat)
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
if [ "$TOOL_NAME" != "Agent" ]; then exit 0; fi
SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"subagent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"subagent_type"[[:space:]]*:[[:space:]]*"//' | sed 's/"//')
if [ -z "$SUBAGENT_TYPE" ]; then exit 0; fi
BARE_NAMES="engineer reviewer bug-fixer researcher differential-reviewer ui-ux-designer reflect-agent orchestrator"
for name in $BARE_NAMES; do
  if [ "$SUBAGENT_TYPE" = "$name" ]; then
    echo "BLOCKED: Bare agent name '$name'. Use 'mas:${name}:${name}' instead."
    exit 2
  fi
done
if [ "$SUBAGENT_TYPE" = "mas:orchestrator:orchestrator" ]; then
  echo "BLOCKED: mas:orchestrator:orchestrator is DEPRECATED. The dev-loop IS the orchestrator."
  exit 2
fi
REFLECT_REPORT="${CLAUDE_PROJECT_DIR}/docs/reports/reflect-report.md"
if [ "$SUBAGENT_TYPE" = "mas:reflect-agent:reflect-agent" ] && [ -f "$REFLECT_REPORT" ]; then
  echo "BLOCKED: Reflect agent already ran (docs/reports/reflect-report.md exists)."
  echo "Dispatch-exactly-once constraint: reflect must run exactly once per dev-loop session."
  exit 2
fi
exit 0
```

Write `validate-skill.sh` to block bare skill names at invocation time:
```bash
#!/bin/bash
# PreToolUse hook: Validate Skill invocation naming
INPUT=$(cat)
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
if [ "$TOOL_NAME" != "Skill" ]; then exit 0; fi
SKILL=$(echo "$INPUT" | grep -o '"skill"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"skill"[[:space:]]*:[[:space:]]*"//' | sed 's/"//')
if [ -z "$SKILL" ]; then exit 0; fi
SUPERPOWERS_SKILLS="writing-plans brainstorm brainstorming executing-plans verification verification-before-completion finishing-branch finishing-a-development-branch subagent-driven-development test-driven-development systematic-debugging using-git-worktrees dispatching-parallel-agents requesting-code-review receiving-code-review"
for s in $SUPERPOWERS_SKILLS; do
  if [ "$SKILL" = "$s" ]; then
    echo "BLOCKED: Bare superpowers skill name '$s'. Use 'superpowers:${s}' instead."
    exit 2
  fi
done
MAS_SKILLS="dev-loop bug-fix reflect release bootstrap ask-questions finishing-branch verification reliability-review se-principles differential-review subagent-driven-development test-driven-development obsidian"
for s in $MAS_SKILLS; do
  if [ "$SKILL" = "$s" ]; then
    echo "BLOCKED: Bare MAS skill name '$s'. Use 'mas:${s}' instead."
    exit 2
  fi
done
exit 0
```

> **Project-local allowlist:** If your project has custom skills whose bare names collide with MAS/superpowers names, add them one per line to `.claude/hooks/allowed-bare-skills.txt`. The hook will pass them through without blocking.

Make executable:
```bash
chmod +x .claude/hooks/*.sh
```

Create or update `.claude/settings.json` to wire the validation hooks as PreToolUse handlers. If `.claude/settings.json` already exists, merge the `hooks` entries; otherwise create it:
```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Agent", "hooks": [{ "type": "command", "command": ".claude/hooks/validate-dispatch.sh" }] },
      { "matcher": "Skill",  "hooks": [{ "type": "command", "command": ".claude/hooks/validate-skill.sh"  }] }
    ]
  }
}
```

> If `.claude/settings.json` already has a `hooks.PreToolUse` array, append the two entries above to it rather than overwriting the existing entries.

### Step 4 — Create output directories and update .gitignore

```bash
mkdir -p docs/{design,plans,reports,results}
mkdir -p docs/tasks/{pending,in-progress,done,blocked}
```

Ensure `.worktrees/` is in `.gitignore` (dev-loop creates worktrees there). If not already present, append it:
```bash
grep -qxF '.worktrees/' .gitignore 2>/dev/null || echo '.worktrees/' >> .gitignore
```

### Step 5 — Verify

```bash
grep -r '{{' CLAUDE.md | grep -v 'Invariant\|Gotcha\|step\|Describe your'
```
If any non-intentional placeholders remain, fill them.

### Step 6 — Critical: Verify testing framework

Check if a testing framework was detected (test command is not empty/placeholder). If NO testing framework is found:

```
⚠️  WARNING: NO TESTING FRAMEWORK DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TDD is non-negotiable in this workflow. Without a testing
framework, the following WILL NOT WORK:

  - /mas:dev-loop (TDD enforced at every task)
  - /mas:test-driven-development
  - /mas:subagent-driven-development (two-stage review requires tests)
  - Engineer agent (refuses to implement without tests)
  - Reviewer agent (blocks on missing test coverage)

ACTION REQUIRED: Install a testing framework before using
any MAS workflow. Examples:
  - Node.js:  npm install -D vitest (or jest)
  - Python:   pip install pytest
  - Go:       (built-in, check go.mod exists)
  - Rust:     (built-in, check Cargo.toml exists)
  - Java:     add junit-jupiter to pom.xml or build.gradle

Then re-run /mas:bootstrap to update the test command.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Do NOT suppress this warning.** Display it prominently before the summary.

### Step 7 — Report

```
MAS Template bootstrapped for: {project name}
Stack: {language} + {framework}
has_ui: {true/false}
.claude/rules/language-stack.md: written — language diagnostics will activate in engineer and reviewer agents
{Omit the .claude/rules/language-stack.md line if language detection was skipped.}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
All agents, skills, and commands are provided by the MAS plugin.
Use /mas: prefixed commands:

  /mas:dev-loop       Full development pipeline
  /mas:bug-fix        Focused bug-fix loop
  /mas:reflect        Check delivery against spec
  superpowers:writing-plans  Create implementation plans
  /mas:ask-questions  Clarify requirements
  /mas:release        Release checklist

Do NOT use unprefixed versions (/dev-loop, /bug-fix) — those
require a local install via git clone.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remaining TODOs:
{Only show items that still have unfilled placeholders in CLAUDE.md.}
  - Fill Architecture Invariants in CLAUDE.md
  - Fill Core Flow in CLAUDE.md
  - Fill Key Gotchas in CLAUDE.md
{If all sections are filled, print: "All sections filled — CLAUDE.md is ready."}

Ready to go? Try:
  /mas:dev-loop <describe your first task>
  /mas:bug-fix <describe the bug>
  /mas:ask-questions <what you want to build>
```
