---
description: Bootstrap MAS Template — auto-detect stack, fill CLAUDE.md, create directories, configure hooks
---

# Bootstrap MAS Template

Set up your project for the Claude Multi-Agent System. $ARGUMENTS

This command configures your project — agent, skill, and command files are NOT installed locally. They are provided by the MAS plugin and accessed via `/mas:` prefixed slash commands.

## What Bootstrap Does

1. Detects your tech stack (language, test/lint/build commands, has_ui)
2. Creates or updates CLAUDE.md with detected values
3. Creates hooks (.claude/hooks/ — 6 hooks for lint, quality gate, dispatch validation, skill validation, compaction, pipeline validation)
4. Creates output directories (docs/superpowers/, docs/reports/, etc.)
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
# PostToolUse hook: Fast lint after file edits
# Triggered on: Edit, Write tool uses
#
# CUSTOMIZE: Replace the LINT_CMD with your project's linter
# Examples:
#   Python:     "ruff check src/ tests/"
#   TypeScript: "eslint src/ --quiet"
#   Go:         "golangci-lint run ./..."

set -euo pipefail

# CUSTOMIZE THIS LINE:
LINT_CMD="{detected-lint-command}"

# Only lint if source files were recently changed
if git diff --name-only HEAD 2>/dev/null | grep -qE '\.(py|ts|js|tsx|jsx|go|rs)$'; then
  $LINT_CMD 2>&1 || true
fi
```

Write `pre-stop-gate.sh` with the detected test command:
```bash
#!/bin/bash
# Stop hook: Non-blocking quality summary before session ends
# Always exits 0 (non-blocking) — informational only
#
# CUSTOMIZE: Replace LINT_CMD and TEST_CMD with your project's commands

set -euo pipefail

# CUSTOMIZE THESE LINES:
LINT_CMD="{detected-lint-command}"
TEST_CMD="{detected-test-command}"

LINT_RESULT=$($LINT_CMD 2>&1 || true)
TEST_RESULT=$($TEST_CMD 2>&1 | tail -5 || true)

cat <<EOF
{"systemMessage": "Session Quality Summary:\n\nLint:\n${LINT_RESULT}\n\nTests:\n${TEST_RESULT}"}
EOF

# Always exit 0 — this hook is informational, never blocks
exit 0
```

Write `validate-dispatch.sh` to block bare agent names at dispatch time:
```bash
#!/bin/bash
# PreToolUse hook: validate Agent dispatch naming
# Blocks bare agent names (e.g., "engineer" instead of "mas:engineer:engineer")

# Read tool input from stdin
INPUT=$(cat)

# Extract tool name from environment
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"

# Debug logging — appends to ~/.claude/hook-debug.log
DEBUG_LOG="${HOME}/.claude/hook-debug.log"
_debug() {
  echo "[$(date '+%Y-%m-%dT%H:%M:%S')] validate-dispatch: $*" >> "$DEBUG_LOG" 2>/dev/null || true
}

# Only check Agent tool calls
if [ "$TOOL_NAME" != "Agent" ]; then
  exit 0
fi

# Extract subagent_type value
SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"subagent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"subagent_type"[[:space:]]*:[[:space:]]*"//' | sed 's/"//')

# Extract model value
MODEL=$(echo "$INPUT" | grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"model"[[:space:]]*:[[:space:]]*"//' | sed 's/"//')

if [ -z "$SUBAGENT_TYPE" ]; then
  exit 0
fi

_debug "TOOL_NAME='${TOOL_NAME}' SUBAGENT_TYPE='${SUBAGENT_TYPE}'"

# Known MAS agent slugs that MUST use mas: prefix
BARE_NAMES="engineer reviewer bug-fixer researcher differential-reviewer ui-ux-designer reflect-agent orchestrator"

for name in $BARE_NAMES; do
  if [ "$SUBAGENT_TYPE" = "$name" ]; then
    _debug "BLOCKED bare name: ${SUBAGENT_TYPE}"
    echo "BLOCKED: Bare agent name '$name' detected."
    echo "Use 'mas:${name}:${name}' instead."
    echo ""
    echo "Quick reference:"
    echo "  BAD:  Agent(subagent_type: \"$name\")"
    echo "  GOOD: Agent(subagent_type: \"mas:${name}:${name}\")"
    exit 2
  fi
done

# Block deprecated orchestrator
if [ "$SUBAGENT_TYPE" = "mas:orchestrator:orchestrator" ]; then
  _debug "BLOCKED deprecated orchestrator"
  echo "BLOCKED: mas:orchestrator:orchestrator is DEPRECATED since v2.0."
  echo "The dev-loop command IS the orchestrator. Do not dispatch this agent."
  exit 2
fi

# Block general agent — use Explore (haiku) for discovery or a MAS specialist instead
if [ "$SUBAGENT_TYPE" = "general" ]; then
  _debug "BLOCKED general agent"
  cat <<'BLOCKED_MSG'
BLOCKED: 'general' is not a valid dispatch in the MAS pipeline.

Use a specific agent instead:
  Discovery / codebase search:  Agent(subagent_type: "Explore")
  Implementation:                Agent(subagent_type: "mas:engineer:engineer")
  Code review:                   Agent(subagent_type: "mas:reviewer:reviewer")
  Research:                      Agent(subagent_type: "mas:researcher:researcher")
  Bug fix:                       Agent(subagent_type: "mas:bug-fixer:bug-fixer")
BLOCKED_MSG
  exit 2
fi

# Block standard/deep reviewer on Haiku — those depths require judgment
if [ "$SUBAGENT_TYPE" = "mas:reviewer:reviewer" ] && echo "$MODEL" | grep -qi "haiku"; then
  # Extract depth from prompt field to allow quick+haiku
  PROMPT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('prompt',''))" 2>/dev/null || echo "")
  DEPTH=$(echo "$PROMPT" | grep -oi 'depth:[[:space:]]*[a-z]*' | head -1 | sed 's/depth:[[:space:]]*//' | tr '[:upper:]' '[:lower:]')
  if [ "$DEPTH" != "quick" ]; then
    _debug "BLOCKED reviewer on haiku (depth=${DEPTH:-standard}): ${MODEL}"
    cat <<EOF
BLOCKED: mas:reviewer:reviewer cannot run on Haiku for standard/deep reviews.
Depth '${DEPTH:-standard}' requires minimum model: sonnet.

Options:
  1. Use model: "sonnet" for standard/deep review
  2. Set depth: quick in prompt if this is truly a trivial change (grep-only scan)

BAD:  Agent(subagent_type: "mas:reviewer:reviewer", model: "haiku")
GOOD: Agent(subagent_type: "mas:reviewer:reviewer", model: "sonnet")
EOF
    exit 2
  fi
fi

# Block reflect re-dispatch if report already exists
REFLECT_REPORT="${CLAUDE_PROJECT_DIR}/docs/reports/reflect-report.md"
if [ "$SUBAGENT_TYPE" = "mas:reflect-agent:reflect-agent" ] && [ -f "$REFLECT_REPORT" ]; then
  _debug "BLOCKED reflect re-dispatch (report exists)"
  echo "BLOCKED: Reflect agent already ran (docs/reports/reflect-report.md exists)."
  echo "Dispatch-exactly-once constraint: reflect runs exactly once per dev-loop session."
  echo "To re-run reflect, delete docs/reports/reflect-report.md first."
  exit 2
fi

_debug "ALLOWED: ${SUBAGENT_TYPE}"
exit 0
```

Write `validate-skill.sh` to block bare skill names at invocation time:
```bash
#!/bin/bash
# PreToolUse hook: Validate Skill tool invocation naming
# Blocks bare superpowers skill names that should use 'superpowers:' prefix
# Blocks bare MAS skill names that should use 'mas:' prefix

INPUT=$(cat)
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"

# Only check Skill tool calls
if [ "$TOOL_NAME" != "Skill" ]; then
  exit 0
fi

# Extract skill name
SKILL=$(echo "$INPUT" | grep -o '"skill"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"skill"[[:space:]]*:[[:space:]]*"//' | sed 's/"//')

if [ -z "$SKILL" ]; then
  exit 0
fi

# Project-local allowlist: if this bare name is explicitly allowed, skip blocking
ALLOWLIST="${CLAUDE_PROJECT_DIR}/.claude/hooks/allowed-bare-skills.txt"
if [ -f "$ALLOWLIST" ] && grep -qxF "$SKILL" "$ALLOWLIST" 2>/dev/null; then
  exit 0
fi

# Superpowers skills that MUST use superpowers: prefix
SUPERPOWERS_SKILLS="writing-plans brainstorm brainstorming executing-plans verification verification-before-completion finishing-branch finishing-a-development-branch subagent-driven-development test-driven-development systematic-debugging using-git-worktrees dispatching-parallel-agents requesting-code-review receiving-code-review"

for s in $SUPERPOWERS_SKILLS; do
  if [ "$SKILL" = "$s" ]; then
    echo "BLOCKED: Bare superpowers skill name '$s' detected."
    echo "Use 'superpowers:${s}' instead."
    echo ""
    echo "Quick reference:"
    echo "  BAD:  Skill(skill: \"$s\")"
    echo "  GOOD: Skill(skill: \"superpowers:${s}\")"
    exit 2
  fi
done

# MAS skills that MUST use mas: prefix
MAS_SKILLS="dev-loop bug-fix reflect release bootstrap ask-questions verification reliability-review se-principles differential-review obsidian"

for s in $MAS_SKILLS; do
  if [ "$SKILL" = "$s" ]; then
    echo "BLOCKED: Bare MAS skill name '$s' detected."
    echo "Use 'mas:${s}' instead."
    echo ""
    echo "Quick reference:"
    echo "  BAD:  Skill(skill: \"$s\")"
    echo "  GOOD: Skill(skill: \"mas:${s}\")"
    exit 2
  fi
done

exit 0
```

> **Project-local allowlist:** If your project has custom skills whose bare names collide with MAS/superpowers names, add them one per line to `.claude/hooks/allowed-bare-skills.txt`. The hook will pass them through without blocking.

Write `suggest-compact.sh` to suggest /compact at strategic intervals:
```bash
#!/bin/bash
# PreToolUse hook: Suggest /compact at strategic intervals
# Triggered on: Edit, Write, Bash tool uses
#
# Adapted from ECC's suggest-compact.js. Tracks tool call count per
# session and suggests /compact at configurable intervals.
#
# Why manual over auto-compact:
# - Auto-compact happens at arbitrary points, often mid-task
# - Strategic compacting preserves context through logical phases
#
# CUSTOMIZE: Adjust COMPACT_THRESHOLD (default: 50)

set -euo pipefail

COMPACT_THRESHOLD="${COMPACT_THRESHOLD:-50}"
COMPACT_INTERVAL=25

SESSION_ID="${CLAUDE_SESSION_ID:-default}"
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
COUNTER_FILE="${TMPDIR:-/tmp}/claude-tool-count-${SESSION_ID}"

# Read current count
COUNT=0
if [ -f "$COUNTER_FILE" ]; then
  COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
  # Validate count is a number
  if ! [[ "$COUNT" =~ ^[0-9]+$ ]]; then
    COUNT=0
  fi
fi

COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

if [ "$COUNT" -eq "$COMPACT_THRESHOLD" ]; then
  echo "[StrategicCompact] ${COMPACT_THRESHOLD} tool calls — consider /compact if transitioning phases" >&2
fi

if [ "$COUNT" -gt "$COMPACT_THRESHOLD" ]; then
  PAST=$((COUNT - COMPACT_THRESHOLD))
  if [ $((PAST % COMPACT_INTERVAL)) -eq 0 ]; then
    echo "[StrategicCompact] ${COUNT} tool calls — good checkpoint for /compact if context is stale" >&2
  fi
fi

exit 0
```

Write `validate-pipeline.sh` to validate the MAS pipeline ran at session end:
```bash
#!/bin/bash
# Stop hook: Validate that the MAS pipeline actually ran
# Triggered on: Every session stop (non-blocking, informational)
#
# Checks for the presence of pipeline artifacts:
# - docs/results/TASK-*-result.md   (engineer agents dispatched)
# - docs/reports/TASK-*-review.md   (reviewer agents dispatched)
# - docs/reports/reflect-report.md  (reflect agent ran)
#
# If a plan exists but results/reviews don't, the pipeline was bypassed.
# This is the structural enforcement that dev-loop checkpoint assertions
# tried to achieve with prose (and failed in 5/5 sessions).

set -euo pipefail

# Check if an active pipeline is in progress (results or reviews exist)
# Plans persist on main after merge, so their presence alone does NOT mean a pipeline is active.
RESULTS=$( (ls docs/results/TASK-*-result.md 2>/dev/null || true) | wc -l | tr -d ' ')
REVIEWS=$( (ls docs/reports/TASK-*-review.md 2>/dev/null || true) | wc -l | tr -d ' ')

# No results AND no reviews = no active pipeline, nothing to validate
if [ "$RESULTS" = "0" ] && [ "$REVIEWS" = "0" ]; then
  exit 0
fi

REFLECT=$( (ls docs/reports/reflect-report.md 2>/dev/null || true) | wc -l | tr -d ' ')
SELF_REVIEWS=$( (ls docs/results/TASK-*-self-review.md 2>/dev/null || true) | wc -l | tr -d ' ')

WARNINGS=""

if [ "$RESULTS" = "0" ]; then
  WARNINGS="${WARNINGS}\n  ⚠ No engineer results found (docs/results/TASK-*-result.md) — agents may not have been dispatched"
fi

if [ "$REVIEWS" = "0" ]; then
  WARNINGS="${WARNINGS}\n  ⚠ No review reports found (docs/reports/TASK-*-review.md) — reviews may have been skipped"
fi

if [ "$RESULTS" != "$REVIEWS" ] && [ "$RESULTS" != "0" ] && [ "$REVIEWS" != "0" ]; then
  WARNINGS="${WARNINGS}\n  ⚠ Result/review count mismatch: ${RESULTS} results vs ${REVIEWS} reviews"
fi

if [ "$REFLECT" = "0" ]; then
  WARNINGS="${WARNINGS}\n  ⚠ No reflect report found (docs/reports/reflect-report.md)"
fi

if [ "$SELF_REVIEWS" = "0" ] && [ "$RESULTS" != "0" ]; then
  WARNINGS="${WARNINGS}\n  ⚠ No self-review files found (docs/results/TASK-*-self-review.md)"
fi

# Sentinel escape hatch: if .reflect-skipped exists with a non-empty reason, skip blocking
SENTINEL="docs/reports/.reflect-skipped"
if [ -f "$SENTINEL" ]; then
  REASON=$(head -1 "$SENTINEL" | tr -d '\n')
  if [ -n "$REASON" ]; then
    cat <<EOF
{"systemMessage": "Pipeline Validation: reflect skipped (intentional).\n  Reason: ${REASON}\n  To require reflect again, delete docs/reports/.reflect-skipped"}
EOF
    exit 0
  fi
fi

# Block session end only when a full pipeline ran but reflect was skipped
# Condition: plan + results + reviews all present, but NO reflect report
if [ "$RESULTS" != "0" ] && [ "$REVIEWS" != "0" ] && [ "$REFLECT" = "0" ]; then
  cat <<EOF
{"systemMessage": "Pipeline Validation BLOCKED:\n  Engineer results: ${RESULTS}\n  Review reports: ${REVIEWS}\n  Reflect report: MISSING ← REQUIRED\n\n  A full pipeline ran (results + reviews present) but the reflect agent was never dispatched.\n  Run: Agent(subagent_type: 'mas:reflect-agent:reflect-agent', ...)\n  Then save the verdict to docs/reports/reflect-report.md before ending this session."}
EOF
  exit 2
fi

# Warn only (non-blocking) for partial pipeline issues
if [ -n "$WARNINGS" ]; then
  cat <<EOF
{"systemMessage": "Pipeline Validation:\n  Engineer results: ${RESULTS}\n  Review reports: ${REVIEWS}\n  Self-reviews: ${SELF_REVIEWS}\n  Reflect report: ${REFLECT}\n${WARNINGS}"}
EOF
fi

exit 0
```

Make executable:
```bash
chmod +x .claude/hooks/*.sh
```

Create or update `.claude/settings.json` to wire all hooks. If `.claude/settings.json` already exists, merge the `hooks` entries; otherwise create it:
```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Agent", "hooks": [{ "type": "command", "command": ".claude/hooks/validate-dispatch.sh" }] },
      { "matcher": "Skill", "hooks": [{ "type": "command", "command": ".claude/hooks/validate-skill.sh" }] },
      { "matcher": "Edit|Write|Bash", "hooks": [{ "type": "command", "command": ".claude/hooks/suggest-compact.sh" }] }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": ".claude/hooks/lint.sh" }] }
    ],
    "Stop": [
      { "matcher": "*", "hooks": [
        { "type": "command", "command": ".claude/hooks/pre-stop-gate.sh" },
        { "type": "command", "command": ".claude/hooks/validate-pipeline.sh" }
      ]}
    ]
  }
}
```

> If `.claude/settings.json` already has a `hooks` section, merge the PreToolUse, PostToolUse, and Stop entries rather than overwriting.

### Step 4 — Create output directories and update .gitignore

```bash
mkdir -p docs/{design,plans,reports,results}
mkdir -p docs/superpowers/{plans,reports}
mkdir -p docs/brainstorms
```

Ensure `.worktrees/` and `.mcp.json` are in `.gitignore`. If not already present, append them:
```bash
grep -qxF '.worktrees/' .gitignore 2>/dev/null || echo '.worktrees/' >> .gitignore
grep -qxF '.mcp.json' .gitignore 2>/dev/null || echo '.mcp.json' >> .gitignore
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
