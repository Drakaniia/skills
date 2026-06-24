# Codebase Organization Patterns by Language

This reference helps the `folder-architecture` skill make **language-appropriate placement decisions** when creating or modifying files. When deciding where to place a new file, the agent should adapt its decision to the project's language and framework conventions.

> This reference is shared with the `audit-codebase` skill. See `skills/audit-codebase/references/ORGANIZATION-PATTERNS.md` for the canonical version.

---

## Universal Principles (Any Language)

These principles apply regardless of stack:

1. **Root is for metadata only** — README.md, LICENSE, CI config, dependency manifests
2. **Separation of concerns** — Business logic, presentation, and data access in distinct areas
3. **Locality** — Related code lives close together (tests near implementation)
4. **Flat until necessary** — Don't nest deeply until a directory has 5+ items
5. **Mirror tests** — Test structure should mirror source structure
6. **Limit `shared/` or `common/`** — These often become dumping grounds. Prefer feature-local code

---

## Language-Specific Patterns

### Python (Django/Flask/FastAPI)

**Standard conventions:**

- Snake case for files (`user_profile.py`)
- Django apps: `myapp/models.py`, `myapp/views.py`, `myapp/urls.py`
- Flask/FastAPI: flat or feature-based

**Typical structure:**

```
project/
  ├── myapp/
  │   ├── models.py
  │   ├── views.py
  │   ├── urls.py
  │   └── admin.py
  ├── config/
  │   ├── settings.py
  │   └── urls.py
  └── manage.py
```

**Refactoring tip:** For Django, group related models/views/urls into apps by domain. For Flask/FastAPI, prefer feature-based folders over technical layers.

#### Splitting Mechanics (Python)

- **Module unit:** Any `.py` file is a module. A directory with `__init__.py` is a package.
- **Import mechanism:** `from module import name`, `import package.module`, `from package import module`
- **Visibility:** `_prefix` indicates private (convention). `__all__` in `__init__.py` controls wildcard exports.
- **Folder creation:** When splitting a file into 3+ modules, create a package directory with `__init__.py` that re-exports the public API. For 1-2 extracted modules, keep in same directory.
- **Barrel file:** `__init__.py` serves as the barrel file, re-exporting public symbols from submodules.
- **Common pitfalls:**
  - Forgetting to create or update `__init__.py` breaks imports
  - Relative imports (`from . import sibling`) must be updated when files move
  - `sys.path` manipulation breaks when files are restructured
- **See also:** [SPLITTING-GUIDE.md](SPLITTING-GUIDE.md) for full before/after code examples

---

### JavaScript / TypeScript (React, Next.js, Node.js)

**Standard conventions:**

- Kebab-case for files and directories (`user-profile.tsx`)
- React components use PascalCase (`UserProfile.tsx`)
- Next.js App Router: file paths ARE routes

**Typical structures:**

_React (feature-first):_

```
src/
  ├── features/
  │   ├── users/
  │   │   ├── components/
  │   │   ├── hooks/
  │   │   ├── api/
  │   │   └── index.ts
  │   └── billing/
  └── shared/
      └── components/
          └── Button.tsx
```

_Next.js App Router:_

```
app/
  ├── users/
  │   ├── page.tsx
  │   ├── layout.tsx
  │   └── [id]/
  │       └── page.tsx
  ├── api/
  └── layout.tsx
lib/
  ├── db.ts
  └── utils.ts
components/
  └── shared/
```

**Refactoring tip:** Avoid dumping all components in one folder. Group by feature/page. Keep `components/` for truly shared UI only.

#### Splitting Mechanics (JavaScript / TypeScript)

- **Module unit:** Any `.js`/`.ts`/`.tsx`/`.jsx` file with `export`/`import` is an ES Module.
- **Import mechanism:** `import { X } from './module'` (named), `import X from './module'` (default), `export { X }`, `export default X`
- **Visibility:** Only `export`ed symbols are visible outside the module. Everything else is private.
- **Barrel file:** `index.ts` or `index.js` re-exports from sibling modules.
- **Folder creation:** When extracting 3+ files, create a subdirectory with an `index.ts` barrel. For 1-2 files, keep in same directory.
- **Common pitfalls:**
  - Circular dependencies are common — check for cycles when splitting
  - `index.ts` barrel must be created/updated to preserve the public API
  - Default exports must be handled carefully when re-exporting
- **See also:** [SPLITTING-GUIDE.md](SPLITTING-GUIDE.md) for full before/after code examples

---

### Go

**Standard conventions:**

- Snake_case for files (`user_service.go`)
- Go uses `internal/` to enforce package privacy
- Follows [golang-standards/project-layout](https://github.com/golang-standards/project-layout)

**Typical structure:**

```
project/
  ├── cmd/
  │   └── server/
  │       └── main.go
  ├── internal/
  │   ├── user/
  │   │   ├── service.go
  │   │   ├── repository.go
  │   │   └── handler.go
  │   └── billing/
  ├── pkg/
  │   └── shared/
  └── go.mod
```

**Refactoring tip:** Use `internal/` for private code. Group by domain (`internal/user/`, `internal/billing/`). Avoid deep nesting inside `internal/`.

#### Splitting Mechanics (Go)

- **Critical rule:** All `.go` files in the **same directory** belong to the **same package**. You cannot split a package across directories.
- **Import mechanism:** Same-package files share all identifiers automatically (no import needed). Cross-package imports use module path from `go.mod`.
- **Visibility:** Capitalized identifiers = exported (public). Lowercase = package-private.
- **Folder creation:** If extracted code needs a new package, create a new subdirectory with a different `package <name>` declaration. For same-package splitting, all files stay in the same directory.
- **Common pitfalls:**
  - Splitting a Go file into a subdirectory creates a NEW package with a DIFFERENT import path
  - All files in a directory must share the same `package` declaration
  - Moving files between packages requires updating all import paths
- **See also:** [SPLITTING-GUIDE.md](SPLITTING-GUIDE.md) for full before/after code examples

---

### Rust

**Standard conventions:**

- Snake_case for files (`user_service.rs`)
- Modules declared in `mod.rs` or `lib.rs`
- Tests live alongside source or in `tests/`

**Typical structure:**

```
project/
  ├── src/
  │   ├── main.rs
  │   ├── lib.rs
  │   ├── user/
  │   │   ├── mod.rs
  │   │   ├── service.rs
  │   │   ├── model.rs
  │   │   └── tests.rs
  │   └── billing/
  │       ├── mod.rs
  │       └── service.rs
  └── tests/
      └── integration_test.rs
```

**Refactoring tip:** Each domain module gets its own directory with a `mod.rs`. Keep modules focused — split large `mod.rs` files by concern.

#### Splitting Mechanics (Rust)

- **Module unit:** A file (`module.rs`) or directory (`module/mod.rs`).
- **Module declaration:** `mod module_name;` in the parent file declares a child module.
- **Import mechanism:** `use crate::module::Item;`, `use crate::module::submodule::Item;`
- **Visibility:** `pub` = public, `pub(crate)` = crate-wide, `pub(super)` = parent module only. Default = private.
- **Folder creation:** When splitting a large module, convert it to a directory:
  - `module.rs` → `module/mod.rs` (declares submodules) + `module/types.rs`, `module/service.rs`, etc.
- **Common pitfalls:**
  - Forgetting `pub` on re-exports in `mod.rs` makes symbols inaccessible
  - Module paths change: `super::Item` may need updating when depth changes
  - Must declare each new file with `pub mod file_name;` in `mod.rs`
- **See also:** [SPLITTING-GUIDE.md](SPLITTING-GUIDE.md) for full before/after code examples

---

### Java / Spring Boot

**Standard conventions:**

- PascalCase for classes (`UserService.java`), camelCase for packages (`com.company.project`)
- Maven/Gradle convention: `src/main/java/`, `src/test/java/`
- Classic layered: `controller/`, `service/`, `repository/`, `entity/`

**Typical structures:**

_Layered (traditional):_

```
src/
  └── main/
      └── java/
          └── com/
              └── company/
                  ├── controller/
                  ├── service/
                  ├── repository/
                  ├── entity/
                  └── config/
```

_Feature-based (modern):_

```
src/
  └── main/
      └── java/
          └── com/
              └── company/
                  ├── user/
                  │   ├── UserController.java
                  │   ├── UserService.java
                  │   ├── UserRepository.java
                  │   └── User.java
                  └── billing/
                      └── ...
```

**Refactoring tip:** The `src/main/java/com/company/` prefix alone is 4 nesting levels. Combine domain-first with the package prefix — but keep the total under 5-6 levels.

#### Splitting Mechanics (Java)

- **Module unit:** One top-level public class per file. Filename must match the class name.
- **Package:** Directory structure mirrors the package hierarchy (`com/company/project/` → `package com.company.project`).
- **Import mechanism:** `import com.company.project.UserService;`
- **Visibility:** `public` (everywhere), package-private (no modifier, within package), `private` (class only).
- **Folder creation:** Extracted helper classes go in the same package (same directory). For domain splitting, create a new subdirectory with a new package.
- **Common pitfalls:**
  - Filename must EXACTLY match the public class name (case-sensitive)
  - Only one top-level public class per file
  - Package-private classes are invisible outside the package
- **See also:** [SPLITTING-GUIDE.md](SPLITTING-GUIDE.md) for full before/after code examples

---

### Ruby on Rails

**Standard conventions:**

- Snake_case for files (`user.rb`)
- Highly opinionated: MVC by default
- `app/models/`, `app/controllers/`, `app/views/`, `app/helpers/`

**Typical structure:**

```
project/
  ├── app/
  │   ├── models/
  │   ├── controllers/
  │   ├── views/
  │   ├── helpers/
  │   └── services/     (custom, for business logic)
  ├── config/
  ├── db/
  │   └── migrate/
  ├── spec/
  │   ├── models/
  │   └── controllers/
  └── Gemfile
```

**Refactoring tip:** For large Rails apps, extract business logic into `app/services/` by domain. Use Rails Engines for truly separate modules.

#### Splitting Mechanics (Ruby)

- **Autoloading:** Rails 6+ uses Zeitwerk — file path MUST match the constant name. `app/models/user.rb` → `User`. `app/services/order_processor.rb` → `OrderProcessor`.
- **Import mechanism:** Rails autoloads by convention. No explicit `require` needed in most cases. `require_relative` for non-Rails code.
- **Folder creation:** Extract concerns to `app/models/concerns/` or `app/controllers/concerns/`. Extract service objects to `app/services/` by domain.
- **Common pitfalls:**
  - File path must exactly match class/module hierarchy for Zeitwerk
  - Concerns must use `ActiveSupport::Concern` for proper module inclusion
  - `require_relative` paths break when files are moved
- **See also:** [SPLITTING-GUIDE.md](SPLITTING-GUIDE.md) for full before/after code examples

---

### C# / .NET

**Standard conventions:**

- PascalCase for files and classes (`UserService.cs`)
- Namespace mirrors folder structure (`Company.Project.Users`)
- Classic: Controllers, Services, Repositories

**Typical structure:**

```
Project/
  ├── Controllers/
  │   └── UsersController.cs
  ├── Services/
  │   └── UserService.cs
  ├── Repositories/
  │   └── UserRepository.cs
  ├── Models/
  │   └── User.cs
  └── Program.cs
```

**Refactoring tip:** For complex apps, use feature folders: `Features/Users/` containing its own Controller, Service, and Model. Use `internal/` for implementation details not meant to be public.

#### Splitting Mechanics (C#)

- **Module unit:** A `.cs` file containing a class. Filename uses PascalCase (`UserService.cs`).
- **Namespace:** Logical grouping that typically mirrors folder structure (`Company.Project.Users`).
- **Partial classes:** C# allows splitting a single class across multiple files with the `partial` keyword. All partial files must declare `partial class`.
- **Import mechanism:** `using Company.Project.Users;`
- **Visibility:** `public` (everywhere), `internal` (assembly-wide), `private` (class only).
- **Folder creation:** For feature-based organization, create subdirectories like `Features/Users/`. For large solutions, extract into separate `.csproj` projects.
- **Common pitfalls:**
  - All `partial` class files must be in the same assembly
  - Namespace should match folder structure (convention)
  - `internal` members are visible within the same `.csproj` only
- **See also:** [SPLITTING-GUIDE.md](SPLITTING-GUIDE.md) for full before/after code examples

---

### PHP / Laravel

**Standard conventions:**

- PascalCase for classes (`UserController.php`)
- Snake_case for files and views
- Highly opinionated MVC structure

**Typical structure:**

```
project/
  ├── app/
  │   ├── Http/
  │   │   ├── Controllers/
  │   │   └── Middleware/
  │   ├── Models/
  │   └── Services/
  ├── config/
  ├── database/
  │   └── migrations/
  ├── resources/
  │   └── views/
  ├── routes/
  └── tests/
```

**Refactoring tip:** For large Laravel apps, group related controllers, models, and services into Modules (`app/Modules/Users/`). Use Service classes to keep controllers thin.

#### Splitting Mechanics (PHP)

- **PSR-4 autoloading:** Namespace maps directly to directory structure. `App\\Services\\OrderService` → `app/Services/OrderService.php`.
- **Module unit:** One class per file, required by PSR-4. Filename must match class name (case-sensitive).
- **Import mechanism:** `use App\\Services\\OrderService;`
- **Folder creation:** Extract service classes to `app/Services/`. For modular Laravel, use `app/Modules/` with subdirectories by domain.
- **Common pitfalls:**
  - Run `composer dump-autoload` after moving/renaming files
  - Namespace must exactly match the directory path
  - Laravel facades and helpers don't need `use` statements
- **See also:** [SPLITTING-GUIDE.md](SPLITTING-GUIDE.md) for full before/after code examples

---

## Common Structural Smells (All Languages)

| Smell                     | What it looks like                                                           | Fix                                          |
| ------------------------- | ---------------------------------------------------------------------------- | -------------------------------------------- |
| **Big dumping ground**    | `utils/` or `helpers/` with 50+ unrelated files                              | Extract into domain-specific modules         |
| **Shotgun surgery**       | Changing one feature requires editing 5+ different folders                   | Consolidate into feature folders             |
| **Framework-itis**        | Everything sorted by tech role (`controllers/`, `models/`, `views/` at root) | Group by feature, use layers within features |
| **Deep inheritance**      | 8+ levels of nesting                                                         | Flatten — merge related subdirectories       |
| **Circular dependencies** | Module A imports Module B imports Module A                                   | Extract shared code into a separate module   |
| **Config spill**          | Config files mixed with source code                                          | Move to `config/` directory                  |
| **Orphan tests**          | Test folder doesn't mirror source structure                                  | Restructure tests to match source            |

---

## Refactoring Decision Guide

When deciding how to structure a project, use this decision tree:

```
Is the project small (< 50 files)?
├── Yes → Suggest technical layered (simple, conventional)
└── No  → Is the project a monorepo or multi-module?
         ├── Yes → Suggest feature-first with per-package organization
         └── No  → Does the project have clear business domains?
                   ├── Yes → Suggest feature-first or hybrid
                   └── No  → Suggest hybrid (layered-by-feature)
```

For frameworks with strong conventions (Rails, Django, Laravel, Next.js):

- Respect framework defaults for the top-level structure
- Apply feature-first patterns WITHIN each app/module boundary
- Don't fight the framework — work within its conventions
