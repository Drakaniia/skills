// codebase-health — OpenCode plugin.
//
// OpenCode has no SessionStart hook and no plugin-manifest dialect. It loads a
// package's `main` as an ES module and expects a default export returning hooks.
// So this file is the OpenCode counterpart to hooks/session-start.mjs: it
// registers the skills directory, the /codebase-health command, and injects the
// router into the system prompt.
//
// .js, not .mjs: OpenCode's .opencode/plugins/ auto-discovery globs *.js only
// and silently skips .mjs. ESM still applies because the package sets
// "type": "module".
//
// Claude Code and Codex use hooks/hooks.json instead and never load this file.

import { readFileSync, existsSync, readdirSync } from "node:fs";
import { homedir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

import { isDisabled, stripFrontmatter } from "../../hooks/session-start.mjs";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const ROUTER = join(ROOT, "skills", "codebase-health", "SKILL.md");
const SKILLS = join(ROOT, "skills");

// The router table stays lean because it is injected into every system prompt.
// The command is on-demand, so it can afford the full descriptions — which
// already carry their own trigger conditions, so nothing is restated here.
function skillCard() {
  const rows = readdirSync(SKILLS, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => {
      const file = join(SKILLS, e.name, "SKILL.md");
      if (!existsSync(file)) return null;
      const md = readFileSync(file, "utf8");
      const name = /^---\r?\n[\s\S]*?^name:\s*(.+)$/m.exec(md)?.[1]?.trim();
      const desc = /^---\r?\n[\s\S]*?^description:\s*(.+)$/m.exec(md)?.[1]?.trim();
      return name && desc ? `**\`${name}\`** — ${desc}` : null;
    })
    .filter(Boolean);

  return [
    "Codebase health is continuous practice, not a one-time audit. Five skills:",
    "",
    ...rows,
    "",
    "The loop: **audit → fix → prevent.** `audit-codebase` finds the problems,",
    "`implement-folder-architecture` fixes them, and `folder-architecture` plus",
    "`code-design` keep them from coming back.",
  ].join("\n");
}

export default async () => {
  let router;
  try {
    if (isDisabled(process.env, join(homedir(), ".config", "codebase-health", "config.json"))) return {};
    if (!existsSync(ROUTER)) return {};
    router = stripFrontmatter(readFileSync(ROUTER, "utf8"));
  } catch {
    return {};
  }

  let card;
  try {
    card = skillCard();
  } catch {
    card = router;
  }

  return {
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(SKILLS)) config.skills.paths.push(SKILLS);

      // /codebase-health — the reference card. Built from each skill's own
      // frontmatter, so a new skill appears here on its own. Per-skill slash
      // commands stay absent: the skills are already invocable, and
      // re-adding commands/ is what decision 12 removed.
      config.command = config.command || {};
      config.command["codebase-health"] = {
        description:
          "List the codebase-health skills and when each one applies. Reference only — runs no audit and changes no files. Skills: audit-codebase (cluttered or disorganized codebase), implement-folder-architecture (an audit report exists and the fixes need executing), folder-architecture (about to create, move, or modify a file), code-design (reviewing, writing, or refactoring a function).",
        template: card,
      };
    },

    "experimental.chat.system.transform": async (_input, output) => {
      if (output.system.length > 0) {
        output.system[output.system.length - 1] += `\n\n${router}`;
      } else {
        output.system.push(router);
      }
    },
  };
};
