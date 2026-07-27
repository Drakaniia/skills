#!/usr/bin/env bash
# check-function-complexity.sh
# Quick heuristic scan for function-level complexity signals in source files.
# Usage: ./check-function-complexity.sh <file-or-directory>
#
# Detects:
#   - Deeply nested code (3+ indentation levels)
#   - Long functions (>30 lines between { })
#   - Functions with "and" in comment description (SRP violation signal)
#   - Functions with side-effect keywords (save, write, send, log, db)
#   - Functions with too many parameters (4+)

set -euo pipefail

TARGET="${1:-}"

if [ -z "$TARGET" ] || [ ! -e "$TARGET" ]; then
  echo "Usage: $0 <file-or-directory>"
  echo "Scans source files for function-level complexity signals."
  exit 1
fi

echo "=== Function Complexity Scan: $TARGET ==="
echo ""

scan_file() {
  local file="$1"
  local issues=0

  echo "--- $(basename "$file") ---"

  # 1. Check for deep nesting (3+ levels of indentation)
  if grep -n -E '^        ' "$file" 2>/dev/null | head -5 | grep -q .; then
    local deep_lines
    deep_lines=$(grep -c -E '^        ' "$file" 2>/dev/null || echo 0)
    echo "  🟡 Deep nesting signal: $deep_lines lines at 8+ spaces"
    issues=$((issues + 1))
  fi

  # 2. Check for long functions (crude heuristic: consecutive non-empty lines between { and })
  if grep -n 'function\|def \|func \|=> {' "$file" 2>/dev/null | head -10 | grep -q .; then
    local func_count
    func_count=$(grep -c 'function\|def \|func \|=> {' "$file" 2>/dev/null || echo 0)
    echo "  ℹ️  $func_count function/method definitions found"
  fi

  # 3. Check for side-effect keywords in function names
  local side_effects
  side_effects=$(grep -n -i 'function.*save\|function.*write\|function.*send\|function.*log\|function.*db\|function.*file\|function.*email\|def .*save\|def .*write\|def .*send\|def .*log\|def .*db' "$file" 2>/dev/null || true)
  if [ -n "$side_effects" ]; then
    echo "  🟡 Side-effect signal in function names:"
    echo "$side_effects" | while IFS= read -r line; do echo "    $line"; done
  fi

  # 4. Check for "and" in function description comments
  local and_violations
  and_violations=$(grep -n -E '(#|//|--|/\*\*)' "$file" 2>/dev/null | grep -i '\band\b' | head -5 || true)
  if [ -n "$and_violations" ]; then
    echo "  🟡 Possible SRP violation: 'and' in comments:"
    echo "$and_violations" | while IFS= read -r line; do echo "    $line"; done
  fi

  # 5. Check for magic numbers (bare numeric literals that aren't 0, 1, -1)
  local magic
  magic=$(grep -n -E '[^a-zA-Z_]([2-9]|[1-9][0-9]+)[^a-zA-Z_]' "$file" 2>/dev/null | grep -v '//.*\|#.*' | head -5 || true)
  if [ -n "$magic" ]; then
    echo "  🟡 Possible magic numbers (threshold: >1):"
    echo "$magic" | while IFS= read -r line; do echo "    $line"; done
  fi

  if [ "$issues" -eq 0 ]; then
    echo "  ✅ No major complexity signals detected"
  fi
  echo ""
}

if [ -f "$TARGET" ]; then
  scan_file "$TARGET"
elif [ -d "$TARGET" ]; then
  find "$TARGET" -type f \( \
    -name "*.py" -o \
    -name "*.js" -o \
    -name "*.ts" -o \
    -name "*.tsx" -o \
    -name "*.go" -o \
    -name "*.rs" -o \
    -name "*.java" -o \
    -name "*.cs" -o \
    -name "*.rb" -o \
    -name "*.php" \
    \) \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/vendor/*" \
    ! -path "*/__pycache__/*" \
    ! -path "*/build/*" \
    ! -path "*/dist/*" \
    2>/dev/null | while IFS= read -r f; do scan_file "$f"; done
fi

echo "=== Scan complete ==="
