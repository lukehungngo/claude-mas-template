#!/bin/bash
# Stop hook: Validate that the MAS pipeline actually ran
# Triggered on: Every session stop (non-blocking, informational)
#
# Checks for the presence of pipeline artifacts:
# - docs/results/TASK-*-result.md   (engineer agents dispatched)
# - docs/reports/TASK-*-review.md   (reviewer agents dispatched)
# - docs/reports/reflect-report.md  (reflect agent ran)
#
# If task specs exist but results/reviews don't, the pipeline was bypassed.
# This is the structural enforcement that dev-loop checkpoint assertions
# tried to achieve with prose (and failed in 5/5 sessions).

set -euo pipefail

# Check if we're in a dev-loop session (task specs exist)
TASK_SPECS=$( (find docs/tasks -name "TASK-*.md" 2>/dev/null || true) | wc -l | tr -d ' ')

# No task specs = not a dev-loop session, nothing to validate
if [ "$TASK_SPECS" = "0" ]; then
  exit 0
fi

RESULTS=$( (ls docs/results/TASK-*-result.md 2>/dev/null || true) | wc -l | tr -d ' ')
REVIEWS=$( (ls docs/reports/TASK-*-review.md 2>/dev/null || true) | wc -l | tr -d ' ')
REFLECT=$( (ls docs/reports/reflect-report.md 2>/dev/null || true) | wc -l | tr -d ' ')
SELF_REVIEWS=$( (ls docs/results/TASK-*-self-review.md 2>/dev/null || true) | wc -l | tr -d ' ')

WARNINGS=""

if [ "$RESULTS" = "0" ]; then
  WARNINGS="${WARNINGS}\n  ⚠ No engineer results found (docs/results/TASK-*-result.md) — agents may not have been dispatched"
fi

if [ "$REVIEWS" = "0" ]; then
  WARNINGS="${WARNINGS}\n  ⚠ No review reports found (docs/reports/TASK-*-review.md) — reviews may have been skipped"
fi

if [ "$RESULTS" != "$REVIEWS" ] && [ "$RESULTS" != "0" ] && [ "$REVIEWS" != "0" ]; then
  WARNINGS="${WARNINGS}\n  ⚠ Result/review count mismatch: ${RESULTS} results vs ${REVIEWS} reviews"
fi

if [ "$REFLECT" = "0" ]; then
  WARNINGS="${WARNINGS}\n  ⚠ No reflect report found (docs/reports/reflect-report.md)"
fi

if [ "$SELF_REVIEWS" = "0" ] && [ "$RESULTS" != "0" ]; then
  WARNINGS="${WARNINGS}\n  ⚠ No self-review files found (docs/results/TASK-*-self-review.md)"
fi

if [ -n "$WARNINGS" ]; then
  cat <<EOF
{"systemMessage": "Pipeline Validation:\n  Task specs: ${TASK_SPECS}\n  Engineer results: ${RESULTS}\n  Review reports: ${REVIEWS}\n  Self-reviews: ${SELF_REVIEWS}\n  Reflect report: ${REFLECT}\n${WARNINGS}\n\n  If task specs exist but artifacts don't, the pipeline was likely bypassed."}
EOF
else
  cat <<EOF
{"systemMessage": "Pipeline Validation: OK (${TASK_SPECS} tasks, ${RESULTS} results, ${REVIEWS} reviews, reflect: yes)"}
EOF
fi

# Always exit 0 — informational only
exit 0
