# Research Proposal: Reflect Agent for MAS Pipeline

## Round
1 of 3

## Problem Definition

The MAS pipeline has six review/validation touchpoints today:

1. **Differential Reviewer** -- stress-tests research proposals pre-implementation (is this approach feasible?)
2. **Engineer Self-Review** -- structural checklist before submission (did I follow TDD, SOLID, etc.?)
3. **Reviewer Phase A** -- business alignment per-task (does this task solve its stated problem?)
4. **Reviewer Phase B** -- technical audit per-task (is the code correct, safe, clean?)
5. **Cross-Task Review (Phase 2D)** -- duplication, integration, pattern consistency across tasks
6. **Verification (Phase 5)** -- tests pass, lint clean, no debug artifacts

What is missing: **nobody asks "did we build the RIGHT thing?"** at the whole-delivery level. The Reviewer checks each task against its task spec. The Cross-Task Review checks tasks against each other. But nobody compares the full branch diff against the original user requirement with a product mindset. Specifically:

- **Scope creep**: Engineer adds a "nice to have" that was not in the requirement. Reviewer approves it because the code is clean. Nobody flags it as out of scope.
- **Scope drift**: Over 10 tasks, the implementation subtly drifts from the original intent. Each task individually "makes sense" but the aggregate diverges.
- **Over-engineering**: A simple requirement gets a complex solution. The Reviewer checks code quality (clean, tested, SOLID) but does not ask "was all this machinery necessary?"
- **Requirement omission**: A requirement gets no task. Phase 3 has a checklist for this, but per `rules/agent-workflow.md` lesson #18, bash gates are ignored in 4/5 sessions.
- **Wrong abstraction level**: The requirement asks for a user-facing feature, but the implementation is an internal refactor. Technically correct, product-wrong.

The prior research (`docs/plans/phase3-acceptance-review-research.md`) recommended strengthening Phase 2D + Phase 3 checklist (Option A) over adding a new agent. That recommendation was sound for the "acceptance review" framing. But the Reflect Agent is a different framing: it is NOT a code reviewer or acceptance tester. It is a product-minded architect that evaluates decisions, not code.

### What makes this hard

1. The line between "product review" and "code review" is blurry. If the Reflect Agent drifts into code review, it becomes a noisy duplicate of the Reviewer.
2. The pipeline already has 7 agent types. Adding an 8th must clear a high bar of marginal value.
3. Per the meta-lesson (`rules/agent-workflow.md`), prose instructions get skipped. The Reflect Agent's value depends on it actually being dispatched, which means it needs structural enforcement.
4. The Reflect Agent must scan the codebase (not just read reports) to verify claims, but it must NOT modify code. This is a read-only investigator.

## Prior Art: The Reflection Pattern in AI

### Academic foundation

The reflection pattern originates from Shinn et al.'s "Reflexion" (2023), which introduced verbal self-reflection as a mechanism for LLM agents to learn from mistakes. The key insight: an agent that explicitly critiques its own output and grounds that critique in external evidence produces higher-quality results than one that simply retries.

### How frameworks implement it

| Framework | Reflection mechanism | Focus |
|-----------|---------------------|-------|
| **LangGraph** | Cyclical graph with generate-reflect-refine loop. MessageGraph accumulates critique. | Self-correction of code/text output |
| **CrewAI** | Role-based: a "reviewer" role agent in a sequential process | Peer review, not self-reflection |
| **AutoGen/AG2** | GroupChat with agents debating through multi-turn conversation | Consensus through dialogue |
| **Google ADK** | Generator-Critic-Refiner as three sequential agents | Output quality improvement |
| **Reflexion (Shinn et al.)** | Actor generates, evaluator critiques, actor reflects on critique and retries | Goal-alignment through verbal feedback |

### Key distinction: reflection vs. evaluation

Most implementations of the "reflection" pattern are about **output quality** -- the agent reflects on whether its code/text is correct. What the task spec asks for is different: **goal alignment** -- did the team solve the right problem? This is closer to the "evaluator" in Reflexion than the "reflector", but with a product mindset rather than a correctness mindset.

The closest analogy in existing frameworks is Google ADK's "evaluator-optimizer" pattern, but adapted: instead of evaluating output quality, the Reflect Agent evaluates decision quality.

## Proposed Approach

### Agent identity

- **Name:** `reflect-agent` (subagent_type: `mas:reflect-agent:reflect-agent`)
- **Description:** Product-minded architect. Evaluates whether the delivery matches the original intent. Checks scope alignment, SRP at the feature level, and decision quality. Never reviews code quality -- that is the Reviewer's job.
- **Persona:** Senior product architect who has seen too many projects that passed all tests but solved the wrong problem.

### Tools

| Tool | Why |
|------|-----|
| Read | Read original requirement, task specs, engineer results, branch diff |
| Glob | Find files modified by the branch |
| Grep | Search for patterns, verify claims about implementation |
| Bash | Run `git diff`, `git log`, `git diff --stat`, count files/tasks |

**Explicitly excluded:** Write, Edit (read-only agent), WebSearch, WebFetch (not needed), Skill (no skills to invoke -- it IS the skill).

### Process: Three-phase reflection

#### Phase 1 -- Requirement Mapping

Input: original user requirement, all task specs from `docs/tasks/done/`

1. Extract every discrete requirement from the original user prompt. Number them R1, R2, R3...
2. For each requirement, find the task(s) that implement it. Map: R1 -> TASK-003, R2 -> TASK-004, TASK-005...
3. Flag **unmapped requirements** (requirement exists, no task implements it).
4. Flag **unmapped tasks** (task exists, no requirement justifies it -- scope creep signal).

Output: Requirement-Task mapping table with gap analysis.

#### Phase 2 -- Decision Audit

Input: original requirement, approved research proposals (if any), full branch diff (`git diff main...HEAD`)

For each significant implementation decision visible in the diff:

1. **Was this the simplest viable approach?** Check if the implementation introduces abstractions, patterns, or infrastructure not warranted by the requirement.
2. **Was this asked for?** Check if the change traces back to a stated requirement. If not, is it a justified prerequisite, or is it scope creep?
3. **SRP at the feature level:** Does each task do ONE thing? Did any task smuggle in unrelated changes?
4. **Alternative analysis:** For the highest-impact decisions, briefly state what alternatives existed and whether the chosen approach is well-justified.

Output: Decision audit with per-decision ALIGNED / DRIFTED / OVER-ENGINEERED tags.

#### Phase 3 -- Verdict

Synthesize Phase 1 and Phase 2 into a branch-level verdict:

| Verdict | Meaning | Action |
|---------|---------|--------|
| **ALIGNED** | Delivery matches intent. Scope is clean. Decisions are justified. | Proceed to verification. |
| **DRIFTED** | Delivery partially matches intent but has scope drift or missed requirements. List specific gaps. | Orchestrator creates remediation tasks and loops back to Phase 2A (max 1 remediation cycle). |
| **OVER-ENGINEERED** | Delivery works but is significantly more complex than the requirement warrants. | Orchestrator presents to human with simplification suggestions. Does NOT block -- human decides. |

### What it reads

| Input | Source | Why |
|-------|--------|-----|
| Original user requirement | Passed in dispatch prompt | Ground truth for intent |
| All task specs | `docs/tasks/done/TASK-*.md` | What was planned |
| All engineer results | `docs/results/TASK-*-result.md` | What was built |
| Research proposals (if any) | `docs/plans/TASK-*-research-*.md` | What decisions were made and why |
| Full branch diff | `git diff main...HEAD` | Actual changes |
| Branch diff stats | `git diff main...HEAD --stat` | File scope |
| Codebase (as needed) | Read, Glob, Grep | Verify claims |

### What it outputs

Write to `docs/reports/reflect-report.md`:

```markdown
# Reflection Report

## Original Requirement
{quoted verbatim}

## Requirement-Task Mapping

| # | Requirement | Task(s) | Status |
|---|-------------|---------|--------|
| R1 | {requirement} | TASK-{id} | COVERED / PARTIAL / MISSING |
| R2 | {requirement} | -- | MISSING |

### Unmapped Tasks (scope creep candidates)
- TASK-{id}: {description} -- not traced to any requirement

## Decision Audit

### Decision 1: {description}
- **Traced to:** R{N}
- **Alternatives considered:** {list}
- **Verdict:** ALIGNED / DRIFTED / OVER-ENGINEERED
- **Evidence:** {file:line or git diff excerpt}
- **Rationale:** {why this verdict}

### Decision 2: ...

## Scope Summary
- Requirements covered: {N} of {M}
- Tasks with clear requirement traceability: {N} of {M}
- Decisions flagged: {N} DRIFTED, {N} OVER-ENGINEERED

## Verdict
{ALIGNED / DRIFTED / OVER-ENGINEERED}

## Remediation (if DRIFTED)
{Specific tasks to create or changes to revert}
```

### Where it fits in the pipeline

**After Phase 2D (all reviews done), before Phase 3 close and before Phase 5 verification.**

Current pipeline:
```
Phase 2A: Batch Engineer dispatch
Phase 2B: Wait and read results
Phase 2C: Batch Reviewer dispatch
Phase 2D: Handle verdicts (APPROVED/BLOCKED) + optional cross-task review
Phase 3:  Close and holistic check
Phase 5:  Verification
```

Proposed pipeline:
```
Phase 2A: Batch Engineer dispatch
Phase 2B: Wait and read results
Phase 2C: Batch Reviewer dispatch
Phase 2D: Handle verdicts + optional cross-task review
Phase 2E: Reflect Agent dispatch    <-- NEW
Phase 3:  Close and holistic check
Phase 5:  Verification
```

**Why here and not elsewhere:**
- **Not before Phase 2C (review):** The Reflect Agent needs the full, reviewed implementation to assess. Reflecting on unreviewed code wastes its analysis on code that might change.
- **Not at Phase 5 (verification):** Too late. Verification is a mechanical pass/fail gate. Reflection findings (DRIFTED) require remediation tasks, which need to go back through Phase 2A.
- **Not replacing Phase 3:** Phase 3 is the orchestrator's close-out checklist. The Reflect Agent is an independent assessment. Phase 3 should read the reflect report as one of its inputs.

### How it differs from existing agents

| Dimension | Reviewer | Differential Reviewer | Reflect Agent |
|-----------|----------|----------------------|---------------|
| **When** | After each engineer task | Before implementation (on proposals) | After all tasks reviewed, before close |
| **Scope** | Per-task | Per-proposal | Whole branch |
| **Persona** | Senior code reviewer | Adversarial skeptic | Product architect |
| **Asks** | "Is this code correct and clean?" | "Will this approach work in practice?" | "Did we build the right thing?" |
| **Cares about** | Bugs, SOLID, duplication, test coverage | Feasibility, edge cases, complexity | Scope alignment, SRP at feature level, decision quality |
| **Does NOT care about** | Whether we solved the right problem | Code quality (hasn't seen code yet) | Code quality, bugs, test coverage |
| **Verdict** | APPROVED / BLOCKED | PROCEED / REVISE / REJECT | ALIGNED / DRIFTED / OVER-ENGINEERED |
| **On failure** | Bug-Fixer | Researcher re-proposes | Remediation tasks or human escalation |

## Data Structures

### Reflect Agent CLAUDE.md frontmatter

```yaml
name: reflect-agent
description: Product-minded architect. Evaluates delivery against original intent. Checks scope alignment, feature-level SRP, and decision quality. Never reviews code quality.
tools:
  - Read
  - Glob
  - Grep
  - Bash
```

### Reflect Report schema (output)

Key sections (all required):
- `Original Requirement` -- verbatim quote
- `Requirement-Task Mapping` -- table with COVERED/PARTIAL/MISSING per requirement
- `Decision Audit` -- per-decision analysis with ALIGNED/DRIFTED/OVER-ENGINEERED
- `Scope Summary` -- counts
- `Verdict` -- ALIGNED/DRIFTED/OVER-ENGINEERED
- `Remediation` -- only if DRIFTED

### Dispatch template addition

New template #9 in `templates/dispatch-templates.md`:

```
Agent(
  subagent_type: "mas:reflect-agent:reflect-agent",
  prompt: """
  ## Original Requirement
  {paste the original user prompt/requirement verbatim}

  ## Task Specs
  {paste all task specs from docs/tasks/done/}

  ## Engineer Results
  {paste all results from docs/results/TASK-*-result.md}

  ## Research Proposals (if any)
  {paste approved proposals, or "N/A"}

  ## Working Directory
  {worktree path}

  ## Output
  Write your reflection report to docs/reports/reflect-report.md
  Issue verdict: ALIGNED / DRIFTED / OVER-ENGINEERED
  """
)
```

## Proposed Checklist (what the Reflect Agent evaluates)

### Scope Alignment
- [ ] Every requirement from the original prompt maps to at least one task
- [ ] Every task maps to at least one requirement (no orphan tasks)
- [ ] No files modified outside the scope implied by the requirement
- [ ] `git diff --stat` file list is consistent with task spec `relevant_files`

### Feature-Level SRP
- [ ] Each task does ONE thing -- no smuggled changes
- [ ] No task combines unrelated concerns (e.g., "add feature X and also refactor Y")
- [ ] Changes are minimal for the stated requirement -- no gold-plating

### Decision Quality
- [ ] For each non-trivial implementation decision, the chosen approach is the simplest that satisfies the requirement
- [ ] If a research proposal was approved, the implementation follows it (not a silent deviation)
- [ ] No unnecessary abstractions, interfaces, or patterns introduced "for future flexibility"
- [ ] Dependencies added (if any) are justified by the requirement, not speculative

### Requirement Coverage
- [ ] All functional requirements are implemented
- [ ] All edge cases mentioned in the requirement are handled
- [ ] No requirement was silently dropped or partially implemented
- [ ] Cross-cutting requirements that span tasks are addressed (not lost at task boundaries)

### Architectural Fitness
- [ ] The solution fits the existing architecture (does not introduce a new paradigm without justification)
- [ ] No architectural invariants from CLAUDE.md are violated
- [ ] The solution is at the right abstraction level (user-facing if requirement is user-facing, internal if requirement is internal)

## Trade-off Analysis

| Approach | Pros | Cons | Complexity |
|----------|------|------|-----------|
| **Proposed: Dedicated Reflect Agent at Phase 2E** | Clear separation of concerns; product persona prevents drift into code review; structural enforcement via artifact gate (`docs/reports/reflect-report.md`); catches scope/decision issues that no existing agent targets | Adds 1 agent dispatch per dev-loop run (~5-15% cost increase); risk of noise if scope is ambiguous; 8th agent type adds cognitive overhead to pipeline | Medium -- new agent CLAUDE.md, new dispatch template, Phase 2E insertion in dev-loop |
| **Alternative A: Extend Cross-Task Review (Phase 2D) with product checklist** | Zero additional agent cost; reuses existing reviewer; simpler pipeline | Reviewer has code-reviewer persona -- asking it to think like a product architect is a persona mismatch; original requirement is not currently injected into cross-task review prompt; mixes two distinct review concerns | Low -- prompt modification only |
| **Alternative B: Reuse Differential Reviewer at Phase 2E** | Reuses existing agent; adversarial mindset is useful; no new agent type | Differential Reviewer is designed for proposals, not delivered code; its adversarial persona optimizes for "what could go wrong" not "did we build the right thing"; prompt would need heavy adaptation | Medium -- new dispatch template, adapted prompt |
| **Alternative C: Fold into Phase 3 orchestrator checklist** | Zero agent cost; fastest to implement | Per meta-lesson, orchestrator checklists are ignored in 4/5 sessions (lesson #18); no independent assessment; orchestrator has confirmation bias (it planned and dispatched the work) | Low -- checklist modification |

### Recommended approach: Proposed (Dedicated Reflect Agent)

**Why not Alternative A:** The Reviewer agent has a code-reviewer persona. Asking it to also be a product architect dilutes its focus. The meta-lesson says specialized agents outperform generalists (review-pipeline-research.md finding: "reviewer expertise is the strongest predictor of effectiveness"). A dedicated product-review persona will produce more useful findings than a code reviewer with a product checklist bolted on.

**Why not Alternative B:** The Differential Reviewer's value comes from evaluating proposals in isolation, before implementation. Its adversarial "what will go wrong" framing is designed for pre-implementation proposals. Post-implementation, the question is "did we build the right thing?" -- a different question requiring a different persona.

**Why not Alternative C:** The prior research (phase3-acceptance-review-research.md) already recommended this as Option A. It is a good minimal step. But the meta-lesson is clear: orchestrator checklists get skipped. The Reflect Agent, dispatched as a separate agent with its own artifact gate, is a structural enforcement mechanism. The orchestrator cannot skip it without the artifact gate failing.

## FP Analysis

**What would trigger false positives (flagging something as DRIFTED or OVER-ENGINEERED when it is actually correct)?**

1. **Justified prerequisites:** Engineer adds a utility function or test helper that is not in the requirement but is necessary for the implementation. The Reflect Agent might flag this as scope creep. **Estimated rate: 10-15%.** Mitigation: the checklist distinguishes "orphan tasks" (no requirement) from "prerequisite tasks" (required by another task that maps to a requirement). The Reflect Agent should trace transitive dependencies.

2. **Ambiguous requirements:** If the original requirement is vague ("improve the pipeline"), almost any implementation is both ALIGNED and DRIFTED depending on interpretation. **Estimated rate: 5-10% for well-scoped requirements, 30%+ for vague requirements.** Mitigation: the Reflect Agent should flag requirement ambiguity as a finding rather than issuing a DRIFTED verdict.

3. **Refactoring that enables the feature:** Engineer refactors existing code to make the feature possible. Not in the requirement, but necessary. **Estimated rate: 5-10%.** Mitigation: check if the refactored code is touched by the feature implementation. If yes, it is a justified prerequisite.

**Overall FP estimate: 15-25% initially, declining to 5-10% after prompt tuning based on first 5 runs.**

## FN Analysis

**What would be missed (something is DRIFTED or OVER-ENGINEERED but the Reflect Agent says ALIGNED)?**

1. **Subtle scope drift across many small tasks:** Each task individually seems aligned, but the aggregate implementation subtly solves a different problem. **Estimated rate: 10-20%.** This is the hardest class of error to catch -- it requires understanding the gestalt, not individual pieces.

2. **Over-engineering that looks like good practice:** Engineer adds comprehensive error handling, retry logic, and observability for a simple feature. Each addition is defensible in isolation. The Reflect Agent might rate it ALIGNED because it maps to "best practices". **Estimated rate: 15-20%.** Mitigation: the checklist explicitly asks "is this the simplest approach?" and "would a junior engineer do less and still satisfy the requirement?"

3. **Missing non-functional requirements:** The original requirement says "add feature X" but implicitly expects it to be fast/secure/accessible. The Reflect Agent checks functional requirement mapping but may miss implicit NFRs. **Estimated rate: 10-15%.** Mitigation: this is outside the Reflect Agent's scope -- NFRs are the Reviewer's responsibility (reliability-review skill).

**Overall FN estimate: 20-30%.** The Reflect Agent is not a silver bullet. It catches a class of errors (scope/decision alignment) that no other agent targets, but it will miss some instances of those errors, especially subtle drift.

## Implementation Hints

### Files to create
1. `agents/reflect-agent/CLAUDE.md` -- agent definition with persona, process, output format
2. Addition to `templates/dispatch-templates.md` -- template #9 for Reflect Agent dispatch

### Files to modify
1. `commands/dev-loop.md` -- insert Phase 2E between Phase 2D and Phase 3; add artifact gate for `docs/reports/reflect-report.md`
2. `templates/dispatch-templates.md` -- add template #9
3. `commands/dev-loop.md` -- update Agent Reference table (add Reflect Agent row)
4. `commands/dev-loop.md` -- update pipeline self-audit checklist (add reflect report check)
5. `commands/dev-loop.md` -- update pipeline diagram (add Phase 2E)

### Structural enforcement
- **Artifact gate:** `docs/reports/reflect-report.md` must exist before Phase 3 proceeds. This is the structural equivalent of "required reviewer" in GitHub branch protection.
- **Tool restriction:** No Write/Edit tools. The Reflect Agent physically cannot modify code.
- **Verdict-driven action:** DRIFTED triggers remediation tasks (structural); OVER-ENGINEERED triggers human escalation (cannot be auto-resolved).

### Test strategy
1. **Dry run on prior sessions:** Take 2-3 completed dev-loop branches and retroactively run the Reflect Agent prompt against them. Measure: does it find scope/decision issues that the Reviewer missed? Does it produce false positives?
2. **Track over 5 runs:** After deployment, measure FP rate, FN rate (via manual spot-check), and "did the Reflect Agent find anything the Reviewer did not?"
3. **Kill criterion:** If after 5 runs the Reflect Agent has found 0 unique issues (everything it flags was already caught by the Reviewer or was a false positive), deprecate it.

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Reflect Agent drifts into code review (duplicates Reviewer) | Medium-High | Medium -- noise, wasted tokens | Strong persona framing: "You do NOT care about bugs, tests, code quality. That is the Reviewer's job." Exclude Skill tool. |
| Reflect Agent is always ALIGNED (rubber-stamps) | Medium | High -- no value, wasted cost | Same mitigation as Differential Reviewer: "NEVER rubber-stamp. Always do the full analysis." Add adversarial prompt: "Assume something is wrong. Find it." |
| Adds cost without catching anything new | Medium | Low -- recoverable (deprecate) | Kill criterion after 5 runs. Start with ALIGNED verdict being the common case -- it is useful to confirm alignment, not just catch drift. |
| Pipeline dispatch discipline: orchestrator skips Phase 2E | Medium (per meta-lesson) | High -- agent never runs | Artifact gate: `docs/reports/reflect-report.md` must exist before Phase 3 close. Add to pipeline self-audit checklist. |
| Ambiguous requirements cause high FP rate | Medium | Medium -- alert fatigue | Reflect Agent should flag ambiguity as a finding, not as DRIFTED. Output should include confidence level. |
| Large branch diffs (1000+ LOC) overwhelm context | Low-Medium | Medium -- shallow analysis | Reflect Agent should focus on `git diff --stat` first, then selectively read high-impact files. Phase 1 (requirement mapping) does not need the full diff -- just task specs. |

## References

### Reflection pattern in AI
- [LangChain Blog: Reflection Agents](https://blog.langchain.com/reflection-agents/) -- LangGraph implementation of generate-reflect-refine cycle
- [Agent Patterns Documentation: Reflection](https://agent-patterns.readthedocs.io/en/stable/patterns/reflection.html) -- formal pattern specification
- [Shinn et al., Reflexion (2023)](https://arxiv.org/abs/2303.11366) -- original paper on verbal self-reflection for LLM agents
- [Hugging Face Blog: AI Trends 2026 - Reflective Agents](https://huggingface.co/blog/aufklarer/ai-trends-2026-test-time-reasoning-reflective-agen) -- industry trends
- [QAT: The Reflection Pattern](https://qat.com/reflection-pattern-ai/) -- practical guide
- [SitePoint: Agentic Design Patterns 2026 Guide](https://www.sitepoint.com/the-definitive-guide-to-agentic-design-patterns-in-2026/) -- comprehensive pattern catalog
- [Edureka: Agentic AI Reflection Pattern](https://www.edureka.co/blog/agentic-ai-reflection-pattern/) -- tutorial
- [ByteByteGo: Top AI Agentic Workflow Patterns](https://blog.bytego.com/p/top-ai-agentic-workflow-patterns) -- pattern comparison

### Multi-agent frameworks
- [DataCamp: CrewAI vs LangGraph vs AutoGen](https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen) -- framework comparison
- [OpenAgents: Framework Comparison 2026](https://openagents.org/blog/posts/2026-02-23-open-source-ai-agent-frameworks-compared) -- updated comparison

### Internal references
- `docs/plans/phase3-acceptance-review-research.md` -- prior research recommending Option A (strengthen Phase 2D + Phase 3). This proposal argues that Option A is insufficient because orchestrator checklists get skipped (meta-lesson).
- `docs/plans/review-pipeline-research.md` -- Generator-Critic pattern research, code review effectiveness data
- `rules/agent-workflow.md` -- meta-lesson: structural constraints beat prose rules. Battle test results showing gate effectiveness.
- `agents/reviewer/CLAUDE.md` -- current reviewer scope (code quality, business alignment per-task)
- `agents/differential-reviewer/CLAUDE.md` -- current differential reviewer scope (proposal feasibility)
- `commands/dev-loop.md` -- current pipeline structure, Phase 2D and Phase 3 definitions
- `templates/dispatch-templates.md` -- existing dispatch templates (6 agent types + batch + convergence protocol)
