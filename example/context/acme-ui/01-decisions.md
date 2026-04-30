# acme-ui — Stage 1 Decisions

## Status: Complete

## Identity
- **Name:** Acme UI
- **Package:** `@acme/ui`
- **Version:** 1.0.0
- **Source:** /path/to/acme-ui
- **Output:** skills/acme-ui/

## Scope
- **Total components:** 3
- **Excluded:** None
- **In scope:** Button, Card, Dialog

## Categories
- **Actions (1):** Button
- **Layout (1):** Card
- **Overlay (1):** Dialog

## Technical

### Styling Approach
- **Framework:** Tailwind CSS v4 with `@theme inline` token mapping
- **Token foundation:** CSS custom properties (`--acme-*`)
- **Variant system:** CVA (class-variance-authority)

### Consumer Styling
- **Class utility:** `cn()` exported from `@acme/ui/utils`
- **Token application:** Tailwind `@theme inline` — `--acme-*` CSS custom properties mapped to Tailwind utilities
- **Rationale:** DS uses Tailwind v4 internally; consumers use `cn()` for class composition

### Compound Components
- **Pattern:** Separate named exports from shared barrel file
- **Examples:** Dialog → DialogHeader, DialogBody, DialogActions

### Design Tokens
- **Colors:** gray (100-900), blue (500, 600, 700), red (500, 600), green (500, 600)
- **Spacing:** 4px base scale (1-16)
- **Radii:** sm (4px), md (6px), lg (8px)
- **Shadows:** sm, md, lg

### Provider / Setup
- **Required:** Import `@acme/ui/styles.css` in root layout
- **No provider wrapper needed**

## Output Structure

### Guides
1. **tokens.md** — Color scales, spacing, radii, shadows
2. **imports.md** — Per-component import paths

### Component Documentation Structure
- `api.md` — Import, props table, compound components, anti-patterns
- `examples/` — Numbered example files with `'use client'` directive

## Environment
- **Registry:** Public (npm)
- **React:** 18.x
- **Next.js:** 14.x (App Router)
- **TypeScript:** 5.x
