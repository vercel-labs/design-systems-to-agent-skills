# Card

Content container with padding and variant options.

## Import

```tsx
import { Card } from '@acme/ui/components/card'
```

## Named Exports

| Export | Kind |
|---|---|
| Card | Component |
| CardProps | Type |

## Props

| Prop | Type | Default | Required | Description |
|---|---|---|---|---|
| `padding` | `'none' \| 'sm' \| 'md' \| 'lg'` | `'md'` | No | Internal padding |
| `variant` | `'default' \| 'outlined' \| 'elevated'` | `'default'` | No | Visual style |

## TypeScript Interface

```tsx
export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  padding?: 'none' | 'sm' | 'md' | 'lg';
  variant?: 'default' | 'outlined' | 'elevated';
}
```

## Inherited Props

Also accepts all standard HTML div attributes via `React.HTMLAttributes<HTMLDivElement>`, including `className`, `onClick`, `role`, etc.

## Anti-patterns

### Wrong: adding manual padding with Tailwind
```tsx
// WRONG — fights the padding prop
<Card className="p-8">Content</Card>
```

### Correct: use padding prop
```tsx
// CORRECT
<Card padding="lg">Content</Card>
```

## Related

- [Button](../button/react-web/api.md) — commonly used inside cards
- [Dialog](../dialog/react-web/api.md) — for modal content that needs card-like styling
