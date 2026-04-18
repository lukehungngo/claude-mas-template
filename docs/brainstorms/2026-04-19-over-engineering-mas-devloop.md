# Brainstorm: Over-Engineering in MAS and Dev-Loop

**Date:** 2026-04-19
**Input type:** Hunch
**Input:** "I have a problem of over engineer in both mas and dev-loop, what do u think?"

## Assumptions

| Assumption | Status | Evidence |
|-----------|--------|----------|
| More agents = better quality | QUESTIONED | Reflect failed 5/5 sessions despite prose enforcement — more complexity made reliability worse |
| Research Convergence Protocol prevents bad implementations | QUESTIONED | No data. Costs 6 agent calls before any code is written |
| Task specs need size + success_test + contract + line-ranged files | QUESTIONED | Orchestrator pre-filling these is double work — engineer derives contract from context |
| Orchestrator must not write code | CONFIRMED | Separation of concerns is valid |
| Reflect agent's job can't be done at planning time | QUESTIONED | Scope drift is a planning failure, not an execution failure |
| 5-agent concurrency cap prevents problems | QUESTIONED | No evidence. Adds counting overhead per dispatch |

## Fundamentals

1. Code must be written and verified correct
2. The requirement must be understood before building
3. Review catches errors the implementer misses
4. **Coordination overhead has its own failure modes** — the orchestrator forgetting to dispatch reflect is a coordination bug caused by pipeline complexity

**Bedrock:** Every layer added to fix a reliability problem increases orchestrator cognitive load → makes it more likely to skip the new layer too. Positive feedback loop of complexity.

## Root Cause

The pipeline was built by adding guards for every observed failure. But:

> Each layer added to fix a reliability problem increases the orchestrator's cognitive load, making it more likely to skip the new layer too.

Examples:
- Reflect skipped → blocking hook → now orchestrator must dispatch reflect + write correct spec_name + not use background mode
- Bad implementations → research convergence → 6 agent calls before any code, 3-round tracking
- Scope creep → reflect agent → separate phase, hook, file naming
- Missed bugs → self-reviews → orchestrator must remember to request
- Uneven tasks → size routing table → must categorize before routing

**Result:** An orchestrator spending more turns orchestrating than engineers spend implementing.

## Output

**Minimum pipeline from first principles:**
```
Plan → Implement (parallel) → Review (parallel) → Done
```

Everything else should be opt-in based on actual risk.

### MAS

1. **Kill Research Convergence Protocol as default** — Researcher + diff-reviewer opt-in for genuinely novel/risky tasks. Default: engineer reads codebase, plans internally, implements.
2. **Merge reflect into review** — Add a "does this solve the stated requirement?" check to the reviewer's checklist. Remove the reflect agent as a mandatory separate dispatch.
3. **Simplify task specs** — Remove `success_test`, `contract`, line-ranged `relevant_files`. Keep: description, goal, relevant_files (bare paths), acceptance criteria.

### Dev-Loop

1. **Flatten to 3 phases** — Plan → Implement+Review (batched) → Finish. Reflect becomes part of the reviewer's checklist, not a separate phase.
2. **Remove size-based routing** — Classification overhead before every dispatch. Use orchestrator judgment instead.
3. **Remove cross-task review** — Almost never triggers, adds decision overhead every session.

### Meta-Rule to Add

> Before adding a new enforcement layer, ask: does this fix the root cause, or does it add a step that the orchestrator will also skip?

## Next Steps

If proceeding: simplify dev-loop to 3 phases, fold reflect into reviewer checklist, make research opt-in.
