# Acme UI — Design Tokens

## Setup

Map Acme UI tokens to Tailwind in your `globals.css`:

```css
@theme inline {
  --color-acme-gray-100: var(--acme-gray-100);
  --color-acme-gray-200: var(--acme-gray-200);
  --color-acme-gray-300: var(--acme-gray-300);
  --color-acme-gray-900: var(--acme-gray-900);
  --color-acme-blue-500: var(--acme-blue-500);
  --color-acme-blue-600: var(--acme-blue-600);
  --color-acme-blue-700: var(--acme-blue-700);
  --color-acme-red-500: var(--acme-red-500);
  --color-acme-red-600: var(--acme-red-600);
  --color-acme-green-500: var(--acme-green-500);
  --color-acme-green-600: var(--acme-green-600);
  --spacing-acme-1: var(--acme-space-1);
  --spacing-acme-2: var(--acme-space-2);
  --spacing-acme-4: var(--acme-space-4);
  --spacing-acme-6: var(--acme-space-6);
  --spacing-acme-8: var(--acme-space-8);
  --radius-acme-sm: var(--acme-radius-sm);
  --radius-acme-md: var(--acme-radius-md);
  --radius-acme-lg: var(--acme-radius-lg);
}
```

## Usage

Apply tokens as Tailwind utilities:

```tsx
<div className="bg-acme-gray-100 p-acme-4 rounded-acme-lg">
  <p className="text-acme-gray-900">Content</p>
</div>
```

## Class Composition

Use `cn()` from `@acme/ui/utils` for conditional classes:

```tsx
import { cn } from '@acme/ui/utils'

<div className={cn('p-acme-4', isActive && 'bg-acme-blue-600 text-white')} />
```

## Anti-patterns

| Wrong | Correct | Why |
|---|---|---|
| `bg-blue-500` | `bg-acme-blue-600` | Raw Tailwind colors bypass the token system |
| `style={{ padding: '16px' }}` | `className="p-acme-4"` | Inline styles fight the Tailwind architecture |
| `clsx('p-4', ...)` | `cn('p-acme-4', ...)` | `cn()` extends tailwind-merge for Acme UI class groups |

## Colors

| Token | Usage |
|---|---|
| `--acme-gray-100` through `--acme-gray-900` | Text, backgrounds, borders |
| `--acme-blue-500` through `--acme-blue-700` | Primary actions, links |
| `--acme-red-500`, `--acme-red-600` | Destructive actions, errors |
| `--acme-green-500`, `--acme-green-600` | Success states |

## Spacing

Base: 4px (`--acme-space: 0.25rem`)

| Token | Value | Tailwind |
|---|---|---|
| `--acme-space-1` | 4px | `p-acme-1`, `m-acme-1`, `gap-acme-1` |
| `--acme-space-2` | 8px | `p-acme-2` |
| `--acme-space-4` | 16px | `p-acme-4` |
| `--acme-space-6` | 24px | `p-acme-6` |
| `--acme-space-8` | 32px | `p-acme-8` |

## Radii

| Token | Value | Tailwind |
|---|---|---|
| `--acme-radius-sm` | 4px | `rounded-acme-sm` |
| `--acme-radius-md` | 6px | `rounded-acme-md` |
| `--acme-radius-lg` | 8px | `rounded-acme-lg` |

## Shadows

| Token | Tailwind |
|---|---|
| `--acme-shadow-sm` | `shadow-acme-sm` |
| `--acme-shadow-md` | `shadow-acme-md` |
| `--acme-shadow-lg` | `shadow-acme-lg` |
