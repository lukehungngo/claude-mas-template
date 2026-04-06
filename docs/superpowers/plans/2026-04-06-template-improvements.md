# MAS Template Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the 7 issues identified in the cross-template audit: naming drift enforcement, high bug-fix rate, skill inlining for subagents, reflect agent over-dispatch, ECC agent routing, rate limit handling, and superpowers entry-point surfacing.

**Architecture:** Structural enforcement via PreToolUse hooks, inline content injection into agent prompts, single-source canonical tables, and explicit dispatch-once constraints. Follows the meta-lesson: prose rules fail, structural constraints work.

**Tech Stack:** Markdown files, shell scripts (hooks), JSON config. No production code changes.

---

## Context

Cross-template audit of 22 claude-devtools sessions (460+ agent dispatches) found:

1. **Naming drift at 32-56%** — bare names (`engineer`) used alongside namespaced (`mas:engineer:engineer`). BAD/GOOD tables added but not yet battle-tested.
2. **Bug-fix rate 25-30%** — 1 in 4 engineer outputs needs a bug-fix cycle. Root causes unknown.
3. **Skill invocation inside subagents fails** — `Skill(skill: "superpowers:test-driven-development")` in engineer prompt is never actually called.
4. **Reflect agent dispatched 2-14 times per session** — should be exactly once at Phase 2E.
5. **ECC agents never used** — specialized reviewers (`typescript-reviewer`, `build-error-resolver`) available but not in routing table.
6. **Rate limits hit 19 times in largest session** — no backoff guidance, concurrent limit exceeded.
7. **Superpowers skills barely used** — `brainstorming`, `verification-before-completion` never invoked.

### File Map

| File | Responsibility | Tasks |
|------|---------------|-------|
| `.claude/settings.json` | Hook config, permissions | Task 1 |
| `.claude/hooks/validate-dispatch.sh` | NEW: PreToolUse hook for naming | Task 1 |
| `agents/engineer/CLAUDE.md` | Engineer agent instructions | Task 2, 3 |
| `agents/bug-fixer/CLAUDE.md` | Bug-fixer agent instructions | Task 3 |
| `commands/dev-loop.md` | Main pipeline orchestration | Task 4, 5, 6, 7 |
| `commands/bug-fix.md` | Bug-fix pipeline | Task 5 |
| `templates/dispatch-templates.md` | Agent dispatch templates | Task 2, 5 |
| `rules/agent-workflow.md` | Battle-test lessons | Task 8 |

---

### Task 1: Add PreToolUse hook to validate agent dispatch naming

**Files:**
- Create: `.claude/hooks/validate-dispatch.sh`
- Modify: `.claude/settings.json:31-41` (hooks.PostToolUse section — add PreToolUse)

The BAD/GOOD tables are a medium-effectiveness fix (models copy patterns). A PreToolUse hook is structural — it physically blocks wrong names before dispatch. This addresses the 32-56% naming drift.

- [ ] **Step 1: Read the current settings.json hooks section**

Read `.claude/settings.json` to confirm exact content (already read above, lines 31-53).

- [ ] **Step 2: Create the validation hook script**

Create `.claude/hooks/validate-dispatch.sh`:

```bash
#!/bin/bash
# PreToolUse hook: validate Agent dispatch naming
# Blocks bare agent names (e.g., "engineer" instead of "mas:engineer:engineer")
# and wrong skill prefixes (e.g., "mas:verification" instead of "verification")

# Read tool input from stdin
INPUT=$(cat)

# Extract tool name from environment or input
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"

# Only check Agent tool calls
if [ "$TOOL_NAME" != "Agent" ]; then
  exit 0
fi

# Extract subagent_type value
SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"subagent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"subagent_type"[[:space:]]*:[[:space:]]*"//' | sed 's/"//')

if [ -z "$SUBAGENT_TYPE" ]; then
  exit 0
fi

# Known MAS agent slugs that MUST use mas: prefix
BARE_NAMES="engineer reviewer bug-fixer researcher differential-reviewer ui-ux-designer reflect-agent orchestrator"

for name in $BARE_NAMES; do
  if [ "$SUBAGENT_TYPE" = "$name" ]; then
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
  echo "BLOCKED: mas:orchestrator:orchestrator is DEPRECATED since v2.0."
  echo "The dev-loop command IS the orchestrator. Do not dispatch this agent."
  exit 2
fi

exit 0
```

- [ ] **Step 3: Make the hook executable**

Run: `chmod +x .claude/hooks/validate-dispatch.sh`

- [ ] **Step 4: Add PreToolUse hook to settings.json**

In `.claude/settings.json`, add a `PreToolUse` entry to the `hooks` object. The current hooks section (lines 31-53) has `PostToolUse` and `Stop`. Add `PreToolUse` before `PostToolUse`:

Replace the hooks section in `.claude/settings.json`:

```json
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Agent",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/validate-dispatch.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/lint.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/pre-stop-gate.sh"
          }
        ]
      }
    ]
  },
```

- [ ] **Step 5: Test the hook manually**

Run: `echo '{"subagent_type": "engineer"}' | CLAUDE_TOOL_NAME=Agent bash .claude/hooks/validate-dispatch.sh; echo "Exit: $?"`
Expected: Output contains "BLOCKED: Bare agent name 'engineer' detected." and exit code 2.

Run: `echo '{"subagent_type": "mas:engineer:engineer"}' | CLAUDE_TOOL_NAME=Agent bash .claude/hooks/validate-dispatch.sh; echo "Exit: $?"`
Expected: No output, exit code 0.

Run: `echo '{"subagent_type": "Explore"}' | CLAUDE_TOOL_NAME=Agent bash .claude/hooks/validate-dispatch.sh; echo "Exit: $?"`
Expected: No output, exit code 0 (Explore is not a MAS agent).

- [ ] **Step 6: Commit**

```bash
git add .claude/hooks/validate-dispatch.sh .claude/settings.json
git commit -m "feat: add PreToolUse hook to block bare agent names in dispatch"
```

---

### Task 2: Add engineer self-review enforcement and root-cause tracking to reduce bug-fix rate

**Files:**
- Modify: `agents/engineer/CLAUDE.md:99-106` (Phase 4 — Pre-completion)
- Modify: `agents/bug-fixer/CLAUDE.md:72-97` (output format)
- Modify: `templates/dispatch-templates.md:79-104` (engineer dispatch template)

The 25-30% bug-fix rate means engineers ship code that fails review. Two fixes: (a) strengthen the engineer's pre-completion gate to catch common reviewer findings, (b) add root-cause tracking to bug-fixer output so we can identify patterns.

- [ ] **Step 1: Read the engineer's Phase 4 pre-completion section**

Read `agents/engineer/CLAUDE.md` lines 99-106 (already read above).

- [ ] **Step 2: Add mandatory test execution to engineer's Phase 4**

In `agents/engineer/CLAUDE.md`, replace the Phase 4 section (lines 99-107) with an expanded version that requires running tests and checking for common P0/P1 patterns:

Replace the current Phase 4 content:

```markdown
### Phase 4 — Pre-completion

Before declaring done, run ALL of these and fix any failures:

```bash
# 1. Lint — must be clean
{{lint-command}}

# 2. Type check — must be clean
{{typecheck-command}}

# 3. Tests — ALL must pass (not just new tests)
{{test-command}}

# 4. Diff review — check for debug artifacts
git diff --cached --name-only  # what you're about to commit
git diff  # uncommitted changes
```

**Mandatory diff checks (common P0/P1 causes):**
- [ ] No `console.log`, `print()`, `debugger`, or `TODO` in diff
- [ ] No commented-out code blocks
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] No files modified outside `relevant_files` from task spec
- [ ] Every new public function has a test
- [ ] Every error path has explicit handling (no silent swallows)
- [ ] No N+1 queries or unbounded loops in new code

**If any check fails, fix it now.** Do not proceed to Phase 5 with known issues — this is the #1 cause of bug-fix cycles (25-30% of engineer outputs need bug-fixing).
```

- [ ] **Step 3: Add root-cause field to bug-fixer output format**

In `agents/bug-fixer/CLAUDE.md`, replace the output format section (lines 79-97) with:

```markdown
## Output Format

```markdown
# Bug Fix Result: TASK-{id}

## Root Cause Category
<!-- Pick exactly ONE. This data is used to improve engineer prompts. -->
- [ ] **Spec gap** — task spec was ambiguous or incomplete
- [ ] **Missing test** — engineer did not test this path
- [ ] **Logic error** — code was wrong despite having tests
- [ ] **Integration issue** — works in isolation, fails when combined
- [ ] **Type/lint error** — caught by tooling the engineer did not run
- [ ] **Edge case** — boundary condition not considered

## Bugs Fixed
### Bug 1: {description from reviewer}
- **File:** {file:line}
- **Root cause:** {one sentence explaining WHY this happened, not just what was wrong}
- **Test:** {test file:test name}
- **Fix:** {one-line description of change}

### Bug 2: ...

## Build Status
- Lint: PASS
- Typecheck: PASS
- Tests: PASS ({X} total, {Y} new)

## Files Modified
- {list of files changed}
```
```

- [ ] **Step 4: Add pre-completion reminder to engineer dispatch template**

In `templates/dispatch-templates.md`, in the Engineer Dispatch section (template #3, lines 79-104), add a reminder after the Skills section. Find the line `## Working Directory` in the engineer template and insert before it:

```markdown

  ## Pre-completion Gate (MANDATORY)
  Before writing your result file, you MUST:
  1. Run lint, typecheck, and ALL tests (not just new ones)
  2. Review your own diff for debug artifacts, TODOs, and commented-out code
  3. Write self-review to docs/results/TASK-{id}-self-review.md
  Skipping this gate is the #1 cause of review failures.
```

- [ ] **Step 5: Verify edits**

Run: `grep -n "Pre-completion Gate" templates/dispatch-templates.md`
Expected: One match in the engineer dispatch section.

Run: `grep -n "Root Cause Category" agents/bug-fixer/CLAUDE.md`
Expected: One match in the output format section.

Run: `grep -n "common P0/P1 causes" agents/engineer/CLAUDE.md`
Expected: One match in Phase 4.

- [ ] **Step 6: Commit**

```bash
git add agents/engineer/CLAUDE.md agents/bug-fixer/CLAUDE.md templates/dispatch-templates.md
git commit -m "feat: strengthen engineer pre-completion gate and add bug-fix root-cause tracking"
```

---

### Task 3: Inline critical skill content into agent prompts

**Files:**
- Modify: `agents/engineer/CLAUDE.md:82-98` (Phase 3 — TDD reference)
- Modify: `agents/bug-fixer/CLAUDE.md:54-66` (Process — TDD/debug references)

Audit showed 0 invocations of `superpowers:test-driven-development` and `superpowers:systematic-debugging` from within subagents, despite being referenced in prompts. Subagents either lack Skill tool access or ignore the instruction. Fix: inline the critical TDD workflow directly into the agent CLAUDE.md.

- [ ] **Step 1: Read the TDD skill content**

Run: `cat ~/.claude/plugins/cache/claude-plugins-official/superpowers/*/skills/test-driven-development/SKILL.md 2>/dev/null | head -80`

This gives us the core TDD workflow to inline.

- [ ] **Step 2: Replace Phase 3 skill reference with inline TDD workflow in engineer**

In `agents/engineer/CLAUDE.md`, replace the Phase 3 section (lines 82-98) with inline content:

```markdown
### Phase 3 — Implementation (TDD)

Per logical unit, follow this cycle strictly:

**RED → GREEN → REFACTOR**

1. **RED:** Write a failing test that describes the desired behavior
   - Test MUST fail when you run it — if it passes, your test is wrong
   - Test should fail for the RIGHT reason (missing function, wrong output — not syntax error)
   - Run: `{{test-command}}` — confirm FAIL

2. **GREEN:** Write the MINIMUM code to make the test pass
   - Do not write more code than the test requires
   - Do not add error handling the test doesn't exercise
   - Do not add features the test doesn't verify
   - Run: `{{test-command}}` — confirm PASS

3. **REFACTOR:** Clean up while tests stay green
   - Remove duplication
   - Improve naming
   - Extract if needed (but only if tests justify it)
   - Run: `{{test-command}}` — confirm still PASS

4. **Repeat** for the next logical unit

**Iron Law:** If you wrote production code before writing its test, delete the code. Write the test first. Then write the code.

**Frontend tasks (if has_ui: true):** When implementing UI components, invoke the frontend design skill:
```
Skill(skill: "frontend-design")
```
This ensures distinctive, production-grade frontend. Follow the design spec from the UI/UX Designer.
```

- [ ] **Step 3: Replace skill references with inline content in bug-fixer**

In `agents/bug-fixer/CLAUDE.md`, replace the Process section steps 2-3 (lines 55-63) with inline content:

```markdown
2. **Reproduce** — Write a minimal failing test that exposes the bug:
   - Write a test that FAILS because of the bug (not a syntax error — the actual wrong behavior)
   - Run: `{{test-command}}` — confirm it FAILS for the right reason
   - If you CANNOT make a test fail for this bug, you do not understand it yet — do NOT proceed to step 3
   - The reproduction test is NON-NEGOTIABLE. No exceptions. No "the bug is obvious so I'll skip the test."
3. **Debug** — If the root cause is still unclear after writing the reproduction test:
   - **Binary search:** Add logging/assertions to narrow the failure to a single function
   - **Input tracing:** Trace the failing input through each transformation step
   - **Diff analysis:** What changed recently? `git log --oneline -10` + `git diff HEAD~1`
   - **Isolation:** Can you reproduce with a minimal input? Strip away everything non-essential
```

- [ ] **Step 4: Verify edits**

Run: `grep -n "RED → GREEN → REFACTOR" agents/engineer/CLAUDE.md`
Expected: One match in Phase 3.

Run: `grep -n "NON-NEGOTIABLE" agents/bug-fixer/CLAUDE.md`
Expected: One match in step 2.

- [ ] **Step 5: Commit**

```bash
git add agents/engineer/CLAUDE.md agents/bug-fixer/CLAUDE.md
git commit -m "feat: inline TDD and debugging workflows into agent prompts"
```

---

### Task 4: Add "dispatch exactly once" constraint to reflect agent

**Files:**
- Modify: `commands/dev-loop.md:247-281` (Phase 2E — Reflect section)

Audit showed reflect agent dispatched 2-14 times per session. It should run exactly once after all reviews complete. Add a structural counter and explicit constraint.

- [ ] **Step 1: Read the current Phase 2E section**

Read `commands/dev-loop.md` lines 247-281 (already read above).

- [ ] **Step 2: Add dispatch-once constraint to Phase 2E**

In `commands/dev-loop.md`, replace the Phase 2E header and first paragraph (lines 247-248) with:

```markdown
##### Phase 2E — Reflect (DISPATCH EXACTLY ONCE)

**This agent runs ONCE per dev-loop execution.** Not once per task, not once per batch — once total, after ALL reviews are complete. In audited sessions, this agent was dispatched 2-14 times. That is wrong.

Trigger condition: ALL of these must be true before dispatching:
1. Every task in `docs/tasks/` is in `done/` or `blocked/` (no pending/in-progress)
2. Every `docs/results/TASK-*-result.md` has a corresponding `docs/reports/TASK-*-review.md`
3. All review verdicts are APPROVED or APPROVED WITH CHANGES (no unresolved BLOCKED)
4. Cross-task review is complete (if CROSS_TASK_REVIEW is enabled)

If ANY condition is false, you are not ready for reflect. Go back to Phase 2D.
```

- [ ] **Step 3: Verify the edit**

Run: `grep -n "DISPATCH EXACTLY ONCE" commands/dev-loop.md`
Expected: One match at the Phase 2E header.

- [ ] **Step 4: Commit**

```bash
git add commands/dev-loop.md
git commit -m "fix: add dispatch-exactly-once constraint to reflect agent phase"
```

---

### Task 5: Add ECC agents to routing table as escalation paths

**Files:**
- Modify: `commands/dev-loop.md:190-211` (routing table section)
- Modify: `commands/bug-fix.md:112-123` (dispatch naming table)

ECC agents (`everything-claude-code:typescript-reviewer`, `everything-claude-code:build-error-resolver`, etc.) are available but never used. Add them as optional escalation paths when MAS agents encounter language-specific or build issues.

- [ ] **Step 1: Read the current routing table**

Read `commands/dev-loop.md` lines 190-211 (already read above).

- [ ] **Step 2: Add ECC escalation section after routing table**

In `commands/dev-loop.md`, after the deprecated agents note (line 211: `> - \`mas:orchestrator:orchestrator\` — Deprecated...`), insert:

```markdown

> **Optional ECC escalation agents** — use when MAS agents need language-specific help:
>
> | Situation | ECC Agent | When to Use |
> |-----------|-----------|-------------|
> | Build fails after engineer dispatch | `everything-claude-code:build-error-resolver` | Engineer result reports build failure, before dispatching bug-fixer |
> | TypeScript/JS review needed | `everything-claude-code:typescript-reviewer` | Reviewer flags TS-specific issues beyond its expertise |
> | Python review needed | `everything-claude-code:python-reviewer` | Reviewer flags Python-specific issues |
> | Go review needed | `everything-claude-code:go-reviewer` | Reviewer flags Go-specific issues |
> | Rust review needed | `everything-claude-code:rust-reviewer` | Reviewer flags Rust-specific issues |
> | Security concern found | `everything-claude-code:security-reviewer` | Reviewer flags auth, crypto, or injection patterns |
>
> **These are NOT replacements for MAS agents.** They are specialist consultants. The MAS reviewer still owns the verdict.
```

- [ ] **Step 3: Add ECC build-error-resolver to bug-fix naming table**

In `commands/bug-fix.md`, after the existing dispatch naming table (line 122: closing `>`), insert:

```markdown
>
> **Build failure shortcut:** If the bug is a build/type error (not a logic bug), dispatch the build resolver instead:
> | `everything-claude-code:build-error-resolver` | Fixes build errors with minimal diffs — faster than full bug-fixer for compile/type issues |
```

- [ ] **Step 4: Verify edits**

Run: `grep -n "ECC escalation" commands/dev-loop.md`
Expected: One match.

Run: `grep -n "build-error-resolver" commands/bug-fix.md`
Expected: One match.

- [ ] **Step 5: Commit**

```bash
git add commands/dev-loop.md commands/bug-fix.md
git commit -m "feat: add ECC agents as escalation paths in routing table"
```

---

### Task 6: Add rate limit handling and model routing guidance

**Files:**
- Modify: `commands/dev-loop.md:30-44` (Runtime Configuration section)

The largest session (168 agents) hit rate limits 19 times. Add explicit backoff guidance and model routing recommendations to reduce consumption.

- [ ] **Step 1: Read the current runtime configuration section**

Read `commands/dev-loop.md` lines 30-44 (already read above).

- [ ] **Step 2: Add rate limit and model routing guidance after the configuration table**

In `commands/dev-loop.md`, after line 44 (`**At no point should more than 5 agents of any type be running simultaneously.**...`), insert:

```markdown

### Rate Limit Handling

If you receive a rate limit error ("You've hit your limit"):
1. **STOP dispatching new agents immediately** — do not queue more work
2. **Note the reset time** from the error message
3. **Report to human:** "Rate limited. Reset at {time}. {N} tasks pending. Resume then?"
4. In `--auto` mode: wait for reset, then resume from the last incomplete batch

**Prevention:** Use `model: "haiku"` for Explore agents and simple codebase searches. Reserve Opus/Sonnet tokens for Engineer, Reviewer, and Researcher agents.

```
Agent(
  subagent_type: "Explore",
  model: "haiku",
  prompt: "..."
)
```

### Connection Errors

If you receive connection errors (ConnectionRefused, FailedToOpenSocket):
1. Wait 30 seconds and retry once
2. If retry fails, report to human: "API connection failed. Check network."
3. Do NOT continue dispatching agents during connection failures
```

- [ ] **Step 3: Verify the edit**

Run: `grep -n "Rate Limit Handling" commands/dev-loop.md`
Expected: One match.

Run: `grep -n "model.*haiku" commands/dev-loop.md`
Expected: One match in the Explore example.

- [ ] **Step 4: Commit**

```bash
git add commands/dev-loop.md
git commit -m "feat: add rate limit handling and model routing guidance to dev-loop"
```

---

### Task 7: Surface superpowers skills at pipeline entry points

**Files:**
- Modify: `commands/dev-loop.md:88-103` (Step 2 — Plan section)

Superpowers skills like `brainstorming` and `verification-before-completion` are available but never invoked in devtools sessions. Surface `brainstorming` before planning when the requirement is ambiguous.

- [ ] **Step 1: Read the current Step 2 section**

Read `commands/dev-loop.md` lines 88-103 (already read above).

- [ ] **Step 2: Add brainstorming trigger before planning**

In `commands/dev-loop.md`, after line 91 (`Skill(skill: "superpowers:writing-plans")`) and before line 93 (`This produces a structured...`), insert:

```markdown

**Pre-planning brainstorm (if requirement is ambiguous or open-ended):**

If the requirement could be solved multiple ways, or the scope is unclear, brainstorm first:

```
Skill(skill: "superpowers:brainstorming")
```

Skip this if the requirement is already specific and scoped (e.g., "fix the login button" or "add pagination to /api/users"). Use it when the requirement is broad (e.g., "improve the auth system" or "add analytics").
```

- [ ] **Step 3: Verify the edit**

Run: `grep -n "brainstorm" commands/dev-loop.md`
Expected: Matches for the new section.

- [ ] **Step 4: Commit**

```bash
git add commands/dev-loop.md
git commit -m "feat: surface brainstorming skill at pipeline entry for ambiguous requirements"
```

---

### Task 8: Update battle-test lessons with new findings

**Files:**
- Modify: `rules/agent-workflow.md:43-66` (battle test results table and summary)

Add lessons #22-24 from the audit findings (bug-fix rate, reflect over-dispatch, skill inlining) so future pipeline modifications are informed by these patterns.

- [ ] **Step 1: Read the current end of battle test table**

Read `rules/agent-workflow.md` lines 43-66 (already read above).

- [ ] **Step 2: Add lessons #22-24 to the battle test table**

In `rules/agent-workflow.md`, after the row for lesson #21 (line 45), insert three new rows:

```markdown
| 22 | Bug-fix rate 25-30% across sessions | Engineer skips pre-completion checks, ships code with common P0/P1 patterns | Expanded Phase 4 checklist + root-cause tracking in bug-fixer output | In progress |
| 23 | Reflect agent dispatched 2-14 times per session | No "dispatch once" constraint, model re-dispatches on every batch | "DISPATCH EXACTLY ONCE" header + trigger conditions checklist | In progress |
| 24 | Skill() calls inside subagent prompts never executed | Subagents ignore or lack access to Skill tool references in their prompts | Inline critical skill content (TDD, debugging) directly into agent CLAUDE.md | In progress |
```

- [ ] **Step 3: Add effectiveness rows to summary table**

In `rules/agent-workflow.md`, after the last row in the summary table (line 66: `BAD/GOOD naming table...`), insert:

```markdown
| PreToolUse hook for dispatch naming | Untested — structural enforcement, blocks bare names before dispatch reaches platform | Hook exits 2 on bare name, forces model to use `mas:` prefix |
| Engineer pre-completion expanded checklist | Untested — addresses 25-30% bug-fix rate by catching common P0/P1 patterns before review | Mandatory diff checks for debug artifacts, missing tests, N+1 queries |
| Inline TDD workflow in agent prompts | Untested — replaces unreliable Skill() references with concrete in-prompt instructions | RED→GREEN→REFACTOR cycle directly in engineer CLAUDE.md |
| Dispatch-exactly-once constraint | Untested — structural counter prevents reflect agent over-dispatch | Trigger conditions: all tasks done, all reviews complete, no blocked tasks |
```

- [ ] **Step 4: Verify edits**

Run: `grep -n "lesson.*2[234]\|Bug-fix rate\|Reflect agent dispatched\|Skill.*calls inside" rules/agent-workflow.md`
Expected: Matches for all three new lesson rows.

- [ ] **Step 5: Commit**

```bash
git add rules/agent-workflow.md
git commit -m "docs: add lessons #22-24 from cross-template audit findings"
```

---

## Self-Review

**Spec coverage check:**
- P0 naming drift (32-56%) → Task 1 (hook) + existing BAD/GOOD tables
- P0 bug-fix rate (25-30%) → Task 2 (engineer pre-completion + root-cause tracking)
- P1 skill inlining → Task 3 (inline TDD/debugging into agent prompts)
- P1 reflect over-dispatch → Task 4 (dispatch-exactly-once constraint)
- P2 ECC agents unused → Task 5 (routing table escalation paths)
- P2 rate limit handling → Task 6 (backoff guidance + model routing)
- P3 superpowers underutilized → Task 7 (brainstorming at entry points)
- Documentation → Task 8 (battle-test lessons)

**Placeholder scan:** No TBD, TODO, or "implement later" found. All steps have concrete content.

**Type consistency:** File paths, section references, and line numbers verified against current file content.
