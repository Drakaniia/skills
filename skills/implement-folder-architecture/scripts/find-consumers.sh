#!/usr/bin/env bash
# find-consumers.sh
# Find all files that import from a given module path.
# Usage: ./find-consumers.sh <module-path> [target-dir]
#
# Example: ./find-consumers.sh src/utils/string_utils .
#
# Supports: Python, JavaScript/TypeScript, Go, Rust, Java, C#, Ruby, PHP

set -euo pipefail

MODULE_PATH="${1:-}"
TARGET_DIR="${2:-.}"

if [ -z "$MODULE_PATH" ]; then
  echo "Usage: $0 <module-path> [target-dir]"
  echo "Finds all files that import from a given module path."
  echo ""
  echo "Examples:"
  echo "  $0 src/utils/string_utils ."
  echo "  $0 order_service ./src"
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: '$TARGET_DIR' is not a directory" >&2
  exit 1
fi

# Extract the module name (last component of path)
MODULE_NAME=$(basename "$MODULE_PATH")
# Extract the directory path for relative import patterns
MODULE_DIR=$(dirname "$MODULE_PATH")

echo "=== Consumers of '$MODULE_PATH' ==="
echo ""

found=0

# Python imports
echo "--- Python (.py) ---"
grep -r -l "from .*${MODULE_NAME}\|import.*${MODULE_NAME}" \
  --include="*.py" \
  "$TARGET_DIR" 2>/dev/null | grep -v "*/node_modules/*" | grep -v "*/.git/*" | head -20 || echo "(none)"
echo ""

# JavaScript/TypeScript imports
echo "--- JS/TS (.js, .ts, .tsx, .jsx) ---"
grep -r -l "from ['\"].*${MODULE_NAME}['\"]\|require(['\"].*${MODULE_NAME}['\"]" \
  --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx" \
  "$TARGET_DIR" 2>/dev/null | grep -v "*/node_modules/*" | grep -v "*/.git/*" | head -20 || echo "(none)"
echo ""

# Go imports
echo "--- Go (.go) ---"
grep -r -l "\"${MODULE_PATH}\|\"${MODULE_DIR}.*${MODULE_NAME}" \
  --include="*.go" \
  "$TARGET_DIR" 2>/dev/null | grep -v "*/node_modules/*" | grep -v "*/.git/*" | head -20 || echo "(none)"
echo ""

# Rust imports
echo "--- Rust (.rs) ---"
grep -r -l "use.*${MODULE_NAME}" \
  --include="*.rs" \
  "$TARGET_DIR" 2>/dev/null | grep -v "*/node_modules/*" | grep -v "*/.git/*" | head -20 || echo "(none)"
echo ""

# Java imports
echo "--- Java (.java) ---"
grep -r -l "import.*${MODULE_NAME}" \
  --include="*.java" \
  "$TARGET_DIR" 2>/dev/null | grep -v "*/node_modules/*" | grep -v "*/.git/*" | head -20 || echo "(none)"
echo ""

# C# imports
echo "--- C# (.cs) ---"
grep -r -l "using.*${MODULE_NAME}" \
  --include="*.cs" \
  "$TARGET_DIR" 2>/dev/null | grep -v "*/node_modules/*" | grep -v "*/.git/*" | head -20 || echo "(none)"
echo ""

# Ruby imports
echo "--- Ruby (.rb) ---"
grep -r -l "require.*${MODULE_NAME}\|require_relative.*${MODULE_NAME}" \
  --include="*.rb" \
  "$TARGET_DIR" 2>/dev/null | grep -v "*/node_modules/*" | grep -v "*/.git/*" | head -20 || echo "(none)"
echo ""

# PHP imports
echo "--- PHP (.php) ---"
grep -r -l "use.*${MODULE_NAME}\|require.*${MODULE_NAME}" \
  --include="*.php" \
  "$TARGET_DIR" 2>/dev/null | grep -v "*/node_modules/*" | grep -v "*/.git/*" | head -20 || echo "(none)"
echo ""

echo "=== Scan complete ==="
