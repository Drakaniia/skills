# Releasing

How to ship a new version of `@qwenzy/codebase-health`. Every command below runs
from the repo root on Windows PowerShell unless noted.

## Read this first: two publish paths

| Path | How | Provenance | Use when |
| --- | --- | --- | --- |
| **Tag pipeline** (preferred) | push a `v*` tag | yes (`--provenance`) | Trusted publishing is configured on npmjs.com |
| **Local** | `npm publish` from your machine | no | Trusted publishing is not configured yet |

**The tag pipeline fails with `ENEEDAUTH` until trusted publishing is set up.**
That is expected, not a bug you introduced. To enable it, once, on
[npmjs.com](https://www.npmjs.com/package/@qwenzy/codebase-health/access) →
package → **Trusted Publishers** → add:

- Repository: `Drakaniia/skills`
- Workflow filename: `release.yml`
- Environment: leave blank (the workflow declares no `environment`)

After that, tagging is all you need. Until then, publish locally and skip the tag
(triggering the tag would only produce a red build).

## Version numbers

`package.json` `version` is the **single source of truth**. `npm run bump` copies
it into the five manifests and every skill's `metadata.version` frontmatter.

```powershell
# 1. Edit package.json `version` by hand — bump to the next version.
#    Use a minor bump for a new rule or feature, patch for a fix.

# 2. Propagate it everywhere.
npm run bump

# 3. Confirm no drift (this is what CI runs).
npm run check-versions
```

Hand-editing a version in any manifest is forbidden — `npm run check-versions`
fails CI on drift.

## Release checklist

```powershell
# Build: syncs _shared/references/ into each skill, then validates.
npm run build

# Everything CI runs, locally, before you push.
npm run check-versions
npm test
npm run validate
```

All three must pass. `npm run build` is required before publishing — the per-skill
`references/` copies are gitignored build output, so a fresh clone ships without
them until you build.

This is now enforced for you: `npm run prepack` runs the sync, and npm runs `prepack`
on every `npm publish` and `npm pack`, so a tarball cannot be built without the
generated references. A publish on a machine with no bash on `PATH` fails rather than
shipping an incomplete package.

## Write the changelog entry

`.github/workflows/release.yml` refuses to publish without a
`## [<version>]` section in `CHANGELOG.md` — it extracts exactly that section and
uses it as the GitHub release body. An empty or missing section aborts the run.

```markdown
## [Unreleased]

## [2.1.0] — 2026-10-02

### Added

- **What changed and why it matters to an installer.** One bullet per user-visible
  change. The audience is someone deciding whether to upgrade, not a git log.
```

Move anything accumulated under `[Unreleased]` into the new section, then leave
`[Unreleased]` empty.

## Commit and push

```powershell
git status
git diff
git add -A
git commit -m "feat: short imperative summary

Why the change was needed, not what the diff shows. Reference the issue if
there is one."
git push origin main
```

Check `git log --oneline -10` for the repo's commit style — conventional commits.

> **Note:** `npm run build` generates `codebase-health-plugin-spec.md` in the repo
> root and the next build removes it. It is not tracked; ignore it, and never
> `git add` it deliberately.

## Publish

### Path A — tag pipeline (once trusted publishing is configured)

```powershell
git tag -a v<version> -m "v<version> — one-line summary"
git push origin v<version>
```

The `Release` workflow then runs the full check suite, publishes with provenance,
and creates the GitHub release from the changelog section. Watch it:

```powershell
gh run list --limit 3
gh run view <run-id> --log-failed
```

If you tagged before committing a fix, move the tag:

```powershell
git tag -f -a v<version> -m "v<version> — one-line summary"
git push origin v<version> --force
```

`npm publish` runs before `gh release create`, and npm will not let you reuse a version
number, so if the release step fails after a successful publish, do **not** re-run the
workflow. Create the release by hand instead:

```powershell
gh release create v<version> --title "v<version>" --notes "<summary>"
```

### Path B — local (before trusted publishing is configured)

```powershell
npm publish
npm view @qwenzy/codebase-health version dist-tags
```

The registry takes a minute or two to propagate — `dist-tags.latest` will still
show the old version right after a successful publish. Re-check before assuming
it failed.

Then create the release manually, since the workflow did not run:

```powershell
gh release create v<version> --title "v<version>" --notes "<summary>"
```

## Verify

```powershell
npm view @qwenzy/codebase-health version    # expect the new version
```

Then confirm the shipped router actually contains your change — this is the part
that breaks silently, because a version bump with no content change publishes
cleanly:

```powershell
npm pack @qwenzy/codebase-health@<version>
tar -xzf qwenzy-codebase-health-<version>.tgz
Select-String -Path package\skills\codebase-health\SKILL.md -Pattern "<what you changed>"
```

More important, confirm the generated per-skill `references/` copies shipped. They are
gitignored build output, so they are absent from a bare checkout and only reach the
tarball if the sync ran — six files across three skills, and their absence breaks an
installer's links rather than the publish:

```powershell
tar -tzf qwenzy-codebase-health-<version>.tgz |
  Select-String "skills/.*/references/(ORGANIZATION-PATTERNS|SPLITTING-GUIDE)\.md"
# expect 6 lines
```

`npm test` asserts this on every PR, so a release that gets here is already covered —
the check above is for confirming a version that is already on the registry.

Finally, install on a second device or agent and restart. Config is loaded once at
startup — skills, plugins, and `AGENTS.md` edits do not hot-reload.

```powershell
# OpenCode
#   "plugin": ["@qwenzy/codebase-health"] in opencode.json

# Claude Code
#   /plugin marketplace add Drakaniia/codebase-health

# Codex
#   codex plugin marketplace add Drakaniia/codebase-health
```

## Opting out

The injected router is suppressible, for users who want the skills without the
session-level bootstrap:

- Env var `CODEBASE_HEALTH` set to `0`, `off`, `false`, or `no`
  (case-insensitive, trimmed)
- `~/.config/codebase-health/config.json` containing `{"bootstrap": false}`

A malformed config file fails open — bootstrap stays on. Both paths make the
plugin register no skills and no command at all.

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `EBADENGINE` during "Upgrade npm" | npm@12 needs Node >= 22, workflow ran Node 20 | Already fixed (Node 24). Check nobody reverted `.github/workflows/release.yml` |
| `fail  sync references: bash not on PATH` | `prepack` needs bash and will not skip | Install Git Bash, or publish from the tag pipeline instead |
| Tag does not match package.json version | Tagged before bumping, or forgot `npm run bump` | Bump `package.json`, run `npm run bump`, commit, then re-tag |
| `ENEEDAUTH` at "Publish to npm" | Trusted publishing not configured on npmjs.com | Configure it (top of this file), or publish locally |
| "No '## [x.y.z]' section in CHANGELOG.md" | Changelog section missing or misnamed | Add it; the version must match the tag exactly |
| `gh release create` failed after a successful publish | npm already has the version and it cannot be re-published | Create the release by hand with `gh release create`; do not re-run the workflow |
| `Validate Skills` red but local green | Shared references drifted, or a generated file was committed | `npm run build`, then commit the regenerated output |
| Version drift in CI | A manifest was hand-edited | `npm run bump` |
| `npm publish` succeeds but registry shows the old version | Propagation delay | Wait a minute, re-check `npm view` |
