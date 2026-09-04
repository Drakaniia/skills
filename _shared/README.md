# Shared Resources

This directory contains the **canonical copies** of shared reference files used across multiple skills.

## Why This Exists

The Agent Skills open standard requires skills to be **self-contained** — each skill directory must work independently when installed. This means some reference files (like `ORGANIZATION-PATTERNS.md` and `SPLITTING-GUIDE.md`) are duplicated across skills.

This `_shared/` directory serves as the **source of truth** for those files. When updating a shared reference:

1. Edit the canonical copy in `_shared/references/`
2. Sync the change to each skill's `references/` directory
3. Skill copies are **byte-identical replicas** of the canonical file — no per-skill intros. Earlier marker-based splicing was not idempotent (the first `---` in a file is ambiguous when the shared body itself contains `---` separators) and corrupted copies, so sync is now a plain overwrite.

## Directory Structure

```
_shared/
├── README.md               # This file
├── references/
│   ├── ORGANIZATION-PATTERNS.md   # Canonical: language-specific folder patterns
│   └── SPLITTING-GUIDE.md         # Canonical: file splitting mechanics
└── scripts/
    └── sync-references.sh         # Sync shared references to all skills
```

## Sync Process

```bash
# After editing a canonical reference, sync to all skills:
./_shared/scripts/sync-references.sh
```

The sync script overwrites each skill copy with the canonical file and is idempotent (a second run is a no-op). Run it and commit both the canonical copy and the synced copies.

To verify manually, the copies must be byte-identical to the canonical file, e.g.:

```bash
diff _shared/references/ORGANIZATION-PATTERNS.md skills/audit-codebase/references/ORGANIZATION-PATTERNS.md
diff _shared/references/SPLITTING-GUIDE.md skills/audit-codebase/references/SPLITTING-GUIDE.md
```
