# Subagent Prompt Template — Acme UI

_(Abbreviated — the full template follows the structure in commands/3-prd.md)_

The following prompt is sent to each subagent. Variables in {braces} are replaced per component.

---

You are generating skill documentation for {COMPONENT_NAME} (Acme UI design system).

**Verified facts (use these — do not generate from memory):**
{CONTENTS_OF_VERIFIED_FACTS_FILE}

**Import path (use EXACTLY this):**
{IMPORT_LINE_FROM_IMPORTS_MD}

**Write files to:**
1. `skills/acme-ui/references/acme-ui/v1/components/{name}/react-web/api.md`
2. `skills/acme-ui/references/acme-ui/v1/components/{name}/react-web/examples/01-basic-usage.md`

**Rules:**
- Import paths: copy EXACTLY from imports.md
- Props: include ONLY props from verified facts
- Every example: complete functional component with export default
- 'use client' directive in every code block

---
