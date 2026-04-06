# Fix MAS Naming Drift Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate the three naming inconsistencies found in the audit: mixed bare/namespaced agent dispatches, skill name prefix drift, and stale orchestrator references.

**Architecture:** Add structural guards (BAD/GOOD examples, quick-reference tables, lesson entries) to the files the LLM reads during orchestration. Per the meta-lesson in `rules/agent-workflow.md`, prose "MUST" rules fail — we need concrete examples and lookup tables the model can copy-paste from.

**Tech Stack:** Markdown files only — no code changes.

---

## Context

The audit of 12 MAS sessions found:

1. **Agent naming drift** — v2.0+ sessions dispatch `engineer` (bare) alongside `mas:engineer:engineer` (namespaced). The templates are correct, but the LLM simplifies names at runtime.
2. **Skill naming drift** — Three variants observed: `writing-plans`, `superpowers:writing-plans`, `mas:writing-plans`. The codebase uses the correct names, but the LLM invents wrong prefixes.
3. **Orchestrator residue** — Marked deprecated in its own CLAUDE.md, but still referenced in the system prompt agent list and dispatched 4 times across sessions.

### Correct Naming Convention (reference)

**Agents** — always `mas:{slug}:{slug}`:
- `mas:engineer:engineer`, `mas:reviewer:reviewer`, `mas:bug-fixer:bug-fixer`
- `mas:researcher:researcher`, `mas:differential-reviewer:differential-reviewer`
- `mas:ui-ux-designer:ui-ux-designer`, `mas:reflect-agent:reflect-agent`

**Local MAS skills** — bare name (they live in `/skills/`):
- `verification`, `finishing-branch`, `ask-questions`, `se-principles`
- `reliability-review`, `property-based-testing`, `differential-review`, `subagent-driven-development`

**Superpowers skills** — `superpowers:` prefix:
- `superpowers:writing-plans`, `superpowers:test-driven-development`, `superpowers:systematic-debugging`

**Other plugin skills** — plugin prefix:
- `frontend-design` (from frontend-design plugin)

---

### Task 1: Add dispatch naming quick-reference to dev-loop.md

**Files:**
- Modify: `commands/dev-loop.md:153-164` (after the checkpoint assertion, before Step 4)

The checkpoint assertion at line 153 already warns about self-implementation. Add a naming quick-reference table right after it so the model sees correct names every time it enters Step 4.

- [ ] **Step 1: Read the current checkpoint assertion block**

Read `commands/dev-loop.md` lines 153-164 to confirm exact content.

- [ ] **Step 2: Add naming quick-reference after the checkpoint assertion**

In `commands/dev-loop.md`, after the closing line of the checkpoint assertion block (line 160: `> Your job: route tasks, dispatch agents, track review cycles, verify results.`), insert:

```markdown

> **DISPATCH NAMING — Copy these exactly. Do NOT simplify or abbreviate.**
>
> | BAD (will break routing) | GOOD (copy this) |
> |--------------------------|-------------------|
> | `Agent(subagent_type: "engineer", ...)` | `Agent(subagent_type: "mas:engineer:engineer", ...)` |
> | `Agent(subagent_type: "reviewer", ...)` | `Agent(subagent_type: "mas:reviewer:reviewer", ...)` |
> | `Agent(subagent_type: "bug-fixer", ...)` | `Agent(subagent_type: "mas:bug-fixer:bug-fixer", ...)` |
> | `Agent(subagent_type: "researcher", ...)` | `Agent(subagent_type: "mas:researcher:researcher", ...)` |
> | `Agent(subagent_type: "differential-reviewer", ...)` | `Agent(subagent_type: "mas:differential-reviewer:differential-reviewer", ...)` |
> | `Agent(subagent_type: "ui-ux-designer", ...)` | `Agent(subagent_type: "mas:ui-ux-designer:ui-ux-designer", ...)` |
> | `Agent(subagent_type: "reflect-agent", ...)` | `Agent(subagent_type: "mas:reflect-agent:reflect-agent", ...)` |
> | `Skill(skill: "mas:verification")` | `Skill(skill: "verification")` |
> | `Skill(skill: "mas:finishing-branch")` | `Skill(skill: "finishing-branch")` |
> | `Skill(skill: "writing-plans")` | `Skill(skill: "superpowers:writing-plans")` |
> | `Skill(skill: "mas:writing-plans")` | `Skill(skill: "superpowers:writing-plans")` |
```

- [ ] **Step 3: Verify the edit**

Run: `grep -n "DISPATCH NAMING" commands/dev-loop.md`
Expected: One match at the inserted line.

- [ ] **Step 4: Commit**

```bash
git add commands/dev-loop.md
git commit -m "fix: add dispatch naming quick-reference to dev-loop checkpoint"
```

---

### Task 2: Add naming quick-reference to bug-fix.md

**Files:**
- Modify: `commands/bug-fix.md` (before the Bug-Fixer dispatch step)

The bug-fix command also dispatches agents. Add the same BAD/GOOD table before the first dispatch point.

- [ ] **Step 1: Read bug-fix.md to find the dispatch section**

Read `commands/bug-fix.md` to find where agents are first dispatched (the Bug-Fixer dispatch).

- [ ] **Step 2: Add naming quick-reference before the Bug-Fixer dispatch**

Find the Bug-Fixer dispatch section and insert the same BAD/GOOD table from Task 1 above it, adapted to only include the agents used in the bug-fix flow:

```markdown
> **DISPATCH NAMING — Copy these exactly. Do NOT simplify or abbreviate.**
>
> | BAD (will break routing) | GOOD (copy this) |
> |--------------------------|-------------------|
> | `Agent(subagent_type: "bug-fixer", ...)` | `Agent(subagent_type: "mas:bug-fixer:bug-fixer", ...)` |
> | `Agent(subagent_type: "reviewer", ...)` | `Agent(subagent_type: "mas:reviewer:reviewer", ...)` |
> | `Agent(subagent_type: "reflect-agent", ...)` | `Agent(subagent_type: "mas:reflect-agent:reflect-agent", ...)` |
> | `Skill(skill: "mas:verification")` | `Skill(skill: "verification")` |
> | `Skill(skill: "mas:finishing-branch")` | `Skill(skill: "finishing-branch")` |
```

- [ ] **Step 3: Verify the edit**

Run: `grep -n "DISPATCH NAMING" commands/bug-fix.md`
Expected: One match.

- [ ] **Step 4: Commit**

```bash
git add commands/bug-fix.md
git commit -m "fix: add dispatch naming quick-reference to bug-fix command"
```

---

### Task 3: Add lesson #21 to agent-workflow.md

**Files:**
- Modify: `rules/agent-workflow.md:43-44` (after lesson #20, before the summary table)

Add the naming drift lesson to the battle-test results table and effectiveness summary.

- [ ] **Step 1: Read the current end of the battle test table**

Read `rules/agent-workflow.md` lines 40-66 to confirm exact content around lesson #20 and the summary table.

- [ ] **Step 2: Add lesson #21 to the battle test table**

After the row for lesson #20 (line 44), insert:

```markdown
| 21 | Agent/skill names drift to bare or wrong prefix | Model simplifies `mas:engineer:engineer` → `engineer`, invents `mas:verification` | BAD/GOOD naming table in dev-loop/bug-fix checkpoint assertions | In progress |
```

- [ ] **Step 3: Add effectiveness row to summary table**

After the last row in the summary table (line 64, "Reflect Agent"), insert:

```markdown
| BAD/GOOD naming table at dispatch checkpoint | Untested — gives model copy-paste target at the moment of dispatch, needs battle testing | BAD: `Agent(subagent_type: "engineer")` → GOOD: `Agent(subagent_type: "mas:engineer:engineer")` |
```

- [ ] **Step 4: Verify the edit**

Run: `grep -n "lesson.*21\|naming drift\|naming table" rules/agent-workflow.md`
Expected: Matches for the new lesson row and effectiveness row.

- [ ] **Step 5: Commit**

```bash
git add rules/agent-workflow.md
git commit -m "docs: add lesson #21 — agent/skill naming drift"
```

---

### Task 4: Add naming reference to dispatch-templates.md header

**Files:**
- Modify: `templates/dispatch-templates.md:1-9` (header section)

The dispatch templates file is read before every agent dispatch. Adding a naming reference here ensures correct names are in context.

- [ ] **Step 1: Read the current header**

Read `templates/dispatch-templates.md` lines 1-9 to confirm exact content.

- [ ] **Step 2: Add naming rule after the "How to use" line**

After line 5 (`**How to use:** For each task, find the appropriate template below...`), insert:

```markdown

**Naming rule:** All agent `subagent_type` values use the `mas:` plugin prefix: `mas:{slug}:{slug}`. Never use bare names like `"engineer"` — always use `"mas:engineer:engineer"`. The templates below show the correct names; copy them exactly.
```

- [ ] **Step 3: Verify the edit**

Run: `grep -n "Naming rule" templates/dispatch-templates.md`
Expected: One match.

- [ ] **Step 4: Commit**

```bash
git add templates/dispatch-templates.md
git commit -m "docs: add naming rule to dispatch-templates header"
```

---

### Task 5: Clean up orchestrator references

**Files:**
- Modify: `commands/dev-loop.md:174-182` (routing table)

The routing table references agent roles by name but not by `subagent_type`. Add a note that the orchestrator is deprecated and should never be dispatched.

- [ ] **Step 1: Read the routing table section**

Read `commands/dev-loop.md` lines 174-192 to confirm exact content.

- [ ] **Step 2: Add deprecation note after the routing table**

After line 191 (`If in doubt, route to Researcher.`), insert:

```markdown

> **Deprecated agents — do NOT dispatch:**
> - `mas:orchestrator:orchestrator` — Deprecated since v2.0. The dev-loop (this command) IS the orchestrator. Never dispatch this agent.
```

- [ ] **Step 3: Verify the edit**

Run: `grep -n "Deprecated agents" commands/dev-loop.md`
Expected: One match.

- [ ] **Step 4: Commit**

```bash
git add commands/dev-loop.md
git commit -m "docs: add orchestrator deprecation note to routing table"
```
