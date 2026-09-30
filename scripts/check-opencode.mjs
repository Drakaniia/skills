#!/usr/bin/env node
// npm run check-opencode — assert the OpenCode adapter is actually reachable.
//
// Both bugs this caught were silent: OpenCode accepts an unresolvable plugin
// spec, creates an empty cache dir, and carries on. Nothing errors. So assert
// the things that must hold, and fail loudly when they do not.

import { existsSync, readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const PLUGIN = join(ROOT, ".opencode", "plugins", "codebase-health.js");
const PKG = join(ROOT, "package.json");

const fail = [];
const check = (ok, msg) => {
  console.log(`${ok ? "ok   " : "FAIL "} ${msg}`);
  if (!ok) fail.push(msg);
};

// 1. The adapter must be .js. OpenCode's .opencode/plugins/ auto-discovery
//    globs *.js and silently skips .mjs, so a .mjs adapter never loads.
check(existsSync(PLUGIN), "adapter exists at .opencode/plugins/codebase-health.js");
check(!existsSync(PLUGIN.replace(/\.js$/, ".mjs")), "no stray .mjs adapter (auto-discovery skips it)");

// 2. package.json must point main and files at the real filename.
const pkg = JSON.parse(readFileSync(PKG, "utf8"));
check(pkg.main === "./.opencode/plugins/codebase-health.js", `package.json main -> ${pkg.main}`);
check(pkg.files.includes(".opencode/plugins/codebase-health.js"), "files[] ships the adapter");
check(pkg.type === "module", 'package.json type is "module" (adapter uses ESM)');

// 3. The adapter must load and expose exactly one default export. OpenCode's
//    legacy loader treats every exported function as a plugin, so a stray
//    named export of a function gets called with the plugin context.
const mod = await import(`file:///${PLUGIN.replace(/\\/g, "/")}`);
const named = Object.keys(mod).filter((k) => k !== "default" && typeof mod[k] === "function");
check(typeof mod.default === "function", "adapter default-exports a function");
check(named.length === 0, `no stray function exports (found: ${named.join(", ") || "none"})`);

// 4. The plugin must register the command and the skills path.
const config = {};
await mod.default({}).then((p) => p.config(config));
check(Boolean(config.command?.["codebase-health"]), "registers /codebase-health");
check(
  Array.isArray(config.skills?.paths) && config.skills.paths.some((p) => p.endsWith("skills")),
  "registers the bundled skills directory",
);

if (fail.length) {
  console.error(`\n${fail.length} check(s) failed`);
  process.exit(1);
}
console.log("\nall checks passed");
