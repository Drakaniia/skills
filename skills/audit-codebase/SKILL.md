---
name: audit-codebase
description: Scan any codebase (language-agnostic) and flag structural health issues including folder bloat, oversized files, deep nesting, naming inconsistencies, orphaned files, doc sprawl, and empty directories. Generates a markdown report with ASCII tree diagrams for folder structure issues and Mermaid graphs for file-level diagrams. Use when a codebase feels cluttered, disorganized, or hard to navigate.
license: Apache-2.0
compatibility: OpenCode >= 1.0, Claude Code >= 2.0, Codex CLI, Cursor, Gemini CLI
allowed-tools:
  - read
  - grep
  - glob
  - bash
  - write
  - look_at
metadata:
  language: language-agnostic
  tags: codebase-audit, codebase-health, structural-analysis, refactoring, code-quality
---

# Audit Codebase

Use this skill to act as a **Codebase Health Auditor** — inspecting any codebase regardless of programming language, framework, or project type, and producing a structured markdown report that the implement-folder-architecture skill can execute from in a subsequent session.

## Core Principles

- **Language-agnostic**: Every check must work on Python, JavaScript, Go, Rust, Java, C++, or any other language without modification. See [organization patterns per language](references/ORGANIZATION-PATTERNS.md) for guidance.
- **Report as contract**: The generated report must contain every detail needed for the implement-folder-architecture skill to execute the fixes without asking clarifying questions.
- **Language-specific splitting guidance**: When the report recommends splitting an oversized file, use [SPLITTING-GUIDE.md](references/SPLITTING-GUIDE.md) for per-language mechanics, import updates, and before/after code examples for Python, JS/TS, Go, Rust, Java, C#, Ruby, and PHP.
- **Before/after clarity**: Every issue must include a diagram showing both the current state and the proposed fix — ASCII trees for folder structures, Mermaid `flowchart`/`graph` for file-level diagrams.
- **Evidence over opinion**: Every flag must reference a measured metric (file count, line count, depth level) against a hardcoded threshold.

## Workflow

```
┌───────────────────────────────────────────────────────────────────┐
│  1. Use `ask_user` tool to ask user preference:                     │
│     a) Full report (comprehensive + diagrams)                     │
│     b) Quick spec (concise, fast-track for AI implement)          │
│                                                                   │
│  2. Scan the codebase (via agent inspection):                     │
│     - Collect all metrics (file counts, line counts,              │
│       nesting depth, naming, placement, docs)                     │
│     - Identify structural smells                                  │
│                                                                   │
│  3. Generate markdown report with:                                │
│     - Executive summary                                           │
│     - Issues found (grouped by refactoring phases)                │
│     - Checklist checkboxes and progress tracker                   │
│     - Before/after diagrams                                       │
│     - Recommended actions with reasoning                          │
│                                                                   │
│  4. Save report as `<repo-name>-audit.md`                         │
│                                                                   │
│  5. Tell the user to use the implement-folder-architecture skill  │
│     with the report to execute the migration incrementally        │
└───────────────────────────────────────────────────────────────────┘
```

## How the AI Scans the Codebase

The agent performs the audit by directly inspecting the codebase using:

- **Hybrid `find + wc` pipeline** — pipe `find` results into `wc -l` and `sort` to count lines per file for identifying oversized files, and to count files per directory for detecting bloated folders. Prefer this hybrid approach over bare `find` alone.
- **`wc -l` command** — to find oversized files that need refactoring:

  ```bash
  # Find all source files, then count lines in each, sorted by size (largest first)
  find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.rs" \) \
    ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/vendor/*' \
    -exec wc -l {} + | sort -rn | head -20
  ```

  This reveals the files with the most lines — candidates for splitting into smaller modules.

- **Content reading tools** — to inspect oversized files and understand their structure

> **Tip:** When auditing a codebase, use `wc -l` to quickly surface the largest files. Sort by line count descending, then investigate any file exceeding the 400-line threshold. For language-specific guidance on how to split these oversized files (including import updates, module structures, and before/after examples), see [SPLITTING-GUIDE.md](references/SPLITTING-GUIDE.md).

## Audit Metrics & Default Thresholds

All thresholds are hardcoded defaults. The AI may adjust thresholds based on project size or user preference at invocation time. See [metric deep dives](references/REFERENCE.md) for detailed examples.

| #   | Metric                       | Threshold                                                                                       | Severity      |
| --- | ---------------------------- | ----------------------------------------------------------------------------------------------- | ------------- |
| 1   | **Folder file count**        | >30 files per directory                                                                         | 🔴 Warning    |
| 2   | **File line count**          | >400 lines per file                                                                             | 🔴 Warning    |
| 3   | **Nesting depth**            | >4 levels of directory nesting                                                                  | 🔴 Warning    |
| 4   | **Naming conventions**       | Multiple casing styles at same level; unclear/abbreviated names                                 | 🟢 Suggestion |
| 5   | **Orphaned/misplaced files** | Files whose purpose doesn't match parent directory; files in root that belong in subdirectories | 🔴 Warning    |
| 6   | **Doc sprawl**               | >5 `.md` files not following a doc structure                                                    | 🟢 Suggestion |
| 7   | **Empty/dead directories**   | Empty directories; directories with only a single subdirectory                                  | 🟢 Suggestion |

> For details on checking `references/`, `scripts/`, and `assets/` directories, see [references/REFERENCE.md](references/REFERENCE.md). For language-specific organization patterns, see [references/ORGANIZATION-PATTERNS.md](references/ORGANIZATION-PATTERNS.md).

> For language-specific file splitting mechanics (import updates, module structures, before/after code examples), see [references/SPLITTING-GUIDE.md](references/SPLITTING-GUIDE.md).

> For the complete report template with phased checklist, progress tracker, and TDD instructions, see [references/REPORT-TEMPLATE.md](references/REPORT-TEMPLATE.md).

## Analysis Depth

The skill operates on three levels simultaneously.

### Level 1: Purely Structural Metrics (always on)

- File/directory tree analysis
- File count per directory
- Line count per file
- Nesting depth measurement
- Naming pattern detection (heuristic: scan for casing styles)
- Empty directory detection
- Doc file detection (`.md`, `.rst`, `.txt`, etc.)

### Level 2: Content Heuristics (always on, language-agnostic)

- Orphaned files: files whose name/extension doesn't match the parent directory theme
- Dead entries: empty files, files with only comments/imports
- Oversized files (line count exceeds threshold)
- Mixed concerns: file with multiple distinct sections (heuristic: comment headers, import blocks)

### Level 3: Language-Aware Heuristics (generic patterns)

- Import/require/include statements to infer module dependencies (pattern matching, not parsing)
- Test files by naming patterns (`*_test.*`, `*.spec.*`, `test_*.*`)
- Configuration files by common names (`package.json`, `Cargo.toml`, `Makefile`, `Dockerfile`, etc.)
- Entry points (`main.*`, `index.*`, `app.*`, `cli.*`)

## Report Format

The report is a markdown file. **Folder structure issues** use ASCII tree diagrams. **File-level issues** can use Mermaid `flowchart`/`graph` for dependency visualization. See the [full report template](references/REPORT-TEMPLATE.md) for a complete, copy-paste-ready skeleton.

Organize **Issues Found** by refactoring phases with checkboxes. Each phase groups related fixes so the user (or AI in a new session) can work through them step by step. Tick off items as they are completed.

### Structure

```markdown
# Audit Report: <repo-name>

Generated: <date>

## Executive Summary

<2-3 sentence overview of findings>

## Severity Legend

- 🔴 **Blocker** — must fix
- 🟡 **Warning** — should fix
- 🟢 **Suggestion** — nice to improve

---

## Issues Found

### Phase 1: Quick Cleanup

_Low effort, safe changes._

- [ ] **Remove empty/dead directories** — `src/legacy/`, `src/archive/`
- [ ] **Consolidate doc files into `docs/`** — 7 `.md` files scattered at root
- [ ] **Standardize naming conventions in `src/`** — mixed camelCase, snake_case, kebab-case

---

### Phase 2: File Refactoring

_Medium effort — split oversized files, fix misplaced files._

- [ ] **Split `src/services/order_service.py`** — 887 lines (threshold: ≤400)

  **Before:**
```

src/utils/
├── string_utils.py
├── date_formatter.js
├── http_client.go
├── validator.py
└── ... and 43 more

```

**After (proposed):**
```

src/utils/
├── string-helpers/
├── date-helpers/
├── network/
└── validators/

````

- [ ] **Move misplaced root files** — `audit-codebase-spec.md`, `SPECIFICATION.md` → `docs/`

---

### Phase 3: Structural Refactoring
_Higher effort — reorganize folders, flatten nesting._

- [ ] **Split `src/utils/`** — 47 files into subdirectories by domain

**Architecture diagram (Mermaid):**
```mermaid
flowchart LR
  A[order_service] --> B[order_validation]
  A --> C[order_pricing]
  A --> D[order_repository]
````

- [ ] **Flatten `src/api/v1/handlers/`** — 5 levels deep (threshold: ≤4)
- [ ] **Organize `scripts/`** — 12 scripts without categorization

---

## Refactoring Progress

Use this checklist to track completion. Mark `[x]` when a task is done:

**Phase 1:** `[ ] / [x] completed`
**Phase 2:** `[ ] / [x] completed`
**Phase 3:** `[ ] / [x] completed`

> Update this checklist as you implement fixes. When all items are ticked, the codebase is clean.

> **⚠️ Before implementing any refactoring that splits or moves code, use `skill:test-driven-development`.** Write tests for existing behavior first, then refactor. This ensures refactored code preserves all functionality and catches regressions early.

```

### Folder Diagram Styling (ASCII Tree)

For folder-level issues (Metric 1), use ASCII directory trees:

```

directory-name/
├── file-or-subdir-1
├── file-or-subdir-2
└── file-or-subdir-3

````

Use:
- `├── ` for items (pipe + dash + dash + space)
- `└── ` for the last item (corner + dash + dash + space)
- Indent subdirectories with `│   ` (pipe + spaces)

### File-Level Diagram Styling (Mermaid)

For file-level issues (Metrics 2-7), use Mermaid when a diagram adds clarity:

```mermaid
flowchart LR
  node1[Module Name]
  node2[Sub-Module]
  node1 --> node2

````

## Reporting Naming Convention Issues

```
**Location:** `src/`
**Issue:** Mixed naming styles detected:
  - `userProfile.ts` (camelCase)
  - `user_profile.ts` (snake_case)
  - `user-profile.ts` (kebab-case)
**Recommended action:** Standardize on one convention (prefer kebab-case for files, or project convention)
```

## Edge Case Handling

| Situation                        | Handling                                                                                                                 |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Empty repository                 | Report: "Repository is empty — nothing to audit"                                                                         |
| Monorepo with many packages      | Analyze each package as a unit, report aggregate + per-package breakdown                                                 |
| Generated/vendor directories     | Auto-detect and skip (`node_modules/`, `.git/`, `build/`, `dist/`, `target/`, `vendor/`, `__pycache__/`, `.venv/`, etc.) |
| Very large codebase (>10K files) | Summarize at top levels, flag only the worst offenders per metric                                                        |
| Binary-only repository           | Report: "No source files detected — structural audit skipped"                                                            |
| Symlinks                         | Follow symlinks but warn about them                                                                                      |
| Hidden files/directories         | Skip `.`-prefixed files and directories unless they are configuration files                                              |

## Final Verification

After generating the report, do a quick consistency check against the [reference documentation](references/REFERENCE.md):

- [ ] Each issue has a clear metric, threshold, and recommended action
- [ ] Folder-level issues use ASCII tree diagrams for before/after
- [ ] File-level issues use Mermaid diagrams where helpful
- [ ] Recommendations account for the project's language/stack (see [organization patterns](references/ORGANIZATION-PATTERNS.md))
- [ ] Each oversized file split plan includes language-specific steps (see [SPLITTING-GUIDE.md](references/SPLITTING-GUIDE.md))
- [ ] Each split plan includes proposed file names, target directory, import changes, and verification steps
- [ ] The report is saved and the file path is communicated to the user
- [ ] The report contains enough context for the implement-folder-architecture skill to execute fixes independently

## Execution Checklist

Before finishing the audit, verify every item below is complete:

- [ ] Used `ask_user` tool to ask user preference: full report or quick spec
- [ ] Scanned all directories (excluded vendor/build/generated dirs)
- [ ] **Metric 1** — Checked folder file counts (>30 files flagged, ASCII tree diagrams added)
- [ ] **Metric 2** — Checked file line counts (>400 lines flagged)
  - [ ] For each oversized file: determined language and identified natural module boundaries
  - [ ] Applied language-specific splitting mechanics from SPLITTING-GUIDE.md
  - [ ] Generated import change tables for each split
- [ ] **Metric 3** — Checked nesting depth (>4 levels flagged)
- [ ] **Metric 4** — Checked naming conventions (mixed styles flagged)
- [ ] **Metric 5** — Checked orphaned/misplaced files
- [ ] **Metric 6** — Checked doc sprawl (>5 scattered `.md` files flagged)
- [ ] **Metric 7** — Checked empty/dead directories
- [ ] Generated ASCII tree diagrams for folder-level issues (Metric 1)
- [ ] Used Mermaid `flowchart`/`graph` for file-level diagrams where helpful
- [ ] Organized issues into refactoring phases (Quick Cleanup → File → Structural)
- [ ] Added `- [ ]` checkboxes to each issue in the report
- [ ] Added Refactoring Progress section with completion tracker
- [ ] Generated language-specific split plans with proposed file names, directory trees, and import change tables for each oversized file (see [SPLITTING-GUIDE.md](references/SPLITTING-GUIDE.md))
- [ ] Saved report to `<repo-name>-audit.md`
