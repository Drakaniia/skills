#!/usr/bin/env bash
# sync-references.sh
# Sync shared reference files to all skills.
# Run from the repo root: ./_shared/scripts/sync-references.sh [--check]
#
# Skills are self-contained per the Agent Skills spec, so shared reference
# files are duplicated into each skill's references/ directory. The copies are
# byte-identical replicas of the canonical files in _shared/references/ — no
# per-skill intros. (Earlier marker-based splicing that tried to preserve an
# intro was not idempotent: the first "---" in a file is ambiguous when the
# shared body itself contains "---" separators, and re-running the sync kept
# appending duplicated content on top of already-synced copies.)
#
# The copies are gitignored build output, so a fresh clone has no references/
# directory at all — the target directory is created as needed.
#
#   (no args)  Write the copies.
#   --check    Verify every copy that already exists is byte-identical to the
#              canonical file, writing only the ones a fresh clone is missing.
#              Compares bytes on disk rather than diffing the working tree,
#              because a gitignored artifact cannot be seen by git. Exits 1
#              naming any copy that differs.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SHARED_REF="$REPO_ROOT/_shared/references"
SKILLS="audit-codebase folder-architecture implement-folder-architecture"
REFS="ORGANIZATION-PATTERNS.md SPLITTING-GUIDE.md"

CHECK=0
case "${1-}" in
  --check) CHECK=1 ;;
  "") ;;
  *)
    echo "Unknown argument: $1" >&2
    echo "Usage: $0 [--check]" >&2
    exit 2
    ;;
esac

echo "Syncing shared references to skills..."

# One row per canonical file. The copies are byte-identical, so a missing or
# differing target means the sync did not run to completion.
failed=0
for ref in $REFS; do
  canonical="$SHARED_REF/$ref"

  if [ ! -s "$canonical" ]; then
    echo "⚠️  Canonical $canonical missing or empty, skipping"
    continue
  fi

  for skill in $SKILLS; do
    target="$REPO_ROOT/skills/$skill/references/$ref"
    mkdir -p "$(dirname "$target")"

    if [ "$CHECK" -eq 1 ] && [ -f "$target" ]; then
      # --check verifies before it writes, so the check cannot be satisfied by
      # the copy the same run just made.
      if cmp -s "$canonical" "$target"; then
        echo "✅ $ref -> $skill already in sync"
      else
        echo "❌ differs from canonical: skills/$skill/references/$ref" >&2
        failed=1
      fi
      continue
    fi

    cp "$canonical" "$target"
    echo "✅ Synced $ref -> $skill"
  done
done

if [ "$CHECK" -eq 1 ]; then
  if [ "$failed" -eq 1 ]; then
    echo "❌ Shared references are out of sync." >&2
    exit 1
  fi
  echo "✅ All generated references match _shared/references/ byte-for-byte."
  exit 0
fi

echo "Done. All references synced."
