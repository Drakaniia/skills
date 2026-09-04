#!/usr/bin/env bash
# sync-references.sh
# Sync shared reference files to all skills.
# Run from the repo root: ./_shared/scripts/sync-references.sh
#
# Skills are self-contained per the Agent Skills spec, so shared reference
# files are duplicated into each skill's references/ directory. The copies are
# byte-identical replicas of the canonical files in _shared/references/ — no
# per-skill intros. (Earlier marker-based splicing that tried to preserve an
# intro was not idempotent: the first "---" in a file is ambiguous when the
# shared body itself contains "---" separators, and re-running the sync kept
# appending duplicated content on top of already-synced copies.)
#
# This script overwrites each copy with the canonical file, so it is
# idempotent by construction: a second run changes nothing.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SHARED_REF="$REPO_ROOT/_shared/references"
SKILLS="audit-codebase folder-architecture implement-folder-architecture"

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

  for skill in $SKILLS; do
    local target="$REPO_ROOT/skills/$skill/references/$ref_name"

    if cmp -s "$canonical" "$target" 2>/dev/null; then
      echo "✅ $ref_name -> $skill already in sync"
      continue
    fi

    cp "$canonical" "$target"

    if cmp -s "$canonical" "$target"; then
      echo "✅ Synced $ref_name -> $skill"
    else
      echo "❌ Sync failed for $ref_name -> $skill" >&2
      exit 1
    fi
  done
}

sync_ref "ORGANIZATION-PATTERNS.md"
sync_ref "SPLITTING-GUIDE.md"

echo "Done. All references synced."
