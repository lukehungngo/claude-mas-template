#!/bin/bash
# MAS Template Static Analysis — Tier 1 Tests
# Run after every commit to catch regressions.
# Usage: bash tests/lint.sh
# Exit code: 0 = all pass, 1 = failures found

set -euo pipefail

PASS=0
FAIL=0
WARN=0

pass() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  ~ $1"; WARN=$((WARN + 1)); }

echo "═══════════════════════════════════════════"
echo "  MAS Template — Static Analysis (Tier 1)"
echo "═══════════════════════════════════════════"
echo ""

# ─── 1. No unprefixed agent dispatches ───────────────────
echo "1. Agent dispatch prefix consistency"
UNPREFIXED=$(grep -rn 'subagent_type:' --include="*.md" agents/ commands/ templates/ skills/ CLAUDE.md 2>/dev/null | grep -v "mas:\|Explore\|orchestrator" || true)
if [ -z "$UNPREFIXED" ]; then
  pass "All agent dispatches use mas: prefix (or Explore built-in)"
else
  fail "Unprefixed agent dispatches found:"
  echo "$UNPREFIXED" | sed 's/^/       /'
fi

# ─── 2. No stale .claude/templates/ paths ────────────────
echo "2. Template path consistency"
STALE_PATHS=$(grep -rn '\.claude/templates/' --include="*.md" agents/ commands/ templates/ skills/ rules/ CLAUDE.md 2>/dev/null || true)
if [ -z "$STALE_PATHS" ]; then
  pass "No stale .claude/templates/ paths"
else
  fail "Stale .claude/templates/ paths found:"
  echo "$STALE_PATHS" | sed 's/^/       /'
fi

# ─── 3. No placeholders in rules ─────────────────────────
echo "3. Rules placeholder check"
RULE_PLACEHOLDERS=$(grep -rn '{{' rules/ --include="*.md" 2>/dev/null || true)
if [ -z "$RULE_PLACEHOLDERS" ]; then
  pass "No placeholders in rules (all universal)"
else
  fail "Placeholders found in rules:"
  echo "$RULE_PLACEHOLDERS" | sed 's/^/       /'
fi

# ─── 4. No active Orchestrator dispatches ─────────────────
echo "4. Orchestrator deprecation check"
ORCH_DISPATCH=$(grep -rn 'subagent_type.*orchestrator' commands/ templates/ CLAUDE.md --include="*.md" 2>/dev/null || true)
if [ -z "$ORCH_DISPATCH" ]; then
  pass "No active Orchestrator dispatches (deprecated)"
else
  fail "Active Orchestrator dispatches found:"
  echo "$ORCH_DISPATCH" | sed 's/^/       /'
fi

# ─── 5. No Orchestrator refs in active agents ─────────────
echo "5. Orchestrator references in active agents"
ORCH_REFS=$(grep -in "orchestrator" agents/engineer/CLAUDE.md agents/reviewer/CLAUDE.md agents/researcher/CLAUDE.md agents/ui-ux-designer/CLAUDE.md agents/bug-fixer/CLAUDE.md agents/differential-reviewer/CLAUDE.md 2>/dev/null || true)
if [ -z "$ORCH_REFS" ]; then
  pass "No Orchestrator references in active agent files"
else
  fail "Orchestrator references in active agents:"
  echo "$ORCH_REFS" | sed 's/^/       /'
fi

# ─── 6. Cross-references resolve ──────────────────────────
echo "6. Cross-reference integrity"
REFS_OK=true

# Check files referenced by commands
for ref in "templates/dispatch-templates.md" "templates/task-spec.md" "templates/review-report.md" "rules/agent-workflow.md" "rules/severity-discipline.md" "rules/honesty-first.md"; do
  if [ ! -f "$ref" ]; then
    fail "Referenced file missing: $ref"
    REFS_OK=false
  fi
done

# Check agent files exist
for agent in engineer reviewer researcher differential-reviewer bug-fixer ui-ux-designer orchestrator; do
  if [ ! -f "agents/$agent/CLAUDE.md" ]; then
    fail "Agent file missing: agents/$agent/CLAUDE.md"
    REFS_OK=false
  fi
done

if $REFS_OK; then
  pass "All cross-referenced files exist"
fi

# ─── 7. Line count budgets ────────────────────────────────
echo "7. File size budgets"
check_lines() {
  local file=$1 max=$2
  if [ -f "$file" ]; then
    local lines
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -le "$max" ]; then
      pass "$file: $lines lines (budget: $max)"
    else
      warn "$file: $lines lines EXCEEDS budget of $max"
    fi
  fi
}

check_lines "commands/dev-loop.md" 500
check_lines "commands/bug-fix.md" 300
check_lines "rules/agent-workflow.md" 100
check_lines "commands/bootstrap.md" 250

# ─── 8. No file-copying in bootstrap ──────────────────────
echo "8. Bootstrap is lightweight"
COPY_REFS=$(grep -in "copy.*agents\|copy.*skills\|copy.*commands\|Step 0" commands/bootstrap.md 2>/dev/null || true)
if [ -z "$COPY_REFS" ]; then
  pass "Bootstrap does not copy agent/skill/command files"
else
  fail "Bootstrap still references file copying:"
  echo "$COPY_REFS" | sed 's/^/       /'
fi

# ─── 9. architecture.md removed ───────────────────────────
echo "9. Template rules removed"
if [ ! -f "rules/architecture.md" ]; then
  pass "rules/architecture.md removed (was template, not universal)"
else
  fail "rules/architecture.md still exists (should be removed)"
fi

# ─── 10. Dispatch templates have all 6 agents ─────────────
echo "10. Dispatch template completeness"
TEMPLATE_FILE="templates/dispatch-templates.md"
MISSING_TEMPLATES=""
for agent in "mas:researcher:researcher" "mas:differential-reviewer:differential-reviewer" "mas:engineer:engineer" "mas:reviewer:reviewer" "mas:bug-fixer:bug-fixer" "mas:ui-ux-designer:ui-ux-designer"; do
  if ! grep -q "$agent" "$TEMPLATE_FILE" 2>/dev/null; then
    MISSING_TEMPLATES="$MISSING_TEMPLATES $agent"
  fi
done

if [ -z "$MISSING_TEMPLATES" ]; then
  pass "All 6 agent templates present in dispatch-templates.md"
else
  fail "Missing templates:$MISSING_TEMPLATES"
fi

# ─── 11. CLAUDE.md has flat dispatch in step 6 ────────────
echo "11. CLAUDE.md architecture consistency"
if grep -q "flat dispatch\|routing table" CLAUDE.md 2>/dev/null; then
  pass "CLAUDE.md step 6 references flat dispatch"
else
  fail "CLAUDE.md step 6 does not reference flat dispatch"
fi

# ─── 12. No duplicate severity tables ─────────────────────
echo "12. Single source of truth for severity"
SEVERITY_TABLES=$(grep -rn "P0.*correctness bug\|P0.*confirmed exploitable\|CRITICAL.*P0.*Confirmed" agents/ commands/ --include="*.md" 2>/dev/null || true)
if [ -z "$SEVERITY_TABLES" ]; then
  pass "No duplicate severity tables (single source: severity-discipline.md)"
else
  warn "Possible duplicate severity definitions:"
  echo "$SEVERITY_TABLES" | sed 's/^/       /'
fi

# ─── Summary ──────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "═══════════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
  echo "  STATUS: FAIL"
  exit 1
else
  echo "  STATUS: PASS"
  exit 0
fi
