---
name: codebase-health
description: Use when starting any session, or when unsure which codebase-health skill applies. Routes to audit-codebase, folder-architecture, code-design, and implement-folder-architecture. Establishes that codebase health is continuous practice, not a one-time audit.
metadata:
  version: "2.1.1"
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

## Standing rule: 400-line files

Check a file's current line count **before** editing or creating it.

- **>350 lines** and the edit pushes it toward/over 400 → warn and propose splitting.
- **>400 lines** → do not add to it unprompted. Propose the split first.

A ~400-line file usually mixes concerns (SoC / SRP), which is what makes it
hard to review and test. Flag it, but do not split it as a drive-by in an
unrelated change — route to `folder-architecture` + `code-design` for the real fix.
