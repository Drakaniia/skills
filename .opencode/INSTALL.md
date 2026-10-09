# Installing codebase-health for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

## Installation

### OpenCode V1

Add the package to the `plugin` array in `opencode.json` (or `opencode.jsonc` —
same schema, either filename works):

```json
{
  "plugin": ["@qwenzy/codebase-health@latest"]
}
```

### OpenCode V2 (2.0.4 or later)

V2 renamed the key to `plugins` (plural):

```json
{
  "plugins": ["@qwenzy/codebase-health@latest"]
}
```

Restart OpenCode. The plugin installs through OpenCode's plugin manager
(Bun installs and caches the npm package at startup — no separate
`npm install` step) and registers all five skills.

Verify by asking: `/codebase-health` — it lists every skill with the
condition it fires under.

OpenCode uses its own plugin install. If you also use Claude Code, Codex, or
another harness, install codebase-health separately for each one.

## Migrating from a manual copy

If you previously copied `skills/` into `.opencode/skills/` or
`~/.config/opencode/skills/`, remove the old copy:

```bash
rm -rf .opencode/skills/audit-codebase .opencode/skills/implement-folder-architecture .opencode/skills/folder-architecture .opencode/skills/code-design .opencode/skills/codebase-health
```

Then follow the installation steps above. Working inside a clone of this repo
needs no config at all: OpenCode auto-discovers `.opencode/plugins/*.js`, so
the adapter loads on its own.

## Usage

Use OpenCode's native `skill` tool:

```
use skill tool to list skills
use skill tool to load audit-codebase
```

## Updating

To pin a specific version instead of tracking `latest`, add the version to the
spec (same form for the V1 `plugin` key and the V2 `plugins` key):

```json
{
  "plugins": ["@qwenzy/codebase-health@2.1.1"]
}
```

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
`~`; a `~/...` entry is treated as a package name, not a local directory):

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

1. Use the `skill` tool to list what's discovered.
2. Check that the plugin is loading (see above).

## Getting Help

- Report issues: https://github.com/Drakaniia/codebase-health/issues
- Full documentation: https://github.com/Drakaniia/codebase-health/blob/main/docs/README.opencode.md
