#!/bin/bash
# PreToolUse hook: validate Agent dispatch naming
# Blocks bare agent names (e.g., "engineer" instead of "mas:engineer:engineer")

# Read tool input from stdin
INPUT=$(cat)

# Extract tool name from environment
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"

# Only check Agent tool calls
if [ "$TOOL_NAME" != "Agent" ]; then
  exit 0
fi

# Extract subagent_type value
SUBAGENT_TYPE=$(echo "$INPUT" | grep -o '"subagent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"subagent_type"[[:space:]]*:[[:space:]]*"//' | sed 's/"//')

if [ -z "$SUBAGENT_TYPE" ]; then
  exit 0
fi

# Known MAS agent slugs that MUST use mas: prefix
BARE_NAMES="engineer reviewer bug-fixer researcher differential-reviewer ui-ux-designer reflect-agent orchestrator"

for name in $BARE_NAMES; do
  if [ "$SUBAGENT_TYPE" = "$name" ]; then
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
  echo "BLOCKED: mas:orchestrator:orchestrator is DEPRECATED since v2.0."
  echo "The dev-loop command IS the orchestrator. Do not dispatch this agent."
  exit 2
fi

exit 0
