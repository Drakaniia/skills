# Changelog

## [Unreleased]

### Fixed

- **Shared reference sync corruption** — `SPLITTING-GUIDE.md` copies in all three skills had their opening section duplicated (the first 14 lines appeared twice), so the CI cross-reference check was failing. `_shared/scripts/sync-references.sh` was not idempotent: it spliced the canonical body at the first `---` line, which is ambiguous when the shared body itself contains `---` separators. It now overwrites each skill copy with the canonical file byte-for-byte, making repeated runs a no-op. CI compares full files instead of from a marker heading so this class of drift fails loudly.

## [1.0.0] — 2026-07-27

### Added

- **Scripts directory** for each skill:
  - `audit-codebase/scripts/` — `scan-codebase.sh`, `check-file-sizes.sh`
  - `folder-architecture/scripts/` — `check-directory-health.sh`
  - `code-design/scripts/` — `check-function-complexity.sh`
  - `implement-folder-architecture/scripts/` — `find-consumers.sh`, `update-imports.sh`
- **`_shared/` directory** with canonical reference files and sync infrastructure
- **`assets/` directory** for each skill (templates, resources)
- **`agents/openai.yaml`** for `code-design` skill (was missing)
- **Version tracking** — added `version: "1.0.0"` to all skill metadata
- **`allowed-tools`** frontmatter field to all skills
- **`package.json`** at repo root for `npx skills add` support
- **`skills.json`** manifest for tooling discovery
- **GitHub Actions CI** — `.github/workflows/validate.yml` for PR validation
- **`CONTRIBUTING.md`** — contribution guidelines
- **`CHANGELOG.md`** — this file

### Changed

- SKILL.md frontmatter now includes `version` in metadata block

### Fixed

- `code-design` skill now has `agents/openai.yaml` for platform auto-discovery
- All skills now include `scripts/` and `assets/` directories per OAS spec

## [0.1.0] — Initial Release

- `audit-codebase` skill
- `folder-architecture` skill
- `code-design` skill
- `implement-folder-architecture` skill
