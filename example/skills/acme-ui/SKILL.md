# Acme UI Design System Skill

**Package:** `@acme/ui` v1.0.0
**Framework:** React 18 + Next.js 14 (App Router)

## Quick Start

1. Import the stylesheet in your root layout:
   ```tsx
   import '@acme/ui/styles.css'
   ```

2. Import components from subpaths:
   ```tsx
   import { Button } from '@acme/ui/components/button'
   import { Card } from '@acme/ui/components/card'
   ```

3. Use design tokens via Tailwind `@theme inline`:
   ```css
   @theme inline {
     --color-acme-blue-600: var(--acme-blue-600);
     --color-acme-gray-100: var(--acme-gray-100);
     --spacing-acme-4: var(--acme-space-4);
   }
   ```
   Then use as Tailwind utilities: `bg-acme-blue-600`, `p-acme-4`.

## Routing Matrix

| Task | Reference |
|---|---|
| Use a component | `acme-ui/v1/components/{name}/react-web/api.md` |
| See usage examples | `acme-ui/v1/components/{name}/react-web/examples/` |
| Find import paths | `acme-ui/v1/guides/imports.md` |
| Use design tokens | `acme-ui/v1/guides/tokens.md` |
| Accessibility | `guidelines/a11y.md` |
| Performance | `guidelines/performance.md` |
| Security | `guidelines/security.md` |

## Reference Structure

```
references/
├── guidelines/          # Cross-cutting best practices
├── acme-ui/v1/
│   ├── index.md         # Component catalog + navigation
│   ├── components.md    # Categorized reference
│   ├── guides/          # Tokens, imports
│   └── components/      # Per-component api + examples
```
