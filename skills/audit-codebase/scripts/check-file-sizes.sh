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

# One walk, one list. The extension and prune lists live here only, so the
# candidate list and both counts cannot drift apart.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
CANDIDATES="$WORK/candidates"
OVER="$WORK/over"

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
  2>/dev/null > "$CANDIDATES"

while IFS= read -r file; do
  lines=$(wc -l < "$file" 2>/dev/null || echo 0)
  if [ "$lines" -gt "$THRESHOLD" ]; then
    printf '%s\t%s\n' "$lines" "$file"
  fi
done < "$CANDIDATES" > "$OVER"

echo "=== Files exceeding ${THRESHOLD} lines (sorted by size) ==="
echo ""
sort -rn "$OVER" | head -30
echo ""
echo "--- Summary ---"
echo "Total files scanned: $(wc -l < "$CANDIDATES" | tr -d ' ')"
echo "Files over ${THRESHOLD} lines: $(wc -l < "$OVER" | tr -d ' ')"
echo ""
echo "=== Check complete ==="
