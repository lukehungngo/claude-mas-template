# Meta-Rules Guide: Lessons Learned from Battle Testing

This file contains hard-won lessons from real battle testing of the MAS pipeline. Every rule here exists because the failure it prevents actually happened. Read this before writing or modifying any agent, skill, or command.

---

## The Meta-Lesson

**Prose instructions get skipped. Structural constraints don't.**

Across 10 real sessions, instructions like "you MUST dispatch sub-agents" were ignored 100% of the time. The model optimizes for getting work done and skips ceremony it deems unnecessary. The only reliable way to enforce behavior is to make the wrong behavior physically impossible (e.g., removing Bash from the Orchestrator so it cannot do inline implementation).

When writing agent instructions:
- **Don't say "you should"** — say nothing, or make it structural
- **Don't add more prose rules** — remove tools, add gates, show exact tool calls
- **Don't describe what to do** — show the exact tool invocation to copy-paste
- **Don't trust "MUST" or "NEVER"** — these are suggestions to the model, not constraints

---

## Battle Test Results (18 sessions audited)

| # | Failure | Root Cause | Fix | Status |
|---|---------|-----------|-----|--------|
| 1 | Skills never invoked | Model skipped Skill() calls | Show exact `Skill(skill: "X")` syntax at each step | Solved |
| 2 | Orchestrator did everything inline | Had Bash, used it for 70 calls | Bash removed; Orchestrator now deprecated (flat dispatch) | Solved |
| 3 | Engineer used Bash for code | 0 Write/Edit, all cat/echo/sed | BAD/GOOD examples in agent CLAUDE.md | Solved |
| 4 | Researcher/Diff Reviewer never used | Always classified as "known pattern" | Routing decision log + novel task criteria in Step 6 | Solved |
| 5 | PlanMode replaced writing-plans | EnterPlanMode confusion | Explicit ban + exact Skill() call in Step 4 | Solved |
| 6 | No cycle limit enforcement | 6 bug-fix rounds (max 2) | Counter + hard stop in Step 6 Phase 3 | Solved |
| 7 | Explorer agents dispatched ad-hoc | Exploration outside pipeline | Formalized as Step 3 | Solved |
| 8 | Verification always skipped | 0/5 sessions called skill | Gate + exact Skill() call in Step 8 | Solved |
| 9 | Agents dispatched from main session | Main session bypassed Orchestrator | Flat dispatch -- dev-loop dispatches directly | Solved |
| 10 | Orchestrator never dispatched | 5/5 sessions self-orchestrated | Checkpoint assertion + flat dispatch | Solved |
| 11 | Bug-Fixer never dispatched | 3/3 sessions fixed directly | Checkpoint assertion in bug-fix command | Solved |
| 12 | Verification/Finishing-Branch skipped | End-of-pipeline completion momentum | Self-audit checklist + artifact gates | Solved |
| 13 | --auto = skip everything | Misinterpreted as "skip pipeline" | BAD/GOOD example pair in commands | Solved |
| 14 | Fix implemented via own failure mode | Silent fallback on Agent() failure | Fallback guidance: escalate, don't bypass | Solved |
| 15 | Orchestrator-as-subagent rejected | Agent tool unavailable at Level 1 | Flat dispatch from Level 0 | Solved |
| 16 | Review coverage 15% | Reviewer dispatch was separate optional step | auto-pair reviewer as atomic operation with engineer | Solved |
| 17 | Artifacts lost on worktree cleanup | Worktree removal deletes docs/ | Archive artifacts to main before removal | Solved |
| 18 | Bash gates ignored (4/5 sessions) | Gates are commands the model chooses to run | Replaced with structural enforcement (engineer self-review output requirement) | Solved |

---

## Summary: Structural Fixes > Prose Rules

| Approach | Effectiveness | Example |
|----------|--------------|---------|
| "You MUST do X" | Low — ignored in 100% of sessions | "You MUST dispatch sub-agents" |
| "Do NOT do X" | Low — ignored unless paired with structural fix | "Do NOT use Bash for file writes" |
| Remove the tool | High — physically impossible to violate | Removing Bash from Orchestrator |
| Show exact tool call | Medium-High — model copies the pattern | `Agent(subagent_type: "mas:engineer:engineer", ...)` template |
| Add file-existence gate | Medium — observable, harder to skip | "GATE: docs/tasks/done/ is non-empty" |
| BAD/GOOD example pair | Medium — concrete patterns stick better than abstract rules | BAD: `cat <<EOF`  GOOD: `Write(file_path: ...)` |
| Counter + hard stop | Medium — gives the model a variable to track | `review_cycle >= 2 → STOP` |
| Checkpoint assertion + audit data | Low — ignored in 4/5 sessions when model is in completion momentum | "STOP. This happened in 5/5 sessions." with real numbers |
| Engineer self-review output requirement | Medium-High — structural, engineer can't complete without producing the file | Gate: engineer must emit self-review artifact before task closes |
| Atomic dispatch pairing | Medium — enforced by template pattern, not by tool removal | Auto-pair reviewer with engineer in dispatch template |
| Eliminate broken nesting layer | High — proven by runtime constraint | Remove Orchestrator subagent, dispatch directly from Level 0 |

**When writing new agents or commands, prefer structural fixes over prose rules. If you catch yourself writing "MUST" or "NEVER", ask: can I remove a tool, add a gate, or show an example instead?**
