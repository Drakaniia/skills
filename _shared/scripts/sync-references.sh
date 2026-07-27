#!/usr/bin/env bash
# Sync shared reference files to all skills.
# Run from the repo root: ./_shared/scripts/sync-references.sh
#
# Preserves the skill-specific intro (everything before the first ---)
# and replaces the shared body with the canonical copy's content.
#
# Uses marker-based boundary detection (first "---" line) instead of
# brittle line offsets, since different skills have different numbers
# of header lines.

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

  if [ ! -s "$canonical" ]; then
    echo "⚠️  Canonical $canonical is empty, skipping"
    return
  fi

  for skill in audit-codebase folder-architecture implement-folder-architecture; do
    local target="$REPO_ROOT/skills/$skill/references/$ref_name"
    if [ -f "$target" ]; then
      # Find the first "---" line in the target — that's the boundary
      # between skill-specific intro and shared body.
      local boundary
      boundary=$(awk '/^---$/ { print NR; exit }' "$target")

      if [ -z "$boundary" ]; then
        echo "⚠️  No '---' boundary found in $target, using full replacement"
        cp "$canonical" "$target"
        echo "⚠️  Replaced $ref_name -> $skill (no boundary found)"
      else
        # Keep lines 1..boundary (the intro, including the --- marker)
        head -n "$boundary" "$target" > "${target}.tmp"

        # Append canonical body from line 2 onwards (skip canonical's opening ---)
        tail -n +2 "$canonical" >> "${target}.tmp"

        mv "${target}.tmp" "$target"
        echo "✅ Synced $ref_name -> $skill (boundary at line $boundary)"
      fi
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
