import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { statSync, readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");

// The three skills that get per-skill copies, and the two files they copy.
// Mirrors _shared/scripts/sync-references.sh.
const SYNCED_SKILLS = [
  "audit-codebase",
  "folder-architecture",
  "implement-folder-architecture",
];
const SYNCED_REFS = ["ORGANIZATION-PATTERNS.md", "SPLITTING-GUIDE.md"];

// No --ignore-scripts: prepack must run, because "does a plain pack include the
// generated references" is the entire question. Skipping scripts would make
// this pass even with the bug, and the bug is that a checkout without the
// generated files publishes an incomplete tarball.
function packFileList() {
  const r = spawnSync("npm pack --dry-run --json", {
    cwd: ROOT,
    encoding: "utf8",
    shell: true,
  });
  assert.equal(r.status, 0, `npm pack --dry-run failed: ${r.stderr}`);
  // build.mjs keeps its progress on stderr precisely so this parses.
  let parsed;
  try {
    parsed = JSON.parse(r.stdout);
  } catch {
    assert.fail(`npm pack --json did not emit clean JSON on stdout:\n${r.stdout}`);
  }
  return new Map(parsed[0].files.map((f) => [f.path, f.size]));
}

test("the tarball carries every generated per-skill reference", () => {
  const files = packFileList();
  for (const skill of SYNCED_SKILLS) {
    for (const ref of SYNCED_REFS) {
      const path = `skills/${skill}/references/${ref}`;
      assert.ok(files.has(path), `missing from the published tarball: ${path}`);
    }
  }
});

test("each generated copy is the same size as its canonical source", () => {
  const files = packFileList();
  for (const ref of SYNCED_REFS) {
    const canonical = statSync(join(ROOT, "_shared", "references", ref)).size;
    for (const skill of SYNCED_SKILLS) {
      const path = `skills/${skill}/references/${ref}`;
      assert.equal(
        files.get(path),
        canonical,
        `${path} does not match _shared/references/${ref} — the sync is stale`,
      );
    }
  }
});

test("prepack is what puts them there", () => {
  // The copies are gitignored, so a checkout has none of them. If prepack were
  // removed, or skipped the way build.mjs used to skip a missing bash, the pack
  // above would silently lose all six and the first test would fail. Assert the
  // hook exists so removing it is a deliberate act, not a tidy-up.
  const pkg = JSON.parse(readFileSync(join(ROOT, "package.json"), "utf8"));
  assert.match(pkg.scripts.prepack ?? "", /--sync-only/, "prepack must sync the references before packing");
});
