# Changelog

## [Unreleased]

## [2.1.1] — 2026-10-02

The first version published through the tag pipeline rather than from a local
`npm publish`. No skill content changed.

### Fixed

- **The tag pipeline could not publish at all.** The `v2.1.0` release run failed with `ENEEDAUTH`, so 2.1.0 never reached npm despite the tag existing — `latest` on the registry was still 2.0.0's successor from a local publish. Nothing in the repo can fix this: a trusted publisher must be registered for this repository on npmjs.com. `RELEASING.md` documents the exact values.
- **The release workflow would have shipped an incomplete tarball.** `skills/{audit-codebase,folder-architecture,implement-folder-architecture}/references/{ORGANIZATION-PATTERNS,SPLITTING-GUIDE}.md` are gitignored build output, and the workflow ran `npm run validate` — which by design cannot generate them — but never the sync. Six files would have been missing, leaving three skills with half their `references/` directory absent. `npm run prepack` now syncs before packing, and npm runs `prepack` on every `npm publish` and `npm pack`, so no path can produce an incomplete tarball.
- **A missing `bash` no longer skips silently.** `npm run build` treated an absent `bash` as a skip notice, which on a local `npm publish` would have shipped that same incomplete tarball. It is now fatal, with a message naming the tool and the fix.
- **`validate.yml` tested a different npm than the release path.** Its `test-hooks` job ran the npm bundled with Node 20 while `release.yml` installs `npm@latest`, so a release-breaking test could pass CI and fail only in the release run. The two now agree, on Node 24 — `npm@latest` requires `^22.22.2 || ^24.15.0 || >=26` and would `EBADENGINE` on 20.

### Added

- **`tests/pack-contents.test.mjs`** — runs `npm pack --dry-run` and asserts the six generated references are in the tarball and byte-size-match their canonical sources. Runs on every PR via the existing `test-hooks` job, so this regression class is caught before a tag rather than after a publish. Tolerant of all three `npm pack --json` output shapes, since npm changes them between majors and CI tracks `npm@latest`.
- **Tag/version guard in the release workflow** — pushing `v2.2.0` while `package.json` still says `2.1.0` would have failed at the registry with `E403 Cannot publish over previously published version`, which reads as a permissions fault rather than a forgotten bump. The workflow now compares the tag against `package.json` and fails with both values named.
- **`RELEASING.md`** — the release process, both publish paths, the pre-publish checklist, and troubleshooting, promoted out of `CONTRIBUTING.md` and into the repo. It was previously untracked and existed only on one machine.

### Changed

- **Release documentation consolidated.** `CONTRIBUTING.md` now links to `RELEASING.md` instead of duplicating the release process inline; `readme.md` links to both.
- **Build progress goes to stderr.** `scripts/build.mjs` writes to stderr rather than stdout, so `npm pack --json` emits parseable JSON instead of having its output corrupted by build chatter.
- **`package-lock.json` regenerated.** It still described the pre-rename package (`@drakaniia/codebase-health@2.0.0`) after commit `435f9ad` moved the scope.

## [2.1.0] — 2026-10-02

### Added

- **400-line standing rule in the router** — `skills/codebase-health/SKILL.md` now carries the file-size check that previously only existed as prose inside `folder-architecture`. Because the router is what the OpenCode plugin, the Claude Code hook, and the Codex hook all inject as session context, the rule now applies on every host and every session instead of only when `folder-architecture` happens to trigger. Over 350 lines and pushing toward 400 → warn and propose a split; over 400 → do not add unprompted. The "do not split as a drive-by" clause is deliberate: the threshold is a nudge to route into `folder-architecture` and `code-design`, not an invitation to refactor unrelated code mid-task.

## [2.0.0] — 2026-09-30

First release as an installable plugin. Packaging, distribution, and discovery — the four existing skills are unchanged in content.

### Added

- **Plugin manifests for Claude Code and Codex** — `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (a single self-marketplace, `source: "./"`), `.codex-plugin/plugin.json`, and `.agents/plugins/marketplace.json`. The two ecosystems use different schemas for the same directory, so the Codex marketplace entry is a separate file.
- **`SessionStart` bootstrap hook** — `hooks/hooks.json` plus `hooks/session-start.mjs`, shared by Claude Code and Codex from one file. Zero npm dependencies, Node >= 18. On startup, resume, clear, and after compaction it reads the router and emits it as session context, so the routing table is in the model's context before the first prompt. It always exits `0`, including on a missing `SKILL.md` or a malformed config, because a non-zero hook exit can wedge a session in the host.
- **`codebase-health` router skill** — a fifth skill at `skills/codebase-health/SKILL.md`, under 60 lines, that maps the current situation to one of the other four. It is what the hook injects, and it is the piece the plugin exists to ship.
- **Opt-out paths** — the `CODEBASE_HEALTH` environment variable (`0`, `off`, `false`, `no`, case-insensitive) or `~/.config/codebase-health/config.json` containing `{"bootstrap": false}`. A malformed config fails open.
- **npm publishing under `@qwenzy/codebase-health`** with `engines.node >= 18` and `publishConfig.access: public`.
- **Single-source versioning** — `_shared/scripts/bump-version.mjs` writes `package.json.version` into all five manifests and every skill's frontmatter; `--check` fails on drift and runs in CI.
- **`npm run build`** — `scripts/build.mjs`, which syncs the shared references into the skills and then validates them. A missing optional tool (`bash`, `skills-ref`) is a skip notice, not a build failure.
- **`tests/session-start.test.mjs`** — `node:test`, no test framework added. Covers frontmatter stripping (including CRLF), every opt-out branch, the end-to-end hook contract, and the missing-router resilience case.
- **`.github/workflows/release.yml`** — tag-driven: on a `v*` tag it re-runs the checks and publishes to npm with OIDC trusted publishing and provenance, then creates the GitHub release from this file's section. No `NPM_TOKEN` secret.
- **Logo at `assets/logo.png`** — moved from `skills/audit-codebase/assets/drakaniia_skills_minimal_logo.png` and renamed. The opaque white background is kept, so marketplace cards are correct on light surfaces.

### Changed

- **Repository renamed `Drakaniia/skills` → `Drakaniia/codebase-health`.** GitHub sets a permanent redirect, so existing clone URLs and `npx skills add Drakaniia/skills` keep resolving. **No npm shim package** — the old package was `private: true` and never published, so there are no npm consumers to strand.
- **License changed Apache-2.0 → MIT**, in `LICENSE` and in the `license` field of all four existing skills and every manifest.
- **Shared references are now build-time generated.** `_shared/references/` is the only canonical copy; the six per-skill copies are gitignored build output. This removes the drift class that broke sync twice in the log (`d8e5f9a` duplicated opening section, `57cb3c3` BOM artifact). Trade-off: a fresh `git clone` has empty `skills/*/references/` until `npm run build` runs. Every host resolves a reference miss gracefully — progressive disclosure just finds no extra file — so it degrades rather than breaks.
- **Install is now per-host plugin installation** — `/plugin marketplace add Drakaniia/codebase-health` for Claude Code, `codex plugin marketplace add` for Codex, or `"@qwenzy/codebase-health"` in the `plugin` array of `opencode.json` for OpenCode. Manual directory copying still works for any spec-compliant agent.
- **Skills are namespaced by Claude Code** — installed skills appear as `/codebase-health:audit-codebase`, which is what makes the flat skill names safe.
- **Version is owned by one script.** `npm run bump` is the only legal way to change it; `npm run check-versions` fails CI on drift. Hand-editing a version in any manifest is forbidden.
- **CI extended** — `validate.yml` keeps its frontmatter and structure jobs, replaces the committed-copy cross-reference check with a generated-clean check, and adds version-drift, hook tests on Node 20, and `claude plugin validate`. Path filters widen to the manifests, hooks, assets, and `package.json`.

### Removed

- **`commands/`** — all four `commands/*.md` files. Claude Code namespaces plugin skills automatically and prefers `skills/` for new plugins; Codex reads `SKILL.md` directly. The commands were also OpenCode-flavored, and one hardcoded the Claude-only `ask_user` tool.
- **`skills.json`** — redundant with the plugin manifests.
- **The committed copies of the shared references** — six files under `skills/*/references/`, now regenerated by `npm run build`.

### Fixed

- **Shared reference sync corruption** — `SPLITTING-GUIDE.md` copies in all three skills had their opening section duplicated (the first 14 lines appeared twice), so the CI cross-reference check was failing. `_shared/scripts/sync-references.sh` was not idempotent: it spliced the canonical body at the first `---` line, which is ambiguous when the shared body itself contains `---` separators. It now overwrites each skill copy with the canonical file byte-for-byte, making repeated runs a no-op. CI compares full files instead of from a marker heading so this class of drift fails loudly.

### Breaking Changes

- **License is now MIT.** Apache-2.0 is not offered alongside it; downstream consumers relying on Apache-2.0 grantor clauses must review.
- **The repository moved.** Anything hardcoding `github.com/Drakaniia/skills` as a git remote still works via the GitHub redirect, but URLs in docs, badges, and CI references should be updated to `github.com/Drakaniia/codebase-health`.
- **`commands/*.md` no longer exist.** If you invoked `/audit-codebase` or the other three as commands, the equivalent is now the namespaced skill — `/codebase-health:audit-codebase`.
- **`skills/*/references/` is no longer committed.** Anyone cloning the repo and expecting the reference appendices to be present must run `npm run build` first.
- **Node >= 18 is now a real runtime requirement**, because the plugin ships an executable session-start hook. It is not a dependency of the skills themselves.

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
