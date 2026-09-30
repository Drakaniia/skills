---
name: codebase-health
description: Use when starting any session, or when unsure which codebase-health skill applies. Routes to audit-codebase, folder-architecture, code-design, and implement-folder-architecture. Establishes that codebase health is continuous practice, not a one-time audit.
metadata:
  version: "2.0.0"
---

# Codebase Health

Codebase health is continuous practice, not a one-time audit. Pick the skill that
matches what you are about to do:

| Skill | When it fires |
| --- | --- |
| `audit-codebase` | User says the codebase feels cluttered, disorganized, or hard to navigate |
| `implement-folder-architecture` | An audit report exists and the fixes need executing |
| `folder-architecture` | The agent is about to create, move, or modify any file |
| `code-design` | Reviewing, writing, or refactoring a function |

The loop: **audit → fix → prevent.** Audit finds the problems,
`implement-folder-architecture` fixes them, and `folder-architecture` plus
`code-design` keep them from coming back.
