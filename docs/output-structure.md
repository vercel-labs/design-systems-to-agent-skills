# Output Structure

What the pipeline produces and how the generated files are organized.

## Hub-and-Spoke Architecture

The generated skill uses a hub-and-spoke model:

```
skills/{ds}/
├── SKILL.md                                    # Hub: entry point + routing
├── references/
│   ├── guidelines/                             # Cross-cutting (DS-agnostic)
│   │   ├── a11y.md
│   │   ├── performance.md
│   │   └── security.md
│   └── {ds}/v{N}/                              # Versioned DS namespace
│       ├── index.md                            # Spoke: component catalog
│       ├── components.md                       # Spoke: categorized reference
│       ├── guides/                             # Spoke: DS-specific guides
│       │   ├── tokens.md
│       │   ├── imports.md
│       │   ├── setup.md
│       │   └── ...
│       └── components/                         # Spoke: per-component docs
│           └── {name}/{platform}/
│               ├── api.md
│               └── examples/
│                   ├── 01-basic-usage.md
│                   ├── 02-common-patterns.md
│                   └── ...
```

**SKILL.md** is the entry point. An agent reads this first and uses its routing matrix to navigate to the right reference file for any task.

### SKILL.md Frontmatter

SKILL.md must begin with YAML frontmatter for skill system registration. Most agent runtimes that support skill discovery (Claude Code, OpenCode) use frontmatter to index skills:

```yaml
---
name: {ds}
description: >
  {DS full name} component and asset reference. Use this skill when building UI
  with {package} — component props, import paths, icons, design tokens,
  and anti-patterns. All data verified from source code.
---
```

The `name` field is the DS short name (e.g., `geistcn`, `andes`). The `description` is a concise summary that helps the agent decide when to invoke the skill. Stage 4 generates this from the decisions file — no extra user input needed.

## Versioned Namespace

All DS-specific content lives under a versioned path: `{ds}/v{N}/`. This enables:
- Multiple versions of the same DS to coexist
- Clear version identification in generated code
- Future migration guides between versions

Example: `acme-ui/v1/components/button/react-web/api.md`

## Guidelines vs Guides

Two distinct directories serve different purposes:

- **`guidelines/`** — Cross-cutting, DS-agnostic best practices (accessibility, performance, security). These apply to any design system and rarely change.
- **`{ds}/v{N}/guides/`** — DS-specific references (tokens, import paths, setup, anti-patterns). These are tied to the specific design system version.

## Component Structure

Each component gets a directory under `components/{name}/{platform}/`:

### Single-variant components

Most components are single-variant:

```
components/button/react-web/
├── api.md
└── examples/
    ├── 01-basic-usage.md
    ├── 02-common-patterns.md
    └── 03-composition.md
```

### Multi-variant components

Components with distinct variant types (e.g., a chart component with bar/line/pie variants) get subdirectories:

```
components/chart/react-web/
├── bar/
│   ├── api.md
│   └── examples/
├── line/
│   ├── api.md
│   └── examples/
└── pie/
    ├── api.md
    └── examples/
```

The PRD specifies which components are single-variant vs multi-variant.

## Platform Namespace

The `{platform}` directory (typically `react-web`) enables future multi-platform support:

- `react-web/` — React for web (most common)
- `react-native/` — React Native
- Other platform targets as needed

## api.md Structure

Each component's `api.md` follows a consistent structure:

```markdown
# {ComponentName}

## Import
(exact import statement from verified facts)

## Named Exports
(table of all exports: components, types, hooks, utilities)

## Props
(table with Type, Default, Required, Description)

## TypeScript Interface
(raw interface from source, in a fenced code block)

## Inherited Props
(what the component extends)

## Compound Components
(sub-component table and nesting pattern, if applicable)

## Controlled vs Uncontrolled
(discriminator pattern, if interactive component)

## Data Attributes
(testing attributes, if extracted)

## Anti-patterns
(common mistakes with WRONG/CORRECT code blocks)

## Related
(links to related components)
```

Not all sections appear in every component. Compound Components is only present for compound components. Controlled vs Uncontrolled is only present for interactive components.

## examples/ Directory

Examples use progressive disclosure via numbered files:

| File | Content |
|---|---|
| `01-basic-usage.md` | Minimal working example |
| `02-common-patterns.md` | 2-3 real-world patterns |
| `03-compound-usage.md` | Sub-component composition (if compound) |
| `04-composition.md` | Combining with other DS components |
| Additional files | Complex components may have more |

Every example file contains complete, copy-paste-ready functional components — not JSX snippets. Each includes:
- Full imports (component + style imports)
- `export default` function component
- `'use client'` directive (if the DS targets Next.js/RSC)

## Asset Catalogs

If the design system includes icons, illustrations, or other assets, they get dedicated catalogs under `assets/`:

```
{ds}/v{N}/assets/
├── icons/{platform}/
│   └── api.md              # Exhaustive icon name list + import patterns
├── logos/{platform}/
│   └── api.md              # Logo catalog with variants
├── pixels/{platform}/
│   └── api.md              # Pixel art catalog
└── illustrations/{platform}/
    └── api.md              # Illustration catalog
```

Asset catalogs are exhaustive lookup tables — every asset name, import path, and variant — that eliminate name hallucination by giving agents a complete enumeration to search.

### Multi-package assets

When a design system ships assets in a separate package (e.g., `@vercel/geistcn` components + `@vercel/geistcn-assets` icons/logos), each package gets its own namespace:

```
references/
├── {ds}/v{N}/                     # Main component package
│   └── assets/                    # Assets from main package (if any)
├── {ds}-assets/v{N}/              # Standalone assets package
│   ├── index.md                   # Package overview + routing
│   └── assets/
│       ├── icons/{platform}/api.md
│       ├── logos/{platform}/api.md
│       └── pixels/{platform}/api.md
```

### Asset catalog format (api.md)

Each asset catalog follows this structure:

```markdown
# {Type} Catalog — {DS Name}

{count} {type}s. Import pattern: `import { ComponentName } from '{package}/{type}/component-name'`

> Load this file whenever you need a {type} from {DS Name}.
> Do NOT guess {type} names — pick from the table below.

## Import

\```tsx
// Direct import (preferred)
import { ArrowUp } from '{package}/icons/arrow-up'

// Barrel import (if supported)
import { ArrowUp } from '{package}/icons'
\```

## Props

| Prop | Type | Default | Description |
|---|---|---|---|
| size | number | 24 | Width and height in pixels |
| color | string | 'currentColor' | Icon color |
| className | string | — | Additional CSS classes |

## All {Type}s ({count})

| Name | Component | Import Path |
|---|---|---|
| arrow-up | ArrowUp | `{package}/icons/arrow-up` |
| check-circle | CheckCircle | `{package}/icons/check-circle` |
...

## Anti-patterns

- DON'T guess icon names — use this catalog
- DON'T import from barrel if DS recommends direct imports
- DON'T hardcode SVG — use the component import
```

For asset types with variants (logos with light/dark/mono), add a Variants column:

```markdown
| Name | Component | Variants | Import Path |
|---|---|---|---|
| vercel | VercelLogo | light, dark, mono | `{package}/logos/vercel` |
```

Props are extracted from one actual asset component file in the source — not generated from memory. The shared props interface (size, color, className) applies to all assets of that type.

## SKILL.md Routing Matrix

The routing matrix in SKILL.md maps user intent to reference files:

```markdown
| Task | Reference |
|---|---|
| Use a component | `{ds}/v{N}/components/{name}/{platform}/api.md` |
| See examples | `{ds}/v{N}/components/{name}/{platform}/examples/` |
| Find import path | `{ds}/v{N}/guides/imports.md` |
| Use design tokens | `{ds}/v{N}/guides/tokens.md` |
| Use an icon | `{ds}/v{N}/assets/icons/{platform}/api.md` |
| Ensure accessibility | `guidelines/a11y.md` |
```

This is how agents navigate the skill — they read SKILL.md first, then follow the routing to the specific file they need.
