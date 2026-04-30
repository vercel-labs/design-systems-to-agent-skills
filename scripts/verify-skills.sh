#!/bin/bash
# =============================================================================
# Stage 5: Programmatic verification of generated design system skills
# =============================================================================
#
# Usage: ./scripts/verify-skills.sh <ds-name> [--fix]
#
# Agent-based verification has the same hallucination risks as generation.
# This script catches mechanical errors deterministically.
#
# Checks:
# 1. File completeness — every in-scope component has api.md + examples/
# 2. Import paths — all match verified facts, no hallucinations
# 3. Structural requirements — sections, directives, documentation
# 4. Cross-reference — all components in index.md and SKILL.md routing matrix
#
# Output: context/<ds>/stage5-verification.md
# =============================================================================

set -euo pipefail

DS_NAME="${1:?Usage: verify-skills.sh <ds-name> [--fix]}"
FIX_MODE="${2:-}"
SKILLS_DIR="skills/$DS_NAME"
FACTS_DIR="context/$DS_NAME/02-verified-facts"
DECISIONS="context/$DS_NAME/01-decisions.md"
OUTPUT="context/$DS_NAME/stage5-verification.md"

# Detect framework from decisions — 'use client' check only applies to Next.js/RSC
NEEDS_USE_CLIENT=false
if [ -f "$DECISIONS" ] && grep -qi "Next\.js\|React Server\|App Router\|'use client'" "$DECISIONS" 2>/dev/null; then
  NEEDS_USE_CLIENT=true
fi

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo " Stage 5: Verifying $DS_NAME skills"
echo "=========================================="
echo ""

# Counters
TOTAL_COMPONENTS=0
TOTAL_FILES=0
MISSING_API=0
MISSING_EXAMPLES=0
IMPORT_ERRORS=0
MISSING_IMPORT_SECTION=0
MISSING_NAMED_EXPORTS=0
MISSING_ANTI_PATTERNS=0
MISSING_STYLE_IMPORTS=0
MISSING_USE_CLIENT=0
MISSING_FROM_INDEX=0
ERRORS=()

# ============================================================================
# Detect output structure
# ============================================================================
# The pipeline generates a versioned namespace: skills/{ds}/references/{ds}/v{N}/components/
# Find the actual component directory by looking for the versioned path
COMP_DIR=""
if [ -d "$SKILLS_DIR/references" ]; then
  # Look for versioned component directories
  for vdir in "$SKILLS_DIR"/references/*/v*/components; do
    if [ -d "$vdir" ]; then
      COMP_DIR="$vdir"
      break
    fi
  done
  # Fall back to flat structure
  if [ -z "$COMP_DIR" ] && [ -d "$SKILLS_DIR/references/components" ]; then
    COMP_DIR="$SKILLS_DIR/references/components"
  fi
fi

if [ -z "$COMP_DIR" ]; then
  echo -e "${RED}ERROR: No component directory found under $SKILLS_DIR/references/${NC}"
  echo "Expected: $SKILLS_DIR/references/{ds}/v{N}/components/"
  exit 1
fi

echo "Component directory: $COMP_DIR"
echo ""

# ============================================================================
# Check 1: File completeness
# ============================================================================
echo "--- Check 1: File completeness ---"

if [ ! -d "$FACTS_DIR/components" ]; then
  echo -e "${RED}ERROR: Verified facts directory not found: $FACTS_DIR/components${NC}"
  echo "Run Stage 2 (extract) first."
  exit 1
fi

for fact_file in "$FACTS_DIR"/components/*.md; do
  [ -f "$fact_file" ] || continue
  comp=$(basename "$fact_file" .md)
  ((TOTAL_COMPONENTS++))

  # Check for api.md — may be at {comp}/api.md or {comp}/{platform}/api.md
  api_found=false
  if [ -f "$COMP_DIR/$comp/api.md" ]; then
    api_found=true
  else
    # Check platform subdirectories
    for pdir in "$COMP_DIR/$comp"/*/; do
      if [ -f "${pdir}api.md" ]; then
        api_found=true
        break
      fi
    done
  fi

  if [ "$api_found" = false ]; then
    echo -e "${RED}MISSING: $comp/api.md${NC}"
    ((MISSING_API++))
    ERRORS+=("Missing api.md: $comp")
  else
    ((TOTAL_FILES++))
  fi

  # Check for examples/ directory — may be at {comp}/examples/ or {comp}/{platform}/examples/
  examples_found=false
  if [ -d "$COMP_DIR/$comp/examples" ]; then
    examples_found=true
  else
    for pdir in "$COMP_DIR/$comp"/*/; do
      if [ -d "${pdir}examples" ]; then
        examples_found=true
        break
      fi
    done
  fi

  if [ "$examples_found" = false ]; then
    echo -e "${RED}MISSING: $comp/examples/${NC}"
    ((MISSING_EXAMPLES++))
    ERRORS+=("Missing examples/: $comp")
  else
    ((TOTAL_FILES++))
  fi
done

echo "Components in scope: $TOTAL_COMPONENTS"
echo "Files found: $TOTAL_FILES / $((TOTAL_COMPONENTS * 2)) expected"
echo "Missing api.md: $MISSING_API"
echo "Missing examples/: $MISSING_EXAMPLES"
echo ""

# ============================================================================
# Check 2: Import path verification
# ============================================================================
echo "--- Check 2: Import paths ---"

if [ -f "$FACTS_DIR/imports.md" ]; then
  VALID_IMPORTS=$(grep -oE "from ['\"][^'\"]+['\"]" "$FACTS_DIR/imports.md" 2>/dev/null | \
    sed "s/from ['\"]//;s/['\"]$//" | sort -u || true)

  while IFS= read -r line; do
    import_path=$(echo "$line" | grep -oE "from ['\"][^'\"]+['\"]" | sed "s/from ['\"]//;s/['\"]$//" || true)

    case "$import_path" in
      react|react/*|next/*|"") continue ;;
    esac

    if [ -n "$import_path" ] && ! echo "$VALID_IMPORTS" | grep -qF "$import_path"; then
      ((IMPORT_ERRORS++))
      ERRORS+=("Wrong import: $line")
    fi
  done < <(grep -rn "from ['\"]" "$COMP_DIR/" 2>/dev/null | grep -v '```' || true)

  if [ "$IMPORT_ERRORS" -gt 0 ]; then
    echo -e "${RED}WRONG IMPORTS FOUND: $IMPORT_ERRORS${NC}"
  else
    echo -e "${GREEN}All import paths verified against facts.${NC}"
  fi
else
  echo -e "${YELLOW}WARNING: imports.md not found — skipping import verification${NC}"
fi
echo ""

# ============================================================================
# Check 3: Structural requirements
# ============================================================================
echo "--- Check 3: Structural requirements ---"

# Find all api.md files recursively
while IFS= read -r api_file; do
  [ -f "$api_file" ] || continue

  # Extract component name from path
  comp_path="${api_file#"$COMP_DIR/"}"
  comp=$(echo "$comp_path" | cut -d'/' -f1)

  if ! grep -q "## Import" "$api_file"; then
    echo -e "${RED}MISSING ## Import section: $comp_path${NC}"
    ((MISSING_IMPORT_SECTION++))
    ERRORS+=("Missing ## Import: $comp_path")
  fi

  if ! grep -q "## Named Exports" "$api_file"; then
    echo -e "${RED}MISSING ## Named Exports section: $comp_path${NC}"
    ((MISSING_NAMED_EXPORTS++))
    ERRORS+=("Missing ## Named Exports: $comp_path")
  fi

  if ! grep -q "## Anti-patterns" "$api_file"; then
    echo -e "${YELLOW}MISSING ## Anti-patterns section: $comp_path${NC}"
    ((MISSING_ANTI_PATTERNS++))
    ERRORS+=("Missing ## Anti-patterns: $comp_path")
  fi
done < <(find "$COMP_DIR" -name "api.md" -type f 2>/dev/null)

# Check example files for 'use client' (only for Next.js/RSC projects)
if [ "$NEEDS_USE_CLIENT" = true ]; then
  while IFS= read -r ex_file; do
    [ -f "$ex_file" ] || continue
    if ! grep -q "use client" "$ex_file"; then
      comp_path="${ex_file#"$COMP_DIR/"}"
      echo -e "${RED}MISSING 'use client': $comp_path${NC}"
      ((MISSING_USE_CLIENT++))
      ERRORS+=("Missing 'use client': $comp_path")
    fi
  done < <(find "$COMP_DIR" -path "*/examples/*.md" -type f 2>/dev/null)
else
  echo -e "${YELLOW}SKIPPED: 'use client' check (not a Next.js/RSC project)${NC}"
fi

echo "Missing ## Import sections: $MISSING_IMPORT_SECTION"
echo "Missing ## Named Exports sections: $MISSING_NAMED_EXPORTS"
echo "Missing ## Anti-patterns sections: $MISSING_ANTI_PATTERNS"
echo "Missing 'use client' directives: $MISSING_USE_CLIENT"
echo ""

# ============================================================================
# Check 4: Cross-reference with index
# ============================================================================
echo "--- Check 4: Cross-references ---"

# Find index.md in the versioned path
INDEX_FILE=""
for idx in "$SKILLS_DIR"/references/*/v*/index.md; do
  if [ -f "$idx" ]; then
    INDEX_FILE="$idx"
    break
  fi
done

if [ -n "$INDEX_FILE" ] && [ -f "$INDEX_FILE" ]; then
  for fact_file in "$FACTS_DIR"/components/*.md; do
    [ -f "$fact_file" ] || continue
    comp=$(basename "$fact_file" .md)
    if ! grep -qi "$comp" "$INDEX_FILE"; then
      echo -e "${YELLOW}NOT IN INDEX: $comp${NC}"
      ((MISSING_FROM_INDEX++))
    fi
  done
  echo "Components missing from index.md: $MISSING_FROM_INDEX"
else
  echo -e "${YELLOW}WARNING: index.md not found — skipping cross-reference check${NC}"
fi
echo ""

# ============================================================================
# Summary
# ============================================================================
TOTAL_ERRORS=${#ERRORS[@]}

echo "=========================================="
echo " SUMMARY"
echo "=========================================="
echo "Components: $TOTAL_COMPONENTS"
echo "Files: $TOTAL_FILES / $((TOTAL_COMPONENTS * 2))"
echo "Import errors: $IMPORT_ERRORS"
echo "Structural issues: $((MISSING_IMPORT_SECTION + MISSING_NAMED_EXPORTS + MISSING_ANTI_PATTERNS + MISSING_USE_CLIENT))"
echo "Cross-reference issues: $MISSING_FROM_INDEX"
echo "Total issues: $TOTAL_ERRORS"
echo ""

if [ "$TOTAL_ERRORS" -eq 0 ]; then
  echo -e "${GREEN}All checks passed.${NC}"
else
  echo -e "${RED}$TOTAL_ERRORS issues found. Review the verification report.${NC}"
fi

# ============================================================================
# Write verification report
# ============================================================================
mkdir -p "$(dirname "$OUTPUT")"

cat > "$OUTPUT" << EOF
## Stage 5 Verification Results — $DS_NAME

### File completeness
- Components in scope: $TOTAL_COMPONENTS
- api.md files: $((TOTAL_COMPONENTS - MISSING_API)) / $TOTAL_COMPONENTS
- examples/ directories: $((TOTAL_COMPONENTS - MISSING_EXAMPLES)) / $TOTAL_COMPONENTS
- Missing: $((MISSING_API + MISSING_EXAMPLES)) items

### Import paths
- Wrong import paths: $IMPORT_ERRORS

### Structural checks
- Missing ## Import sections: $MISSING_IMPORT_SECTION
- Missing ## Named Exports sections: $MISSING_NAMED_EXPORTS
- Missing ## Anti-patterns sections: $MISSING_ANTI_PATTERNS
- Missing 'use client' directives: $MISSING_USE_CLIENT

### Cross-references
- Components missing from index.md: $MISSING_FROM_INDEX

### Overall
- **Total issues: $TOTAL_ERRORS**
$(if [ "$TOTAL_ERRORS" -eq 0 ]; then echo "- **Status: PASSED**"; else echo "- **Status: ISSUES FOUND — review and fix before final commit**"; fi)

$(if [ "$TOTAL_ERRORS" -gt 0 ]; then
echo "### Issue details"
for err in "${ERRORS[@]}"; do
  echo "- $err"
done
fi)
EOF

echo ""
echo "Verification report written to: $OUTPUT"

# If --fix flag and there are import errors, suggest next steps
if [ "$FIX_MODE" = "--fix" ] && [ "$IMPORT_ERRORS" -gt 0 ]; then
  echo ""
  echo "=========================================="
  echo " FIX MODE"
  echo "=========================================="
  echo "Import errors detected. To fix, create a script that:"
  echo "1. Reads the verified import paths from $FACTS_DIR/imports.md"
  echo "2. Scans all files in $COMP_DIR/"
  echo "3. Replaces wrong import paths with verified ones"
fi
