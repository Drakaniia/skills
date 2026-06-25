---
name: audit-codebase
description: Scan codebase for structural health issues and generate an audit report
---

Run the audit-codebase skill to scan this codebase for structural health issues. Generate a full markdown audit report with before/after diagrams organized by refactoring phases.

Ask the user if they want a full report (comprehensive) or quick spec (fast-track for AI implementation). Then scan the codebase, detect issues (folder bloat, oversized files, deep nesting, naming inconsistencies, orphaned files, doc sprawl, empty directories), and save the report.
