---
name: implement-folder-architecture
description: Execute a folder architecture migration from an audit report
---

Activate the implement-folder-architecture skill to execute a structural refactoring based on an existing audit report. The skill works incrementally through three phases: Quick Cleanup (safe renames/removals), File Refactoring (splitting oversized files, moving misplaced files), and Structural Refactoring (splitting bloated directories, flattening nesting, architecture migration). After each step, the build and tests are verified before proceeding. Use this after running `/audit-codebase` to implement its recommendations.
