# Researcher Agent Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close 5 quality gaps in the researcher agent identified via first-principles analysis and backtested against external literature on LLM agent failure modes.

**Architecture:** Two files change independently. `agents/researcher/CLAUDE.md` gets 4 changes (bailout for underspecified specs, source quality hierarchy, Open Questions section, Confidence field). `commands/dev-loop.md` gets 1 change (novel routing pre-screen). No new files. No executable code — markdown-only project.

**Tech Stack:** Markdown edits. Test suite: `bash tests/lint.sh` (static analysis). Baseline: 12 passed, 3 pre-existing failures (acceptable).

---

### Task 1: Researcher agent — 4 quality improvements

**Files:**
- Modify: `agents/researcher/CLAUDE.md`

Four changes in one task (same file, cohesive edit):
- **Gap 5**: Step 1 — bailout when task spec is underspecified
- **Gap 2**: Step 2 — source quality hierarchy with staleness flag
- **Gap 3**: Proposal template — `## Confidence` field
- **Gap 1**: Proposal template — `## Open Questions` section

- [ ] **Step 1: Read the current file**

```bash
cat agents/researcher/CLAUDE.md
```

- [ ] **Step 2: Add underspecified-spec bailout to Step 1 (Gap 5)**

Find Step 1 in the Process section. It currently ends with:
```
4. Search the codebase for existing patterns that might apply
```

Add a 5th item immediately after:
```markdown
5. **Underspecified check:** If the task spec has no success criteria, no constraints, and no scope boundaries — STOP. Do not proceed to Step 2. Write a blocker to the output file:
   ```
   BLOCKER: Task spec is too vague to research.
   Missing: [list which of these are absent: success criteria / constraints / scope]
   Cannot propose a solution to an undefined problem. Return to dispatcher for clarification.
   ```
```

- [ ] **Step 3: Add source quality hierarchy to Step 2 (Gap 2)**

Find Step 2 item 3: `3. Search the web for prior art, papers, existing solutions`

Replace it with:
```markdown
3. Search the web for prior art, papers, existing solutions. Apply this **source quality hierarchy** — weight sources in this order:
   1. Official docs / language specs / RFCs (highest weight)
   2. Peer-reviewed papers
   3. Well-maintained open-source repos (>1k stars, active commits in last 12 months)
   4. Established engineering blogs (e.g. Stripe, Netflix Tech, Thoughtworks)
   5. Blog posts / StackOverflow (lowest — independently verify before citing)

   **Staleness rule:** Flag any source older than 2023 with ⚠️ and a note: "pre-2023 — verify still current". Do NOT cite a URL you cannot confirm exists.
```

- [ ] **Step 4: Add Confidence field to proposal template (Gap 3)**

Find the proposal template in Step 3. It starts with:
```markdown
## Round
{N} of 3
```

Add the Confidence section immediately after `{N} of 3`:
```markdown

## Confidence
{HIGH | MEDIUM | LOW} — {one-line rationale}

Examples:
- HIGH — official docs confirmed + 2 independent implementations found
- MEDIUM — one reliable source found, no production examples verified
- LOW — no prior art found; approach is novel or speculative

LOW confidence → Differential Reviewer MUST issue REVISE or ESCALATE, not PROCEED.
```

- [ ] **Step 5: Add Open Questions section to proposal template (Gap 1)**

Find the end of the proposal template. It currently ends with:
```markdown
## References
{Links, papers, prior art}
```

Add a new section immediately after:
```markdown

## Open Questions
{List anything you could not find evidence for, are uncertain about, or that requires clarification before implementation. If none, write "None."

**If this section is non-empty:** The Differential Reviewer MUST address every item before issuing PROCEED. Unresolved open questions block PROCEED.}
```

- [ ] **Step 6: Verify structure is correct**

```bash
grep -n "## Confidence\|## Open Questions\|Underspecified\|Source quality\|staleness\|pre-2023" agents/researcher/CLAUDE.md
```

Expected output: all 5 terms appear, each at a distinct line number.

- [ ] **Step 7: Run lint**

```bash
bash tests/lint.sh 2>&1 | tail -6
```

Expected: `12 passed, 3 failed` — same pre-existing failures, 0 new.

- [ ] **Step 8: Commit**

```bash
git add agents/researcher/CLAUDE.md
git commit -m "feat: researcher — underspecified bailout, source quality hierarchy, confidence field, open questions"
```

---

### Task 2: Dev-loop routing — novel pre-screen

**Files:**
- Modify: `commands/dev-loop.md`

One change: add a pre-screen paragraph after the Novel task criteria list to prevent trivially-discoverable tasks from being routed to Researcher.

- [ ] **Step 1: Read the routing section**

```bash
grep -n "Novel task criteria\|If in doubt" commands/dev-loop.md
```

Expected: two lines — "Novel task criteria" at one line, "If in doubt, route to Researcher." shortly after.

- [ ] **Step 2: Add pre-screen after "If in doubt" line**

Find:
```markdown
If in doubt, route to Researcher.
```

Replace with:
```markdown
If in doubt, route to Researcher.

**Novel routing pre-screen:** Before routing to Researcher, ask: "Can this task be solved with a 30-minute codebase read + one web search?" If yes — the answer is *discoverable*, not novel — route directly to Engineer and save research budget. Reserve Researcher for tasks where the *approach itself* is non-obvious and competing options have real trade-offs.
```

- [ ] **Step 3: Verify**

```bash
grep -n "pre-screen\|30-minute" commands/dev-loop.md
```

Expected: both terms present at adjacent lines.

- [ ] **Step 4: Run lint**

```bash
bash tests/lint.sh 2>&1 | tail -6
```

Expected: `12 passed, 3 failed` — same pre-existing failures, 0 new. (dev-loop.md line-count warning is pre-existing.)

- [ ] **Step 5: Commit**

```bash
git add commands/dev-loop.md
git commit -m "feat: dev-loop — add novel routing pre-screen to reduce unnecessary Researcher dispatches"
```

---

## Verification

After both tasks complete:

```bash
bash tests/lint.sh 2>&1 | tail -6
grep -n "## Confidence\|## Open Questions\|Underspecified check\|Source quality\|pre-2023" agents/researcher/CLAUDE.md
grep -n "pre-screen\|30-minute" commands/dev-loop.md
```

All three commands must return hits. Lint must show 0 new failures.
