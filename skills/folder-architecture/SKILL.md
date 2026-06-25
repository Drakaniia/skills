---
name: folder-architecture
description: Define and enforce best-practice folder architecture whenever creating or modifying files. Use whenever the AI adds or edits code to prevent structural clutter, directory bloat, misplaced files, naming inconsistencies, and deep nesting.
license: Apache-2.0
compatibility: OpenCode >= 1.0, Claude Code >= 2.0, Codex CLI, Cursor, Gemini CLI
allowed-tools:
  - read
  - grep
  - glob
  - write
  - edit
  - bash
metadata:
  language: language-agnostic
  tags: folder-architecture, code-organization, file-structure, best-practices, architecture-enforcement
---

# Folder Architecture

Use this skill to act as a **Structure Guardian** — proactively enforcing clean folder organization and best-practice file placement **before** every file creation or modification. This skill prevents structural decay at the point of change.

## Core Principles

- **Language-agnostic**: Every check applies to any language. Language-specific details are in [references/ORGANIZATION-PATTERNS.md](references/ORGANIZATION-PATTERNS.md).
- **Prevention over cleanup**: Check structure BEFORE creating or modifying files — not after.
- **Follow existing conventions**: When the project already has a pattern (even if imperfect), match it for new files. Only proactively restructure when clear rules are violated.
- **Respect framework defaults**: Don't fight established conventions (Rails MVC, Django apps, Next.js App Router, Go's `internal/`).
- **Feature-first by default**: Prefer grouping by domain/feature over technical layering. Let the AI choose the best architecture pattern based on project size and complexity.
- **Self-contained**: See [references/ORGANIZATION-PATTERNS.md](references/ORGANIZATION-PATTERNS.md) for language-specific patterns and [references/SPLITTING-GUIDE.md](references/SPLITTING-GUIDE.md) for file-splitting mechanics.

## When This Skill Activates

This skill activates **every time** the AI adds or edits code:

- Creating a new file
- Modifying an existing file
- Creating a new directory
- Adding new imports/exports
- Restructuring existing code (moving files, renaming)

## Thresholds (Hard Defaults)

| #   | Check                        | Threshold                                  | Severity      | Action                                                                                                                |
| --- | ---------------------------- | ------------------------------------------ | ------------- | --------------------------------------------------------------------------------------------------------------------- |
| 1   | **Directory file count**     | >30 files per directory                    | 🔴 Blocker    | Create subdirectory before placing file                                                                               |
| 2   | **File line count (growth)** | File will cross >400 lines after edits     | 🔴 Blocker    | Warn and suggest splitting                                                                                            |
| 3   | **Nesting depth**            | >4 levels deep                             | 🔴 Blocker    | HARD BLOCK: Do not create deeper than 4 levels. Place the file at a shallower level or flatten the target tree first. |
| 4   | **Root-level source code**   | Any source file in project root            | 🔴 Blocker    | Place in appropriate subdirectory                                                                                     |
| 5   | **Config-in-source**         | Config files mixed with source code        | 🟡 Warning    | Move to `config/`                                                                                                     |
| 6   | **Naming consistency**       | New file doesn't match existing convention | 🟡 Warning    | Rename to match project pattern                                                                                       |
| 7   | **Misplaced file**           | File type doesn't match parent directory   | 🟡 Warning    | Move to appropriate directory                                                                                         |
| 8   | **Dumping ground**           | Adding to `utils/`, `helpers/`, `shared/`  | 🟡 Warning    | Check if feature-local placement is better                                                                            |
| 9   | **Barrel file stale**        | New file added without updating barrel     | 🟡 Warning    | Auto-update barrel (index.ts, **init**.py, etc.)                                                                      |
| 10  | **Circular import risk**     | New import may create a cycle              | 🟢 Suggestion | Check import chain                                                                                                    |

> **Adjusting thresholds**: For small projects (<50 files), use stricter limits (≤15 files/dir, ≤200 lines/file). For large projects (>500 files), relax to ≤50 files/dir, ≤600 lines/file.

## Workflow: Before Every File Operation

Before the AI creates or modifies any file, run through this **step-by-step checklist** in order:

### Step 1: Detect Project Convention

Scan the project to detect:

- **Naming convention**: Check nearby files for kebab-case, snake_case, camelCase, PascalCase
- **Architecture pattern**: Is it feature-first, layered, or mixed?
- **Framework defaults**: Does the framework prescribe a structure (Rails, Django, Next.js)?
- **Existing barrel files**: Are there `index.ts`, `__init__.py`, `mod.rs` files?

> **Implementation tip**: Read 3-5 existing files from the target directory to detect patterns. If the directory is empty, check sibling directories.

### Step 2: Check Target Directory Health

Before placing a new file in a directory:

- [ ] **File count check**: Count files in the target directory. If >30 files, **create a subdirectory** before adding the file.
- [ ] **Nesting depth check**: Is the directory >4 levels from the project root? If so, **do not create deeper**. Suggest flattening or placing the file where nesting is shallower.
- [ ] **Dumping ground check**: Is the directory named `utils/`, `helpers/`, `shared/`, `common/`, `misc/`? If so, verify the new file truly belongs there (must be used by 3+ features). Otherwise, suggest a feature-local location.
- [ ] **Directory theme check**: Does the directory name match the file type? (e.g., don't put a `.py` file in `images/`, don't put a config file in `components/`)

### Step 3: Check File Placement

- [ ] **Root check**: If the file would go in the project root, **move it** to `src/`, `lib/`, or an appropriate subdirectory. Root is only for: README.md, LICENSE, CI config, dependency manifests (package.json, Cargo.toml, etc.), and build config.
- [ ] **Config check**: If the file is a config file (`.yml`, `.json`, `.toml`, `.ini`), does it belong in a `config/` directory? Flag if mixed with source code.
- [ ] **Test mirroring**: For test files, ensure the test path mirrors the source path. E.g., `src/features/users/user.service.ts` → `tests/features/users/user.service.test.ts`.
- [ ] **Feature proximity**: Check if there's an existing feature folder related to the new file. Prefer placing the file within that feature's directory tree.

### Step 4: Check Naming

- [ ] **Detect convention**: What naming style do nearby files use? (kebab-case, snake_case, camelCase, PascalCase)
- [ ] **Match convention**: Name the new file using the detected convention
- [ ] **Component naming**: If the file exports a React/Vue/Svelte component, use PascalCase for the filename (e.g., `UserProfile.tsx`)
- [ ] **Test naming**: Match the source file naming convention (e.g., `user.service.ts` → `user.service.test.ts` or `test_user_service.py`)

### Step 5: Check Import Hygiene

- [ ] **Import ordering**: Organize imports in this order with blank-line separators:
  1. Standard library / built-in modules
  2. Third-party packages / frameworks
  3. Local / project imports
  4. Relative imports (if used, prefer absolute)
- [ ] **Barrel file update**: If the directory has a barrel file (`index.ts`, `__init__.py`, `mod.rs`), add a re-export line for the new file.
- [ ] **Circular dependency check**: If adding a new import, verify it does not create a direct A→B→A cycle. Trace the immediate import chain of the imported module.

### Step 6: Check for Oversized Files (Modifications)

When **modifying** an existing file:

- [ ] **Current size check**: Read the file's current line count. If it's already >350 lines and the edit will push it near or over 400, **warn and suggest splitting**.
- [ ] **Growth tracking**: If the file has grown by 100+ lines since the last change, consider whether the new code belongs in a separate file.
- [ ] **Split recommendation**: If splitting is needed, use the `audit-codebase` skill to generate a detailed split plan, or follow the language-specific mechanics in [references/SPLITTING-GUIDE.md](references/SPLITTING-GUIDE.md).

## Architecture Pattern Reference

When deciding how to organize a project's folders, choose the appropriate pattern:

### 1. Feature-First (Domain-Driven) — Best for medium-to-large projects

```
src/
  ├── users/           (everything related to users)
  │   ├── handlers/
  │   ├── models/
  │   ├── tests/
  │   └── index.ts
  ├── billing/         (everything related to billing)
  │   ├── handlers/
  │   ├── models/
  │   ├── tests/
  │   └── index.ts
  └── shared/          (truly cross-cutting, 3+ consumers)
      └── middleware/
```

### 2. Technical Layered — Good for small/simple projects

```
src/
  ├── controllers/
  ├── services/
  ├── repositories/
  ├── models/
  └── middleware/
```

### 3. Hybrid (Layered-by-Feature) — Best for scaling projects

```
src/
  └── features/
      ├── users/
      │   ├── application/      (DTOs, handlers)
      │   ├── domain/           (business entities)
      │   ├── infrastructure/   (database, external APIs)
      │   └── presentation/     (UI components, controllers)
      └── billing/
```

### 4. Ports & Adapters (Hexagonal) — For complex business domains

```
src/
  ├── domain/          (pure business logic, no frameworks)
  ├── application/     (use cases / application services)
  ├── ports/           (interfaces/contracts)
  └── adapters/        (implementations: database, web, API)
```

**Decision guide**: For small projects (<50 files), prefer **technical layered**. For medium projects (50-500 files), prefer **feature-first**. For large/complex projects (>500 files), prefer **hybrid or hexagonal**.

## Monorepo Handling

For monorepos with multiple packages/modules:

- Apply checks **per-package**, not globally
- Each package is treated as its own project with its own thresholds
- Check root-level `packages/` or `apps/` directories for bloat (each should contain ≤30 subdirectories)
- Shared packages (e.g., `@shared/ui`, `common/`) should follow stricter rules: max 15 files per directory
- Each package should have a consistent architecture pattern (don't mix feature-first and layered across packages)

## Shared / Cross-Cutting Code Policy

The `shared/`, `common/`, or `lib/` directory is permitted but **strictly limited**:

- **Entry requirement**: A function/module must be used by **3+ features** before it qualifies for shared/placement
- **Size limit**: Shared/ directory must not exceed 30 files total. If exceeded, split into `shared/ui/`, `shared/utils/`, `shared/types/`, etc.
- **No business logic**: Shared/ is for technical cross-cutting concerns only (formatting, types, HTTP clients, logging). Business logic must remain in feature folders.
- **Prefer duplication over wrong abstraction**: If only 1-2 features use the code, keep it local. Extract to shared/ only when the 3rd consumer appears.

## Barrel File Policy

Whenever adding a new file that exports symbols, check if the enclosing directory has a barrel file:

| Language | Barrel file                    | Update action                                   |
| -------- | ------------------------------ | ----------------------------------------------- |
| Python   | `__init__.py`                  | Add `from .new_module import ExportedSymbol`    |
| JS/TS    | `index.ts` or `index.js`       | Add `export { X } from './new-module'`          |
| Rust     | `mod.rs`                       | Add `pub mod new_module;` and re-export         |
| Go       | N/A (package-level visibility) | No barrel needed — same package is auto-visible |

If no barrel file exists and only 1-2 files are in the directory, do not create one. Barrel files are only needed when a directory has 3+ public modules.

## Language-Specific Patterns

For language-specific folder conventions, naming styles, and module mechanics, see:

- [ORGANIZATION-PATTERNS.md](references/ORGANIZATION-PATTERNS.md) — How to organize code per language (Python, JS/TS, Go, Rust, Java, C#, Ruby, PHP)
- [SPLITTING-GUIDE.md](references/SPLITTING-GUIDE.md) — How to split oversized files per language (import changes, module boundaries, before/after examples)

## Edge Cases

| Situation                             | Handling                                                                                          |
| ------------------------------------- | ------------------------------------------------------------------------------------------------- |
| **Empty project**                     | Create a standard structure: `src/` or `lib/` based on language                                   |
| **No clear convention**               | Default to kebab-case for JS/TS, snake_case for Python/Rust/Go, PascalCase for components/classes |
| **Generated code**                    | Skip checks for files in `generated/`, `dist/`, `build/` — they follow their own rules            |
| **Third-party/vendor**                | Skip checks for `node_modules/`, `vendor/`, `.venv/`                                              |
| **Hidden files**                      | Skip `.`-prefixed files except config files                                                       |
| **Symlinks**                          | Follow symlinks but avoid creating new ones                                                       |
| **Test-only project**                 | If the project is exclusively tests, use the test framework's convention (`__tests__/`, `spec/`)  |
| **User explicitly requests location** | If the user says "put it in [path]", follow their instruction but flag any structural issues      |

## Interaction with audit-codebase Skill

This skill (folder-architecture) and audit-codebase are complementary:

| Aspect          | folder-architecture (this)             | audit-codebase                |
| --------------- | -------------------------------------- | ----------------------------- |
| **When**        | Before/during file operations          | After-the-fact review         |
| **Purpose**     | Prevent clutter proactively            | Detect existing issues        |
| **Scope**       | Single file/directory at a time        | Full codebase scan            |
| **Action**      | Place correctly, warn, split if needed | Generate report with fix plan |
| **Split depth** | Basic split warning + context          | Full split plan with diagrams |

**When to use audit-codebase**: If during development you notice pervasive structural issues (multiple oversized files, many bloated directories, inconsistent patterns), switch to `audit-codebase` for a comprehensive review.

## Execution Checklist

Before creating or modifying any file, verify every applicable item:

### Pre-File Creation

- [ ] **Step 1**: Detected project convention (naming, architecture pattern)
- [ ] **Step 2**: Target directory is healthy (<30 files, ≤4 levels deep)
- [ ] **Step 2**: Not adding to a dumping ground (utils/shared verified)
- [ ] **Step 3**: File is not in project root
- [ ] **Step 3**: Config files go in config/ directory
- [ ] **Step 3**: Tests mirror source structure
- [ ] **Step 4**: File naming matches project convention
- [ ] **Step 5**: Imports are correctly ordered
- [ ] **Step 5**: Barrel file is updated (if exists)
- [ ] **Step 5**: No circular import created

### Pre-File Modification

- [ ] **Step 6**: Existing file is not near the 400-line threshold
- [ ] **Steps 1-5**: All applicable creation checks re-verified if adding new exports
