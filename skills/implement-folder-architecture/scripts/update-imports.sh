#!/usr/bin/env bash
# update-imports.sh
# Update import paths after a file move or rename.
# Usage: ./update-imports.sh <old-path> <new-path> [target-dir]
#
# Searches for files that import from old-path and shows the replacement.
# This is a DRY-RUN by default — it shows what would change without modifying files.
# Pass --apply to actually apply changes.

set -euo pipefail

OLD_PATH="${1:-}"
NEW_PATH="${2:-}"
TARGET_DIR="${3:-.}"
APPLY=false

# Check for --apply flag
for arg in "$@"; do
  if [ "$arg" = "--apply" ]; then
    APPLY=true
  fi
done

if [ -z "$OLD_PATH" ] || [ -z "$NEW_PATH" ]; then
  echo "Usage: $0 <old-path> <new-path> [target-dir] [--apply]"
  echo ""
  echo "Shows/replaces import paths after a file move."
  echo "Without --apply: dry-run (shows what would change)"
  echo "With --apply:    performs the replacement"
  echo ""
  echo "Examples:"
  echo "  $0 src/utils/string_utils src/features/users/string_utils ."
  echo "  $0 src/utils/string_utils src/features/users/string_utils . --apply"
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: '$TARGET_DIR' is not a directory" >&2
  exit 1
fi

echo "=== Import Update: $OLD_PATH → $NEW_PATH ==="
if [ "$APPLY" = true ]; then
  echo "Mode: APPLY (will modify files)"
else
  echo "Mode: DRY-RUN (no changes made, pass --apply to apply)"
fi
echo ""

# Extract old and new basenames/dirs for replacement patterns
OLD_NAME=$(basename "$OLD_PATH")
NEW_NAME=$(basename "$NEW_PATH")

# Build sed replacement command
if [ "$APPLY" = true ]; then
  # Python
  grep -r -l "from .*${OLD_NAME}\|import.*${OLD_NAME}" \
    --include="*.py" \
    "$TARGET_DIR" 2>/dev/null | grep -v "*/node_modules/*" | grep -v "*/.git/*" | while IFS= read -r file; do
    echo "Updating: $file"
    sed -i "s|${OLD_PATH}|${NEW_PATH}|g; s|${OLD_NAME}|${NEW_NAME}|g" "$file"
  done

  # JS/TS
  grep -r -l "from ['\"].*${OLD_NAME}['\"]\|require(['\"].*${OLD_NAME}['\"]" \
    --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx" \
    "$TARGET_DIR" 2>/dev/null | grep -v "*/node_modules/*" | grep -v "*/.git/*" | while IFS= read -r file; do
    echo "Updating: $file"
    sed -i "s|${OLD_PATH}|${NEW_PATH}|g; s|${OLD_NAME}|${NEW_NAME}|g" "$file"
  done

  echo ""
  echo "✅ Imports updated. Verify with build/tests."
else
  echo "Files that would be updated:"

  # Python
  matches=$(grep -r -l "from .*${OLD_NAME}\|import.*${OLD_NAME}" \
    --include="*.py" \
    "$TARGET_DIR" 2>/dev/null | grep -v "*/node_modules/*" | grep -v "*/.git/*" || true)
  if [ -n "$matches" ]; then
    echo "--- Python ---"
    echo "$matches" | while IFS= read -r f; do echo "  $f"; done
  fi

  # JS/TS
  matches=$(grep -r -l "from ['\"].*${OLD_NAME}['\"]\|require(['\"].*${OLD_NAME}['\"]" \
    --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx" \
    "$TARGET_DIR" 2>/dev/null | grep -v "*/node_modules/*" | grep -v "*/.git/*" || true)
  if [ -n "$matches" ]; then
    echo "--- JS/TS ---"
    echo "$matches" | while IFS= read -r f; do echo "  $f"; done
  fi

  echo ""
  echo "Run with --apply to apply changes."
fi

echo ""
echo "=== Import update complete ==="
