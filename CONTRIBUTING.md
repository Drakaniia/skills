# Contributing to Drakaniia/skills

Thanks for your interest in improving these skills! This repo follows the [Agent Skills open standard](https://openagentskills.dev).

## How to Contribute

### 1. Understand the Structure

Each skill is a standalone directory under `skills/`:

```
skills/<skill-name>/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable utility scripts
├── references/       # Optional: detailed reference files
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

#### Shared References

Some reference files (`ORGANIZATION-PATTERNS.md`, `SPLITTING-GUIDE.md`) are duplicated across skills because the OAS spec requires self-contained skills. The canonical copies live in `_shared/references/`.

**When updating a shared reference:**
1. Edit `_shared/references/<file>.md`
2. Run `_shared/scripts/sync-references.sh` to sync to all skills
3. Commit both the canonical copy and the synced copies

#### Scripts Guidelines

- Scripts in `scripts/` must be **self-contained** with clear documentation
- Prefer **POSIX-compatible shell** (`.sh`) for cross-platform use
- Include **helpful error messages** and handle edge cases
- No external dependencies beyond standard POSIX tools

### 4. Pull Request Process

1. **Validate your skill** — run `npx skills-ref validate skills/<skill-name>` (requires `skills-ref`)
2. **Update CHANGELOG.md** — add your change under the appropriate version
3. **Keep PRs focused** — one change per PR (new skill, bug fix, enhancement)
4. **Update cross-references** — if you rename a reference or change a path, update all skills that reference it

### 5. Code of Conduct

Be respectful, constructive, and inclusive. This is a small open-source project — we're all here to learn and improve.

## Development Setup

```bash
git clone https://github.com/Drakaniia/skills.git
cd skills

# Optional: install validation tool
npm install

# Validate all skills
npx skills-ref validate skills/audit-codebase
npx skills-ref validate skills/folder-architecture
npx skills-ref validate skills/code-design
npx skills-ref validate skills/implement-folder-architecture
```

## Questions?

Open an issue or start a discussion. We're happy to help.
