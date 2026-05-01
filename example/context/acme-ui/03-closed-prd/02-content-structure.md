# Content Structure — Acme UI

_(Abbreviated — see commands/3-prd.md for the full content structure specification)_

## api.md (per component)
- ## Import — exact import statement + style import from verified facts
- ## Named Exports — table of all exports with Kind (Component, Type, Hook, Utility)
- ## Props — table with Type, Default, Required, Description
- ## TypeScript Interface — raw TS interface from verified facts (fenced code block)
- ## Inherited Props — what the component extends
- ## Compound Components — sub-component table and nesting pattern (if applicable)
- ## Anti-patterns — common mistakes with WRONG/CORRECT code blocks
- ## Related — links to related components

## examples/ directory (per component)
- `01-basic-usage.md` — minimal working example
- `02-common-patterns.md` — 2-3 real-world patterns
- `03-compound-usage.md` — sub-component composition (if applicable)

Every example file must include:
- `'use client'` directive at top of every code block
- Full imports in every example (component import + style import)
- Every example is a complete functional component with `export default`
