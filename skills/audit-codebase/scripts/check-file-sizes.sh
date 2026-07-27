#!/usr/bin/env bash
# check-file-sizes.sh
# Find oversized source files in a codebase.
# Usage: ./check-file-sizes.sh [target-dir] [threshold=400]
#
# Outputs files sorted by line count (largest first).
# Default threshold: 400 lines (matching the audit-codebase skill default).

set -euo pipefail

TARGET_DIR="${1:-.}"
THRESHOLD="${2:-400}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: '$TARGET_DIR' is not a directory" >&2
  exit 1
fi

echo "=== Files exceeding ${THRESHOLD} lines (sorted by size) ==="
echo ""

find "$TARGET_DIR" -type f \( \
  -name "*.py" -o \
  -name "*.js" -o \
  -name "*.jsx" -o \
  -name "*.ts" -o \
  -name "*.tsx" -o \
  -name "*.go" -o \
  -name "*.rs" -o \
  -name "*.java" -o \
  -name "*.cs" -o \
  -name "*.rb" -o \
  -name "*.php" -o \
  -name "*.c" -o \
  -name "*.cpp" -o \
  -name "*.h" -o \
  -name "*.hpp" \
  \) \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/vendor/*" \
  ! -path "*/.venv/*" \
  ! -path "*/__pycache__/*" \
  ! -path "*/build/*" \
  ! -path "*/dist/*" \
  ! -path "*/target/*" \
  ! -path "*/.codegraph/*" \
  2>/dev/null | \
  while IFS= read -r file; do
    lines=$(wc -l < "$file" 2>/dev/null || echo 0)
    if [ "$lines" -gt "$THRESHOLD" ]; then
      echo "${lines}	${file}"
    fi
  done | sort -rn | head -30

echo ""
echo "--- Summary ---"
total=$(find "$TARGET_DIR" -type f \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/vendor/*" \
  ! -path "*/.venv/*" \
  ! -path "*/__pycache__/*" \
  ! -path "*/build/*" \
  ! -path "*/dist/*" \
  ! -path "*/target/*" \
  ! -path "*/.codegraph/*" \
  2>/dev/null | wc -l)
echo "Total files scanned: $total"
echo "Files over ${THRESHOLD} lines: $(find "$TARGET_DIR" -type f \( -name "*.py" -o -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.cs" -o -name "*.rb" -o -name "*.php" -o -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/vendor/*" ! -path "*/.venv/*" ! -path "*/__pycache__/*" ! -path "*/build/*" ! -path "*/dist/*" ! -path "*/target/*" ! -path "*/.codegraph/*" 2>/dev/null | while IFS= read -r file; do lines=$(wc -l < "$file" 2>/dev/null || echo 0); [ "$lines" -gt "$THRESHOLD" ] && echo "$file"; done | wc -l)"

echo ""
echo "=== Check complete ==="
