#!/bin/bash
# PreToolUse hook: Suggest /compact at strategic intervals
# Triggered on: Edit, Write, Bash tool uses
#
# Adapted from ECC's suggest-compact.js. Tracks tool call count per
# session and suggests /compact at configurable intervals.
#
# Why manual over auto-compact:
# - Auto-compact happens at arbitrary points, often mid-task
# - Strategic compacting preserves context through logical phases
#
# CUSTOMIZE: Adjust COMPACT_THRESHOLD (default: 50)

set -euo pipefail

COMPACT_THRESHOLD="${COMPACT_THRESHOLD:-50}"
COMPACT_INTERVAL=25

SESSION_ID="${CLAUDE_SESSION_ID:-default}"
SESSION_ID=$(echo "$SESSION_ID" | tr -cd 'a-zA-Z0-9_-')
COUNTER_FILE="${TMPDIR:-/tmp}/claude-tool-count-${SESSION_ID}"

# Read current count
COUNT=0
if [ -f "$COUNTER_FILE" ]; then
  COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
  # Validate count is a number
  if ! [[ "$COUNT" =~ ^[0-9]+$ ]]; then
    COUNT=0
  fi
fi

COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

if [ "$COUNT" -eq "$COMPACT_THRESHOLD" ]; then
  echo "[StrategicCompact] ${COMPACT_THRESHOLD} tool calls — consider /compact if transitioning phases" >&2
fi

if [ "$COUNT" -gt "$COMPACT_THRESHOLD" ]; then
  PAST=$((COUNT - COMPACT_THRESHOLD))
  if [ $((PAST % COMPACT_INTERVAL)) -eq 0 ]; then
    echo "[StrategicCompact] ${COUNT} tool calls — good checkpoint for /compact if context is stale" >&2
  fi
fi

exit 0
