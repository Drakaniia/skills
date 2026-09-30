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
# This script overwrites each copy with the canonical file, so it is
# idempotent by construction: a second run changes nothing.
#
# The copies are gitignored build artifacts, so a fresh clone has no references/
# directory at all — the target directory is created as needed.
#
#   (no args)  Write the copies.
#   --check    Write, then verify every copy is byte-identical to the canonical
#              file. Compares bytes on disk rather than diffing the working tree,
#              because a gitignored artifact cannot be seen by git. Exits 1
#              naming any file that is missing or differs.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SHARED_REF="$REPO_ROOT/_shared/references"
SKILLS="audit-codebase folder-architecture implement-folder-architecture"
REFS="ORGANIZATION-PATTERNS.md SPLITTING-GUIDE.md"

usage() {
  cat <<'EOF'
Usage: sync-references.sh [--check]

  (no args)  Overwrite each skills/*/references copy with the canonical file.
  --check    Sync, then verify every copy matches the canonical bytes.
             Exits 1 on any missing or differing target, 0 when all match.
EOF
}

CHECK=0
case "${1-}" in
  "") ;;
  --check) CHECK=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown argument: $1" >&2
    usage >&2
    exit 2
    ;;
esac

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
    local dir="$REPO_ROOT/skills/$skill/references"
    local target="$dir/$ref_name"

    mkdir -p "$dir"

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

for ref in $REFS; do
  sync_ref "$ref"
done

if [ "$CHECK" -eq 1 ]; then
  failed=0
  for skill in $SKILLS; do
    for ref in $REFS; do
      canonical="$SHARED_REF/$ref"
      target="$REPO_ROOT/skills/$skill/references/$ref"

      if [ ! -f "$canonical" ]; then
        continue
      fi

      if [ ! -f "$target" ]; then
        echo "❌ missing: skills/$skill/references/$ref" >&2
        failed=1
      elif ! cmp -s "$canonical" "$target"; then
        echo "❌ differs from canonical: skills/$skill/references/$ref" >&2
        failed=1
      fi
    done
  done

  if [ "$failed" -eq 1 ]; then
    echo "❌ Shared references are out of sync." >&2
    exit 1
  fi

  echo "✅ All generated references match _shared/references/ byte-for-byte."
  exit 0
fi

echo "Done. All references synced."
