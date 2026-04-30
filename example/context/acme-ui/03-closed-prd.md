# Acme UI — Closed PRD

## Scope
- **Components:** 3 (Button, Card, Dialog)
- **Guides:** 2 (tokens, imports)
- **Guidelines:** 3 (a11y, performance, security)
- **Single run** (well below 50-component ceiling)

## Section 1: File Manifest

### Infrastructure
| File | Path |
|---|---|
| SKILL.md | `skills/acme-ui/SKILL.md` |
| index.md | `skills/acme-ui/references/acme-ui/v1/index.md` |
| components.md | `skills/acme-ui/references/acme-ui/v1/components.md` |

### Guidelines
| File | Path |
|---|---|
| a11y.md | `skills/acme-ui/references/guidelines/a11y.md` |
| performance.md | `skills/acme-ui/references/guidelines/performance.md` |
| security.md | `skills/acme-ui/references/guidelines/security.md` |

### Guides
| File | Path |
|---|---|
| tokens.md | `skills/acme-ui/references/acme-ui/v1/guides/tokens.md` |
| imports.md | `skills/acme-ui/references/acme-ui/v1/guides/imports.md` |

### Components
| Component | Path Pattern |
|---|---|
| Button | `skills/acme-ui/references/acme-ui/v1/components/button/react-web/api.md` + `examples/` |
| Card | `skills/acme-ui/references/acme-ui/v1/components/card/react-web/api.md` + `examples/` |
| Dialog | `skills/acme-ui/references/acme-ui/v1/components/dialog/react-web/api.md` + `examples/` |

**Total files:** ~18 (3 infrastructure + 3 guidelines + 2 guides + 3 api.md + ~7 example files)

## Section 2: Content Structure

_(Abbreviated — see commands/3-prd.md for the full content structure specification)_

Each api.md includes: Import, Named Exports, Props, TypeScript Interface, Anti-patterns, Related.
Each examples/ directory includes: 01-basic-usage.md, 02-common-patterns.md, and additional files for compound components.

## Section 3: Wave Plan

### Wave 1: Infrastructure
- SKILL.md
- index.md
- components.md
- guidelines/a11y.md
- guidelines/performance.md
- guidelines/security.md

### Wave 2: Guides
- tokens.md
- imports.md

### Wave 3: Components — Batch 1
- Button
- Card
- Dialog

## Section 4: Success Criteria

- [ ] Import paths match verified facts exactly
- [ ] Every prop from facts appears in the props table
- [ ] Compound components documented with nesting pattern
- [ ] All examples include 'use client' directive
- [ ] Every example is a complete functional component

## Section 5: Sub-agent Prompt Template

_(Abbreviated — the full template follows the structure in commands/3-prd.md)_

Key rules for sub-agents:
- Import paths: copy EXACTLY from imports.md
- Props: include ONLY props from verified facts
- Every example: complete functional component with export default
- 'use client' directive in every code block
