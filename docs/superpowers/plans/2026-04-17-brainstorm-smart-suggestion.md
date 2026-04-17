# Brainstorm Smart Next-Step Suggestion Implementation Plan

> **For agentic workers:** This plan is executed by the dev-loop. Do NOT invoke superpowers:subagent-driven-development. The dev-loop dispatches `mas:engineer:engineer` directly.

**Goal:** Make the brainstorm command emit a primary next-command suggestion tailored to the concluded input/output type, while preserving the existing alternatives menu.

**Architecture:** Single-file edit to `commands/brainstorm.md`. Replace the static three-line next-steps block in Step 4 with a conditional primary suggestion driven by the input-type contract (lines 21–30), followed by the existing alternatives as a fallback menu. No code execution — pure instruction-doc change.

**Tech Stack:** Markdown command file, no runtime.

---

### Task 1: Replace static Next Steps with conditional primary + alternatives

**Files:**
- Modify: `commands/brainstorm.md` — Step 4 block (lines 85–96)

**Context for engineer:**

The brainstorm command is an analytical slash command. Its Step 4 currently prints a static menu of three commands regardless of what the brainstorm concluded. We want a **primary suggestion** that matches the concluded output type, plus the **existing alternatives menu** kept as secondary options.

Mapping from the Input → Output contract table (lines 21–30 of the file, already committed — do not re-derive):

| Concluded output | Primary next command |
|------------------|----------------------|
| Root cause (confirmed with evidence) | `/mas:bug-fix` |
| Hypothesis (no evidence yet) | investigate further, then `/mas:bug-fix` |
| Solution direction (clear) | `/mas:dev-loop` |
| Validation = YES (idea worth doing) | `/mas:dev-loop` |
| Validation = NO (idea rejected) | stop / refine scope |
| Answer (yes/no to a question) | usually none — human decides |
| Framing (context/how-to-think) | none — analytical only |
| Analysis (hunch explored) | `/mas:bug-fix` if root cause surfaced; `/mas:dev-loop` if solution direction clear; otherwise refine |
| Feasibility check (constraints) | situational |
| Evaluation (criteria gaps) | depends on gaps |

**Keep unchanged:**
- Lines 1–84 (header, foundation, contract table, flow, Steps 1–3).
- Lines 98–124 (Output Format — the saved doc still has a `## Next Steps` section; it already takes free-form content).
- Lines 126–140 (What This Command Does NOT Do, Integration diagram).

- [ ] **Step 1: Read the current Step 4 block**

Open `commands/brainstorm.md` and locate the block starting at "### Step 4 — Save" through the triple-backtick code block that ends with "Or continue refining.".

- [ ] **Step 2: Replace Step 4 content with new version**

Replace the block from `### Step 4 — Save` through the closing ` ``` ` (lines 85–96 inclusive) with this exact content:

````markdown
### Step 4 — Save and Suggest

Write the brainstorm to `docs/brainstorms/YYYY-MM-DD-<topic>.md`.

Then, based on the concluded output type, print a **primary suggestion** plus the **alternatives menu**. Do not auto-invoke — human decides.

**Pick the primary suggestion using this table:**

| Concluded output | Primary suggestion |
|------------------|--------------------|
| Root cause confirmed (evidence supports it) | `/mas:bug-fix fix <root cause> — see docs/brainstorms/<file>.md` |
| Hypothesis only (root cause not yet confirmed) | Investigate further to confirm the hypothesis, then `/mas:bug-fix` |
| Solution direction is clear and actionable | `/mas:dev-loop implement <solution> — see docs/brainstorms/<file>.md` |
| Idea validated YES (worth building) | `/mas:dev-loop implement <idea> — see docs/brainstorms/<file>.md` |
| Idea validated NO (not worth building) | Stop. Refine scope or pick a different idea. |
| Answer to a question (yes/no) | Usually none — human decides what to do with the answer. |
| Framing for context | None — analytical only. Proceed with your own next action. |
| Analysis of a hunch | If root cause surfaced → `/mas:bug-fix`. If solution direction clear → `/mas:dev-loop`. Otherwise refine. |
| Feasibility check on constraints | Situational — depends on whether the path is feasible. |
| Evaluation against criteria | Depends on identified gaps — address gaps first, then `/mas:dev-loop` if cleared. |

If none of the rows fit cleanly, suggest the most relevant next action in plain language (e.g., "gather more data on X", "prototype the risky part first", "defer until Y is decided").

**Print format:**

```
Brainstorm saved to docs/brainstorms/<file>.md

Suggested next step:
  <primary suggestion from the table above>

Alternatives (your choice):
  /mas:dev-loop implement brainstorm at docs/brainstorms/<file>.md
  /mas:bug-fix fix based on brainstorm at docs/brainstorms/<file>.md
  Or continue refining.
```
````

- [ ] **Step 3: Verify the file still renders cleanly**

Run:
```bash
head -140 commands/brainstorm.md | tail -60
```

Expected: new Step 4 block is present, contract table (lines 21–30), Output Format (saved doc template), and Integration diagram are all still intact.

- [ ] **Step 4: Run lint baseline**

Run: `bash tests/lint.sh`

Expected: Same 3 pre-existing failures as baseline (bootstrap.md:344 example, language-stack placeholders, engineer/CLAUDE.md:35 orchestrator reference). No new failures. Line-count budgets unchanged for the files we touched (brainstorm.md is not in the budget list).

- [ ] **Step 5: Write result file**

Write to `docs/results/TASK-01-result.md` per engineer agent contract: summary of change, files modified, deviations (if any), lint status (new failures vs baseline).

- [ ] **Step 6: Commit**

```bash
git add commands/brainstorm.md
git commit -m "feat: smart next-step suggestion in brainstorm command

Primary suggestion is now conditional on the concluded output type
(root cause → bug-fix, solution direction → dev-loop, etc.), with
the existing alternatives menu preserved as fallback."
```

## Self-Review Notes (planner)

- **Spec coverage:** Task 1 covers the full user ask — conditional primary + fallback alternatives.
- **Placeholders:** None. The replacement block is fully specified.
- **Type consistency:** N/A — markdown only, no cross-task type references.
- **Scope:** Single file, single logical change. No need to split tasks.
