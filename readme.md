# Skills

> Language-agnostic agent skills for keeping codebases healthy — audit structural health, execute fixes, prevent decay, design clean functions, and ship pixel-perfect UI components.

Agent skills are reusable instructions that coding agents (OpenCode, Claude Code, Codex, Cursor, and others) discover and load on demand. This repo is a collection of skills built around a single philosophy: **codebase health is a continuous practice, not a one-time audit.**

## Quick Install

```bash
npx skills add Drakaniia/skills
```

## How It Works

Most codebases decay slowly. A file here, a directory there. Before long, you have 47 files in `src/utils/`, a 900-line `services.py`, and no clear convention for where anything goes.

These five skills approach the problem from complementary angles:

1. **audit-codebase** scans any codebase and surfaces _all_ the structural issues — bloated directories, oversized files, deep nesting, naming chaos, orphaned files. It produces a report with ASCII trees and Mermaid diagrams.

2. **implement-folder-architecture** executes the structural fixes from the audit report — moving files, splitting directories, updating imports, and verifying builds incrementally.

3. **folder-architecture** runs _before_ every file operation — creating, modifying, or moving files. It checks thresholds (file counts, nesting depth, naming consistency) and steers the agent to place things correctly, keeping decay from accumulating.

4. **code-design** enforces clean function-level design _inside_ files — pure functions, single responsibility, guard clauses, side-effect management, and top-to-bottom readability. It runs during code review and function creation.

5. **visual-regression** turns reference images (screenshots, Figma exports, mockups) into Playwright visual tests. Saves the image as a baseline, writes the test, then guides the fix → re-run → diff loop until the component matches the reference pixel-perfectly.

Audit to find problems, fix them systematically, prevent them from recurring, write clean code from the start, and verify it looks right. Together they form a layered defense: audit to find problems, fix them systematically, prevent them from recurring, and write clean code from the start.

## Skills

### Codebase Health

### Codebase Health

| Skill                                                                        | What It Does                                                                                                                                                                                                                                                                        | When It Activates                                                                                |
| ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **[audit-codebase](./skills/audit-codebase/)**                               | Scans any repo (language-agnostic) and flags structural issues: folder bloat, oversized files (>400 lines), deep nesting (>4 levels), naming inconsistencies, orphaned files, doc sprawl, and empty directories. Generates a structured markdown report with before/after diagrams. | On demand — when a codebase feels cluttered, disorganized, or hard to navigate.                  |
| **[implement-folder-architecture](./skills/implement-folder-architecture/)** | Executes the structural fixes from an audit report — moves files, splits directories, updates imports, barrel files, and verifies builds incrementally after each phase.                                                                                                            | After `audit-codebase` generates a report, or when a systematic folder reorganization is needed. |
| **[folder-architecture](./skills/folder-architecture/)**                     | Enforces clean folder organization and best-practice file placement _before_ every file creation or modification. Checks file counts, nesting depth, naming conventions, dumping grounds (utils/), barrel file freshness, and import hygiene.                                       | Every time the agent adds or edits code — proactive prevention.                                  |
| **[code-design](./skills/code-design/)**                                     | Enforces clean function-level design inside files — pure functions, single responsibility, guard clauses, imperative shell pattern, side-effect management, and top-to-bottom readability. Includes a 5-step review checklist and 7 red flags.                                      | During code review, function creation, or when refactoring oversized functions.                  |

### Visual Testing

| Skill                                                | What It Does                                                                                                                                                                                                                                                 | When It Activates                                                                   |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------- |
| **[visual-regression](./skills/visual-regression/)** | Turns user-provided reference images into Playwright visual tests. Saves the reference as a baseline, writes the test, and guides the fix → re-run → diff loop until the component matches pixel-perfectly. Includes troubleshooting and edge case guidance. | When the user provides a reference image and wants a component to match it exactly. |

> **Language support:** All skills are language-agnostic — they work on Python, JavaScript/TypeScript, Go, Rust, Java, C#, Ruby, PHP, and any other language. Each includes language-specific reference guides for organization patterns, file-splitting mechanics, and function-level design traps.

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
        │
        ▼
visual-regression
  │
  ├─ Receives reference image (screenshot / Figma export / mockup)
  ├─ Saves as baseline in e2e/visual/baselines/
  ├─ Writes Playwright visual test
  ├─ Guides fix → re-run → diff → pass loop
  └─ Use: when matching a component to a reference image
```

- **Already messy?** Run `audit-codebase` → get a full report → run `implement-folder-architecture` to execute the fix → `folder-architecture` keeps it clean → `code-design` ensures functions inside are well-designed → `visual-regression` verifies the UI matches the design spec.
- **Starting fresh?** `folder-architecture` activates during file ops, `code-design` activates during function creation, `visual-regression` activates when reference images are provided.
- **All five installed?** The agent seamlessly uses each when appropriate — `folder-architecture` during daily work, `code-design` during code review, `audit-codebase` when the user asks for a health check, `implement-folder-architecture` when the audit report needs to be executed, and `visual-regression` when a component needs to match a reference image.

### Manual Install

Skills are auto-discovered from their directory. Clone this repo or copy the skill directories to the appropriate location for your platform:

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
      "folder-architecture": "allow",
      "code-design": "allow",
      "visual-regression": "allow"
    }
  }
}
```

Each skill follows the [Agent Skills open standard](https://openagentskills.dev) — one `SKILL.md` per directory, YAML frontmatter with `name` and `description`, progressive disclosure loading.

## Commands

After installation, use these commands in your agent's TUI:

| Command                          | Description                                                      |
| -------------------------------- | ---------------------------------------------------------------- |
| `/audit-codebase`                | Scan codebase for structural health issues and generate a report |
| `/implement-folder-architecture` | Execute folder architecture migration from an audit report       |
| `/folder-architecture`           | Enforce clean folder organization before file operations         |
| `/code-design`                   | Review and enforce clean function-level design inside files      |
| `/visual-regression`             | Implement pixel-perfect components from reference images         |

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
