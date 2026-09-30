#!/usr/bin/env node
// package.json `version` is the single source of truth. This script writes it
// into every manifest and skill frontmatter. It never writes package.json.
//
//   node _shared/scripts/bump-version.mjs           # write
//   node _shared/scripts/bump-version.mjs --check   # exit 1 on drift, write nothing

import { readFileSync, writeFileSync, readdirSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const CHECK = process.argv.includes("--check");

const JSON_TARGETS = [
  [".claude-plugin/plugin.json", (j) => j.version],
  [".claude-plugin/marketplace.json", (j) => j.plugins[0].version],
  [".codex-plugin/plugin.json", (j) => j.version],
  [".agents/plugins/marketplace.json", (j) => j.plugins[0].version],
];

const version = JSON.parse(readFileSync(join(ROOT, "package.json"), "utf8")).version;
if (typeof version !== "string" || !version) {
  console.error("package.json has no `version` to sync from");
  process.exit(1);
}

const drifted = [];
let changed = 0;

// `version:` line inside the SKILL.md frontmatter `metadata:` block.
const FM_VERSION = /^(---\r?\n[\s\S]*?^\s*metadata:\r?\n(?:[ \t]+.*\r?\n)*?[ \t]+version:\s*)[^\n]*/m;

function write(file, next, current) {
  if (next === current) return;
  drifted.push(file);
  if (CHECK) return;
  writeFileSync(join(ROOT, file), next);
  changed++;
}

for (const [file, get] of JSON_TARGETS) {
  if (!existsSync(join(ROOT, file))) {
    console.error(`missing ${file} — create it before running bump-version`);
    process.exit(1);
  }
  const raw = readFileSync(join(ROOT, file), "utf8");
  const json = JSON.parse(raw);
  if (get(json) === version) continue;
  // Surgical string edit so the rest of the file keeps its exact formatting.
  const next = raw.replace(
    /("version"\s*:\s*)"[^"]*"/,
    (_, prefix) => `${prefix}${JSON.stringify(version)}`
  );
  if (next === raw) {
    console.error(`could not find a version field in ${file}`);
    process.exit(1);
  }
  write(file, next, raw);
}

const skillsDir = join(ROOT, "skills");
if (existsSync(skillsDir)) {
  for (const skill of readdirSync(skillsDir, { withFileTypes: true })) {
    if (!skill.isDirectory()) continue;
    const file = `skills/${skill.name}/SKILL.md`;
    if (!existsSync(join(ROOT, file))) continue;
    const raw = readFileSync(join(ROOT, file), "utf8");
    // Only the `version:` line inside the leading `metadata:` block may change.
    if (!FM_VERSION.test(raw)) {
      console.log(`note: ${file} has no metadata.version, skipped`);
      continue;
    }
    write(file, raw.replace(FM_VERSION, (_, prefix) => prefix + JSON.stringify(version)), raw);
  }
}

if (CHECK) {
  if (drifted.length === 0) {
    console.log(`version in sync: ${version}`);
    process.exit(0);
  }
  console.error(`version drift (package.json says ${version}):`);
  for (const file of drifted) console.error(`  ${file}`);
  console.error("run: npm run bump");
  process.exit(1);
}

console.log(
  changed === 0
    ? `version already in sync: ${version}`
    : `wrote ${version} to ${changed} file(s)`
);
