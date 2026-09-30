#!/usr/bin/env node
// Emits the codebase-health router as session context.

import { readFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROUTER = join(HERE, "..", "skills", "codebase-health", "SKILL.md");

export function isDisabled(env, configPath) {
  const v = String(env.CODEBASE_HEALTH ?? "").trim().toLowerCase();
  if (["0", "off", "false", "no"].includes(v)) return true;
  if (existsSync(configPath)) {
    try {
      return JSON.parse(readFileSync(configPath, "utf8")).bootstrap === false;
    } catch {}
  }
  return false;
}

export function stripFrontmatter(md) {
  const m = /^---\r?\n[\s\S]*?\r?\n---\r?\n?/.exec(md);
  return m ? md.slice(m[0].length).trim() : md.trim();
}

// Both Claude Code and Codex read hookSpecificOutput.additionalContext; the flat
// top-level additionalContext is Copilot-only. Verified against ponytail
// hooks/ponytail-runtime.js:87-95 and superpowers hooks/session-start:41-43.
export function shapeOutput(text) {
  return {
    hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: text },
  };
}

function drainStdin() {
  return new Promise((resolve) => {
    if (process.stdin.isTTY) return resolve();
    process.stdin.on("error", resolve);
    process.stdin.on("end", resolve);
    process.stdin.resume();
  });
}

async function main() {
  await drainStdin();
  if (isDisabled(process.env, join(homedir(), ".config", "codebase-health", "config.json"))) return;
  if (!existsSync(ROUTER)) return;
  process.stdout.write(JSON.stringify(shapeOutput(stripFrontmatter(readFileSync(ROUTER, "utf8")))));
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    await main();
  } catch {}
  process.exitCode = 0;
}
