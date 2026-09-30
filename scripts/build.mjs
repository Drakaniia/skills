#!/usr/bin/env node
// npm run build — generate the shared references, then validate every skill.
// Both steps need optional tooling (bash, skills-ref), so a missing tool is a
// skip notice, not a build failure. A tool that runs and reports a problem is
// still fatal.

import { spawnSync } from "node:child_process";
import { readdirSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const SKILLS_REF = join(ROOT, "node_modules", "skills-ref", "dist", "cli.js");

function run(label, file, args) {
  const r = spawnSync(file, args, { cwd: ROOT, stdio: "inherit" });
  if (r.status !== 0) {
    console.error(`fail  ${label}: exit ${r.status ?? r.signal}`);
    process.exit(r.status ?? 1);
  }
  console.log(`ok    ${label}`);
}

console.log("building codebase-health\n");

const validateOnly = process.argv.includes("--validate-only");

if (!validateOnly) {
  if (!spawnSync("bash", ["--version"], { stdio: "ignore" }).error) {
    run("sync references", "bash", ["_shared/scripts/sync-references.sh"]);
  } else {
    console.log("skip  sync references: bash not on PATH (run the sync script in Git Bash)");
  }
}

if (!existsSync(SKILLS_REF)) {
  console.log("skip  validate skills: skills-ref not installed (npm i, then npm run validate)");
} else {
  // Expand the glob here: PowerShell does not glob native-command args, and
  // `skills-ref validate` accepts exactly one path.
  const skills = readdirSync(join(ROOT, "skills"), { withFileTypes: true })
    .filter((e) => e.isDirectory() && existsSync(join(ROOT, "skills", e.name, "SKILL.md")))
    .map((e) => `./skills/${e.name}`);
  for (const skill of skills) {
    run(`validate ${skill}`, process.execPath, [SKILLS_REF, "validate", skill]);
  }
}

console.log("\ndone");
