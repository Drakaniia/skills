````markdown
# Agent Skills Specification

## Directory Structure

A skill is a directory containing, at minimum, a `SKILL.md` file:

```text
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: documentation
├── assets/           # Optional: templates, resources
└── ...               # Any additional files or directories
```

---

## SKILL.md Format

The `SKILL.md` file must contain YAML frontmatter followed by Markdown content.

### Frontmatter

| Field           | Required | Constraints                                                                                                       |
| --------------- | -------- | ----------------------------------------------------------------------------------------------------------------- |
| `name`          | Yes      | Max 64 characters. Lowercase letters, numbers, and hyphens only. Must not start or end with a hyphen.             |
| `description`   | Yes      | Max 1024 characters. Non-empty. Describes what the skill does and when to use it.                                 |
| `license`       | No       | License name or reference to a bundled license file.                                                              |
| `compatibility` | No       | Max 500 characters. Indicates environment requirements (intended product, system packages, network access, etc.). |
| `metadata`      | No       | Arbitrary key-value mapping for additional metadata.                                                              |
| `allowed-tools` | No       | Space-separated string of pre-approved tools the skill may use. (Experimental)                                    |

### Minimal Example

```yaml
---
name: skill-name
description: A description of what this skill does and when to use it.
---
```

### Example With Optional Fields

```yaml
---
name: pdf-processing
description: Extract PDF text, fill forms, merge files. Use when handling PDFs.
license: Apache-2.0
metadata:
  author: example-org
  version: "1.0"
---
```

---

## `name` Field

The required `name` field:

- Must be 1–64 characters
- May only contain unicode lowercase alphanumeric characters (`a-z`, `0-9`) and hyphens (`-`)
- Must not start or end with a hyphen (`-`)
- Must not contain consecutive hyphens (`--`)
- Must match the parent directory name

### Valid Examples

```yaml
name: pdf-processing
name: data-analysis
name: code-review
```

### Invalid Examples

```yaml
name: PDF-Processing      # uppercase not allowed
name: -pdf                # cannot start with hyphen
name: pdf--processing     # consecutive hyphens not allowed
```

---

## `description` Field

The required `description` field:

- Must be 1–1024 characters
- Should describe both what the skill does and when to use it
- Should include specific keywords that help agents identify relevant tasks

### Good Example

```yaml
description: Extracts text and tables from PDF files, fills PDF forms, and merges multiple PDFs. Use when working with PDF documents or when the user mentions PDFs, forms, or document extraction.
```

### Poor Example

```yaml
description: Helps with PDFs.
```

---

## `license` Field

The optional `license` field:

- Specifies the license applied to the skill
- Recommended to keep it short (license name or bundled license file)

### Example

```yaml
license: Proprietary. LICENSE.txt has complete terms
```

---

## `compatibility` Field

The optional `compatibility` field:

- Must be 1–500 characters if provided
- Should only be included when the skill has specific environment requirements
- Can indicate intended product, required packages, network access requirements, etc.

### Examples

```yaml
compatibility: Designed for Claude Code (or similar products)

compatibility: Requires git, docker, jq, and access to the internet

compatibility: Requires Python 3.14+ and uv
```

Most skills do not need the `compatibility` field.

---

## `metadata` Field

The optional `metadata` field:

- A map from string keys to string values
- Clients can use this to store additional properties not defined by the Agent Skills specification
- Use reasonably unique key names to avoid conflicts

### Example

```yaml
metadata:
  author: example-org
  version: "1.0"
```

---

## `allowed-tools` Field

The optional `allowed-tools` field:

- A space-separated string of tools that are pre-approved to run
- Experimental; support may vary between agent implementations

### Example

```yaml
allowed-tools: Bash(git:*) Bash(jq:*) Read
```

---

## Body Content

The Markdown body after the frontmatter contains the skill instructions.

There are no format restrictions. Write whatever helps agents perform the task effectively.

### Recommended Sections

- Step-by-step instructions
- Examples of inputs and outputs
- Common edge cases

The agent loads this entire file once it activates a skill. Consider moving lengthy content into reference files.

---

## Optional Directories

### `scripts/`

Contains executable code that agents can run.

Scripts should:

- Be self-contained or clearly document dependencies
- Include helpful error messages
- Handle edge cases gracefully

Supported languages depend on the agent implementation. Common options include:

- Python
- Bash
- JavaScript

---

### `references/`

Contains additional documentation that agents can read when needed.

Examples:

```text
REFERENCE.md - Detailed technical reference
FORMS.md     - Form templates or structured data formats
finance.md   - Domain-specific reference
legal.md     - Domain-specific reference
```

Keep individual reference files focused. Agents load them on demand, reducing context usage.

---

### `assets/`

Contains static resources such as:

- Templates
- Images
- Data files
- Schemas
- Lookup tables

Examples:

```text
assets/
├── templates/
├── diagrams/
├── schemas/
└── lookup-tables/
```

---

## Progressive Disclosure

Agents load skills progressively, pulling in more detail only when needed.

### Loading Stages

| Stage                                   | Content                                                                         |
| --------------------------------------- | ------------------------------------------------------------------------------- |
| Metadata (~100 tokens)                  | `name` and `description` fields are loaded at startup for all skills            |
| Instructions (<5000 tokens recommended) | Full `SKILL.md` body is loaded when the skill is activated                      |
| Resources (as needed)                   | Files in `scripts/`, `references/`, and `assets/` are loaded only when required |

### Recommendation

Keep the main `SKILL.md` under **500 lines**.

Move detailed reference material into separate files.

---

## File References

When referencing other files in your skill, use relative paths from the skill root.

### Example

```markdown
See [the reference guide](references/REFERENCE.md) for details.

Run the extraction script:

scripts/extract.py
```

### Guidelines

- Keep file references one level deep from `SKILL.md`
- Avoid deeply nested reference chains

---

## Validation

Use the `skills-ref` reference library to validate your skills:

```bash
skills-ref validate ./my-skill
```

This checks that:

- `SKILL.md` frontmatter is valid
- Naming conventions are followed
- Required fields are present
- Specification constraints are satisfied
````
