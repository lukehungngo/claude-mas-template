# TASK-{id}: {title}

## Meta
- **id:** TASK-{id}
- **size:** micro | standard | complex
  - `micro` — 1 file, ≤20 lines, no new API surface → quick review, skip reflect + delivery report
  - `standard` — multi-file, known pattern → full pipeline
  - `complex` — novel algorithm, new boundary, competing trade-offs → researcher → deep review + reflect
- **type:** research | design | impl | review | bugfix
- **agent:** engineer | reviewer | researcher | differential-reviewer | bug-fixer | ui-ux-designer
- **status:** pending | in-progress | done | blocked
- **depends_on:** [TASK-xxx, ...]
- **parallel_safe:** true | false
- **priority:** P0 | P1 | P2

## Context
- **relevant_files:** [exact file paths WITH line ranges — e.g., `src/auth.ts:45-80`, `lib/utils.py:12-35`]
- **do_not_touch:** [adjacent files that MUST NOT be modified — be explicit]
- **reference_files:** [files to read for context only, not modify]
- **proposal:** [path to approved research proposal in `docs/plans/`, if applicable]
- **design_spec:** [path to approved design spec in `docs/design/`, if applicable — only for UI tasks]
- **success_test:** `{exact test command}` — assert `{specific value}` at `{file:line}`
  - Example: `pytest tests/auth_test.py::test_rate_limit_returns_429 -v` — assert response.status_code == 429
- **contract:** `{exact function/API signature}` → `{return type}` raises `{error types}`
  - Example: `def validate_token(token: str, secret: str) -> TokenPayload` raises `InvalidTokenError`

## Objective

{One paragraph max. What should be built/fixed/researched and why.}

## Acceptance Criteria

Each criterion MUST be a runnable shell command:

- [ ] `{{test-command}}` passes
- [ ] `{{lint-command}}` clean
- [ ] `{{typecheck-command}}` clean
- [ ] `{specific functional check}` — e.g., `curl localhost:8080/api/health | jq .status`

## Business Context

{Link to original requirement, OKR, issue, or user story. Why does this matter?}

## Output

Write result based on task type:
- **research** → `docs/plans/TASK-{id}-research-r{round}.md`
- **design** → `docs/design/TASK-{id}-design.md` + `docs/design/TASK-{id}-mockup.html`
- **impl** → `docs/results/TASK-{id}-result.md`
- **review** → `docs/reports/TASK-{id}-review.md`
- **bugfix** → `docs/reports/TASK-{id}-bugfix-result.md`
