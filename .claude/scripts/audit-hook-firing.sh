#!/bin/bash
# Audit script: check if validate-dispatch hook is firing and catch bare-after-block patterns
# Usage: bash .claude/scripts/audit-hook-firing.sh

LOG="${HOME}/.claude/hook-debug.log"

if [ ! -f "$LOG" ]; then
  echo "No hook debug log found at $LOG"
  echo "Run a session with the updated validate-dispatch.sh first."
  exit 1
fi

echo "=== Hook Debug Log Analysis ==="
echo "Log: $LOG"
echo "Total entries: $(wc -l < "$LOG")"
echo ""

echo "--- Dispatch Decisions ---"
ALLOWED=$(grep -c "ALLOWED:" "$LOG" 2>/dev/null || echo 0)
BLOCKED=$(grep -c "BLOCKED" "$LOG" 2>/dev/null || echo 0)
echo "Allowed: $ALLOWED"
echo "Blocked: $BLOCKED"
if [ "$((ALLOWED + BLOCKED))" -gt 0 ]; then
  BLOCK_RATE=$(awk "BEGIN {printf \"%.1f\", $BLOCKED * 100 / ($ALLOWED + $BLOCKED)}")
  echo "Block rate: ${BLOCK_RATE}%"
fi
echo ""

echo "--- Blocked Agent Types ---"
grep "BLOCKED bare name:" "$LOG" | sed 's/.*BLOCKED bare name: //' | sort | uniq -c | sort -rn
echo ""

echo "--- Allowed Agent Types ---"
grep "ALLOWED:" "$LOG" | sed 's/.*ALLOWED: //' | sort | uniq -c | sort -rn
echo ""

echo "--- Consecutive Bare Name Retries (model retrying after block) ---"
python3 - <<'PYEOF' 2>/dev/null || echo "  (python3 not available)"
import re, os
log_path = os.path.expanduser("~/.claude/hook-debug.log")
lines = open(log_path).readlines()
prev_blocked = None
retries = 0
for line in lines:
    m = re.search(r'BLOCKED bare name: (\S+)', line)
    if m:
        name = m.group(1)
        if prev_blocked == name:
            retries += 1
            print(f'  Retry detected: {name} blocked twice consecutively')
        prev_blocked = name
    elif 'ALLOWED' in line:
        prev_blocked = None
print(f'Total retry patterns: {retries}')
PYEOF
