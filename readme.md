# Codebase Health

> Language-agnostic agent skills for keeping codebases healthy — one audits structure, another executes fixes, a third prevents decay, a fourth ensures the code _inside_ files is well-designed, and a fifth routes between them.

Agent skills are reusable instructions that coding agents (Claude Code, Codex, OpenCode, and others) discover and load on demand. This repo is packaged as a plugin built around a single philosophy: **codebase health is a continuous practice, not a one-time audit.**

## Quick Install

### Claude Code

```text
/plugin marketplace add Drakaniia/codebase-health
/plugin install codebase-health@codebase-health
```

### Codex

```bash
codex plugin marketplace add Drakaniia/codebase-health
codex plugin add codebase-health@codebase-health
```

### OpenCode

Add the package to the `plugin` array in `opencode.json`:

```json
{
  "plugin": ["@drakaniia/codebase-health"]
}
```

All three install the same five skills. The session-start hook is registered for Claude Code and Codex, which read the shared `hooks/hooks.json`.

> **Migrating from `Drakaniia/skills`?** This repo was renamed to `Drakaniia/codebase-health`. GitHub keeps a permanent redirect from the old path, so `npx skills add Drakaniia/skills` and any existing clone URLs still resolve — nothing to do. There is no npm shim to worry about: the old package name was `private: true` and was never published. To move to the plugin, install it as above and remove the old skill directories.

## The Five Skills

| Skill                                                                                 | What It Does                                                                                                                                                                                                                                            | When It Activates                                                                                       |
| ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| **[audit-codebase](./skills/audit-codebase/)**                                        | Scans any repo (language-agnostic) and flags structural issues: folder bloat, oversized files (>400 lines), deep nesting (>4 levels), naming inconsistencies, orphaned files, doc sprawl, and empty directories. Generates a structured markdown report with before/after diagrams. | On demand — when a codebase feels cluttered, disorganized, or hard to navigate.                           |
| **[implement-folder-architecture](./skills/implement-folder-architecture/)**          | Executes the structural fixes from an audit report — moves files, splits directories, updates imports, barrel files, and verifies builds incrementally after each phase.                                                                                | After `audit-codebase` generates a report, or when a systematic folder reorganization is needed.        |
| **[folder-architecture](./skills/folder-architecture/)**                              | Enforces clean folder organization and best-practice file placement _before_ every file creation or modification. Checks file counts, nesting depth, naming conventions, dumping grounds (utils/), barrel file freshness, and import hygiene.              | Every time the agent adds or edits code — proactive prevention.                                          |
| **[code-design](./skills/code-design/)**                                              | Enforces clean function-level design inside files — pure functions, single responsibility, guard clauses, imperative shell pattern, side-effect management, and top-to-bottom readability. Includes a 5-step review checklist and 7 red flags.       | During code review, function creation, or when refactoring oversized functions.                          |
| **[codebase-health](./skills/codebase-health/)**                                      | A thin router. It does not do any work itself — it maps the current situation to the right skill above, and is what the session-start hook injects so the routing table is already in context.                                                             | At session start, and whenever it is unclear which of the four skills applies.                            |

> **Language support:** All skills are language-agnostic — they work on Python, JavaScript/TypeScript, Go, Rust, Java, C#, Ruby, PHP, and any other language. Each includes language-specific reference guides for organization patterns, file-splitting mechanics, and function-level design traps.

## How It Works

Most codebases decay slowly. A file here, a directory there. Before long, you have 47 files in `src/utils/`, a 900-line `services.py`, and no clear convention for where anything goes.

The four working skills approach the problem from opposite ends:

1. **audit-codebase** scans any codebase and surfaces _all_ the structural issues — bloated directories, oversized files, deep nesting, naming chaos, orphaned files. It produces a report with ASCII trees and Mermaid diagrams.

2. **implement-folder-architecture** executes the structural fixes from the audit report — moving files, splitting directories, updating imports, and verifying builds incrementally.

3. **folder-architecture** runs _before_ every file operation — creating, modifying, or moving files. It checks thresholds (file counts, nesting depth, naming consistency) and steers the agent to place things correctly, keeping decay from accumulating.

4. **code-design** enforces clean function-level design _inside_ files — pure functions, single responsibility, guard clauses, side-effect management, and top-to-bottom readability. It runs during code review and function creation.

One is a health checkup. Another is the contractor that does the renovation. The third is the daily hygiene that keeps things clean. The fourth ensures the code inside is as clean as the structure around it. Together they form a layered defense: audit to find problems, fix them systematically, prevent them from recurring, and write clean code from the start.

The fifth, **codebase-health**, is the router that sits on top of that loop and points at whichever step you are on.

## Session-Start Bootstrap

Installing the plugin registers a `SessionStart` hook (`hooks/session-start.mjs`, zero npm dependencies). On startup, resume, clear, and after a compaction, it reads `skills/codebase-health/SKILL.md` and injects it as session context.

The effect: the routing table is already in the model's context before you say anything, so the right skill tends to get picked without a round trip. The hook reads the router at runtime rather than embedding a copy, so editing `SKILL.md` is the only place the routing text lives.

The hook never fails loudly. Any error — missing file, malformed config — still exits `0`, because a non-zero hook exit can wedge a session in the host.

### Opting Out

Either of these disables the bootstrap:

```bash
# Environment variable: 0, off, false, no (case-insensitive)
export CODEBASE_HEALTH=off
```

```json
// ~/.config/codebase-health/config.json
{ "bootstrap": false }
```

The skills themselves stay installed either way; you just lose the automatic injection. A malformed config file fails open — it does not disable the hook.

## How They Work Together

```
audit-codebase
  │
  ├─ Scans entire codebase
  ├─ Generates fix plan
  ├─ Output: markdown report
  └─ Use: quarterly / monthly
        │
        ▼
implement-folder-architecture
  │
  ├─ Reads audit report
  ├─ Executes migration phase by phase
  ├─ Splits folders, moves files, updates imports
  ├─ Verifies build after each step
  └─ Use: after audit-codebase
        │
        ▼
folder-architecture
  │
  ├─ Checks single file ops
  ├─ Warns before bad placement
  ├─ Suggests splits before bloat
  └─ Use: every commit / edit
        │
        ▼
code-design
  │
  ├─ Reviews function-level design
  ├─ Enforces pure functions & SRP
  ├─ Manages side effects (imperative shell)
  └─ Use: during code review / function creation
```

- **Already messy?** Run `audit-codebase` → get a full report → run `implement-folder-architecture` to execute the fix → `folder-architecture` keeps it clean → `code-design` ensures functions inside are well-designed.
- **Starting fresh?** `folder-architecture` activates during file ops, `code-design` activates during function creation — both prevent structural and functional decay from the start.
- **Not sure which one applies?** Ask for `codebase-health` and let the router decide.

## Invoking Skills

Claude Code namespaces plugin skills, so the installed commands are:

| Command                                  | Description                                                      |
| ---------------------------------------- | ---------------------------------------------------------------- |
| `/codebase-health`                       | Route to the right skill for the current task                    |
| `/codebase-health:audit-codebase`        | Scan codebase for structural health issues and generate a report |
| `/codebase-health:implement-folder-architecture` | Execute folder architecture migration from an audit report |
| `/codebase-health:folder-architecture`   | Enforce clean folder organization before file operations         |
| `/codebase-health:code-design`           | Review and enforce clean function-level design inside files      |

Codex exposes the router as `$codebase-health`. Other hosts use their own skill-invocation syntax; the skill directories are plain `SKILL.md` files either way.

### Manual Install

Plugin manifests ship for Claude Code, Codex, and OpenCode. For anything else, skills are auto-discovered from their directory — clone this repo or copy the skill directories to the appropriate location for your platform:

| Platform    | Location                                            |
| ----------- | --------------------------------------------------- |
| Claude Code | `.claude/skills/` or `~/.claude/skills/`            |
| Codex CLI   | `.codex/skills/` or `~/.codex/skills/`              |
| Cursor      | `.cursor/rules/` (see platform docs)                |
| Gemini CLI  | `.agents/skills/` or `~/.agents/skills/`            |
| OpenCode    | `.opencode/skills/` or `~/.config/opencode/skills/` |

For per-agent permissions, configure in `opencode.json`:

```json
{
  "permission": {
    "skill": {
      "audit-codebase": "allow",
      "code-design": "allow",
      "folder-architecture": "allow",
      "implement-folder-architecture": "allow"
    }
  }
}
```

Each skill follows the [Agent Skills open standard](https://openagentskills.dev) — one `SKILL.md` per directory, YAML frontmatter with `name` and `description`, progressive disclosure loading.

## Repository Structure

```
codebase-health/
├── .claude-plugin/                      # Claude manifest + self-marketplace
├── .codex-plugin/                       # Codex manifest
├── .agents/plugins/marketplace.json     # Codex marketplace entry
├── hooks/                               # SessionStart hook (shared by Claude + Codex)
├── skills/
│   ├── codebase-health/                 # Router — injected at session start
│   ├── audit-codebase/                  # Scan → report
│   ├── implement-folder-architecture/   # Report → execution
│   ├── folder-architecture/             # Prevention (file ops)
│   └── code-design/                     # Prevention (function level)
├── _shared/references/                  # Canonical shared references
├── scripts/                             # Build orchestration
├── tests/                               # node:test hook tests
├── .github/workflows/                   # CI validation + release
├── assets/logo.png
├── package.json                         # Published as @drakaniia/codebase-health
├── CONTRIBUTING.md
└── CHANGELOG.md
```

Each skill follows the OAS progressive disclosure pattern:

```
<skill>/
├── SKILL.md              # Loaded on activation (<500 lines)
├── scripts/              # Executable utilities (loaded on demand)
├── references/           # Detailed reference files (generated, loaded on demand)
├── agents/               # Platform agent configs
└── assets/               # Templates, resources (loaded on demand)
```

> **Note:** `skills/*/references/` is build output. The shared copies of `ORGANIZATION-PATTERNS.md` and `SPLITTING-GUIDE.md` are generated from `_shared/references/` and are not committed, so a fresh clone has empty `references/` directories until you run `npm run build`. Hosts resolve a reference miss gracefully — progressive disclosure simply finds no extra file — so skills still work, just without the deep-dive appendices until you build. See [CONTRIBUTING.md](CONTRIBUTING.md#shared-references-are-generated).

## Requirements

- **Node.js >= 18** — a real runtime requirement, for the session-start hook. The hook itself has zero npm dependencies.
- An AI coding agent that supports the Agent Skills spec (`SKILL.md` discovery): Claude Code, Codex, or OpenCode for the plugin path; any spec-compliant agent for the manual path.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines, the release procedure, and the new-skill checklist. Quick overview:

1. Follow the [Agent Skills Specification](https://openagentskills.dev/docs/specification)
2. Keep `SKILL.md` under 500 lines
3. Edit shared references in `_shared/references/`, then run `npm run build`
4. Validate: `npm run validate` (on Windows, `npx skills-ref validate skills/<skill-name>` — the script relies on shell glob expansion)
5. Never hand-edit a version — `npm run bump` is the only legal way
6. Submit a PR

## License

MIT
