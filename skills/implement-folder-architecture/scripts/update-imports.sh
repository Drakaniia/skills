#!/usr/bin/env bash
# update-imports.sh
# Update import paths after a file move or rename.
# Usage: ./update-imports.sh <old-path> <new-path> [target-dir] [--apply]
#
# Searches for files that import from old-path and shows the replacement.
# This is a DRY-RUN by default — it shows what would change without modifying files.
# Pass --apply to actually apply changes.
#
# Languages: Python and JS/TS. A language without an import form you can rewrite
# with one sed expression (Go, Rust, Java, C#, Ruby, PHP) belongs here only after
# someone adds the rewrite — find-consumers.sh covers the wider set for reading.

set -euo pipefail

OLD_PATH="${1:-}"
NEW_PATH="${2:-}"
TARGET_DIR="${3:-.}"
APPLY="${4:-}"

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

OLD_NAME=$(basename "$OLD_PATH")
NEW_NAME=$(basename "$NEW_PATH")

echo "=== Import Update: $OLD_PATH → $NEW_PATH ==="
if [ "$APPLY" = "--apply" ]; then
  echo "Mode: APPLY (will modify files)"
else
  echo "Mode: DRY-RUN (no changes made, pass --apply to apply)"
fi
echo ""

# One row per language: label | --include globs | ERE that finds the import line.
# Same shape as find-consumers.sh, so adding a language is one row.
while IFS='|' read -r label includes pattern; do
  matches=$(grep -r -l -E "$pattern" $includes "$TARGET_DIR" 2>/dev/null \
    | grep -v "*/node_modules/*" \
    | grep -v "*/.git/*" || true)
  [ -n "$matches" ] || continue

  if [ "$APPLY" = "--apply" ]; then
    echo "$matches" | while IFS= read -r file; do
      echo "Updating: $file"
      sed -i "s|${OLD_PATH}|${NEW_PATH}|g; s|${OLD_NAME}|${NEW_NAME}|g" "$file"
    done
  else
    echo "--- $label ---"
    echo "$matches" | while IFS= read -r file; do echo "  $file"; done
  fi
done <<EOF
Python (.py)|--include=*.py|from .*${OLD_NAME}|import.*${OLD_NAME}
JS/TS (.js, .jsx, .ts, .tsx)|--include=*.js --include=*.jsx --include=*.ts --include=*.tsx|from ['\"].*${OLD_NAME}['\"]|require\(['\"].*${OLD_NAME}['\"]
EOF

echo ""
if [ "$APPLY" = "--apply" ]; then
  echo "✅ Imports updated. Verify with build/tests."
else
  echo "Run with --apply to apply changes."
fi

echo "=== Import update complete ==="
