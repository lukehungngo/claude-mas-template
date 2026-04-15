# Bootstrap Hook Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 6 bugs in `commands/bootstrap.md` Step 3 where hook scripts are outdated stubs and settings.json is missing 4 of 6 hooks.

**Architecture:** Replace the inline hook stubs in bootstrap.md with the full production versions from `.claude/hooks/`. Update settings.json template to wire all 6 hooks. Fix skill list bugs. All changes are in one file: `commands/bootstrap.md`.

**Tech Stack:** Bash (hook scripts), JSON (settings.json), Markdown (bootstrap command doc)

---

### File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `commands/bootstrap.md` | Modify (lines 251-337) | Step 3 hook scripts + settings.json template |

**do_not_touch:** `agents/`, `skills/`, `hooks/`, `.claude/hooks/`, `templates/`, `CHANGELOG.md` (changelog updated separately at release), `README.md`

---

### Task 1: Replace validate-dispatch.sh stub with full version

**Files:**
- Modify: `commands/bootstrap.md:263-290`
- Reference: `.claude/hooks/validate-dispatch.sh` (source of truth)

**Context:** The bootstrap template writes a simplified validate-dispatch.sh missing: debug logging, haiku model blocking for reviewer, better error messages. The actual running hook at `.claude/hooks/validate-dispatch.sh` has all of these.

- [ ] **Step 1:** In `commands/bootstrap.md`, replace the `validate-dispatch.sh` script block (lines 263-290) with the full version from `.claude/hooks/validate-dispatch.sh`. The full version includes:
  - Debug logging function (`_debug()` writing to `~/.claude/hook-debug.log`)
  - Model extraction for haiku blocking
  - Haiku reviewer blocking with depth-aware exception (quick depth allowed)
  - Quick-reference error messages with BAD/GOOD examples
  - `_debug "ALLOWED"` at exit

The exact content to use is the full `.claude/hooks/validate-dispatch.sh` (92 lines). Copy it verbatim into the bootstrap markdown code block.

- [ ] **Step 2:** Verify the replacement by checking line count — the new block should be ~92 lines (was ~28 lines).

---

### Task 2: Replace validate-skill.sh stub with full version + fix skill lists

**Files:**
- Modify: `commands/bootstrap.md:292-316`
- Reference: `.claude/hooks/validate-skill.sh` (source of truth, but with fixes)

**Context:** The bootstrap template is missing: allowlist check, better error messages. Also, the MAS_SKILLS list has bugs: `test-driven-development` doesn't exist as a MAS skill, and `finishing-branch`/`subagent-driven-development` are duplicated in both SUPERPOWERS and MAS lists. The actual `.claude/hooks/validate-skill.sh` is also missing `obsidian` from MAS_SKILLS.

- [ ] **Step 1:** In `commands/bootstrap.md`, replace the `validate-skill.sh` script block (lines 292-316) with the full version from `.claude/hooks/validate-skill.sh` BUT with these fixes applied:

  **Fix A — Remove duplicates from MAS_SKILLS:** Remove `finishing-branch`, `subagent-driven-development`, and `test-driven-development` from MAS_SKILLS. These are already caught by SUPERPOWERS_SKILLS (which is checked first). `test-driven-development` doesn't even exist as a MAS skill. The corrected MAS_SKILLS:
  ```
  MAS_SKILLS="dev-loop bug-fix reflect release bootstrap ask-questions verification reliability-review se-principles differential-review obsidian"
  ```

  **Fix B — Add `obsidian`:** Already included in Fix A above. The actual `.claude/hooks/validate-skill.sh` is missing it.

  **Fix C — Keep allowlist check:** The full version already has it (lines 21-25).

- [ ] **Step 2:** Also update the actual `.claude/hooks/validate-skill.sh` with the same MAS_SKILLS fix (remove duplicates, add obsidian). This keeps the repo's own hook in sync.

---

### Task 3: Wire all 6 hooks in settings.json template

**Files:**
- Modify: `commands/bootstrap.md:325-337`

**Context:** Bootstrap only wires 2 of 6 hooks. The actual `.claude/settings.json` has all 6. But 2 hooks (`suggest-compact.sh`, `validate-pipeline.sh`) live in the plugin's `hooks/` directory, not `.claude/hooks/`. Bootstrap needs to either copy them inline or reference the plugin cache path.

**Decision:** Copy `suggest-compact.sh` and `validate-pipeline.sh` inline into bootstrap Step 3 (same pattern as validate-dispatch.sh and validate-skill.sh). This ensures bootstrapped projects are self-contained and don't depend on plugin cache paths.

- [ ] **Step 1:** Add `suggest-compact.sh` script block after the validate-skill.sh block. Content: copy from `hooks/suggest-compact.sh` (48 lines).

- [ ] **Step 2:** Add `validate-pipeline.sh` script block after suggest-compact.sh. Content: copy from `hooks/validate-pipeline.sh` (80 lines).

- [ ] **Step 3:** Update the `lint.sh` script block (lines 251-255) to use the full template from `hooks/lint.sh` (20 lines) instead of the bare one-liner.

- [ ] **Step 4:** Update the `pre-stop-gate.sh` script block (lines 257-261) to use the full template from `hooks/pre-stop-gate.sh` (22 lines) instead of the bare one-liner.

- [ ] **Step 5:** Replace the settings.json template (lines 326-335) with the full version that wires all 6 hooks:

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

- [ ] **Step 6:** Update the "What Bootstrap Does" section (line 3) from "Creates hooks (.claude/hooks/lint.sh, .claude/hooks/pre-stop-gate.sh)" to "Creates hooks (6 hooks: lint, pre-stop-gate, validate-dispatch, validate-skill, suggest-compact, validate-pipeline)"

---

### Task 4: Version bump + CHANGELOG

**Files:**
- Modify: `.claude-plugin/plugin.json` (version field)
- Modify: `.claude-plugin/marketplace.json` (version field)
- Modify: `CHANGELOG.md` (add entry)

- [ ] **Step 1:** Bump version from `2.12.1` to `2.12.2` in both plugin.json and marketplace.json.

- [ ] **Step 2:** Add CHANGELOG entry for v2.12.2 documenting all fixes:

```markdown
## [2.12.2] — 2026-04-15

### Fixed
- **bootstrap: validate-dispatch.sh stub missing features** — Replaced 28-line stub with full 92-line production hook. Adds debug logging, haiku model blocking for reviewer, and quick-reference error messages.
- **bootstrap: validate-skill.sh stub missing allowlist** — Replaced stub with full hook including `allowed-bare-skills.txt` check. Fixed MAS_SKILLS list: removed `test-driven-development` (not a MAS skill), removed duplicates (`finishing-branch`, `subagent-driven-development`) already caught by SUPERPOWERS_SKILLS, added `obsidian`.
- **bootstrap: settings.json missing 4 of 6 hooks** — Added PostToolUse (lint.sh on Edit|Write), Stop (pre-stop-gate.sh + validate-pipeline.sh), and PreToolUse (suggest-compact.sh on Edit|Write|Bash). Bootstrapped projects now get all 6 hooks.
- **bootstrap: lint.sh and pre-stop-gate.sh stubs** — Replaced bare one-liner stubs with full templates from plugin hooks directory.
- **bootstrap: suggest-compact.sh and validate-pipeline.sh not installed** — Now written inline by bootstrap and wired into settings.json.
```

---

### Verification

After all tasks:
```bash
# Check bootstrap.md has all 6 hook scripts
grep -c '#!/bin/bash' commands/bootstrap.md
# Expected: 6 (lint.sh, pre-stop-gate.sh, validate-dispatch.sh, validate-skill.sh, suggest-compact.sh, validate-pipeline.sh)

# Check settings.json template has all hook types
grep -c 'PreToolUse\|PostToolUse\|Stop' commands/bootstrap.md
# Expected: >=3 (one for each hook type)

# Check MAS_SKILLS doesn't have test-driven-development
grep 'test-driven-development' commands/bootstrap.md
# Expected: only in SUPERPOWERS_SKILLS, NOT in MAS_SKILLS

# Check obsidian is in MAS_SKILLS
grep 'obsidian' commands/bootstrap.md
# Expected: appears in MAS_SKILLS line
```
