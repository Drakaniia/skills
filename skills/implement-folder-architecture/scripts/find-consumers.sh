#!/usr/bin/env bash
# find-consumers.sh
# Find all files that import from a given module path.
# Usage: ./find-consumers.sh <module-path> [target-dir]
#
# Example: ./find-consumers.sh src/utils/string_utils .
#
# Supports: Python, JavaScript/TypeScript, Go, Rust, Java, C#, Ruby, PHP

set -euo pipefail

MODULE_PATH="${1:-}"
TARGET_DIR="${2:-.}"

if [ -z "$MODULE_PATH" ]; then
  echo "Usage: $0 <module-path> [target-dir]"
  echo "Finds all files that import from a given module path."
  echo ""
  echo "Examples:"
  echo "  $0 src/utils/string_utils ."
  echo "  $0 order_service ./src"
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: '$TARGET_DIR' is not a directory" >&2
  exit 1
fi

# Extract the module name (last component of path)
MODULE_NAME=$(basename "$MODULE_PATH")
# Directory part, for the language whose import paths are absolute.
MODULE_DIR=$(dirname "$MODULE_PATH")

# One row per language: label | --include globs | ERE matched against the line.
# A file is a consumer if any line of it matches, in any language.
#
# python:  from .x.y import y  |  import x.y
# js/ts:   from 'x/y'  |  require("x/y")
# go:      the quoted module path itself
# rust:    use x::y
# java:    import x.y.Z
# c#:      using X.Y;
# ruby:    require 'x/y'  |  require_relative 'y'
# php:     use X\Y;  |  require 'x/y'
while IFS='|' read -r label includes pattern; do
  echo "--- $label ---"
  grep -r -l -E "$pattern" $includes "$TARGET_DIR" 2>/dev/null \
    | grep -v "*/node_modules/*" \
    | grep -v "*/.git/*" \
    | head -20 || echo "(none)"
  echo ""
done <<EOF
Python (.py)|--include=*.py|from .*${MODULE_NAME}|import.*${MODULE_NAME}
JS/TS (.js, .jsx, .ts, .tsx)|--include=*.js --include=*.jsx --include=*.ts --include=*.tsx|from ['\"].*${MODULE_NAME}['\"]|require\(['\"].*${MODULE_NAME}['\"]
Go (.go)|--include=*.go|\"${MODULE_PATH}|\"${MODULE_DIR}.*${MODULE_NAME}
Rust (.rs)|--include=*.rs|use.*${MODULE_NAME}
Java (.java)|--include=*.java|import.*${MODULE_NAME}
C# (.cs)|--include=*.cs|using.*${MODULE_NAME}
Ruby (.rb)|--include=*.rb|require.*${MODULE_NAME}|require_relative.*${MODULE_NAME}
PHP (.php)|--include=*.php|use.*${MODULE_NAME}|require.*${MODULE_NAME}
EOF

echo "=== Scan complete ==="
