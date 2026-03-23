---
description: Bootstrap MAS Template — auto-detect stack, fill placeholders, configure hooks
---

# Bootstrap MAS Template

Install and configure the Claude Multi-Agent System for this repo. $ARGUMENTS

## Mode Detection

Check if `$ARGUMENTS` contains `--update`. Also check if `.claude/agents/` already exists.

- **Fresh install:** `.claude/agents/` does NOT exist, or `--update` is NOT passed → run **Full Bootstrap** (all steps)
- **Update:** `--update` is passed AND `.claude/agents/` exists → run **Update Mode** (skip to Update Steps below)

---

## Full Bootstrap (fresh install)

### Step 0 — Copy MAS files into project

Copy agents, skills, commands, rules, hooks, and templates from the plugin into the project's `.claude/` directory. Also copy CLAUDE.md to the project root if it doesn't exist.

- Find the plugin cache directory at `~/.claude/plugins/cache/luke-plugins/mas/` (use the latest version subdirectory)
- Find the plugin cache: `PLUGIN_DIR=$(ls -d ~/.claude/plugins/cache/luke-plugins/mas/*/ | sort -V | tail -1)`
- Create `.claude/` if needed: `mkdir -p .claude`
- For each directory (`agents`, `commands`, `skills`, `hooks`, `rules`, `templates`):
  - If the directory does NOT exist in `.claude/` → copy it entirely
  - If the directory already exists → copy only items (subdirs/files) that don't already exist. For items that DO already exist, list them and ask the user: "These already exist — overwrite with MAS versions? (y/n/pick individually)". Only overwrite if the user confirms.
- For `settings.json`: only copy if `.claude/settings.json` does not exist
- Log what was copied and what was skipped so the user knows
- **Handle CLAUDE.md:**
  - If `CLAUDE.md` does NOT exist → copy the template as-is
  - If `CLAUDE.md` already exists → do NOT overwrite. Instead, read the existing file and append the **Mandatory Workflow** and **Project Type** sections from the template (the `## Mandatory Workflow` and `## Project Type` blocks) at the end, only if those sections are not already present. Preserve all existing content.
- If the plugin cache is not found, warn the user and ask them to use the git clone method instead.

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

### Step 2 — Replace all `{{placeholders}}`

Replace across every file in `.claude/` and `CLAUDE.md`:
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

### Step 3 — Fix hooks

Update `lint.sh` and `pre-stop-gate.sh` with the detected lint/test commands. Run `chmod +x .claude/hooks/*.sh`.

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
grep -r '{{' .claude/ CLAUDE.md --include='*.md' --include='*.sh' --include='*.json' | grep -v 'Invariant\|Gotcha\|step\|Describe your'
```
If any non-intentional placeholders remain, fill them.

### Step 6 — Critical: Verify testing framework

Check if a testing framework was detected (test command is not empty/placeholder). If NO testing framework is found:

```
⚠️  WARNING: NO TESTING FRAMEWORK DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TDD is non-negotiable in this workflow. Without a testing
framework, the following WILL NOT WORK:

  - /dev-loop (TDD enforced at every task)
  - /test-driven-development
  - /subagent-driven-development (two-stage review requires tests)
  - Engineer agent (refuses to implement without tests)
  - Reviewer agent (blocks on missing test coverage)

ACTION REQUIRED: Install a testing framework before using
any MAS workflow. Examples:
  - Node.js:  npm install -D vitest (or jest)
  - Python:   pip install pytest
  - Go:       (built-in, check go.mod exists)
  - Rust:     (built-in, check Cargo.toml exists)
  - Java:     add junit-jupiter to pom.xml or build.gradle

Then re-run /bootstrap to update the test command.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Do NOT suppress this warning.** Display it prominently before the summary.

### Step 7 — Report

```
MAS Template bootstrapped for: {project name}
Stack: {language} + {framework}
has_ui: {true/false}
Agents: 7 (6 active + ui-ux-designer conditional)
Skills: 13 | Commands: 4 | Rules: 4 | Hooks: 2

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/mas:bootstrap is the ONLY command you need from the plugin.
From now on, use the local (unprefixed) commands:

  /dev-loop         (not /mas:dev-loop)
  /ask-questions    (not /mas:ask-questions)
  /new-feature      (not /mas:new-feature)

The /mas: versions are raw templates with unfilled
placeholders — they won't work for your project.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remaining TODOs:
{Only show items that still have unfilled placeholders in CLAUDE.md.
 Check each section — if it contains real content (not just {{placeholder}}), omit it from this list.}
  - Fill Architecture Invariants in CLAUDE.md    ← only if ## Architecture Invariants still has {{Invariant}} placeholders
  - Fill Core Flow in CLAUDE.md                  ← only if ## Core Flow still has {{Describe your}} or {{step}} placeholders
  - Fill Key Gotchas in CLAUDE.md                ← only if ## Key Gotchas still has {{Gotcha}} placeholders
{If all sections are filled, print: "All sections filled — CLAUDE.md is ready."}

Ready to go? Try one of these:
  /dev-loop <describe your first task>
  /new-feature <feature name>
  /ask-questions <what you want to build>
```

---

## Update Mode (`--update`)

When the user runs `/mas:bootstrap --update`, update the MAS framework files while preserving all project-specific customizations.

### Update Step 1 — Extract current placeholder values

Before overwriting anything, read the current local files to extract the placeholder values that were filled during the original bootstrap. Read from any agent or skill file (e.g., `.claude/agents/engineer/CLAUDE.md`):

| Placeholder | How to extract |
|-------------|----------------|
| `{{PROJECT_NAME}}` | Read from CLAUDE.md `# {name}` heading or first line |
| `{{description}}` | Read from CLAUDE.md first paragraph or agent persona lines |
| `{{test-command}}` | Read from `.claude/agents/engineer/CLAUDE.md` — look for the line with the test command in Phase 4 |
| `{{lint-command}}` | Same file, lint command line |
| `{{typecheck-command}}` | Same file, typecheck command line |
| `{{build-command}}` | Read from CLAUDE.md Build & Test section |
| `{{install-command}}` | Read from CLAUDE.md Build & Test section |
| `{{format-command}}` | Read from CLAUDE.md Build & Test section |
| `{{your tech stack}}` | Read from CLAUDE.md Code Style section |
| `has_ui` | Read from CLAUDE.md Project Type section |

Store these values — they will be re-applied after overwriting.

### Update Step 2 — Categorize files

| Category | Files | Action |
|----------|-------|--------|
| **Framework (overwrite)** | `agents/*/CLAUDE.md`, `skills/*/SKILL.md`, `skills/*/*.md`, `commands/*.md` (except `bootstrap.md`), `templates/*.md` | Overwrite with new plugin versions, then re-apply placeholders |
| **User-owned (never touch)** | `CLAUDE.md`, `settings.json`, `settings.local.json` | Never overwrite — these have project-specific content (invariants, permissions, env) |
| **Hooks (merge carefully)** | `hooks/*.sh` | Only update if the user hasn't modified them. Check: if local file differs from the *previous* plugin version in more than just placeholder values → ask user before overwriting |
| **Rules (merge carefully)** | `rules/*.md` | Same as hooks — only update if unmodified by user |
| **Bootstrap command** | `commands/bootstrap.md` | Always overwrite — this is the updater itself, it should stay current |

### Update Step 3 — Overwrite framework files

1. Find plugin cache: `PLUGIN_DIR=$(ls -d ~/.claude/plugins/cache/luke-plugins/mas/*/ | sort -V | tail -1)`
2. For each **framework** file:
   - Copy the new version from `$PLUGIN_DIR` → `.claude/`
   - Log: `UPDATED: agents/orchestrator/CLAUDE.md`
3. For each **user-owned** file:
   - Skip entirely
   - Log: `SKIPPED (user-owned): CLAUDE.md`
4. For each **hooks/rules** file:
   - Compare local content (with placeholders stripped) against the new plugin version
   - If identical (only placeholder diffs) → overwrite silently
   - If user has made custom changes → show diff and ask: "This file has custom changes. Overwrite with new MAS version? (y/n)"
   - Log result
5. For **new files** that exist in plugin but not locally (new agents, skills, commands added in update):
   - Copy them in
   - Log: `ADDED: agents/new-agent/CLAUDE.md`

### Update Step 4 — Re-apply placeholder values

Using the values extracted in Update Step 1, replace all `{{placeholders}}` across the overwritten framework files. Same replacement logic as Full Bootstrap Step 2.

### Update Step 5 — Re-fix hooks

Same as Full Bootstrap Step 3. Update `lint.sh` and `pre-stop-gate.sh` with the current lint/test commands. Run `chmod +x .claude/hooks/*.sh`.

### Update Step 6 — Create any new output directories

```bash
mkdir -p docs/{design,plans,reports,results}
mkdir -p docs/tasks/{pending,in-progress,done,blocked}
```
(Idempotent — safe to re-run.)

### Update Step 7 — Verify

Same as Full Bootstrap Step 5. Check for unfilled placeholders.

### Update Step 8 — Report

```
MAS Template updated for: {project name}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
UPDATED (framework files replaced + placeholders re-applied):
  - agents/orchestrator/CLAUDE.md
  - agents/engineer/CLAUDE.md
  - agents/reviewer/CLAUDE.md
  - ... (list all updated files)

ADDED (new files from plugin):
  - ... (list any new files, or "none")

SKIPPED (user-owned, not touched):
  - CLAUDE.md
  - settings.json

HOOKS/RULES:
  - hooks/lint.sh — updated (no custom changes detected)
  - rules/tdd.md — skipped (custom changes preserved)
  - ... (list each with action taken)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your project-specific config (CLAUDE.md, settings.json) was
NOT modified. Only MAS framework files were updated.

Remaining TODOs:
{Check CLAUDE.md — only show items that still have unfilled placeholders:}
  - Fill Architecture Invariants    ← only if still has {{Invariant}} placeholders
  - Fill Core Flow                  ← only if still has {{Describe your}} or {{step}} placeholders
  - Fill Key Gotchas                ← only if still has {{Gotcha}} placeholders
{If all filled: "All CLAUDE.md sections filled — nothing to do."}

Continue using local (unprefixed) commands: /dev-loop, /ask-questions, etc.
```
