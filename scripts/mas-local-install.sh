#!/usr/bin/env bash
# mas-local-install.sh — Install MAS pipeline routing to a team repo without touching its CLAUDE.md
#
# Usage:
#   mas-local-install.sh <project-dir> [--has-ui]
#   mas-local-install.sh /Users/soh/working/eduquest
#   mas-local-install.sh /Users/soh/working/aitomatic/dana/desktop --has-ui
#   mas-local-install.sh --list          # show all installed projects
#   mas-local-install.sh --uninstall <project-dir>
#
# What it does:
#   Copies templates/local-inject.md to ~/.claude/projects/<path-hash>/CLAUDE.md
#   This file is loaded by Claude Code as user-local project instructions,
#   alongside whatever CLAUDE.md the team repo already has.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/../templates" && pwd)"
TEMPLATE="$TEMPLATE_DIR/local-inject.md"
CLAUDE_DIR="$HOME/.claude/projects"

# Convert absolute path to Claude Code's project directory key
# Claude Code uses the path with / replaced by - and leading - stripped
path_to_key() {
  local p="$1"
  # Resolve to absolute path
  p="$(cd "$p" && pwd)"
  # Replace / with - (Claude Code convention)
  echo "$p" | sed 's|/|-|g'
}

usage() {
  echo "Usage: mas-local-install.sh <project-dir> [--has-ui]"
  echo "       mas-local-install.sh --list"
  echo "       mas-local-install.sh --uninstall <project-dir>"
  echo ""
  echo "Installs MAS pipeline routing as local-only CLAUDE.md for team repos."
  echo "Does NOT modify the repo's own CLAUDE.md."
  exit 1
}

list_installed() {
  echo "MAS local installs:"
  echo ""
  found=0
  for dir in "$CLAUDE_DIR"/*/; do
    [ -d "$dir" ] || continue
    if [ -f "$dir/CLAUDE.md" ]; then
      if grep -q "MAS Pipeline" "$dir/CLAUDE.md" 2>/dev/null; then
        key=$(basename "$dir")
        # Convert key back to path for display
        path=$(echo "$key" | sed 's|^-||; s|-|/|g')
        has_ui="false"
        if grep -q 'has_ui:\*\* true' "$dir/CLAUDE.md" 2>/dev/null; then
          has_ui="true"
        fi
        echo "  $path (has_ui: $has_ui)"
        found=1
      fi
    fi
  done
  if [ "$found" -eq 0 ]; then
    echo "  (none)"
  fi
}

# Handle --list
if [ "${1:-}" = "--list" ]; then
  list_installed
  exit 0
fi

# Handle --uninstall
if [ "${1:-}" = "--uninstall" ]; then
  [ -z "${2:-}" ] && usage
  PROJECT_DIR="$2"
  [ ! -d "$PROJECT_DIR" ] && echo "Error: $PROJECT_DIR is not a directory" && exit 1
  KEY=$(path_to_key "$PROJECT_DIR")
  TARGET="$CLAUDE_DIR/$KEY/CLAUDE.md"
  if [ -f "$TARGET" ]; then
    rm "$TARGET"
    echo "Removed MAS local config for: $PROJECT_DIR"
  else
    echo "No MAS local config found for: $PROJECT_DIR"
  fi
  exit 0
fi

# Require project dir
[ -z "${1:-}" ] && usage
PROJECT_DIR="$1"
HAS_UI="${2:-}"

[ ! -d "$PROJECT_DIR" ] && echo "Error: $PROJECT_DIR is not a directory" && exit 1
[ ! -f "$TEMPLATE" ] && echo "Error: Template not found at $TEMPLATE" && exit 1

# Compute target path
KEY=$(path_to_key "$PROJECT_DIR")
TARGET_DIR="$CLAUDE_DIR/$KEY"
TARGET="$TARGET_DIR/CLAUDE.md"

# Create directory if needed
mkdir -p "$TARGET_DIR"

# Check for existing non-MAS CLAUDE.md
if [ -f "$TARGET" ]; then
  if ! grep -q "MAS Pipeline" "$TARGET" 2>/dev/null; then
    echo "Warning: $TARGET already exists and is NOT a MAS overlay."
    echo "Existing content will be preserved with MAS appended."
    echo ""
    # Append MAS section to existing file
    echo "" >> "$TARGET"
    echo "<!-- MAS Pipeline overlay (auto-installed by mas-local-install.sh) -->" >> "$TARGET"
    cat "$TEMPLATE" >> "$TARGET"
    echo "Appended MAS pipeline to existing: $TARGET"
    exit 0
  else
    echo "Updating existing MAS overlay..."
  fi
fi

# Copy template
cp "$TEMPLATE" "$TARGET"

# Set has_ui if requested
if [ "$HAS_UI" = "--has-ui" ]; then
  sed -i '' 's/has_ui:.* false/has_ui:** true/' "$TARGET"
  echo "Set has_ui: true"
fi

echo "Installed MAS pipeline to: $TARGET"
echo "Project: $PROJECT_DIR"
echo ""
echo "This is a local-only config. It will NOT be committed to the team repo."
echo "Claude Code will load it alongside the repo's own CLAUDE.md."
