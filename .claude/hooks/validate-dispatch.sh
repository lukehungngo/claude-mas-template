#!/bin/bash
# PreToolUse hook: validate Agent dispatch naming
# Blocks bare agent names (e.g., "engineer" instead of "mas:engineer:engineer")

# Read tool input from stdin
INPUT=$(cat)

# Extract tool name from environment
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"

# Debug logging — appends to ~/.claude/hook-debug.log
DEBUG_LOG="${HOME}/.claude/hook-debug.log"
_debug() {
  echo "[$(date '+%Y-%m-%dT%H:%M:%S')] validate-dispatch: $*" >> "$DEBUG_LOG" 2>/dev/null || true
}

# Only check Agent tool calls
if [ "$TOOL_NAME" != "Agent" ]; then
  exit 0
fi

# Extract subagent_type value
SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"subagent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"subagent_type"[[:space:]]*:[[:space:]]*"//' | sed 's/"//')

# Extract model value
MODEL=$(echo "$INPUT" | grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"model"[[:space:]]*:[[:space:]]*"//' | sed 's/"//')

if [ -z "$SUBAGENT_TYPE" ]; then
  exit 0
fi

_debug "TOOL_NAME='${TOOL_NAME}' SUBAGENT_TYPE='${SUBAGENT_TYPE}'"

# Known MAS agent slugs that MUST use mas: prefix
BARE_NAMES="engineer reviewer bug-fixer researcher differential-reviewer ui-ux-designer reflect-agent orchestrator"

for name in $BARE_NAMES; do
  if [ "$SUBAGENT_TYPE" = "$name" ]; then
    _debug "BLOCKED bare name: ${SUBAGENT_TYPE}"
    echo "BLOCKED: Bare agent name '$name' detected."
    echo "Use 'mas:${name}:${name}' instead."
    echo ""
    echo "Quick reference:"
    echo "  BAD:  Agent(subagent_type: \"$name\")"
    echo "  GOOD: Agent(subagent_type: \"mas:${name}:${name}\")"
    exit 2
  fi
done

# Block deprecated orchestrator
if [ "$SUBAGENT_TYPE" = "mas:orchestrator:orchestrator" ]; then
  _debug "BLOCKED deprecated orchestrator"
  echo "BLOCKED: mas:orchestrator:orchestrator is DEPRECATED since v2.0."
  echo "The dev-loop command IS the orchestrator. Do not dispatch this agent."
  exit 2
fi

# Block general agent — use Explore (haiku) for discovery or a MAS specialist instead
if [ "$SUBAGENT_TYPE" = "general" ]; then
  _debug "BLOCKED general agent"
  cat <<'BLOCKED_MSG'
BLOCKED: 'general' is not a valid dispatch in the MAS pipeline.

Use a specific agent instead:
  Discovery / codebase search:  Agent(subagent_type: "Explore")
  Implementation:                Agent(subagent_type: "mas:engineer:engineer")
  Code review:                   Agent(subagent_type: "mas:reviewer:reviewer")
  Research:                      Agent(subagent_type: "mas:researcher:researcher")
  Bug fix:                       Agent(subagent_type: "mas:bug-fixer:bug-fixer")
BLOCKED_MSG
  exit 2
fi

# Block standard/deep reviewer on Haiku — those depths require judgment
if [ "$SUBAGENT_TYPE" = "mas:reviewer:reviewer" ] && echo "$MODEL" | grep -qi "haiku"; then
  # Extract depth from prompt field to allow quick+haiku
  PROMPT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('prompt',''))" 2>/dev/null || echo "")
  DEPTH=$(echo "$PROMPT" | grep -oi 'depth:[[:space:]]*[a-z]*' | head -1 | sed 's/depth:[[:space:]]*//' | tr '[:upper:]' '[:lower:]')
  if [ "$DEPTH" != "quick" ]; then
    _debug "BLOCKED reviewer on haiku (depth=${DEPTH:-standard}): ${MODEL}"
    cat <<EOF
BLOCKED: mas:reviewer:reviewer cannot run on Haiku for standard/deep reviews.
Depth '${DEPTH:-standard}' requires minimum model: sonnet.

Options:
  1. Use model: "sonnet" for standard/deep review
  2. Set depth: quick in prompt if this is truly a trivial change (grep-only scan)

BAD:  Agent(subagent_type: "mas:reviewer:reviewer", model: "haiku")
GOOD: Agent(subagent_type: "mas:reviewer:reviewer", model: "sonnet")
EOF
    exit 2
  fi
fi

# Block reflect re-dispatch if any reflect report already exists
if [ "$SUBAGENT_TYPE" = "mas:reflect-agent:reflect-agent" ]; then
  EXISTING_REFLECT=$(ls "${CLAUDE_PROJECT_DIR}/docs/reports/"*-reflect-report.md 2>/dev/null | head -1)
  if [ -n "$EXISTING_REFLECT" ]; then
    _debug "BLOCKED reflect re-dispatch (report exists: $EXISTING_REFLECT)"
    echo "BLOCKED: Reflect agent already ran ($(basename "$EXISTING_REFLECT") exists)."
    echo "Dispatch-exactly-once constraint: reflect runs exactly once per dev-loop session."
    echo "To re-run reflect, delete the existing reflect report first."
    exit 2
  fi
fi

_debug "ALLOWED: ${SUBAGENT_TYPE}"
exit 0
