#!/usr/bin/env bash
# Sync shared reference files to all skills.
# Run from the repo root: ./_shared/scripts/sync-references.sh
#
# This copies the canonical reference files from _shared/references/
# to each skill's references/ directory, preserving the skill-specific
# introductory paragraph (first 5 lines).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SHARED_REF="$REPO_ROOT/_shared/references"

echo "Syncing shared references to skills..."

sync_ref() {
  local ref_name="$1"
  local canonical="$SHARED_REF/$ref_name"

  if [ ! -f "$canonical" ]; then
    echo "⚠️  Canonical $canonical not found, skipping"
    return
  fi

  for skill in audit-codebase folder-architecture implement-folder-architecture; do
    local target="$REPO_ROOT/skills/$skill/references/$ref_name"
    if [ -f "$target" ]; then
      # Preserve first 5 lines of target (skill-specific intro), replace the rest
      local head_lines=$(head -n 5 "$target")
      local body_lines=$(tail -n +6 "$canonical")
      echo "$head_lines" > "$target"
      echo "$body_lines" >> "$target"
      echo "✅ Synced $ref_name -> $skill"
    else
      # No existing file, copy whole thing
      cp "$canonical" "$target"
      echo "✅ Created $ref_name in $skill"
    fi
  done
}

sync_ref "ORGANIZATION-PATTERNS.md"
sync_ref "SPLITTING-GUIDE.md"

echo "Done. All references synced."
