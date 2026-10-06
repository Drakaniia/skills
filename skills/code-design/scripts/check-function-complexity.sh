#!/usr/bin/env bash
# check-function-complexity.sh
# Quick heuristic scan for function-level complexity signals in source files.
# Usage: ./check-function-complexity.sh <file-or-directory>
#
# Detects:
#   - Deeply nested code (3+ indentation levels)
#   - Side-effect keywords in definition names (save, write, send, log, db, ...)
#
# Both checks are signals, not verdicts — a warning here means read the
# function, not that it must be split. Earlier versions also grepped every
# comment for the word "and" and every numeric literal for a magic number;
# both fired on ordinary code and were removed.

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

  echo "--- $(basename "$file") ---"

  # 1. Deep nesting: lines indented 8+ spaces.
  local deep
  deep=$(grep -c -E '^ {8}' "$file" 2>/dev/null || echo 0)
  if [ "$deep" -gt 0 ]; then
    echo "  🟡 Deep nesting signal: $deep lines at 8+ spaces"
  fi

  # 2. Side effects named in a definition line — read the boundary, don't assume.
  local side_effects
  side_effects=$(grep -n -iE '(function|def |func )\w*\w*(save|write|send|log|db|email|file)\w*' "$file" 2>/dev/null | head -5 || true)
  if [ -n "$side_effects" ]; then
    echo "  🟡 Side-effect signal in definition lines:"
    echo "$side_effects" | while IFS= read -r line; do echo "    $line"; done
  fi

  if [ "$deep" -eq 0 ] && [ -z "$side_effects" ]; then
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
