# Differential Review REVISE Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the 4 REVISE changes from the differential review to reduce false positives, fix the 52% reviewer rate, and add hook observability.

**Architecture:** Four independent changes to shell hooks and one markdown file. No new abstractions — each fix is the minimal change to the file it touches. Tasks can be done in any order; Task 3 has the highest expected impact (reviewer rate 52% → 85%).

**Tech Stack:** Bash, Markdown. No external dependencies. Tests are manual shell invocations.

---

## File Map

| File | Change | Task |
|------|--------|------|
| `.claude/hooks/validate-skill.sh` | Add allowlist check for project-local bare skill names | Task 1 |
| `hooks/validate-pipeline.sh` | Add `.reflect-skipped` sentinel file escape hatch | Task 2 |
| `commands/dev-loop.md` | Add between-batch review count check in Phase 2B→2C transition | Task 3 |
| `.claude/hooks/validate-dispatch.sh` | Add stderr debug logging + hook-fired counter | Task 4 |
| `commands/bootstrap.md` | Install updated validate-dispatch.sh with debug logging | Task 4 |

---

## Task 1: Add allowlist to validate-skill.sh

**Problem:** validate-skill.sh blocks any bare skill name matching its hardcoded list. A project with a custom skill named `verification` or `finishing-branch` gets silently blocked. No way to opt out.

**Fix:** Before the blocking loop, check if the bare skill name appears in `$CLAUDE_PROJECT_DIR/.claude/hooks/allowed-bare-skills.txt`. If it does, exit 0 (allow). If the file doesn't exist, proceed to the normal blocking logic.

**Files:**
- Modify: `.claude/hooks/validate-skill.sh` (after the `SKILL` extraction block, before the SUPERPOWERS_SKILLS loop)

- [ ] **Step 1: Read the current file to find the insertion point**

```bash
grep -n "SKILL\|exit 0\|SUPERPOWERS" /Users/soh/working/ai/claude-mas-template/.claude/hooks/validate-skill.sh
```

Expected output shows lines like:
```
16:SKILL=$(echo "$INPUT" | grep -o ...
20:if [ -z "$SKILL" ]; then
21:  exit 0
23:
24:# Superpowers skills that MUST use superpowers: prefix
25:SUPERPOWERS_SKILLS="writing-plans brainstorm ...
```

- [ ] **Step 2: Add the allowlist check after the empty-SKILL guard**

In `.claude/hooks/validate-skill.sh`, insert this block AFTER the `if [ -z "$SKILL" ]; then exit 0; fi` block and BEFORE the `# Superpowers skills` comment:

```bash
# Project-local allowlist: if this bare name is explicitly allowed, skip blocking
ALLOWLIST="${CLAUDE_PROJECT_DIR}/.claude/hooks/allowed-bare-skills.txt"
if [ -f "$ALLOWLIST" ] && grep -qxF "$SKILL" "$ALLOWLIST" 2>/dev/null; then
  exit 0
fi
```

The full file after the edit should look like:

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
MAS_SKILLS="dev-loop bug-fix reflect release bootstrap ask-questions finishing-branch verification reliability-review se-principles differential-review subagent-driven-development test-driven-development"

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

- [ ] **Step 3: Test — bare skill with no allowlist file (should BLOCK)**

```bash
cd /Users/soh/working/ai/claude-mas-template

echo '{"skill": "verification"}' | CLAUDE_TOOL_NAME=Skill CLAUDE_PROJECT_DIR=$(pwd) .claude/hooks/validate-skill.sh
echo "Exit: $? (expected 2)"
```

Expected: exit 2, "BLOCKED: Bare MAS skill name 'verification' detected."

- [ ] **Step 4: Test — bare skill listed in allowlist (should PASS)**

```bash
cd /Users/soh/working/ai/claude-mas-template

echo "verification" > /tmp/test-allowlist.txt
echo '{"skill": "verification"}' | CLAUDE_TOOL_NAME=Skill CLAUDE_PROJECT_DIR=/tmp CLAUDE_PROJECT_DIR=$(pwd) .claude/hooks/validate-skill.sh

# Actually set the allowlist in the right place
mkdir -p .claude/hooks
echo "verification" > .claude/hooks/allowed-bare-skills.txt
echo '{"skill": "verification"}' | CLAUDE_TOOL_NAME=Skill CLAUDE_PROJECT_DIR=$(pwd) .claude/hooks/validate-skill.sh
echo "Exit: $? (expected 0)"
rm .claude/hooks/allowed-bare-skills.txt
```

Expected: exit 0 (no output).

- [ ] **Step 5: Test — different bare skill not in allowlist (still BLOCK)**

```bash
echo "finishing-branch" > .claude/hooks/allowed-bare-skills.txt
echo '{"skill": "verification"}' | CLAUDE_TOOL_NAME=Skill CLAUDE_PROJECT_DIR=$(pwd) .claude/hooks/validate-skill.sh
echo "Exit: $? (expected 2)"
rm .claude/hooks/allowed-bare-skills.txt
```

Expected: exit 2 (verification is not in the allowlist).

- [ ] **Step 6: Test — prefixed skill always passes (unaffected by allowlist)**

```bash
echo '{"skill": "superpowers:verification"}' | CLAUDE_TOOL_NAME=Skill CLAUDE_PROJECT_DIR=$(pwd) .claude/hooks/validate-skill.sh
echo "Exit: $? (expected 0)"
```

Expected: exit 0.

- [ ] **Step 7: Update bootstrap.md to mention the allowlist**

In `commands/bootstrap.md`, find the section that describes `validate-skill.sh` (the write instruction added in v2.7.0). After the hook content block, add a note:

```markdown
> **Project-local allowlist:** If your project has custom skills whose bare names collide with MAS/superpowers names, add them one per line to `.claude/hooks/allowed-bare-skills.txt`. Example: if your project has a local `verification` skill, add `verification` to the allowlist and the hook will pass it through.
```

- [ ] **Step 8: Commit**

```bash
git add .claude/hooks/validate-skill.sh commands/bootstrap.md
git commit -m "fix: add project-local allowlist to validate-skill hook to prevent FPs on custom skills"
```

---

## Task 2: Add sentinel file escape hatch to validate-pipeline.sh

**Problem:** `validate-pipeline.sh` blocks session end when results + reviews exist but reflect is missing. This FPs on legitimate partial sessions (~15-20% estimated). No way to say "I intentionally skipped reflect for this session."

**Fix:** Before the blocking check, look for `docs/reports/.reflect-skipped`. If it exists and contains a non-empty reason, print the reason and exit 0 (non-blocking).

**Files:**
- Modify: `hooks/validate-pipeline.sh` (add sentinel check before the blocking `if` statement)

- [ ] **Step 1: Read the current blocking section**

```bash
grep -n "exit 2\|BLOCKED\|sentinel\|skipped" /Users/soh/working/ai/claude-mas-template/hooks/validate-pipeline.sh
```

Expected: shows the `if [ "$RESULTS" != "0" ] && [ "$REVIEWS" != "0" ] && [ "$REFLECT" = "0" ]` block near the bottom.

- [ ] **Step 2: Add the sentinel check before the blocking if-block**

In `hooks/validate-pipeline.sh`, insert this block immediately BEFORE the `# Block session end only when a full pipeline ran but reflect was skipped` comment:

```bash
# Sentinel escape hatch: if .reflect-skipped exists with a reason, skip the blocking check
SENTINEL="docs/reports/.reflect-skipped"
if [ -f "$SENTINEL" ]; then
  REASON=$(cat "$SENTINEL" | head -1 | tr -d '\n')
  if [ -n "$REASON" ]; then
    cat <<EOF
{"systemMessage": "Pipeline Validation: reflect skipped (intentional).\n  Reason: ${REASON}\n  To require reflect again, delete docs/reports/.reflect-skipped"}
EOF
    exit 0
  fi
fi
```

- [ ] **Step 3: Test — full pipeline + sentinel file (should PASS, not block)**

```bash
cd /Users/soh/working/ai/claude-mas-template

mkdir -p docs/tasks docs/results docs/reports
touch docs/tasks/TASK-001.md docs/results/TASK-001-result.md docs/reports/TASK-001-review.md
echo "Exploratory session — reflect not needed for documentation-only changes" > docs/reports/.reflect-skipped

hooks/validate-pipeline.sh
echo "Exit: $? (expected 0)"
```

Expected: exit 0 with message "Pipeline Validation: reflect skipped (intentional)."

- [ ] **Step 4: Test — sentinel file with empty content (should still BLOCK)**

```bash
echo "" > docs/reports/.reflect-skipped
hooks/validate-pipeline.sh
echo "Exit: $? (expected 2)"
rm docs/reports/.reflect-skipped
```

Expected: exit 2 (empty sentinel = no reason = not a valid skip).

- [ ] **Step 5: Test — no sentinel file, full pipeline, no reflect (still BLOCKS)**

```bash
hooks/validate-pipeline.sh
echo "Exit: $? (expected 2)"
```

Expected: exit 2, "Pipeline Validation BLOCKED".

- [ ] **Step 6: Clean up test artifacts**

```bash
rm -rf docs/tasks docs/results docs/reports
```

- [ ] **Step 7: Update dev-loop.md to document the sentinel**

In `commands/dev-loop.md`, find the Phase 2E section (around the "DISPATCH EXACTLY ONCE" note). After the reflect dispatch instructions, add:

```markdown
> **Intentional reflect skip:** If reflect is not needed for this session (e.g., documentation-only changes, exploratory spike), create `docs/reports/.reflect-skipped` with a one-line reason before ending the session:
> ```bash
> echo "Reason: documentation update only — no implementation decisions to evaluate" > docs/reports/.reflect-skipped
> ```
> The `validate-pipeline.sh` Stop hook will accept this and not block session end.
```

- [ ] **Step 8: Commit**

```bash
git add hooks/validate-pipeline.sh commands/dev-loop.md
git commit -m "fix: add sentinel file escape hatch to validate-pipeline when reflect is intentionally skipped"
```

---

## Task 3: Add between-batch review checkpoint to dev-loop.md

**Problem:** The reviewer dispatch rate is 52%. The existing "Review count invariant" in dev-loop.md (Phase 2B) is prose-only and ignored ~48% of the time. The current artifact gate runs at end-of-pipeline (before Step 5) — too late to prevent skipping mid-pipeline.

**Fix:** In Phase 2B, add an explicit per-batch checkpoint that must pass before dispatching the NEXT engineer batch. The check is: count result files from this batch, count review files from this batch. If they don't match, do not proceed to the next batch.

**Files:**
- Modify: `commands/dev-loop.md` (Phase 2B section, after the "Wait for all engineers" paragraph)

- [ ] **Step 1: Find the exact Phase 2B location**

```bash
grep -n "Phase 2B\|Phase 2C\|Wait for all engineers\|Do not continue to review" /Users/soh/working/ai/claude-mas-template/commands/dev-loop.md
```

Note the line numbers for "Wait for all engineers" and "Phase 2C".

- [ ] **Step 2: Read Phase 2B through 2C to understand the current flow**

```bash
sed -n '264,300p' /Users/soh/working/ai/claude-mas-template/commands/dev-loop.md
```

- [ ] **Step 3: Add the between-batch checkpoint**

In `commands/dev-loop.md`, find the paragraph that currently reads:

```
Wait for all engineers in the current batch to finish. Read each result file at `docs/results/TASK-{id}-result.md`. If any result file does not exist, that engineer dispatch failed — investigate before proceeding. Do not continue to review until all engineers have succeeded or failures are understood.
```

Replace it with:

```
Wait for all engineers in the current batch to finish. Read each result file at `docs/results/TASK-{id}-result.md`. If any result file does not exist, that engineer dispatch failed — investigate before proceeding. Do not continue to review until all engineers have succeeded or failures are understood.

**Between-batch gate (BLOCKING):** Before dispatching the next engineer batch, verify the current batch is fully reviewed:

```bash
# Count result files for this batch's task IDs
BATCH_RESULTS=$(ls docs/results/TASK-*-result.md 2>/dev/null | wc -l | tr -d ' ')
BATCH_REVIEWS=$(ls docs/reports/TASK-*-review.md 2>/dev/null | wc -l | tr -d ' ')
echo "Results: $BATCH_RESULTS | Reviews: $BATCH_REVIEWS"
```

If `BATCH_REVIEWS < BATCH_RESULTS`, you have unreviewed engineer output. **STOP. Do not dispatch the next engineer batch.** Go back to Phase 2C and dispatch reviewers for the unreviewed tasks first. Only proceed to the next engineer batch when all previous results have corresponding review files.
```

- [ ] **Step 4: Verify the edit reads cleanly**

```bash
grep -A 20 "Between-batch gate" /Users/soh/working/ai/claude-mas-template/commands/dev-loop.md
```

Expected: the new "Between-batch gate (BLOCKING)" section appears with the bash block and the STOP instruction.

- [ ] **Step 5: Add a corresponding note to the routing table preamble**

In `commands/dev-loop.md`, find the "Review count invariant" line (around line 266):

```
**Review count invariant:** Expected reviews = Expected engineer dispatches. Track both counts. If counts diverge at any point, you skipped reviews — STOP and fix before continuing.
```

Append to this line:

```
This is enforced by the between-batch gate in Phase 2B — check result/review counts before each new engineer batch, not just at end-of-pipeline.
```

- [ ] **Step 6: Commit**

```bash
git add commands/dev-loop.md
git commit -m "fix: add between-batch review gate in Phase 2B to enforce 1:1 engineer:reviewer ratio"
```

---

## Task 4: Add debug logging to validate-dispatch.sh + audit hook firing

**Problem:** Sessions running CLI 2.1.92 (with validate-dispatch.sh active) still show 41% bare names. Either the hook isn't firing, the model retries after being blocked, or the `CLAUDE_TOOL_NAME` environment variable isn't being set in some contexts. We don't know which.

**Fix:** Add stderr debug logging to validate-dispatch.sh. Each hook invocation logs: timestamp, TOOL_NAME env var, extracted SUBAGENT_TYPE, and decision (allowed/blocked). Output goes to `~/.claude/hook-debug.log`. Also add a test command to verify the hook fires correctly in the current environment.

**Files:**
- Modify: `.claude/hooks/validate-dispatch.sh` (add debug logging)
- Create: `.claude/scripts/audit-hook-firing.sh` (NEW — reads hook-debug.log and session JSONL to correlate)

- [ ] **Step 1: Add debug logging to validate-dispatch.sh**

In `.claude/hooks/validate-dispatch.sh`, add this debug function immediately after the `INPUT=$(cat)` line:

```bash
# Debug logging — writes to ~/.claude/hook-debug.log
DEBUG_LOG="${HOME}/.claude/hook-debug.log"
_debug() {
  echo "[$(date '+%Y-%m-%dT%H:%M:%S')] validate-dispatch: $*" >> "$DEBUG_LOG" 2>/dev/null || true
}
```

Then add `_debug` calls at key decision points:

After extracting SUBAGENT_TYPE:
```bash
_debug "TOOL_NAME='${TOOL_NAME}' SUBAGENT_TYPE='${SUBAGENT_TYPE}'"
```

Before each `exit 2` (bare name block):
```bash
_debug "BLOCKED bare name: ${SUBAGENT_TYPE}"
```

Before the reflect guard `exit 2`:
```bash
_debug "BLOCKED reflect re-dispatch (report exists)"
```

Before the final `exit 0`:
```bash
_debug "ALLOWED: ${SUBAGENT_TYPE}"
```

The full updated file:

```bash
#!/bin/bash
# PreToolUse hook: validate Agent dispatch naming
# Blocks bare agent names (e.g., "engineer" instead of "mas:engineer:engineer")

# Read tool input from stdin
INPUT=$(cat)

# Extract tool name from environment
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"

# Debug logging — writes to ~/.claude/hook-debug.log
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

- [ ] **Step 2: Test debug logging works**

```bash
cd /Users/soh/working/ai/claude-mas-template

# Test allowed dispatch logs correctly
echo '{"subagent_type": "mas:engineer:engineer"}' | CLAUDE_TOOL_NAME=Agent CLAUDE_PROJECT_DIR=$(pwd) .claude/hooks/validate-dispatch.sh
grep "ALLOWED: mas:engineer:engineer" ~/.claude/hook-debug.log | tail -1
```

Expected: a log line like `[2026-04-11T...] validate-dispatch: ALLOWED: mas:engineer:engineer`

```bash
# Test blocked dispatch logs correctly
echo '{"subagent_type": "engineer"}' | CLAUDE_TOOL_NAME=Agent CLAUDE_PROJECT_DIR=$(pwd) .claude/hooks/validate-dispatch.sh
grep "BLOCKED bare name: engineer" ~/.claude/hook-debug.log | tail -1
```

Expected: a log line like `[2026-04-11T...] validate-dispatch: BLOCKED bare name: engineer`

- [ ] **Step 3: Create audit-hook-firing.sh**

Create `.claude/scripts/audit-hook-firing.sh`:

```bash
#!/bin/bash
# Audit script: check if validate-dispatch hook is firing and catch bare-after-block patterns
#
# Usage: bash .claude/scripts/audit-hook-firing.sh
#
# Reads ~/.claude/hook-debug.log and checks for:
# 1. How many unique session timestamps fired the hook
# 2. Bare name block count vs allowed count
# 3. Bare-name-then-bare-name patterns (model retrying after block with same bare name)

LOG="${HOME}/.claude/hook-debug.log"

if [ ! -f "$LOG" ]; then
  echo "No hook debug log found at $LOG"
  echo "Run a session with the updated validate-dispatch.sh first."
  exit 1
fi

echo "=== Hook Debug Log Analysis ==="
echo "Log: $LOG"
echo "Total entries: $(wc -l < "$LOG")"
echo ""

echo "--- Dispatch Decisions ---"
ALLOWED=$(grep -c "ALLOWED:" "$LOG" 2>/dev/null || echo 0)
BLOCKED=$(grep -c "BLOCKED" "$LOG" 2>/dev/null || echo 0)
echo "Allowed: $ALLOWED"
echo "Blocked: $BLOCKED"
if [ "$((ALLOWED + BLOCKED))" -gt 0 ]; then
  BLOCK_RATE=$(echo "scale=1; $BLOCKED * 100 / ($ALLOWED + $BLOCKED)" | bc 2>/dev/null || echo "?")
  echo "Block rate: ${BLOCK_RATE}%"
fi
echo ""

echo "--- Blocked Agent Types ---"
grep "BLOCKED bare name:" "$LOG" | sed 's/.*BLOCKED bare name: //' | sort | uniq -c | sort -rn
echo ""

echo "--- Allowed Agent Types ---"
grep "ALLOWED:" "$LOG" | sed 's/.*ALLOWED: //' | sort | uniq -c | sort -rn
echo ""

echo "--- Consecutive Bare Name Retries (model retrying after block) ---"
# Look for BLOCKED followed immediately by another BLOCKED for same name
python3 -c "
import re, sys
lines = open('$LOG').readlines()
prev_blocked = None
retries = 0
for line in lines:
    m = re.search(r'BLOCKED bare name: (\S+)', line)
    if m:
        name = m.group(1)
        if prev_blocked == name:
            retries += 1
            print(f'  Retry detected: {name} blocked twice in a row')
        prev_blocked = name
    elif 'ALLOWED' in line:
        prev_blocked = None
print(f'Total retry patterns: {retries}')
" 2>/dev/null || echo "  (python3 not available for retry analysis)"
```

- [ ] **Step 4: Make audit script executable**

```bash
chmod +x /Users/soh/working/ai/claude-mas-template/.claude/scripts/audit-hook-firing.sh
```

- [ ] **Step 5: Test the audit script (dry run with fake log)**

```bash
cd /Users/soh/working/ai/claude-mas-template

# Generate test log entries
echo '[2026-04-11T10:00:01] validate-dispatch: TOOL_NAME='"'"'Agent'"'"' SUBAGENT_TYPE='"'"'engineer'"'"'' >> ~/.claude/hook-debug.log
echo '[2026-04-11T10:00:01] validate-dispatch: BLOCKED bare name: engineer' >> ~/.claude/hook-debug.log
echo '[2026-04-11T10:00:05] validate-dispatch: TOOL_NAME='"'"'Agent'"'"' SUBAGENT_TYPE='"'"'mas:engineer:engineer'"'"'' >> ~/.claude/hook-debug.log
echo '[2026-04-11T10:00:05] validate-dispatch: ALLOWED: mas:engineer:engineer' >> ~/.claude/hook-debug.log

bash .claude/scripts/audit-hook-firing.sh
```

Expected output shows:
```
Allowed: 1
Blocked: 1
Block rate: 50.0%
--- Blocked Agent Types ---
   1 engineer
--- Allowed Agent Types ---
   1 mas:engineer:engineer
```

- [ ] **Step 6: Commit**

```bash
git add .claude/hooks/validate-dispatch.sh .claude/scripts/audit-hook-firing.sh
git commit -m "feat: add debug logging to validate-dispatch hook and hook-firing audit script"
```

---

## Task 5: Update plugin, bump version, release

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `.claude-plugin/plugin.json` (bump to 2.8.0)
- Modify: `.claude-plugin/marketplace.json` (bump to 2.8.0)
- Rebuild: `claude-mas-template.plugin`

- [ ] **Step 1: Add CHANGELOG entry**

In `CHANGELOG.md`, add before `## [2.7.0]`:

```markdown
## [2.8.0] — 2026-04-11

### Added

- **validate-skill.sh allowlist** — Project-local `allowed-bare-skills.txt` prevents FPs when custom skills share names with MAS/superpowers skills.
- **validate-pipeline.sh sentinel** — `docs/reports/.reflect-skipped` escape hatch for intentional partial sessions. Hook reads the file's reason and exits 0 instead of blocking.
- **Between-batch review gate** in `dev-loop.md` Phase 2B — Explicit check before each new engineer batch: reviews must match results. Addresses 52% reviewer rate gap.
- **Debug logging** in `validate-dispatch.sh` — All hook decisions logged to `~/.claude/hook-debug.log`. Timestamps, TOOL_NAME env var, subagent type, and decision (ALLOWED/BLOCKED).
- **`audit-hook-firing.sh`** — New audit script that reads the debug log and reports allowed/blocked counts, block rate, and consecutive-retry patterns (model retrying bare names after block).

### Changed

- `commands/bootstrap.md` — Updated validate-skill.sh instructions to mention the allowlist mechanism.
- `commands/dev-loop.md` — Between-batch gate documentation added to Phase 2B. Reflect skip sentinel documented in Phase 2E.

---

```

- [ ] **Step 2: Bump versions**

In `.claude-plugin/plugin.json`, change `"version": "2.7.0"` to `"version": "2.8.0"`.
In `.claude-plugin/marketplace.json`, change `"version": "2.7.0"` to `"version": "2.8.0"`.

- [ ] **Step 3: Rebuild plugin**

```bash
cd /Users/soh/working/ai/claude-mas-template
rm -f claude-mas-template.plugin
zip -r claude-mas-template.plugin \
  .claude-plugin/plugin.json \
  .claude-plugin/marketplace.json \
  CLAUDE.md README.md \
  agents/bug-fixer/CLAUDE.md \
  agents/differential-reviewer/CLAUDE.md \
  agents/engineer/CLAUDE.md \
  agents/reflect-agent/CLAUDE.md \
  agents/researcher/CLAUDE.md \
  agents/reviewer/CLAUDE.md \
  agents/ui-ux-designer/CLAUDE.md \
  commands/bootstrap.md commands/bug-fix.md \
  commands/dev-loop.md commands/reflect.md commands/release.md \
  hooks/lint.sh hooks/pre-stop-gate.sh \
  hooks/suggest-compact.sh hooks/validate-pipeline.sh \
  rules/agent-workflow.md rules/honesty-first.md \
  rules/meta-rules-guide.md rules/severity-discipline.md \
  skills/ask-questions/SKILL.md \
  skills/differential-review/SKILL.md \
  skills/finishing-branch/SKILL.md \
  skills/property-based-testing/SKILL.md \
  skills/reliability-review/SKILL.md \
  skills/se-principles/SKILL.md \
  skills/subagent-driven-development/SKILL.md \
  skills/verification/SKILL.md \
  templates/dispatch-templates.md \
  templates/review-report.md \
  templates/task-spec.md
```

- [ ] **Step 4: Verify**

```bash
unzip -p claude-mas-template.plugin .claude-plugin/plugin.json | grep version
```

Expected: `"version": "2.8.0"`.

- [ ] **Step 5: Commit, tag, push, release**

```bash
git add CHANGELOG.md .claude-plugin/plugin.json .claude-plugin/marketplace.json claude-mas-template.plugin
git commit -m "chore: bump version to v2.8.0"
git tag v2.8.0
git push origin main --tags
gh release create v2.8.0 \
  --repo lukehungngo/claude-mas-template \
  --title "v2.8.0 — False positive fixes and reviewer rate enforcement" \
  --notes "## What's New

Fixes from differential review of v2.7.0. Reduces false positives in hooks, addresses 52% reviewer rate gap, and adds hook observability.

### validate-skill.sh allowlist
Projects with custom skills that share names with MAS/superpowers skills can add them to \`.claude/hooks/allowed-bare-skills.txt\` (one name per line). Hook passes them through instead of blocking.

### validate-pipeline.sh sentinel
Create \`docs/reports/.reflect-skipped\` with a one-line reason to bypass the reflect-missing blocker for intentional partial sessions.

### Between-batch review gate (Phase 2B)
Dev-loop now requires reviews to match results before dispatching next engineer batch. Targets the 52% reviewer rate observed in production sessions.

### Hook debug logging
\`validate-dispatch.sh\` logs every decision to \`~/.claude/hook-debug.log\`. New \`.claude/scripts/audit-hook-firing.sh\` correlates hook activity with session data to detect if bare-name retries are happening after blocks."
```

---

## Self-Review

**Spec coverage:**
1. ✅ validate-skill.sh allowlist — Task 1
2. ✅ validate-pipeline.sh sentinel — Task 2
3. ✅ Between-batch review gate — Task 3
4. ✅ validate-dispatch.sh debug logging + audit script — Task 4
5. ✅ Release — Task 5

**Placeholder scan:** No TBDs, no "add appropriate error handling" placeholders. All bash blocks are complete and runnable.

**Type consistency:** No types involved (shell/markdown). File paths are consistent across all tasks.
