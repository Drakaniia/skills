#!/usr/bin/env bash
# check-directory-health.sh
# Check a directory against folder-architecture thresholds.
# Usage: ./check-directory-health.sh <target-dir> [max-files=30] [max-depth=4]
#
# Checks:
#   - File count vs threshold
#   - Nesting depth
#   - Dumping ground directories (utils/, helpers/, shared/, common/)
#   - Root-level source files
#   - Naming convention consistency

set -euo pipefail

TARGET_DIR="${1:-}"
MAX_FILES="${2:-30}"
MAX_DEPTH="${3:-4}"

if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]; then
  echo "Usage: $0 <target-dir> [max-files=30] [max-depth=4]"
  echo "Error: '$TARGET_DIR' is not a valid directory" >&2
  exit 1
fi

echo "=== Directory Health Check: $TARGET_DIR ==="
echo ""

issues=0

# 1. File count check
echo "--- File Count ---"
file_count=$(find "$TARGET_DIR" -type f \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/vendor/*" \
  ! -path "*/.venv/*" \
  ! -path "*/__pycache__/*" \
  2>/dev/null | wc -l)
if [ "$file_count" -gt "$MAX_FILES" ]; then
  echo "🔴 BLOCKER: $file_count files (threshold: $MAX_FILES)"
  issues=$((issues + 1))
else
  echo "✅ $file_count files (threshold: $MAX_FILES)"
fi
echo ""

# 2. Nesting depth check
echo "--- Nesting Depth ---"
max_nesting=$(find "$TARGET_DIR" -type d \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/vendor/*" \
  ! -path "*/.venv/*" \
  ! -path "*/__pycache__/*" \
  2>/dev/null | \
  awk -F/ '{print NF-1}' | \
  sort -rn | \
  head -1)
max_nesting=${max_nesting:-0}
if [ "$max_nesting" -gt "$MAX_DEPTH" ]; then
  echo "🔴 BLOCKER: $max_nesting levels deep (threshold: $MAX_DEPTH)"
  issues=$((issues + 1))
else
  echo "✅ Max nesting: $max_nesting levels (threshold: $MAX_DEPTH)"
fi
echo ""

# 3. Dumping ground check
echo "--- Dumping Grounds ---"
for d in "$TARGET_DIR"/utils/ "$TARGET_DIR"/helpers/ "$TARGET_DIR"/shared/ "$TARGET_DIR"/common/; do
  if [ -d "$d" ]; then
    count=$(find "$d" -type f \
      ! -path "*/node_modules/*" \
      ! -path "*/.git/*" \
      2>/dev/null | wc -l)
    if [ "$count" -gt 0 ]; then
      echo "🟡 WARNING: $(basename "$d")/ has $count files — check if feature-local placement is better"
    fi
  fi
done
echo ""

# 4. Root-level source check
echo "--- Root-Level Files ---"
root_files=$(find "$TARGET_DIR" -maxdepth 1 -type f \
  ! -name "README.md" \
  ! -name "readme.md" \
  ! -name "LICENSE" \
  ! -name "LICENSE*" \
  ! -name "package.json" \
  ! -name "package-lock.json" \
  ! -name "yarn.lock" \
  ! -name "Cargo.toml" \
  ! -name "go.mod" \
  ! -name "go.sum" \
  ! -name "pyproject.toml" \
  ! -name "requirements*.txt" \
  ! -name "Makefile" \
  ! -name "Dockerfile" \
  ! -name "docker-compose*.yml" \
  ! -name ".gitignore" \
  ! -name "*.md" \
  ! -name ".env*" \
  2>/dev/null | head -10)
if [ -n "$root_files" ]; then
  echo "🔴 BLOCKER: Source files found at project root:"
  echo "$root_files" | while IFS= read -r f; do echo "  - $(basename "$f")"; done
  issues=$((issues + 1))
else
  echo "✅ No source files at root"
fi
echo ""

# 5. Naming consistency check
echo "--- Naming Conventions ---"
snake=0
kebab=0
camel=0
pascal=0
while IFS= read -r f; do
  name=$(basename "$f")
  case "$name" in
    *_*) snake=$((snake + 1)) ;;
    *-*) kebab=$((kebab + 1)) ;;
    [a-z]*[A-Z]*) camel=$((camel + 1)) ;;
    [A-Z]*) pascal=$((pascal + 1)) ;;
  esac
done < <(find "$TARGET_DIR" -maxdepth 1 -type f 2>/dev/null)

echo "  snake_case: $snake  kebab-case: $kebab  camelCase: $camel  PascalCase: $pascal"
# Find the dominant convention
if [ "$snake" -gt 0 ] || [ "$kebab" -gt 0 ] || [ "$camel" -gt 0 ] || [ "$pascal" -gt 0 ]; then
  dominant="$snake"
  dominant_name="snake_case"
  for pair in "$kebab:kebab-case" "$camel:camelCase" "$pascal:PascalCase"; do
    count="${pair%%:*}"
    name="${pair##*:}"
    if [ "$count" -gt "$dominant" ]; then
      dominant="$count"
      dominant_name="$name"
    fi
  done
  echo "  Dominant convention: $dominant_name ($dominant files)"
fi
echo ""

if [ "$issues" -gt 0 ]; then
  echo "⚠️  Found $issues issue(s) — review before adding files."
else
  echo "✅ Directory is healthy — ready for new files."
fi
echo ""
echo "=== Check complete ==="
