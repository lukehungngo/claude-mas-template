# Research Proposal: Phase 3 Acceptance Review Agent

## Round
1 of 3

## Problem Definition

The current MAS dev-loop pipeline has three review layers:
- **Phase 2B/2C:** Per-task code review (reviewer checks each task individually for business alignment + technical quality)
- **Phase 2D:** Cross-task review (optional, checks duplication/integration/patterns across tasks)
- **Phase 3:** Close and Holistic Check -- currently the **orchestrator itself** runs a checklist ("do these tasks TOGETHER deliver what was asked?"), but NO agent is dispatched

The question: does the orchestrator's Phase 3 checklist leave a gap that a dedicated acceptance review agent would close? Specifically, does the "whole branch diff vs original requirement" review catch problems that per-task and cross-task reviews miss?

## Evidence from Session Data

### Evidence Source 1: Per-Dev-Loop-Run Analysis (workflow-routing.md)

Six dev-loop runs were analyzed in detail:

| Run | Tasks | Task Review Coverage | Integration Issues Found Post-Review |
|-----|-------|---------------------|--------------------------------------|
| 1 (devtools, OKR spec) | 5 | 100% | No data |
| 2 (devtools, v3 + audit) | 4 | 100% | No data |
| 3 (devtools, state machine) | 27 | 100% | No data |
| 4 (devtools, tier 3 + v4) | 10 | 50% (second batch unreviewed) | No data |
| 5 (devtools, next phase) | 8 | 100% | No data |
| 6 (mas-template, pipeline fixes) | 5 | 100% | No data |

**Key finding: There is no recorded evidence of integration issues that per-task reviews caught OR missed.** The session logs track review coverage (92% overall) but do not track "did the final delivery match the original requirement?" There is no data on whole-delivery failure rate because nobody measured it.

### Evidence Source 2: Lessons Learned (2026-03-28.md)

Lesson #10 is directly relevant:

> "Differential review caught what 4 review rounds missed. The adversarial differential review of Step 6 issued a REJECT verdict, identifying that the Orchestrator architecture was fundamentally broken. Four normal review rounds had only found surface issues (stale references, wrong counts)."

This is evidence that **normal reviews (per-task) miss architectural/integration-level problems** that a different review mode (adversarial/holistic) catches. However, this was a differential review of a research proposal, not a code-level acceptance review. The lesson is directional, not directly transferable.

### Evidence Source 3: Battle Test Results (agent-workflow.md)

No battle test entry describes a failure mode of "per-task reviews passed but the whole delivery was wrong." The 19 documented failures are about:
- Pipeline steps being skipped (8 entries)
- Wrong agent dispatched or not dispatched (6 entries)
- Model behavioral quirks (5 entries)

None are about review quality gaps at the integration level.

### Evidence Source 4: Current Reviewer Coverage (reviewer CLAUDE.md)

The reviewer already performs:
- **Phase A -- Business Alignment:** "Cross-check against business intent -- does this solve the actual problem?"
- **Phase B -- Technical Audit:** Architecture check, duplication audit (code, intent, knowledge, cross-file)

This means the per-task reviewer already checks requirement alignment for each task individually. What it does NOT check:
- Whether tasks A, B, and C **together** satisfy the original requirement
- Whether the combined diff introduces emergent issues (e.g., conflicting state management across tasks)
- Whether something was simply **omitted** from the plan (a requirement that got no task)

### Evidence Source 5: Cross-Task Review (Phase 2D)

The existing cross-task review (dispatch-templates.md, Step 5) checks:
- Duplication across tasks
- Integration gaps
- Pattern consistency

This partially covers the "together" gap. However, it does NOT:
- Compare the branch diff against the **original requirement** (it only sees task specs and results)
- Check for **omitted requirements** (it reviews what was built, not what was asked for)
- Apply adversarial thinking ("what could go wrong with these changes as a whole?")

## Proposed Approach

**Recommendation: REVISE -- strengthen Phase 2D and Phase 3, do NOT add a new agent.**

### Rationale

The evidence does not support adding a new agent dispatch:

1. **No measured failure rate at the whole-delivery level.** Without data showing that per-task + cross-task reviews miss integration-level defects, the marginal value of Phase 3 is speculative.

2. **The reviewer already checks business alignment per-task.** Adding a whole-branch review duplicates this check at higher token cost.

3. **Phase 2D already covers integration/duplication.** It just needs the original requirement injected into its prompt to close the "omission" gap.

4. **Cost is non-trivial.** Based on session data, the heaviest session dispatched 37 engineers + 10 reviewers + 4 differential reviewers = 51 agent dispatches. Adding another reviewer at Phase 3 adds ~2-5% to total agent cost. For smaller runs (5 tasks), it adds ~20% to review cost for unknown value.

5. **Structural enforcement beats prose review.** The meta-lesson from agent-workflow.md is clear: "prose instructions get skipped, structural constraints don't." An agent performing a holistic review is a prose-level check. An artifact gate checking "every requirement maps to a task" is a structural check.

### What to do instead

**Option A (recommended): Strengthen Phase 2D + Phase 3 checklist without new agent dispatch.**

Phase 2D changes:
- Inject the **original user requirement** into the cross-task reviewer prompt (currently missing -- the reviewer only sees task specs and results)
- Add an explicit check: "List every requirement from the original prompt. Map each to a task. Flag unmapped requirements."
- Add an explicit check: "Review the combined git diff. Identify any emergent issues across file boundaries."

Phase 3 changes:
- Add a structural gate: count requirements in the original prompt vs tasks in `docs/tasks/done/`. If count diverges, flag before proceeding.
- Add a `git diff main...HEAD --stat` check: are there files modified that no task spec mentions? (indicates scope creep or unreviewed changes)

**Option B (alternative): Reuse differential-reviewer agent at Phase 3.**

Dispatch the differential-reviewer with a modified prompt:
- Input: original requirement + full branch diff + all task results
- Question: "Does this branch, as a whole, solve the original problem? What could go wrong?"
- Verdict: PROCEED/REVISE (if REVISE, create remediation tasks and loop back to Phase 2A)

This reuses an existing agent without creating a new one. The differential reviewer is already designed for adversarial analysis. Cost: 1 additional agent dispatch per dev-loop run.

**Option C (alternative): New dedicated acceptance-reviewer agent.**

Create a new agent type `mas:acceptance-reviewer:acceptance-reviewer` with a specialized prompt focused on requirement-to-delivery mapping and integration risk. This is the heaviest option and is not justified by the current evidence.

## Data Structures

No new data structures needed for Option A. For Option B, the differential-reviewer output would use its existing format (`docs/reports/TASK-{id}-differential-r{round}.md`) adapted to a branch-level review (`docs/reports/acceptance-review.md`).

## Trade-off Analysis

| Approach | Pros | Cons | Token Cost | Implementation Effort |
|----------|------|------|------------|----------------------|
| **Option A: Strengthen 2D + 3 checklist** | Zero additional agent cost; structural gates are reliable per meta-lesson; closes the requirement-omission gap | Still relies on orchestrator discipline for Phase 3 checklist; no adversarial review of combined changes | 0 extra tokens | Low -- prompt edit + 1 bash gate |
| **Option B: Reuse differential-reviewer** | Adversarial review of whole branch; catches emergent issues; reuses existing agent | 1 extra dispatch per run (~2-20% cost increase); differential-reviewer was designed for proposals, not code diffs; may produce noisy results on large diffs | 1 agent dispatch | Medium -- new dispatch template + prompt adaptation |
| **Option C: New acceptance-reviewer agent** | Purpose-built for the job; cleanest separation of concerns | Highest cost (new agent + dispatch); no evidence justifying this level of investment; adds maintenance burden | 1 agent dispatch + ongoing maintenance | High -- new agent definition + templates + testing |

## FP Analysis

For Option B (if pursued):
- **False positive rate estimate: 15-25%.** The differential reviewer is tuned for adversarial analysis of proposals. When pointed at a full branch diff (potentially 1000+ LOC across many files), it will likely flag issues that are already handled or are intentional trade-offs. This noise level is manageable but not zero.
- **Mitigation:** Use a narrower prompt -- instead of "what could go wrong?", ask "does every stated requirement have a corresponding implementation? List gaps only."

For Option A:
- **False positive rate: ~5%.** Structural gates (count matching) have very low false positive rates. The prompt-injected requirement check may occasionally flag a requirement that was intentionally deferred, but this is easily resolved.

## FN Analysis

For all options, the key false negative is:
- **Emergent integration bugs.** Two tasks that individually pass review but create a conflict when combined (e.g., both modify the same state, introduce circular dependencies, or create race conditions). None of the options fully catch this -- it requires running the combined code, which is what Phase 5 (verification/tests) already does.
- **Estimated FN rate for emergent bugs: unchanged across all options.** This class of bug is better caught by tests than by review.

## Implementation Hints

For **Option A** (recommended):

1. **File to modify:** `templates/dispatch-templates.md` -- Step 5 (Cross-Task Review) prompt
   - Add: "## Original Requirement\n{paste the original user prompt/requirement}"
   - Add check: "List each requirement. Map to TASK-{id}. Flag unmapped requirements."

2. **File to modify:** `commands/dev-loop.md` -- Phase 3 section
   - Add bash gate: compare requirement count vs done-task count
   - Add bash gate: `git diff main...HEAD --stat` vs task spec `relevant_files` lists

3. **Test strategy:** Run on next 3 dev-loop sessions and track:
   - Did Phase 2D catch any requirement omissions with the new prompt?
   - Did Phase 3 gates catch any scope drift?
   - Compare against baseline (current 6 runs had 0 measured integration failures)

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Phase 3 agent adds cost without catching anything new | High (no evidence of gap) | Low (wasted tokens) | Start with Option A (zero cost); measure before escalating to Option B |
| Requirement-count gate produces false positives on vague requirements | Medium | Low (easy to dismiss) | Gate should warn, not block. Only block if count divergence > 2 |
| Cross-task reviewer ignores injected requirement (prose instructions skipped) | Medium (per meta-lesson) | Medium (gap remains) | Make requirement-mapping a required section in the review template, not just a prompt hint |
| Option B differential-reviewer produces noisy results on large diffs | Medium-High | Medium (alert fatigue) | Narrow the prompt to requirement mapping only, not general adversarial review |

## Recommendation

**REVISE (Option A first, Option B if evidence warrants).**

The evidence does not justify a new Phase 3 agent dispatch today. The correct sequence is:

1. **Immediately:** Implement Option A -- inject original requirement into Phase 2D prompt, add structural gates to Phase 3.
2. **Measure:** Track requirement-omission catches and integration-level issues over the next 5-10 dev-loop runs.
3. **Escalate if needed:** If Option A catches 0 issues but manual review reveals missed integration problems, escalate to Option B (differential-reviewer at Phase 3).
4. **Never:** Option C (new agent) -- not justified by evidence, violates the "simplest structural fix first" meta-lesson.

The strongest signal in the data is Lesson #10 ("differential review caught what 4 review rounds missed"), but that was about architectural feasibility of a proposal, not about code integration. The pipeline already has the differential reviewer for proposals (pre-implementation). Adding it post-implementation for code review is a different problem with no measured failure rate.

## References

- SmartBear/Cisco Code Review Study -- 200-400 LOC optimal review size, detection degrades beyond that
- [DORA Metrics](https://dora.dev/guides/dora-metrics/) -- small batch sizes improve both speed and stability; AI adoption increases instability without review infrastructure
- [Continuous Delivery: Anatomy of the Deployment Pipeline](https://www.informit.com/articles/article.aspx?p=1621865&seqNum=5) -- acceptance test gate as second milestone after unit tests
- [Software Quality Gates](https://testrigor.com/blog/software-quality-gates/) -- pass/fail checks on metrics at each pipeline stage
- [Multi-Agent AI Orchestration Patterns 2025-2026](https://www.onabout.ai/p/mastering-multi-agent-orchestration-architectures-patterns-roi-benchmarks-for-2025-2026) -- Decision Validation Architecture: Intent Router, Specialist Agents, Consensus Builder, Final Validator
- [Building Resilient Multi-Agent Reasoning Systems (2026)](https://medium.com/@nraman.n6/building-resilient-multi-agent-reasoning-systems-a-practical-guide-for-2026-23992ab8156f) -- staged review gates with consensus mechanisms
- Internal: `docs/testing/workflow-routing.md` -- per-dev-loop-run analysis, 92% task review coverage
- Internal: `docs/lesson_learn/2026-03-28.md` -- Lesson #10 (differential review caught what normal reviews missed)
- Internal: `rules/agent-workflow.md` -- meta-lesson: structural constraints > prose instructions
- Internal: `docs/plans/review-pipeline-research.md` -- Generator-Critic pattern, review effectiveness research
- Internal: `agents/reviewer/CLAUDE.md` -- current reviewer already checks business alignment per-task
- Internal: `templates/dispatch-templates.md` Step 5 -- current cross-task review prompt (missing original requirement)
