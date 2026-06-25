# Skills

> Language-agnostic agent skills for keeping codebases healthy — one detects structural problems, the other prevents them before they happen.

Agent skills are reusable instructions that coding agents (OpenCode, Claude Code, Codex, Cursor, and others) discover and load on demand. This repo is a collection of skills built around a single philosophy: **codebase health is a continuous practice, not a one-time audit.**

## How It Works

Most codebases decay slowly. A file here, a directory there. Before long, you have 47 files in `src/utils/`, a 900-line `services.py`, and no clear convention for where anything goes.

These two skills approach the problem from opposite ends:

1. **audit-codebase** scans any codebase and surfaces *all* the structural issues —bloated directories, oversized files, deep nesting, naming chaos, orphaned files. It produces a report with ASCII trees and Mermaid diagrams that another AI session can implement from directly.

2. **folder-architecture** runs *before* every file operation — creating, modifying, or moving files. It checks thresholds (file counts, nesting depth, naming consistency) and steers the agent to place things correctly, keeping decay from accumulating.

One is a health checkup. The other is daily hygiene. Together they form a closed loop: audit to find problems, then prevent them from recurring.

## Skills

### Codebase Health

| Skill | What It Does | When It Activates |
|---|---|---|
| **[audit-codebase](./skills/audit-codebase/)** | Scans any repo (language-agnostic) and flags structural issues: folder bloat, oversized files (>400 lines), deep nesting (>4 levels), naming inconsistencies, orphaned files, doc sprawl, and empty directories. Generates a structured markdown report with before/after diagrams that an AI can implement from. | On demand — when a codebase feels cluttered, disorganized, or hard to navigate. |
| **[folder-architecture](./skills/folder-architecture/)** | Enforces clean folder organization and best-practice file placement *before* every file creation or modification. Checks file counts, nesting depth, naming conventions, dumping grounds (utils/), barrel file freshness, and import hygiene. | Every time the agent adds or edits code — proactive prevention. |

### Language Support

Both skills are fully language-agnostic. They work on Python, JavaScript/TypeScript, Go, Rust, Java, C#, Ruby, PHP, and any other language without modification. Each includes language-specific reference guides for organization patterns and file-splitting mechanics.

## How They Work Together

```
audit-codebase                    folder-architecture
  │                                    │
  ├─ Scans entire codebase             ├─ Checks single file ops
  ├─ Generates fix plan                ├─ Warns before bad placement
  ├─ Output: markdown report           ├─ Suggests splits before bloat
  └─ Use: quarterly / monthly          └─ Use: every commit / edit
```

- **Already messy?** Run `audit-codebase` → get a full report split into refactoring phases → fix issues.
- **Want to stay clean?** `folder-architecture` activates automatically during file operations to prevent new problems.
- **Both installed?** The agent seamlessly uses each when appropriate — folder-architecture during daily work, audit-codebase when the user asks for a health check.

## Installation

### Quick install with npx (recommended)

```bash
# Install all skills
npx skills add Drakaniia/skills

# Install specific skills
npx skills add Drakaniia/skills --skill folder-architecture
npx skills add Drakaniia/skills --skill audit-codebase

# Install globally instead of project-local
npx skills add Drakaniia/skills -g

# See what's available without installing
npx skills add Drakaniia/skills --list
```

### Manual install

Skills are auto-discovered from their directory. Clone this repo and your agent will find them in the expected paths. Alternatively, symlink or copy the `skills/` directory into your project's `.opencode/skills/` or global `~/.config/opencode/skills/`.

For per-agent permissions, configure in `opencode.json`:

```json
{
  "permission": {
    "skill": {
      "audit-codebase": "allow",
      "folder-architecture": "allow"
    }
  }
}
```

### Commands (Slash Commands in TUI)

After installation, use these commands in your agent's TUI:

| Command | Description |
|---|---|
| `/audit-codebase` | Scan codebase for structural health issues and generate a report |
| `/folder-architecture` | Enforce clean folder organization before file operations |

### Manual Install (Non-npx)

Copy the skill directories to the appropriate location for your platform:

| Platform | Location |
|---|---|
| Claude Code | `.claude/skills/` or `~/.claude/skills/` |
| Codex CLI | `.codex/skills/` or `~/.codex/skills/` |
| Cursor | `.cursor/rules/` (see platform docs) |
| Gemini CLI | `.agents/skills/` or `~/.agents/skills/` |
| OpenCode | `.opencode/skills/` or `~/.config/opencode/skills/` |

Each skill follows the [Agent Skills open standard](https://openagentskills.dev) — one `SKILL.md` per directory, YAML frontmatter with `name` and `description`, progressive disclosure loading.

## Requirements

- An AI coding agent that supports the Agent Skills spec (SKILL.md discovery)
- No additional dependencies, packages, or runtime — everything runs through your agent's native tools

## Contributing

Skills are structured as standalone `SKILL.md` files with optional `references/`, `scripts/`, and `agents/` subdirectories. If you'd like to add a skill or improve an existing one:

1. Follow the [Agent Skills Specification](https://openagentskills.dev/docs/specification) for directory structure and frontmatter
2. Keep `SKILL.md` under 500 lines — move depth into reference files
3. Ensure the skill is language-agnostic or explicitly scopes its language support
4. Submit a PR

## License

Apache-2.0
