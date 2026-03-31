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

Make executable:
```bash
chmod +x .claude/hooks/*.sh
```

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
