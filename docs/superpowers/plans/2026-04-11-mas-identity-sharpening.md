# MAS Identity Sharpening — Engineer + Reviewer Improvements

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sharpen the MAS template around what makes it uniquely yours — earned from real usage, not agnostic tooling — by closing the gaps real session data exposed and doubling down on the structural enforcement patterns no other tool has.

**Architecture:** Five targeted improvements across engineer and reviewer agents, plus a hook and template change. No new agents. No new abstractions. Every change earned from the 37-review, 27-session audit.

**Tech Stack:** Bash (hooks), Markdown (agent prompts + templates)

---

## Strategic Framing — What Is Uniquely Yours

Before the tasks: this section articulates the MAS identity so every task reinforces it rather than drifts away from it.

### What you have that GSD / superpowers don't

1. **Audit-driven evolution** — `mas-audit.py` + `hook-debug.log` + session parsing. You measure actual agent behavior, find drift, write hooks that enforce correction, ship. Nobody else has this loop. GSD writes prose; you write enforcement code.

2. **Hook-level structural enforcement** — `validate-dispatch.sh`, `validate-skill.sh`, `validate-pipeline.sh`. When the model makes a bad decision (bare name, wrong model, skipped reflect), the shell blocks it. Prose guidelines get rationalized away. Shell exits don't.

3. **Business alignment baked into review** — Phase A of the reviewer checks intent, not just code. GSD separates this into a post-execution verifier. You bundle it because reviewers are the last gate before merge and SHOULD verify intent.

4. **Reflect as accountability** — The reflect agent checks "did we build what we said we'd build?" after the pipeline. This is the meta-check that prevents shipping technically correct code that solves the wrong problem.

5. **Between-batch gate** — 1:1 engineer:reviewer ratio enforced structurally. Came from data showing 52% reviewer rate. No other tool tracks this.

### What you're missing (from real data, not theory)

1. **Reviewer depth protocol** — The Haiku issue is not "block haiku." It's "the controller doesn't know what depth of review each task needs." Define depth (quick/standard/deep) with model floor per depth. Controller picks depth; depth determines minimum model.

2. **Engineer deviation taxonomy** — Right now: ambiguity = block. In practice, a senior engineer auto-fixes a missing null check, auto-adds a missing import, and stops for architecture changes. Encoding this as a 4-rule protocol reduces unnecessary blocking and aligns with how you actually work.

3. **Analysis paralysis guard** — Sessions where engineer reads 10+ files before writing a single line of code. These waste tokens and context. A counter forcing a decision after 5 consecutive reads without a write is a real signal from GSD worth adding.

4. **Machine-readable review frontmatter** — Current review reports are prose only. `mas-audit.py` has to guess at review quality. YAML frontmatter in `docs/reports/TASK-{id}-review.md` makes review quality measurable by the audit loop.

5. **Stub tracker before result** — The Phase 3 adversarial reviewer (#34 in audit) caught "routes never registered in server.ts." The engineer wrote the route file but didn't wire it. A stub scan before writing the result catches this class of error.

---

## File Map

| File | Change |
|------|--------|
| `agents/reviewer/CLAUDE.md` | Add depth mode protocol (quick/standard/deep) |
| `agents/engineer/CLAUDE.md` | Add deviation taxonomy + analysis paralysis guard + stub tracker |
| `templates/review-report.md` | Add YAML frontmatter block |
| `.claude/hooks/validate-dispatch.sh` | Add reviewer depth+model enforcement |
| `CHANGELOG.md` | v2.9.0 entry |
| `.claude-plugin/plugin.json` | Bump to v2.9.0 |
| `.claude-plugin/marketplace.json` | Bump to v2.9.0 |

---

## Task 1: Reviewer Depth Mode Protocol

**Files:**
- Modify: `agents/reviewer/CLAUDE.md`
- Modify: `.claude/hooks/validate-dispatch.sh`

The fix for the Haiku reviewer is not model pinning — it's a protocol that defines what depth of review is appropriate and what model floor each depth requires. The controller picks depth; the hook enforces the floor.

**Depth definitions:**
- `quick` — grep-level pattern scan, no full file reads. For trivial changes: rename, config tweak, doc update. Floor: any model.
- `standard` — per-file reads, full diff review, all Phase B steps. Default for all implementation tasks. Floor: sonnet.
- `deep` — cross-file call graph, type boundaries, full adversarial pass. For P0 fixes, cross-cutting changes, final branch review. Floor: sonnet (opus preferred).

- [ ] **Step 1: Add depth protocol to reviewer agent**

In `agents/reviewer/CLAUDE.md`, after the `---` following the frontmatter block, add a new section before `## Persona`:

```markdown
## Dispatch Contract

The agent dispatching this reviewer MUST specify review depth in the prompt:

- `depth: quick` — grep-only pattern scan. No full file reads. For renames, config tweaks, doc-only changes.
  - Model floor: any
- `depth: standard` — Full per-file reads, complete Phase B. Default for all implementation tasks.
  - Model floor: sonnet
- `depth: deep` — Cross-file analysis, call graph tracing, full adversarial pass. For P0 fixes, cross-cutting changes, final branch reviews.
  - Model floor: sonnet (opus preferred)

If depth is not specified, treat as `standard`.

**Quick depth skips:** Phase A (business alignment), reliability-review skill, property-based-testing skill.
**Quick depth runs:** build check, diff grep for obvious P0 patterns (hardcoded secrets, SQL concat, unhandled promise), verdict.
```

- [ ] **Step 2: Add depth enforcement to validate-dispatch.sh**

In `.claude/hooks/validate-dispatch.sh`, after the existing "Block reviewer on Haiku" block (or add it fresh after the orchestrator block), add:

```bash
# Block standard/deep reviewer on Haiku — those depths require judgment
if [ "$SUBAGENT_TYPE" = "mas:reviewer:reviewer" ] && echo "$MODEL" | grep -qi "haiku"; then
  # Extract depth from prompt field to allow quick+haiku
  PROMPT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('prompt',''))" 2>/dev/null || echo "")
  DEPTH=$(echo "$PROMPT" | grep -oi 'depth:[[:space:]]*[a-z]*' | head -1 | sed 's/depth:[[:space:]]*//')
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
```

- [ ] **Step 3: Verify hook parses depth correctly**

```bash
# Test: standard review on haiku should block
echo '{"subagent_type":"mas:reviewer:reviewer","model":"haiku","prompt":"Review Task 6 spec + quality review"}' | \
  TOOL_NAME=Agent CLAUDE_PROJECT_DIR=/tmp bash .claude/hooks/validate-dispatch.sh
# Expected: exit 2, BLOCKED message mentioning depth standard

# Test: quick review on haiku should pass
echo '{"subagent_type":"mas:reviewer:reviewer","model":"haiku","prompt":"depth: quick Review config rename"}' | \
  TOOL_NAME=Agent CLAUDE_PROJECT_DIR=/tmp bash .claude/hooks/validate-dispatch.sh
# Expected: exit 0

# Test: standard review on sonnet should pass
echo '{"subagent_type":"mas:reviewer:reviewer","model":"sonnet","prompt":"depth: standard Review Task 6"}' | \
  TOOL_NAME=Agent CLAUDE_PROJECT_DIR=/tmp bash .claude/hooks/validate-dispatch.sh
# Expected: exit 0
```

- [ ] **Step 4: Commit**

```bash
git add agents/reviewer/CLAUDE.md .claude/hooks/validate-dispatch.sh
git commit -m "feat: add reviewer depth protocol (quick/standard/deep) with model floor enforcement"
```

---

## Task 2: Engineer Deviation Taxonomy

**Files:**
- Modify: `agents/engineer/CLAUDE.md`

Right now the engineer's non-negotiables say "treat ambiguity as a blocker — never guess, always clarify." That's too conservative. A senior engineer auto-fixes obvious gaps and stops for things that actually need a decision. This task adds a 4-rule deviation taxonomy that mirrors how you actually work.

- [ ] **Step 1: Add deviation taxonomy to engineer non-negotiables**

In `agents/engineer/CLAUDE.md`, after the existing **Non-negotiables** block, add:

```markdown
**Deviation Taxonomy** — When you encounter something not in the spec, apply these rules in order:

| Priority | Situation | Action |
|----------|-----------|--------|
| Rule 1 | Broken behavior (test fails, runtime error, null crash) | Auto-fix. Document in result under "Deviations." |
| Rule 2 | Missing critical safety (missing null check, missing input validation, broken import) | Auto-fix. Document in result under "Deviations." |
| Rule 3 | Ambiguous requirement (unclear business logic, two valid interpretations) | Stop. Write question to `docs/tasks/TASK-{id}-clarification.md`. Do not guess. |
| Rule 4 | Architectural change (new dependency, changed interface contract, schema migration) | Stop immediately. Do not implement. Flag as blocker in result. |

Rule 1 and 2 deviations must be listed in the result file. Rule 3 and 4 deviations are blockers — write the clarification file and exit.
```

- [ ] **Step 2: Add analysis paralysis guard to Phase 1**

In `agents/engineer/CLAUDE.md`, at the end of Phase 1 (Planning), add:

```markdown
**Analysis Paralysis Guard:** Count your Read/Grep/Glob calls. If you have made 5 or more file reads without writing or editing any file, stop and make a decision:
- Either you have enough information → proceed to Phase 2
- Or you are blocked → write the clarification file and stop

Do not continue reading. Reading more files will not resolve ambiguity — only a decision or a question will.
```

- [ ] **Step 3: Verify changes look right**

```bash
grep -n "Deviation Taxonomy\|Analysis Paralysis" agents/engineer/CLAUDE.md
# Expected: both strings appear
```

- [ ] **Step 4: Commit**

```bash
git add agents/engineer/CLAUDE.md
git commit -m "feat: add deviation taxonomy and analysis paralysis guard to engineer agent"
```

---

## Task 3: Stub Tracker in Engineer Pre-Completion

**Files:**
- Modify: `agents/engineer/CLAUDE.md`

The Phase 3 adversarial reviewer in the eduquest session caught "routes never registered in server.ts." The engineer wrote the service and route file but never wired it to the server. A stub scan before writing the result catches this class before review.

- [ ] **Step 1: Add stub tracker to Phase 4 (Pre-completion)**

In `agents/engineer/CLAUDE.md`, in Phase 4 — Pre-completion, after the existing checklist, add:

```markdown
- [ ] **Stub scan:** Search your new files for unwired components before declaring done.

Run these checks (adapt paths to your stack):
```bash
# Unregistered routes (Fastify/Express pattern)
grep -r "router\.\|fastify\.\|app\." src/ --include="*.ts" | grep -v "server\|app\|index" | head -20

# Unregistered services (DI container pattern)
grep -rn "class.*Service\|class.*Repository" src/ --include="*.ts" | head -20
# Then verify each class appears in container/registry file

# TODO/FIXME/stub markers in new files
grep -rn "TODO\|FIXME\|STUB\|placeholder\|hardcoded" docs/results/ src/ --include="*.ts" --include="*.md" 2>/dev/null
```

If you find an unwired component, wire it before writing the result. Document it under "Deviations" if the wiring was not in the original spec.
```

- [ ] **Step 2: Verify the change**

```bash
grep -n "Stub scan" agents/engineer/CLAUDE.md
# Expected: appears in Phase 4
```

- [ ] **Step 3: Commit**

```bash
git add agents/engineer/CLAUDE.md
git commit -m "feat: add stub scanner to engineer pre-completion phase"
```

---

## Task 4: Machine-Readable Review Report Frontmatter

**Files:**
- Modify: `templates/review-report.md`

The audit loop (`mas-audit.py`) currently has to parse prose to assess review quality. YAML frontmatter in every review report makes it machine-readable — enabling the audit to measure block rate, P0 find rate, and thin-review detection automatically.

- [ ] **Step 1: Update review-report.md template**

Replace the entire content of `templates/review-report.md` with:

```markdown
---
task_id: TASK-{id}
title: "{title}"
verdict: APPROVED | APPROVED_WITH_CHANGES | BLOCKED
depth: quick | standard | deep
model: "{model used — fill from dispatch context}"
findings:
  p0: 0
  p1: 0
  p2: 0
  p3: 0
business_alignment: PASS | FAIL | SKIP
build_status: PASS | FAIL
---

## Review: TASK-{id} — {title}

### Business Alignment
<!-- Skip this section for depth: quick -->
- [PASS/FAIL] {requirement} — {evidence}

### Build Status
PASS / FAIL — {one-line summary, e.g., "All 142 tests pass, lint clean, typecheck clean"}

### P0 — Blockers
<!-- Confirmed correctness bugs, security vulns, data loss, crashes -->
<!-- Format: file:line — description -->

{Empty if none.}

### P1 — Must Fix
<!-- Wrong edge cases, missing critical tests, type unsafety -->

{Empty if none.}

### P2 — Should Fix
<!-- Design issues, naming, missing docstrings -->

### P3 — Optional
<!-- Style, minor cleanup -->

### Verdict
APPROVED / APPROVED WITH CHANGES / BLOCKED

### Summary
{2-3 sentences on overall code quality, key observations, and confidence level}
```

- [ ] **Step 2: Update reviewer agent to fill frontmatter**

In `agents/reviewer/CLAUDE.md`, in the Output Format section, update the instruction to say:

```markdown
## Output Format

Use the template at `templates/review-report.md`. Fill the YAML frontmatter fields:
- `verdict`: match your final verdict (use underscore form: `APPROVED_WITH_CHANGES`)
- `depth`: the depth you ran (quick/standard/deep)
- `model`: write the model name from your system context (e.g., `claude-sonnet-4-6`)
- `findings.p0/p1/p2/p3`: counts of issues at each severity
- `business_alignment`: PASS/FAIL/SKIP (SKIP for quick depth)
- `build_status`: PASS/FAIL
```

- [ ] **Step 3: Verify template has frontmatter**

```bash
head -15 templates/review-report.md
# Expected: starts with ---
# Expected: contains task_id, verdict, depth, model, findings fields
```

- [ ] **Step 4: Commit**

```bash
git add templates/review-report.md agents/reviewer/CLAUDE.md
git commit -m "feat: add machine-readable YAML frontmatter to review reports"
```

---

## Task 5: CHANGELOG + Version Bump to v2.9.0

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Add CHANGELOG entry**

In `CHANGELOG.md`, add before the existing `## [2.8.0]` entry:

```markdown
## [2.9.0] — 2026-04-11

### Identity Sharpening — Engineer + Reviewer

The MAS template's unique value is structural enforcement over prose guidance. This release closes the gaps real session data exposed (37 reviews, 27 sessions audited).

#### Reviewer
- **Depth protocol**: Three review depths (quick/standard/deep) with model floor per depth. Controller picks depth; hook enforces floor. Replaces the binary "block haiku" approach with a protocol that mirrors how senior engineers actually delegate review work.
- **Machine-readable frontmatter**: YAML header in every `docs/reports/TASK-*-review.md` — verdict, depth, model, finding counts. Enables `mas-audit.py` to measure review quality automatically.

#### Engineer  
- **Deviation taxonomy**: 4-rule protocol for auto-fix vs stop. Rule 1: auto-fix bugs. Rule 2: auto-fix missing safety. Rule 3: stop for ambiguous requirements. Rule 4: stop for architectural changes. Replaces "treat all ambiguity as a blocker."
- **Analysis paralysis guard**: 5+ reads without a write forces a decision. Eliminates token-burning read loops.
- **Stub tracker**: Pre-completion scan for unwired components (unregistered routes, unwired services). Catches the "wrote the file but didn't register it" class of error before review.

#### Hook
- `validate-dispatch.sh`: Reviewer depth enforcement — haiku blocked for standard/deep depth, allowed for quick depth.
```

- [ ] **Step 2: Bump plugin.json**

In `.claude-plugin/plugin.json`, change `"version": "2.8.0"` to `"version": "2.9.0"`.

- [ ] **Step 3: Bump marketplace.json**

In `.claude-plugin/marketplace.json`, change `"version": "2.8.0"` to `"version": "2.9.0"`.

- [ ] **Step 4: Rebuild plugin archive**

```bash
cd /Users/soh/working/ai/claude-mas-template

zip -r claude-mas-template.plugin \
  .claude-plugin/ \
  agents/engineer/ \
  agents/reviewer/ \
  agents/bug-fixer/ \
  agents/researcher/ \
  agents/differential-reviewer/ \
  agents/ui-ux-designer/ \
  agents/reflect-agent/ \
  commands/ \
  hooks/ \
  rules/ \
  skills/ \
  templates/ \
  .claude/hooks/ \
  .claude/scripts/ \
  .claude/settings.json \
  CHANGELOG.md \
  README.md

echo "Plugin size: $(du -sh claude-mas-template.plugin | cut -f1)"
```

Expected: Plugin rebuilds without error, size roughly similar to v2.8.0 (~72KB).

- [ ] **Step 5: Commit and tag**

```bash
git add CHANGELOG.md .claude-plugin/plugin.json .claude-plugin/marketplace.json claude-mas-template.plugin
git commit -m "chore: bump version to v2.9.0"
git tag v2.9.0
git push origin main --tags
```

- [ ] **Step 6: Create GitHub release**

```bash
gh release create v2.9.0 claude-mas-template.plugin \
  --title "v2.9.0 — Identity Sharpening: Reviewer Depth Protocol + Engineer Deviation Taxonomy" \
  --notes "$(cat <<'EOF'
## What's New

This release closes gaps identified from 37 real reviewer dispatches and 27 MAS sessions. Every change is earned from data, not theory.

### Reviewer
- **Depth protocol** (quick/standard/deep) with model floor enforcement via hook
- **Machine-readable frontmatter** in review reports — enables audit automation

### Engineer
- **Deviation taxonomy** — 4-rule auto-fix vs stop protocol
- **Analysis paralysis guard** — forces decision after 5 reads without a write
- **Stub tracker** — pre-completion scan for unwired components

### Why this matters
The MAS template's value is structural enforcement over prose. A reviewer running on Haiku for a standard review isn't a config problem — it's a missing protocol. These changes encode senior engineering judgment as rules the system enforces, not guidelines the model can rationalize away.
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- Reviewer depth protocol → Task 1 ✓
- Model floor enforcement via hook → Task 1 ✓  
- Engineer deviation taxonomy → Task 2 ✓
- Analysis paralysis guard → Task 2 ✓
- Stub tracker → Task 3 ✓
- Machine-readable review frontmatter → Task 4 ✓
- Version bump + release → Task 5 ✓

**What this plan does NOT address (intentionally deferred):**
- Language-specific reviewer checklists (GSD gap) — too prescriptive for a template that must work across stacks
- Nyquist auditor (auto-fill coverage gaps) — new agent, different scope
- Security auditor (ASVS-level) — new agent, different scope
- These are worth a separate v3.0 discussion but don't belong here
