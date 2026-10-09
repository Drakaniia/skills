# codebase-health for OpenCode

Complete guide for using codebase-health with [OpenCode.ai](https://opencode.ai).

## Installation

### OpenCode V1

```json
{
  "plugin": ["@qwenzy/codebase-health@latest"]
}
```

### OpenCode V2 (2.0.4 or later)

```json
{
  "plugins": ["@qwenzy/codebase-health@latest"]
}
```

Either `opencode.json` or `opencode.jsonc` works — same schema. Restart
OpenCode. The plugin installs through OpenCode's plugin manager (Bun installs
and caches the npm package at startup) and registers all five skills.

Verify by asking: `/codebase-health` — it lists every skill with the condition
it fires under.

### Migrating from a manual copy

If you previously copied `skills/` into `.opencode/skills/` or
`~/.config/opencode/skills/`, remove the old copy:

```bash
rm -rf .opencode/skills/audit-codebase .opencode/skills/implement-folder-architecture .opencode/skills/folder-architecture .opencode/skills/code-design .opencode/skills/codebase-health
```

Then follow the installation steps above.

## Usage

### Finding Skills

Use OpenCode's native `skill` tool to list all available skills:

```
use skill tool to list skills
```

### Loading a Skill

```
use skill tool to load audit-codebase
```

### The Five Skills

| Skill | When it fires |
| --- | --- |
| `audit-codebase` | User says the codebase feels cluttered, disorganized, or hard to navigate |
| `implement-folder-architecture` | An audit report exists and the fixes need executing |
| `folder-architecture` | The agent is about to create, move, or modify any file |
| `code-design` | Reviewing, writing, or refactoring a function |

`codebase-health` itself is the router — the plugin injects it at session
start and registers it as the `/codebase-health` reference card.

### Personal Skills

Create your own skills in `~/.config/opencode/skills/`. Project skills go in
`.opencode/skills/` within your project.

## Updating

To pin a specific version instead of tracking `latest` (same form for the V1
`plugin` key and the V2 `plugins` key):

```json
{
  "plugins": ["@qwenzy/codebase-health@2.1.1"]
}
```

## How It Works

OpenCode has no `SessionStart` hook, so the package ships a small OpenCode
adapter at `.opencode/plugins/codebase-health.js` (its `main`). It does three
things:

1. **Registers the skills directory** via the `config` hook, injecting into
   `config.skills.paths` — no symlinks or manual config.
2. **Registers the `/codebase-health` command** — a reference card built from
   each skill's own frontmatter, so a new skill appears there on its own.
   Reference only: it runs no audit and changes no files.
3. **Injects the router** via `experimental.chat.system.transform` — the same
   opt-out rules apply (`CODEBASE_HEALTH=off` or
   `~/.config/codebase-health/config.json` with `{"bootstrap": false}`).

Working inside a clone of this repo needs no config at all: OpenCode
auto-discovers `.opencode/plugins/*.js`, so the adapter loads on its own.

Skills speak in actions ("create a todo", "dispatch a subagent", "read a
file"). Map them to OpenCode's native tools:

- "Create or update todos" → `todowrite`
- `Subagent (general-purpose):` → `task` tool with `subagent_type: "general"`
  (or `"explore"` for codebase exploration)
- "Invoke a skill" → OpenCode's native `skill` tool
- "Read a file" → `read`
- "Create a file" / "edit a file" / "delete a file" → `apply_patch`
- "Run a shell command" → `bash`
- "Search file contents" / "find files by name" → `grep`, `glob`
- "Fetch a URL" → `webfetch`

## Troubleshooting

### Plugin not loading

1. Verify the plugin line in your `opencode.json` / `opencode.jsonc`.
2. Check logs. V1: `opencode run --print-logs "hello" 2>&1 | grep -i codebase-health`.
   V2 loads plugins in the background server, so add `--standalone`:
   `opencode run --standalone --print-logs "hello" 2>&1 | grep -i codebase-health`.
3. Make sure you're running a recent version of OpenCode.

### Windows install issues

If OpenCode cannot install the npm package, install with system npm and point
OpenCode at the local package with an absolute path (OpenCode does not expand
`~`):

```powershell
npm install @qwenzy/codebase-health --prefix "$HOME\.config\opencode"
```

**V1:**

```json
{
  "plugin": ["C:\\Users\\<you>\\.config\\opencode\\node_modules\\@qwenzy\\codebase-health"]
}
```

**V2 (2.0.4 or later):**

```json
{
  "plugins": ["C:\\Users\\<you>\\.config\\opencode\\node_modules\\@qwenzy\\codebase-health"]
}
```

### Skills not found

1. Use the `skill` tool to list available skills.
2. Check that the plugin is loading (see above).
3. Each skill needs a `SKILL.md` file with valid YAML frontmatter.

## Getting Help

- Report issues: https://github.com/Drakaniia/codebase-health/issues
- Main documentation: https://github.com/Drakaniia/codebase-health
