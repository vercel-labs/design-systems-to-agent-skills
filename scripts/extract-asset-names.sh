#!/bin/bash
# =============================================================================
# Extract asset names from TypeScript source and produce markdown table rows
# =============================================================================
#
# Reads a TypeScript name array file (e.g., icon-names.ts) and outputs
# markdown table rows suitable for asset catalog generation.
#
# Usage:
#   ./scripts/extract-asset-names.sh \
#     --src /path/to/package/src/__generated__/icon-names.ts \
#     --type icons \
#     --package "@vercel/geistcn-assets" \
#     --prefix "icon-" \
#     --export-style named
#
# Output (to stdout):
#   | arrow-up | ArrowUp | `@vercel/geistcn-assets/icons/arrow-up` |
#   | check-circle | CheckCircle | `@vercel/geistcn-assets/icons/check-circle` |
#   ...
#
# The agent captures stdout and writes it into catalog files.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
SRC=""
TYPE=""
PACKAGE=""
PREFIX=""
EXPORT_STYLE="named"  # named | default

while [[ $# -gt 0 ]]; do
  case $1 in
    --src)       SRC="$2";          shift 2 ;;
    --type)      TYPE="$2";         shift 2 ;;
    --package)   PACKAGE="$2";      shift 2 ;;
    --prefix)    PREFIX="$2";       shift 2 ;;
    --export-style) EXPORT_STYLE="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: extract-asset-names.sh --src <file> --type <icons|logos|pixels|illustrations> --package <npm-package> [--prefix <prefix>] [--export-style named|default]"
      echo ""
      echo "Options:"
      echo "  --src           Path to the TypeScript names file (e.g., icon-names.ts)"
      echo "  --type          Asset type: icons, logos, pixels, illustrations"
      echo "  --package       npm package name (e.g., @vercel/geistcn-assets)"
      echo "  --prefix        Optional prefix to prepend to import path segments"
      echo "  --export-style  'named' (import { X }) or 'default' (import X from). Default: named"
      echo ""
      echo "Output: markdown table rows to stdout"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Validate required arguments
# ---------------------------------------------------------------------------
if [ -z "$SRC" ]; then
  echo "ERROR: --src is required" >&2
  exit 1
fi
if [ -z "$TYPE" ]; then
  echo "ERROR: --type is required" >&2
  exit 1
fi
if [ -z "$PACKAGE" ]; then
  echo "ERROR: --package is required" >&2
  exit 1
fi
if [ ! -f "$SRC" ]; then
  echo "ERROR: Source file not found: $SRC" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Extract names and produce markdown table rows in a single pipeline
# ---------------------------------------------------------------------------
#
# Performance: processes ALL names in one awk invocation.
# The original per-name bash loop spawned sed+awk subprocesses per entry,
# which took minutes for 500+ names. This single-pass approach handles
# 1000+ names in under a second.
#
# Strategy: find all quoted strings between array brackets [ ... ],
# then pipe through one awk that does kebab→PascalCase + table formatting.
#
# Handles:
#   export const iconNames = ["arrow-up", "check-circle", ...]
#   export const ICON_NAMES = ['arrow-up', 'check-circle', ...]
#   Multi-line arrays with one name per line

ARRAY_CONTENT=$(sed -n '/\[/,/\]/p' "$SRC" | tr '\n' ' ')

if [ -z "$ARRAY_CONTENT" ]; then
  echo "ERROR: No array content found in $SRC" >&2
  echo "Expected a TypeScript file with an array of quoted strings." >&2
  exit 1
fi

# Extract quoted strings → sort → single-pass awk for PascalCase + table rows
RESULT=$(echo "$ARRAY_CONTENT" \
  | grep -oE "['\"][a-zA-Z0-9][a-zA-Z0-9_-]*['\"]" \
  | sed "s/['\"]//g" \
  | sort -u \
  | awk -v pkg="$PACKAGE" -v type="$TYPE" -v prefix="$PREFIX" '
    function to_pascal(s,    parts, n, i, out, ch) {
      n = split(s, parts, "-")
      out = ""
      for (i = 1; i <= n; i++) {
        ch = substr(parts[i], 1, 1)
        out = out toupper(ch) substr(parts[i], 2)
      }
      return out
    }
    {
      name = $0
      pascal = to_pascal(name)
      if (prefix != "") {
        path = pkg "/" prefix name
      } else {
        path = pkg "/" type "/" name
      }
      printf "| %s | %s | `%s` |\n", name, pascal, path
      count++
    }
    END {
      printf "\n# Extracted %d %s from %s\n", count, type, FILENAME > "/dev/stderr"
      printf "# Package: %s\n", pkg > "/dev/stderr"
      printf "# Total: %d %s\n", count, type > "/dev/stderr"
    }
  ')

if [ -z "$RESULT" ]; then
  echo "ERROR: No asset names found in $SRC" >&2
  echo "The file should contain an array of quoted strings." >&2
  exit 1
fi

echo "$RESULT"
