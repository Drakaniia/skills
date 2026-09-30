// codebase-health — OpenCode plugin.
//
// OpenCode has no SessionStart hook and no plugin-manifest dialect. It loads a
// package's `main` as an ES module and expects a default export returning hooks.
// So this file is the OpenCode counterpart to hooks/session-start.mjs: it
// registers the skills directory and injects the router into the system prompt.
//
// Claude Code and Codex use hooks/hooks.json instead and never load this file.

import { readFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

import { isDisabled, stripFrontmatter } from "../../hooks/session-start.mjs";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const ROUTER = join(ROOT, "skills", "codebase-health", "SKILL.md");
const SKILLS = join(ROOT, "skills");

export default async () => {
  let router;
  try {
    if (isDisabled(process.env, join(homedir(), ".config", "codebase-health", "config.json"))) return {};
    if (!existsSync(ROUTER)) return {};
    router = stripFrontmatter(readFileSync(ROUTER, "utf8"));
  } catch {
    return {};
  }

  return {
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(SKILLS)) config.skills.paths.push(SKILLS);
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
