#!/usr/bin/env bash
# scan-codebase.sh
# Scans a codebase directory for structural metrics.
# Usage: ./scan-codebase.sh [target-dir]
#
# Outputs:
#   - File count per directory (sorted by count descending)
#   - Listing of empty directories
#   - Source file count by extension

set -euo pipefail

TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: '$TARGET_DIR' is not a directory" >&2
  exit 1
fi

echo "=== Codebase Scan: $TARGET_DIR ==="
echo ""

# 1. File count per directory
echo "--- Files per Directory (top 20) ---"
find "$TARGET_DIR" -type f \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/vendor/*" \
  ! -path "*/.venv/*" \
  ! -path "*/__pycache__/*" \
  ! -path "*/build/*" \
  ! -path "*/dist/*" \
  ! -path "*/target/*" \
  ! -path "*/.next/*" \
  ! -path "*/.codegraph/*" \
  2>/dev/null | \
  sed 's|/[^/]*$||' | \
  sort | \
  uniq -c | \
  sort -rn | \
  head -20

echo ""

# 2. Empty directories
echo "--- Empty Directories ---"
find "$TARGET_DIR" -type d \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/vendor/*" \
  ! -path "*/.venv/*" \
  ! -path "*/__pycache__/*" \
  -empty 2>/dev/null || echo "(none)"

echo ""

# 3. Source file count by extension
echo "--- Source Files by Extension ---"
find "$TARGET_DIR" -type f \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/vendor/*" \
  ! -path "*/.venv/*" \
  ! -path "*/__pycache__/*" \
  ! -path "*/build/*" \
  ! -path "*/dist/*" \
  ! -path "*/target/*" \
  2>/dev/null | \
  sed 's/.*\.//' | \
  sort | \
  uniq -c | \
  sort -rn | \
  head -15

echo ""
echo "=== Scan complete ==="
