#!/bin/bash
# Stop hook: Validate that the MAS pipeline actually ran
# Triggered on: Every session stop (non-blocking, informational)
#
# Checks for the presence of pipeline artifacts:
# - docs/results/TASK-*-result.md   (engineer agents dispatched)
# - docs/reports/TASK-*-review.md   (reviewer agents dispatched)
# - docs/reports/reflect-report.md  (reflect agent ran)
#
# If a plan exists but results/reviews don't, the pipeline was bypassed.
# This is the structural enforcement that dev-loop checkpoint assertions
# tried to achieve with prose (and failed in 5/5 sessions).

set -euo pipefail

# Check if an active pipeline is in progress (results or reviews exist)
# Plans persist on main after merge, so their presence alone does NOT mean a pipeline is active.
RESULTS=$( (ls docs/results/TASK-*-result.md 2>/dev/null || true) | wc -l | tr -d ' ')
REVIEWS=$( (ls docs/reports/TASK-*-review.md 2>/dev/null || true) | wc -l | tr -d ' ')

# No results AND no reviews = no active pipeline, nothing to validate
if [ "$RESULTS" = "0" ] && [ "$REVIEWS" = "0" ]; then
  exit 0
fi

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

# Sentinel escape hatch: if .reflect-skipped exists with a non-empty reason, skip blocking
SENTINEL="docs/reports/.reflect-skipped"
if [ -f "$SENTINEL" ]; then
  REASON=$(head -1 "$SENTINEL" | tr -d '\n')
  if [ -n "$REASON" ]; then
    cat <<EOF
{"systemMessage": "Pipeline Validation: reflect skipped (intentional).\n  Reason: ${REASON}\n  To require reflect again, delete docs/reports/.reflect-skipped"}
EOF
    exit 0
  fi
fi

# Block session end only when a full pipeline ran but reflect was skipped
# Condition: a plan + results + reviews all present, but NO reflect report
if [ "$RESULTS" != "0" ] && [ "$REVIEWS" != "0" ] && [ "$REFLECT" = "0" ]; then
  cat <<EOF
{"systemMessage": "Pipeline Validation BLOCKED:\n  Engineer results: ${RESULTS}\n  Review reports: ${REVIEWS}\n  Reflect report: MISSING ← REQUIRED\n\n  A full pipeline ran (results + reviews present) but the reflect agent was never dispatched.\n  Run: Agent(subagent_type: 'mas:reflect-agent:reflect-agent', ...)\n  Then save the verdict to docs/reports/reflect-report.md before ending this session."}
EOF
  exit 2
fi

# Warn only (non-blocking) for partial pipeline issues
if [ -n "$WARNINGS" ]; then
  cat <<EOF
{"systemMessage": "Pipeline Validation:\n  Engineer results: ${RESULTS}\n  Review reports: ${REVIEWS}\n  Self-reviews: ${SELF_REVIEWS}\n  Reflect report: ${REFLECT}\n${WARNINGS}"}
EOF
fi

exit 0
