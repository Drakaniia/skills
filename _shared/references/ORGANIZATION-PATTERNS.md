# Codebase Organization Patterns by Language

> **Canonical reference.** Each skill that uses this reference has a skill-specific introductory paragraph; the content below is shared identically across all skills. Edit this file to update the shared content, then run `_shared/scripts/sync-references.sh` to sync to all skills.

> **Skill-specific intro template:** "This reference helps the `<skill-name>` skill make **language-appropriate <context>** when <use-case>. When <action>, the agent should adapt its decision to the project's language and framework conventions."

See below for language-specific folder conventions, naming styles, and module mechanics.

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
