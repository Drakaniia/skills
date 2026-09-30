import { test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, writeFileSync, copyFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

import { isDisabled, stripFrontmatter, shapeOutput } from "../hooks/session-start.mjs";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const HOOK = join(ROOT, "hooks", "session-start.mjs");

const tmp = () => mkdtempSync(join(tmpdir(), "ch-"));

function run(env = {}, cwd = ROOT, hook = HOOK) {
  return spawnSync(process.execPath, [hook], {
    input: JSON.stringify({ hook_event_name: "SessionStart", source: "startup" }),
    encoding: "utf8",
    env: { ...process.env, ...env },
    cwd,
  });
}

test("stripFrontmatter: removes YAML block, body survives", () => {
  assert.equal(stripFrontmatter("---\nname: a\n---\n\nbody text\n"), "body text");
});

test("stripFrontmatter: doc with no frontmatter passes through unchanged", () => {
  assert.equal(stripFrontmatter("just a body\n"), "just a body");
});

test("stripFrontmatter: CRLF input handled", () => {
  assert.equal(stripFrontmatter("---\r\nname: a\r\n---\r\n\r\nbody\r\n"), "body");
});

test("isDisabled: off/0/false/no disable, case-insensitive and trimmed", () => {
  for (const v of ["off", "0", "false", "no", "OFF", "  No  "]) {
    assert.equal(isDisabled({ CODEBASE_HEALTH: v }, join(tmp(), "missing.json")), true, v);
  }
});

test("isDisabled: full/on/1/true do not disable", () => {
  for (const v of ["full", "on", "1", "true", ""]) {
    assert.equal(isDisabled({ CODEBASE_HEALTH: v }, join(tmp(), "missing.json")), false, v);
  }
});

test("isDisabled: config file {bootstrap:false} disables", () => {
  const d = tmp();
  const p = join(d, "config.json");
  writeFileSync(p, JSON.stringify({ bootstrap: false }));
  assert.equal(isDisabled({}, p), true);
});

test("isDisabled: config file {bootstrap:true} does not disable", () => {
  const d = tmp();
  const p = join(d, "config.json");
  writeFileSync(p, JSON.stringify({ bootstrap: true }));
  assert.equal(isDisabled({}, p), false);
});

test("isDisabled: malformed config JSON fails open", () => {
  const d = tmp();
  const p = join(d, "config.json");
  writeFileSync(p, "{ not json");
  assert.equal(isDisabled({}, p), false);
});

test("isDisabled: missing config file does not disable", () => {
  assert.equal(isDisabled({}, join(tmp(), "absent.json")), false);
});

test("shapeOutput: emits hookSpecificOutput.additionalContext", () => {
  const out = shapeOutput("ctx");
  assert.equal(out.hookSpecificOutput.additionalContext, "ctx");
  assert.equal(out.hookSpecificOutput.hookEventName, "SessionStart");
});

test("end-to-end: exits 0 with parseable JSON on stdout", () => {
  const r = run();
  assert.equal(r.status, 0);
  const parsed = JSON.parse(r.stdout);
  assert.ok(parsed.hookSpecificOutput.additionalContext.length > 0);
});

test("end-to-end: CODEBASE_HEALTH=off exits 0 with empty output", () => {
  const r = run({ CODEBASE_HEALTH: "off" });
  assert.equal(r.status, 0);
  assert.equal(r.stdout, "");
});

test("resilience: missing SKILL.md exits 0 rather than wedging the session", () => {
  const d = tmp();
  mkdirSync(join(d, "hooks"));
  const staged = join(d, "hooks", "session-start.mjs");
  copyFileSync(HOOK, staged);
  const r = run({}, d, staged);
  assert.equal(r.status, 0);
  assert.equal(r.stdout, "");
});

test("router body survives the round trip: no frontmatter in output", () => {
  const parsed = JSON.parse(execFileSync(process.execPath, [HOOK], { input: "{}", encoding: "utf8" }));
  assert.doesNotMatch(parsed.hookSpecificOutput.additionalContext, /^---\r?\n/);
});
