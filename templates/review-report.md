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
