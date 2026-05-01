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
# Helper: kebab-case to PascalCase
# ---------------------------------------------------------------------------
to_pascal_case() {
  local input="$1"
  # Split on hyphens, capitalize each segment, join
  echo "$input" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1' | sed 's/ //g'
}

# ---------------------------------------------------------------------------
# Determine the singular form of the type for import paths
# ---------------------------------------------------------------------------
# icons -> icon, logos -> logo, pixels -> pixel, illustrations -> illustration
TYPE_SINGULAR="${TYPE%s}"

# ---------------------------------------------------------------------------
# Extract names from the TypeScript file
# ---------------------------------------------------------------------------
# Strategy: find all quoted strings between array brackets [ ... ]
# Handles:
#   export const iconNames = ["arrow-up", "check-circle", ...]
#   export const ICON_NAMES = ['arrow-up', 'check-circle', ...]
#   Multi-line arrays with one name per line

NAMES=()

# Read the file and extract quoted strings that appear within array context
# First, try to find content between [ and ] brackets
ARRAY_CONTENT=$(sed -n '/\[/,/\]/p' "$SRC" | tr '\n' ' ')

if [ -z "$ARRAY_CONTENT" ]; then
  echo "ERROR: No array content found in $SRC" >&2
  echo "Expected a TypeScript file with an array of quoted strings." >&2
  exit 1
fi

# Extract all quoted strings (single or double quotes)
while IFS= read -r name; do
  [ -n "$name" ] && NAMES+=("$name")
done < <(echo "$ARRAY_CONTENT" | grep -oE "['\"][a-zA-Z0-9][a-zA-Z0-9_-]*['\"]" | sed "s/['\"]//g" | sort -u)

if [ ${#NAMES[@]} -eq 0 ]; then
  echo "ERROR: No asset names found in $SRC" >&2
  echo "The file should contain an array of quoted strings." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Output: header comment (to stderr for agent context)
# ---------------------------------------------------------------------------
echo "# Extracted ${#NAMES[@]} ${TYPE} from $(basename "$SRC")" >&2
echo "# Source: $SRC" >&2
echo "# Package: $PACKAGE" >&2
echo "" >&2

# ---------------------------------------------------------------------------
# Output: markdown table rows (to stdout for catalog use)
# ---------------------------------------------------------------------------
for name in "${NAMES[@]}"; do
  pascal=$(to_pascal_case "$name")

  # Build import path
  if [ -n "$PREFIX" ]; then
    import_path="${PACKAGE}/${PREFIX}${name}"
  else
    import_path="${PACKAGE}/${TYPE}/${name}"
  fi

  echo "| ${name} | ${pascal} | \`${import_path}\` |"
done

# ---------------------------------------------------------------------------
# Summary to stderr
# ---------------------------------------------------------------------------
echo "" >&2
echo "# Total: ${#NAMES[@]} ${TYPE}" >&2
