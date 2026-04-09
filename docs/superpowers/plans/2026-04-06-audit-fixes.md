# Audit Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 5 structural issues identified in the 4-day MAS usage audit: naming drift in user projects, reflect over-dispatch, missing skill prefix validation, non-blocking pipeline validation, and orphaned orchestrator in plugin.

**Architecture:** All fixes are shell hooks and markdown patches. No production code. The root cause of naming drift is bootstrap not installing `validate-dispatch.sh` in user projects — the template repo has it, but users don't. All other fixes are either hook logic upgrades or markdown updates.

**Tech Stack:** Bash, Markdown, JSON (settings.json). No test framework.

---

## File Map

| File | Responsibility | Task |
|------|---------------|------|
| `commands/bootstrap.md` | Add validate-dispatch + validate-skill to Step 3 | Task 1 |
| `.claude/hooks/validate-dispatch.sh` | Add reflect once-only guard | Task 2 |
| `.claude/hooks/validate-skill.sh` | NEW: block unprefixed superpowers skill names | Task 3 |
| `.claude/settings.json` | Add PreToolUse hook for Skill tool | Task 3 |
| `hooks/validate-pipeline.sh` | Upgrade from warn to block when reflect missing | Task 4 |
| `claude-mas-template.plugin` | Rebuild without orchestrator agent | Task 5 |
| `CHANGELOG.md` | Document all changes | Task 5 |

---

## Task 1: Fix bootstrap to install validate-dispatch.sh and validate-skill.sh in user projects

**Root cause of naming drift:** `commands/bootstrap.md` Step 3 only creates `lint.sh` and `pre-stop-gate.sh`. It does NOT create `validate-dispatch.sh`, so user projects have no naming enforcement hook.

**Files:**
- Modify: `commands/bootstrap.md` (Step 3 section)

- [ ] **Step 1: Read the current Step 3 block in bootstrap.md**

```bash
grep -n "Step 3" commands/bootstrap.md
```
Find the line numbers for Step 3 (Create hooks section).

- [ ] **Step 2: Add validate-dispatch.sh to bootstrap Step 3**

In `commands/bootstrap.md`, after the `chmod +x .claude/hooks/*.sh` line in Step 3, add the following new hook creation instructions:

```markdown
Write `validate-dispatch.sh` to block bare agent names:
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
```

- [ ] **Step 3: Add validate-skill.sh to bootstrap Step 3**

After `validate-dispatch.sh`, add:

```markdown
Write `validate-skill.sh` to enforce superpowers: prefix:
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
    echo "BLOCKED: Bare superpowers skill name '$s'."
    echo "Use 'superpowers:${s}' instead."
    exit 2
  fi
done
exit 0
```
```

- [ ] **Step 4: Add the two new hooks to the settings.json that bootstrap creates**

In bootstrap Step 3, after the chmod line, add:

```markdown
Update `.claude/settings.json` to add PreToolUse hooks for the new validators. Add to the `hooks.PreToolUse` array:
```json
{
  "matcher": "Agent",
  "hooks": [{ "type": "command", "command": ".claude/hooks/validate-dispatch.sh" }]
},
{
  "matcher": "Skill",
  "hooks": [{ "type": "command", "command": ".claude/hooks/validate-skill.sh" }]
}
```
```

- [ ] **Step 5: Test the bootstrap step manually**

```bash
grep -A 50 "Step 3" commands/bootstrap.md | grep "validate-dispatch\|validate-skill"
```
Expected: both hook names appear in the Step 3 block.

- [ ] **Step 6: Commit**

```bash
git add commands/bootstrap.md
git commit -m "fix: bootstrap installs validate-dispatch and validate-skill hooks in user projects"
```

---

## Task 2: Add reflect once-only guard to template's validate-dispatch.sh

The template repo's own `validate-dispatch.sh` (used in template dev sessions) doesn't have the reflect guard yet. Add it.

**Files:**
- Modify: `.claude/hooks/validate-dispatch.sh`

- [ ] **Step 1: Read current validate-dispatch.sh**

```bash
cat .claude/hooks/validate-dispatch.sh
```

- [ ] **Step 2: Add reflect once-only guard**

Before the final `exit 0` in `.claude/hooks/validate-dispatch.sh`, add:

```bash
# Block reflect re-dispatch if report already exists
REFLECT_REPORT="${CLAUDE_PROJECT_DIR}/docs/reports/reflect-report.md"
if [ "$SUBAGENT_TYPE" = "mas:reflect-agent:reflect-agent" ] && [ -f "$REFLECT_REPORT" ]; then
  echo "BLOCKED: Reflect agent already ran (docs/reports/reflect-report.md exists)."
  echo "Dispatch-exactly-once constraint: reflect runs exactly once per dev-loop session."
  echo "To re-run reflect, delete docs/reports/reflect-report.md first."
  exit 2
fi
```

- [ ] **Step 3: Test the guard**

```bash
# Simulate reflect dispatch with no existing report (should pass)
echo '{"subagent_type": "mas:reflect-agent:reflect-agent"}' | CLAUDE_TOOL_NAME=Agent .claude/hooks/validate-dispatch.sh
echo "Exit code: $?"
```
Expected: exit 0 (no output, not blocked).

```bash
# Simulate reflect dispatch with existing report (should block)
mkdir -p docs/reports && touch docs/reports/reflect-report.md
echo '{"subagent_type": "mas:reflect-agent:reflect-agent"}' | CLAUDE_TOOL_NAME=Agent CLAUDE_PROJECT_DIR=$(pwd) .claude/hooks/validate-dispatch.sh
echo "Exit code: $?"
rm docs/reports/reflect-report.md
```
Expected: exit 2 with "BLOCKED: Reflect agent already ran" message.

- [ ] **Step 4: Commit**

```bash
git add .claude/hooks/validate-dispatch.sh
git commit -m "fix: block reflect re-dispatch when reflect-report.md already exists"
```

---

## Task 3: Add validate-skill.sh hook to template repo

**Files:**
- Create: `.claude/hooks/validate-skill.sh`
- Modify: `.claude/settings.json` (add PreToolUse for Skill tool)

- [ ] **Step 1: Create validate-skill.sh**

Create `.claude/hooks/validate-skill.sh`:

```bash
#!/bin/bash
# PreToolUse hook: Validate Skill tool invocation naming
# Blocks bare superpowers skill names that should use 'superpowers:' prefix
#
# Pattern: Skill(skill: "writing-plans") → BLOCKED
# Correct: Skill(skill: "superpowers:writing-plans") → allowed

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

- [ ] **Step 2: Make executable**

```bash
chmod +x .claude/hooks/validate-skill.sh
```

- [ ] **Step 3: Add Skill PreToolUse hook to settings.json**

In `.claude/settings.json`, add to the `hooks.PreToolUse` array (after the existing Agent matcher):

```json
{
  "matcher": "Skill",
  "hooks": [
    {
      "type": "command",
      "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/validate-skill.sh"
    }
  ]
}
```

- [ ] **Step 4: Test validate-skill.sh**

```bash
# Test bare superpowers skill (should block)
echo '{"skill": "writing-plans"}' | CLAUDE_TOOL_NAME=Skill .claude/hooks/validate-skill.sh
echo "Exit code: $?"
```
Expected: exit 2 with "BLOCKED: Bare superpowers skill name 'writing-plans' detected."

```bash
# Test prefixed skill (should pass)
echo '{"skill": "superpowers:writing-plans"}' | CLAUDE_TOOL_NAME=Skill .claude/hooks/validate-skill.sh
echo "Exit code: $?"
```
Expected: exit 0 (no output).

```bash
# Test bare MAS skill (should block)
echo '{"skill": "verification"}' | CLAUDE_TOOL_NAME=Skill .claude/hooks/validate-skill.sh
echo "Exit code: $?"
```
Expected: exit 2 with "BLOCKED: Bare MAS skill name 'verification' detected."

```bash
# Test non-MAS skill (should pass)
echo '{"skill": "python-patterns"}' | CLAUDE_TOOL_NAME=Skill .claude/hooks/validate-skill.sh
echo "Exit code: $?"
```
Expected: exit 0.

- [ ] **Step 5: Commit**

```bash
git add .claude/hooks/validate-skill.sh .claude/settings.json
git commit -m "feat: add validate-skill hook to enforce superpowers:/mas: prefix on Skill invocations"
```

---

## Task 4: Upgrade validate-pipeline.sh from warn to block when reflect is missing

Currently `validate-pipeline.sh` always exits 0 (informational). This means the reflect-skipping behavior has no consequence. Upgrade: if task specs AND results AND reviews all exist but reflect-report.md is missing, exit 2 (block session end).

**Files:**
- Modify: `hooks/validate-pipeline.sh`

- [ ] **Step 1: Read current exit logic in validate-pipeline.sh**

```bash
grep -n "exit" hooks/validate-pipeline.sh
```
Confirm the final line is `exit 0`.

- [ ] **Step 2: Change the blocking condition**

In `hooks/validate-pipeline.sh`, replace the final `# Always exit 0 — informational only` block with:

```bash
# Block session end only when a full pipeline ran but reflect was skipped
# Condition: task specs exist + results exist + reviews exist + NO reflect report
if [ -n "$WARNINGS" ] && [ "$RESULTS" != "0" ] && [ "$REVIEWS" != "0" ] && [ "$REFLECT" = "0" ]; then
  cat <<EOF
{"systemMessage": "Pipeline Validation BLOCKED:\n  Task specs: ${TASK_SPECS}\n  Engineer results: ${RESULTS}\n  Review reports: ${REVIEWS}\n  Reflect report: MISSING ← REQUIRED\n\n  A full pipeline ran (results + reviews present) but the reflect agent was never dispatched.\n  Run: Agent(subagent_type: 'mas:reflect-agent:reflect-agent', ...)\n  Then save the verdict to docs/reports/reflect-report.md before ending this session."}
EOF
  exit 2
fi

# Warn only (exit 0) for partial pipeline issues
if [ -n "$WARNINGS" ]; then
  cat <<EOF
{"systemMessage": "Pipeline Validation:\n  Task specs: ${TASK_SPECS}\n  Engineer results: ${RESULTS}\n  Review reports: ${REVIEWS}\n  Self-reviews: ${SELF_REVIEWS}\n  Reflect report: ${REFLECT}\n${WARNINGS}\n\n  If task specs exist but artifacts don't, the pipeline was likely bypassed."}
EOF
fi

exit 0
```

- [ ] **Step 3: Test — full pipeline with no reflect should block**

```bash
mkdir -p docs/tasks docs/results docs/reports
touch docs/tasks/TASK-001.md
touch docs/results/TASK-001-result.md
touch docs/reports/TASK-001-review.md
# No reflect-report.md

hooks/validate-pipeline.sh
echo "Exit code: $?"
```
Expected: exit 2 with blocking message about missing reflect.

- [ ] **Step 4: Test — partial pipeline (results but no reviews) should warn only**

```bash
rm docs/reports/TASK-001-review.md
hooks/validate-pipeline.sh
echo "Exit code: $?"
rm -rf docs/tasks docs/results docs/reports
```
Expected: exit 0 with warning (not blocking).

- [ ] **Step 5: Test — no task specs should skip entirely**

```bash
hooks/validate-pipeline.sh
echo "Exit code: $?"
```
Expected: exit 0 with no output (not a dev-loop session).

- [ ] **Step 6: Commit**

```bash
git add hooks/validate-pipeline.sh
git commit -m "feat: validate-pipeline blocks session end when full pipeline ran but reflect is missing"
```

---

## Task 5: Remove orchestrator from plugin, update CHANGELOG, bump version, release

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `.claude-plugin/plugin.json` (bump version)
- Modify: `.claude-plugin/marketplace.json` (bump version)
- Rebuild: `claude-mas-template.plugin` (exclude orchestrator)

- [ ] **Step 1: Update CHANGELOG.md — add v2.7.0 entry**

In `CHANGELOG.md`, add after the `## [2.6.0]` heading:

```markdown
## [2.7.0] — 2026-04-06

### Added

- **`validate-skill.sh` hook** — PreToolUse hook that blocks bare superpowers/MAS skill names. Enforces `superpowers:writing-plans` over `writing-plans`, etc.
- **Reflect once-only guard** in `validate-dispatch.sh` — Blocks re-dispatch of `mas:reflect-agent:reflect-agent` when `docs/reports/reflect-report.md` already exists.

### Changed

- **`validate-pipeline.sh` upgraded to blocking** — When a full pipeline ran (results + reviews exist) but reflect-report.md is missing, session end is now blocked (exit 2) instead of warned (exit 0).
- **`commands/bootstrap.md`** — Now installs `validate-dispatch.sh` and `validate-skill.sh` in user projects, fixing naming drift in externally bootstrapped repos.

### Removed

- **`agents/orchestrator/`** removed from plugin distribution — Was deprecated in v2.0, now physically absent. Still exists in the template repo for reference.
```

- [ ] **Step 2: Bump plugin version to 2.7.0**

In `.claude-plugin/plugin.json`, change `"version": "2.6.0"` to `"version": "2.7.0"`.
In `.claude-plugin/marketplace.json`, change `"version": "2.6.0"` to `"version": "2.7.0"`.

- [ ] **Step 3: Rebuild plugin without orchestrator**

```bash
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

- [ ] **Step 4: Verify plugin contents**

```bash
unzip -p claude-mas-template.plugin .claude-plugin/plugin.json | grep version
unzip -l claude-mas-template.plugin | grep orchestrator
```
Expected: version shows `2.7.0`, orchestrator line shows nothing.

- [ ] **Step 5: Commit, tag, push, release**

```bash
git add CHANGELOG.md .claude-plugin/plugin.json .claude-plugin/marketplace.json claude-mas-template.plugin
git commit -m "chore: bump version to v2.7.0"
git tag v2.7.0
git push origin main --tags
gh release create v2.7.0 \
  --title "v2.7.0 — Structural enforcement of naming conventions" \
  --notes "## What's New

Four structural fixes from the 4-day MAS usage audit.

### Naming drift fixed (root cause)
- \`validate-dispatch.sh\` + \`validate-skill.sh\` now installed by bootstrap in user projects
- All user projects get naming enforcement hooks on first \`/mas:bootstrap\`

### Reflect over-dispatch fixed
- \`validate-dispatch.sh\` now blocks reflect re-dispatch when \`docs/reports/reflect-report.md\` exists

### Reflect skipping fixed
- \`validate-pipeline.sh\` now blocks session end (exit 2) when full pipeline ran but reflect is missing

### Orchestrator removed from plugin
- \`agents/orchestrator/\` excluded from v2.7.0 plugin — deprecated since v2.0, now physically absent"
```
