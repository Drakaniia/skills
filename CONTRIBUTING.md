# Contributing to Drakaniia/codebase-health

Thanks for your interest in improving these skills! This repo follows the [Agent Skills open standard](https://openagentskills.dev).

## How to Contribute

### 1. Understand the Structure

Each skill is a standalone directory under `skills/`:

```
skills/<skill-name>/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable utility scripts
├── references/       # Optional: generated reference files (see below)
├── agents/           # Optional: platform-specific agent configs
└── assets/           # Optional: templates, resources
```

### 2. Before You Start

- **Check existing issues** — someone may already be working on it
- **Open an issue first** for significant changes to discuss approach
- **Keep skills self-contained** — each skill must work when installed standalone

### 3. Making Changes

#### SKILL.md Guidelines

- Keep under **500 lines** — move depth into `references/`
- YAML frontmatter must have valid `name` (lowercase, hyphens) and `description`
- Use **progressive disclosure** — SKILL.md is the overview, references are the details
- Include a **verification checklist** at the end
- **Never add a `version` field by hand** — see [Releasing](#releasing)

#### Shared References Are Generated

`ORGANIZATION-PATTERNS.md` and `SPLITTING-GUIDE.md` exist as a single canonical copy in `_shared/references/`. The per-skill copies under `skills/*/references/` are **build output**: they are gitignored, regenerated on every build, and overwritten byte-for-byte.

**The rule:** never commit them, never hand-edit them. Editing a copy is a silent no-op — the next `npm run build` discards your change.

**When updating a shared reference:**

1. Edit `_shared/references/<file>.md`
2. Run `npm run build` to regenerate the skill copies
3. Commit **only** the canonical file under `_shared/references/`

CI runs the sync script and then `git diff --exit-code`, so drift between the canonical copy and what the sync produces fails the build.

> **A fresh clone has empty `skills/*/references/` directories until you run `npm run build`.** This is expected. Every host resolves a `references/` miss gracefully — progressive disclosure just finds no extra file — so the skills still load, only without the deep-dive appendices. Run the build if you are working on the skills themselves.

#### Scripts Guidelines

- Scripts in `scripts/` must be **self-contained** with clear documentation
- Prefer **POSIX-compatible shell** (`.sh`) for cross-platform use
- Include **helpful error messages** and handle edge cases
- No external dependencies beyond standard POSIX tools

#### Adding a New Skill

1. Create `skills/<skill-name>/SKILL.md` with valid frontmatter
2. Add a row to the router table in `skills/codebase-health/SKILL.md` — **skill, and the condition under which it fires**
3. Run `npm run build` to generate any shared references
4. Run `npm run validate` and `npm test`
5. If the skill ships a `references/` file that is not shared, add it directly — it is committed
6. Document it in `readme.md` (skill table + invocation table) and in `CHANGELOG.md`

Step 2 is the one people forget. The `SessionStart` hook injects the router, not the skills — **a skill that is missing from the router table is invisible to the bootstrap**, and the router must stay under 60 lines, so keep the "when it fires" condition to a single clause.

### 4. Pull Request Process

1. **Validate** — run `npm run validate` and `npm test`
2. **Check versions** — run `npm run check-versions`; it exits non-zero if any manifest has drifted
3. **Update CHANGELOG.md** — add your change under the appropriate version
4. **Keep PRs focused** — one change per PR (new skill, bug fix, enhancement)
5. **Update cross-references** — if you rename a reference or change a path, update all skills that reference it

### 5. Code of Conduct

Be respectful, constructive, and inclusive. This is a small open-source project — we're all here to learn and improve.

## Development Setup

```bash
git clone https://github.com/Drakaniia/codebase-health.git
cd codebase-health

npm install
npm run build      # generate skills/*/references/ from _shared/references/
npm run validate   # skills-ref validate ./skills/*
npm test           # node --test tests/
```

| Script                 | What it does                                                       |
| ---------------------- | ------------------------------------------------------------------ |
| `npm run build`        | Sync shared references into the skills, then validate              |
| `npm run prepack`      | Sync only; npm runs this on every `npm publish` and `npm pack`     |
| `npm run validate`     | OAS frontmatter and structure validation across all skills         |
| `npm test`             | `node:test` suite for the session-start hook and the packed tarball |
| `npm run sync-refs`    | Shared-reference sync only                                         |
| `npm run check-versions` | Fails if any manifest's version disagrees with `package.json`    |
| `npm run bump`         | Propagates `package.json`'s version into every manifest — see [RELEASING.md](RELEASING.md) |

> **On Windows:** `npm run validate` passes `./skills/*` to `skills-ref`, which relies on the shell expanding the glob. `cmd.exe` does not, so it fails with *"Path does not exist"*. Validate per skill there instead: `npx skills-ref validate skills/code-design`.

## Manual Smoke Test

**Real session injection cannot be automated.** The hook's own behaviour is covered by `npm test`, but whether the host actually injects the router into a live session has to be checked by hand. Do this before tagging a release that changes the hook:

1. Launch Claude Code fresh in a scratch directory
2. Confirm the router text appears in session context
3. Run `/codebase-health:audit-codebase` once
4. Repeat steps 1–3 in Codex, invoking the router as `$codebase-health`

If the router does not appear, check `CODEBASE_HEALTH` and `~/.config/codebase-health/config.json` first — both can disable it silently.

## Releasing

See **[RELEASING.md](RELEASING.md)** for the full workflow: versioning, the
pre-publish checklist, the changelog section the release workflow requires, both
publish paths, and troubleshooting.

Two things to know before your first release:

- **Never hand-edit a version in any manifest.** `package.json.version` is the
  single source of truth; edit it there and run `npm run bump` to propagate.
  `npm run check-versions` runs in CI and fails on drift.
- **Trusted publishing must be registered on npmjs.com** for this repository,
  pointing at `release.yml`. It cannot be set from the repo. Until it is, the tag
  pipeline fails with `ENEEDAUTH` and releases have to be published locally — see
  the two-path table in `RELEASING.md`. The package is published from the
  `@qwenzy` scope while the GitHub org is `Drakaniia`; the two names differing is
  expected.

## Questions?

Open an issue or start a discussion. We're happy to help.
