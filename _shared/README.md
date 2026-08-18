# Shared Resources

This directory contains the **canonical copies** of shared reference files used across multiple skills.

## Why This Exists

The Agent Skills open standard requires skills to be **self-contained** — each skill directory must work independently when installed. This means some reference files (like `ORGANIZATION-PATTERNS.md` and `SPLITTING-GUIDE.md`) are duplicated across skills.

This `_shared/` directory serves as the **source of truth** for those files. When updating a shared reference:

1. Edit the canonical copy in `_shared/references/`
2. Sync the change to each skill's `references/` directory
3. Skills that differ only in their introductory paragraph — keep the intro skill-specific but the main body in sync

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

Or manually: copy `_shared/references/ORGANIZATION-PATTERNS.md` to:

- `skills/audit-codebase/references/ORGANIZATION-PATTERNS.md`
- `skills/folder-architecture/references/ORGANIZATION-PATTERNS.md`
- `skills/implement-folder-architecture/references/ORGANIZATION-PATTERNS.md`

And `_shared/references/SPLITTING-GUIDE.md` to:

- `skills/audit-codebase/references/SPLITTING-GUIDE.md`
- `skills/folder-architecture/references/SPLITTING-GUIDE.md`
- `skills/implement-folder-architecture/references/SPLITTING-GUIDE.md`
