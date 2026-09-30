import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync, mkdirSync, existsSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { stripFrontmatter } from "../hooks/session-start.mjs";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const PLUGIN = join(ROOT, ".opencode", "plugins", "codebase-health.js");

async function loadPlugin(env) {
  for (const k of ["CODEBASE_HEALTH"]) delete process.env[k];
  if (env?.CODEBASE_HEALTH) process.env.CODEBASE_HEALTH = env.CODEBASE_HEALTH;
  const mod = await import(`${pathToFileURL(PLUGIN).href}?t=${Math.random()}`);
  return mod.default({});
}

test("registers the bundled skills directory", async () => {
  const plugin = await loadPlugin();
  const config = {};
  await plugin.config(config);
  assert.equal(config.skills.paths.length, 1);
  // .opencode/plugins/<file> -> up two -> repo root -> skills/
  assert.equal(config.skills.paths[0], join(ROOT, "skills"));
  assert.ok(existsSync(join(config.skills.paths[0], "codebase-health", "SKILL.md")));
});

test("does not duplicate the skills path when applied twice", async () => {
  const plugin = await loadPlugin();
  const config = {};
  await plugin.config(config);
  await plugin.config(config);
  assert.equal(config.skills.paths.length, 1);
});

test("preserves an existing skills path from user config", async () => {
  const plugin = await loadPlugin();
  const config = { skills: { paths: ["/my/own/skills"] } };
  await plugin.config(config);
  assert.equal(config.skills.paths.length, 2);
  assert.equal(config.skills.paths[0], "/my/own/skills");
});

test("injects the router into a non-empty system prompt", async () => {
  const plugin = await loadPlugin();
  const output = { system: ["base prompt"] };
  await plugin["experimental.chat.system.transform"]({}, output);
  assert.equal(output.system.length, 1);
  assert.ok(output.system[0].startsWith("base prompt"));
  assert.ok(output.system[0].includes("Codebase Health"));
});

test("injects the router when the system prompt is empty", async () => {
  const plugin = await loadPlugin();
  const output = { system: [] };
  await plugin["experimental.chat.system.transform"]({}, output);
  assert.equal(output.system.length, 1);
  assert.ok(output.system[0].includes("Codebase Health"));
});

test("the injected router has no YAML frontmatter", async () => {
  const plugin = await loadPlugin();
  const output = { system: [] };
  await plugin["experimental.chat.system.transform"]({}, output);
  assert.ok(!output.system[0].startsWith("---"));
  assert.ok(!output.system[0].includes("name: codebase-health"));
});

test("registers /codebase-health whose template is the router itself", async () => {
  const plugin = await loadPlugin();
  const config = {};
  await plugin.config(config);
  const cmd = config.command["codebase-health"];
  assert.ok(cmd, "command not registered");
  assert.ok(cmd.description.length > 0);
  // One source of truth: the command body is the router, not a copy of it.
  const routerBody = stripFrontmatter(
    readFileSync(join(ROOT, "skills", "codebase-health", "SKILL.md"), "utf8"),
  );
  assert.equal(cmd.template, routerBody);
  for (const s of ["audit-codebase", "folder-architecture", "code-design", "implement-folder-architecture"]) {
    assert.ok(cmd.template.includes(s), `routing table missing ${s}`);
  }
});

test("preserves user-defined commands", async () => {
  const plugin = await loadPlugin();
  const config = { command: { "my-own": { description: "mine", template: "hi" } } };
  await plugin.config(config);
  assert.equal(Object.keys(config.command).length, 2);
  assert.ok(config.command["my-own"]);
});

test("CODEBASE_HEALTH=off registers no command either", async () => {
  const plugin = await loadPlugin({ CODEBASE_HEALTH: "off" });
  assert.deepEqual(plugin, {});
  assert.equal(plugin.config, undefined);
});

test("CODEBASE_HEALTH=off yields no hooks at all", async () => {
  const plugin = await loadPlugin({ CODEBASE_HEALTH: "off" });
  assert.deepEqual(plugin, {});
});

test("a missing router degrades to no hooks rather than throwing", async () => {
  const dir = mkdtempSync(join(tmpdir(), "ch-"));
  mkdirSync(join(dir, ".opencode", "plugins"), { recursive: true });
  mkdirSync(join(dir, "hooks"), { recursive: true });
  writeFileSync(
    join(dir, ".opencode", "plugins", "p.mjs"),
    `import { isDisabled, stripFrontmatter } from "${pathToFileURL(join(ROOT, "hooks", "session-start.mjs")).href}";
export default async () => {
  if (isDisabled(process.env, "")) return {};
  return { config: async () => {}, "experimental.chat.system.transform": async (_i, o) => o.system.push(stripFrontmatter("no router here")) };
};`,
  );
  const mod = await import(pathToFileURL(join(dir, ".opencode", "plugins", "p.mjs")).href);
  const plugin = await mod.default({});
  assert.deepEqual(plugin, {});
});
