---
## Universal Principles (Any Language)

These principles apply regardless of stack:

1. **Root is for metadata only** â€” README.md, LICENSE, CI config, dependency manifests
2. **Separation of concerns** â€” Business logic, presentation, and data access in distinct areas
3. **Locality** â€” Related code lives close together (tests near implementation)
4. **Flat until necessary** â€” Don't nest deeply until a directory has 5+ items
5. **Mirror tests** â€” Test structure should mirror source structure
6. **Limit `shared/` or `common/`** â€” These often become dumping grounds. Prefer feature-local code

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
  â”œâ”€â”€ myapp/
  â”‚   â”œâ”€â”€ models.py
  â”‚   â”œâ”€â”€ views.py
  â”‚   â”œâ”€â”€ urls.py
  â”‚   â””â”€â”€ admin.py
  â”œâ”€â”€ config/
  â”‚   â”œâ”€â”€ settings.py
  â”‚   â””â”€â”€ urls.py
  â””â”€â”€ manage.py
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
  â”œâ”€â”€ features/
  â”‚   â”œâ”€â”€ users/
  â”‚   â”‚   â”œâ”€â”€ components/
  â”‚   â”‚   â”œâ”€â”€ hooks/
  â”‚   â”‚   â”œâ”€â”€ api/
  â”‚   â”‚   â””â”€â”€ index.ts
  â”‚   â””â”€â”€ billing/
  â””â”€â”€ shared/
      â””â”€â”€ components/
          â””â”€â”€ Button.tsx
```

_Next.js App Router:_

```
app/
  â”œâ”€â”€ layout.tsx                  â† root layout (required)
  â”œâ”€â”€ page.tsx                    â† home page
  â”œâ”€â”€ (marketing)/                â† route group (no URL prefix)
  â”‚   â”œâ”€â”€ layout.tsx
  â”‚   â””â”€â”€ page.tsx
  â”œâ”€â”€ users/
  â”‚   â”œâ”€â”€ page.tsx
  â”‚   â”œâ”€â”€ layout.tsx
  â”‚   â””â”€â”€ [id]/
  â”‚       â””â”€â”€ page.tsx
  â”œâ”€â”€ _components/                â† private folder (not routed)
  â”‚   â””â”€â”€ UserCard.tsx
  â”œâ”€â”€ _lib/
  â”‚   â””â”€â”€ utils.ts
  â””â”€â”€ api/                        â† API routes
      â””â”€â”€ users/
          â””â”€â”€ route.ts
lib/                              â† shared code (outside app/)
  â”œâ”€â”€ db.ts
  â””â”€â”€ utils.ts
components/
  â””â”€â”€ shared/
```

**Next.js routing conventions:**
- **File paths ARE routes** â€” `app/users/[id]/page.tsx` â†’ `/users/:id`
- **Route groups** `(group)` â€” organize without affecting URL structure
- **Private folders** `_folder` â€” prefix with underscore to exclude from routing (for co-located components, utils, etc.)
- Public code lives in `app/` for route co-location; shared code lives outside `app/` at project root

**Refactoring tip:** Avoid dumping all components in one folder. Group by feature/page. Keep `components/` for truly shared UI only. Use route groups to separate marketing, dashboard, and auth sections within `app/`.

#### Splitting Mechanics (JavaScript / TypeScript)

- **Module unit:** Any `.js`/`.ts`/`.tsx`/`.jsx` file with `export`/`import` is an ES Module.
- **Import mechanism:** `import { X } from './module'` (named), `import X from './module'` (default), `export { X }`, `export default X`
- **Visibility:** Only `export`ed symbols are visible outside the module. Everything else is private.
- **Barrel file:** `index.ts` or `index.js` re-exports from sibling modules.
- **Folder creation:** When extracting 3+ files, create a subdirectory with an `index.ts` barrel. For 1-2 files, keep in same directory.
- **Common pitfalls:**
  - Circular dependencies are common â€” check for cycles when splitting
  - `index.ts` barrel must be created/updated to preserve the public API
  - Default exports must be handled carefully when re-exporting
- **See also:** [SPLITTING-GUIDE.md](SPLITTING-GUIDE.md) for full before/after code examples

---

### Go

**Standard conventions:**

- Snake_case for files (`user_service.go`)
- **No official project layout** â€” Go has no mandated directory structure. The Go team's advice: keep it simple, put a `go.mod` at root, organize by domain.
- `internal/` enforces package privacy â€” packages under `internal/` can only be imported by the parent module
- `cmd/` is the conventional location for binary entry points (one subdirectory per binary)

**Typical structure:**

```
project/
  â”œâ”€â”€ cmd/
  â”‚   â””â”€â”€ server/
  â”‚       â””â”€â”€ main.go             â† binary entry point
  â”œâ”€â”€ internal/
  â”‚   â”œâ”€â”€ user/
  â”‚   â”‚   â”œâ”€â”€ service.go
  â”‚   â”‚   â”œâ”€â”€ repository.go
  â”‚   â”‚   â””â”€â”€ handler.go
  â”‚   â””â”€â”€ billing/
  â”œâ”€â”€ go.mod
  â””â”€â”€ go.sum
```

> **Note on `pkg/`:** Some projects use a top-level `pkg/` directory for code meant to be shared externally, but this is **controversial** â€” the Go standard library does not use it, and many in the Go community consider it unnecessary. Prefer exporting from the domain package directly or using `internal/` for private code.

**Refactoring tip:** Use `internal/` for private code. Group by domain (`internal/user/`, `internal/billing/`). Keep packages flat â€” avoid deep nesting inside `internal/`.

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
- Modules declared in `lib.rs` or `main.rs`
- Since Rust 2018 edition, the preferred module root file is `module_name.rs`, NOT `mod.rs`
- Tests live alongside source (unit) or in `tests/` (integration)

**Typical structure (2018+ style â€” preferred):**

```
project/
  â”œâ”€â”€ src/
  â”‚   â”œâ”€â”€ main.rs                  â† declares child modules with `mod user;`
  â”‚   â”œâ”€â”€ lib.rs                   â† (if library crate)
  â”‚   â”œâ”€â”€ user.rs                  â† root of the `user` module
  â”‚   â”œâ”€â”€ user/
  â”‚   â”‚   â”œâ”€â”€ service.rs           â† submodule of user
  â”‚   â”‚   â”œâ”€â”€ model.rs
  â”‚   â”‚   â””â”€â”€ tests.rs             â† unit tests for user module
  â”‚   â”œâ”€â”€ billing.rs               â† root of the `billing` module
  â”‚   â””â”€â”€ billing/
  â”‚       â””â”€â”€ service.rs
  â””â”€â”€ tests/
      â””â”€â”€ integration_test.rs
```

**Alternative (pre-2018 `mod.rs` style â€” still valid):**

```
project/
  â”œâ”€â”€ src/
  â”‚   â”œâ”€â”€ main.rs
  â”‚   â”œâ”€â”€ user/
  â”‚   â”‚   â”œâ”€â”€ mod.rs               â† module root, same role as user.rs above
  â”‚   â”‚   â”œâ”€â”€ service.rs
  â”‚   â”‚   â””â”€â”€ model.rs
  â”‚   â””â”€â”€ billing/
  â”‚       â”œâ”€â”€ mod.rs
  â”‚       â””â”€â”€ service.rs
  â””â”€â”€ tests/
```

Both styles work. The compiler looks for `module.rs` first, then `module/mod.rs`. Having **both** in the same project causes error E0761. Prefer the 2018+ style for new projects.

**Refactoring tip:** Each domain module gets its own directory. Keep module root files thin â€” split logic into submodules by concern.

#### Splitting Mechanics (Rust)

- **Module unit:** A file (`module.rs`) or directory (`module/mod.rs` or `module.rs` + `module/`).
- **Module declaration:** `mod module_name;` in the parent file declares a child module.
- **Import mechanism:** `use crate::module::Item;`, `use crate::module::submodule::Item;`
- **Visibility:** `pub` = public, `pub(crate)` = crate-wide, `pub(super)` = parent module only. Default = private.
- **Folder creation:** When splitting a large module into submodules, convert it to a directory:
  - 2018+ style: `module.rs` â†’ keep `module.rs` (root) + create `module/submodule.rs`
  - Legacy style: `module.rs` â†’ `module/mod.rs` + create `module/submodule.rs`
  - The new file must be declared with `pub mod submodule;` in the root file.
- **Common pitfalls:**
  - Forgetting `pub` on re-exports in the module root file makes symbols inaccessible
  - Module paths change: `super::Item` may need updating when depth changes
  - Must declare each new file with `pub mod file_name;` in the module root
  - Having both `module.rs` AND `module/mod.rs` is a compile error (E0761) â€” pick one style
- **See also:** [SPLITTING-GUIDE.md](SPLITTING-GUIDE.md) for full before/after code examples

---

### Java / Spring Boot

**Standard conventions:**

- PascalCase for classes (`UserService.java`), camelCase for packages (`com.company.project`)
- Maven/Gradle convention: `src/main/java/`, `src/test/java/`
- Spring Boot officially recommends **feature-based** (domain-first) packages over layered

**Typical structures:**

_Feature-based (recommended by Spring Boot):_

```
src/
  â””â”€â”€ main/
      â””â”€â”€ java/
          â””â”€â”€ com/
              â””â”€â”€ company/
                  â”œâ”€â”€ user/
                  â”‚   â”œâ”€â”€ UserController.java
                  â”‚   â”œâ”€â”€ UserService.java
                  â”‚   â”œâ”€â”€ UserRepository.java
                  â”‚   â””â”€â”€ User.java
                  â””â”€â”€ billing/
                      â””â”€â”€ ...
```

_Layered (traditional â€” acceptable for simple apps):_

```
src/
  â””â”€â”€ main/
      â””â”€â”€ java/
          â””â”€â”€ com/
              â””â”€â”€ company/
                  â”œâ”€â”€ controller/
                  â”œâ”€â”€ service/
                  â”œâ”€â”€ repository/
                  â”œâ”€â”€ entity/
                  â””â”€â”€ config/
```

**Refactoring tip:** Spring Boot's official docs show feature-based packages (`com.example.myapplication.customer.CustomerController`). The `src/main/java/com/company/` prefix alone is 4 nesting levels â€” combine domain-first with the package prefix but keep total under 5-6 levels. Use layered only for trivial apps.

#### Splitting Mechanics (Java)

- **Module unit:** One top-level public class per file. Filename must match the class name.
- **Package:** Directory structure mirrors the package hierarchy (`com/company/project/` â†’ `package com.company.project`).
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
  â”œâ”€â”€ app/
  â”‚   â”œâ”€â”€ models/
  â”‚   â”œâ”€â”€ controllers/
  â”‚   â”œâ”€â”€ views/
  â”‚   â”œâ”€â”€ helpers/
  â”‚   â””â”€â”€ services/     (custom, for business logic)
  â”œâ”€â”€ config/
  â”œâ”€â”€ db/
  â”‚   â””â”€â”€ migrate/
  â”œâ”€â”€ spec/
  â”‚   â”œâ”€â”€ models/
  â”‚   â””â”€â”€ controllers/
  â””â”€â”€ Gemfile
```

**Refactoring tip:** For large Rails apps, extract business logic into `app/services/` by domain. Use Rails Engines for truly separate modules.

#### Splitting Mechanics (Ruby)

- **Autoloading:** Rails 6+ uses Zeitwerk â€” file path MUST match the constant name. `app/models/user.rb` â†’ `User`. `app/services/order_processor.rb` â†’ `OrderProcessor`.
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
  â”œâ”€â”€ Controllers/
  â”‚   â””â”€â”€ UsersController.cs
  â”œâ”€â”€ Services/
  â”‚   â””â”€â”€ UserService.cs
  â”œâ”€â”€ Repositories/
  â”‚   â””â”€â”€ UserRepository.cs
  â”œâ”€â”€ Models/
  â”‚   â””â”€â”€ User.cs
  â””â”€â”€ Program.cs
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
  â”œâ”€â”€ app/
  â”‚   â”œâ”€â”€ Http/
  â”‚   â”‚   â”œâ”€â”€ Controllers/
  â”‚   â”‚   â””â”€â”€ Middleware/
  â”‚   â”œâ”€â”€ Models/
  â”‚   â””â”€â”€ Services/
  â”œâ”€â”€ config/
  â”œâ”€â”€ database/
  â”‚   â””â”€â”€ migrations/
  â”œâ”€â”€ resources/
  â”‚   â””â”€â”€ views/
  â”œâ”€â”€ routes/
  â””â”€â”€ tests/
```

**Refactoring tip:** For large Laravel apps, group related controllers, models, and services into Modules (`app/Modules/Users/`). Use Service classes to keep controllers thin.

#### Splitting Mechanics (PHP)

- **PSR-4 autoloading:** Namespace maps directly to directory structure. `App\Services\OrderService` â†’ `app/Services/OrderService.php`.
- **Module unit:** One class per file, required by PSR-4. Filename must match class name (case-sensitive).
- **Import mechanism:** `use App\Services\OrderService;`
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
| **Deep inheritance**      | 8+ levels of nesting                                                         | Flatten â€” merge related subdirectories       |
| **Circular dependencies** | Module A imports Module B imports Module A                                   | Extract shared code into a separate module   |
| **Config spill**          | Config files mixed with source code                                          | Move to `config/` directory                  |
| **Orphan tests**          | Test folder doesn't mirror source structure                                  | Restructure tests to match source            |

---

## Refactoring Decision Guide

When recommending a restructure, use this decision tree:

```
Is the project small (< 50 files)?
â”œâ”€â”€ Yes â†’ Suggest technical layered (simple, conventional)
â””â”€â”€ No  â†’ Is the project a monorepo or multi-module?
         â”œâ”€â”€ Yes â†’ Suggest feature-first with per-package organization
         â””â”€â”€ No  â†’ Does the project have clear business domains?
                   â”œâ”€â”€ Yes â†’ Suggest feature-first or hybrid
                   â””â”€â”€ No  â†’ Suggest hybrid (layered-by-feature)
```

For frameworks with strong conventions (Rails, Django, Laravel, Next.js):

- Respect framework defaults for the top-level structure
- Apply feature-first patterns WITHIN each app/module boundary
- Don't fight the framework â€” work within its conventions
