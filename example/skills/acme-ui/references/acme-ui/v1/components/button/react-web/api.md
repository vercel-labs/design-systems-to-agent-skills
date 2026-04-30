# Button

Interactive component for user actions.

## Import

```tsx
import { Button } from '@acme/ui/components/button'
```

## Named Exports

| Export | Kind |
|---|---|
| Button | Component |
| ButtonProps | Type |

## Props

| Prop | Type | Default | Required | Description |
|---|---|---|---|---|
| `variant` | `'primary' \| 'secondary' \| 'destructive' \| 'ghost'` | `'primary'` | No | Visual style variant |
| `size` | `'sm' \| 'md' \| 'lg'` | `'md'` | No | Button size |
| `loading` | `boolean` | `false` | No | Show loading spinner, disables interactions |
| `prefix` | `React.ReactNode` | — | No | Element rendered before children |
| `suffix` | `React.ReactNode` | — | No | Element rendered after children |

## TypeScript Interface

```tsx
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'destructive' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  prefix?: React.ReactNode;
  suffix?: React.ReactNode;
}
```

## Inherited Props

Also accepts all standard HTML button attributes via `React.ButtonHTMLAttributes<HTMLButtonElement>`, including `onClick`, `disabled`, `type`, `className`, `aria-label`, etc.

## Anti-patterns

### Wrong: using raw Tailwind colors to style a Button
```tsx
// WRONG
<Button className="bg-blue-500 text-white">Submit</Button>
```

### Correct: use variant prop
```tsx
// CORRECT
<Button variant="primary">Submit</Button>
```

### Wrong: forgetting disabled state during loading
```tsx
// WRONG — button is still clickable while loading
<Button loading onClick={handleSubmit}>Submit</Button>
```

### Correct: loading disables automatically
```tsx
// CORRECT — loading prop disables interactions internally
<Button loading onClick={handleSubmit}>Submit</Button>
// onClick won't fire while loading=true
```

## Related

- [Card](../card/react-web/api.md) — often used inside cards
- [Dialog](../dialog/react-web/api.md) — used in DialogActions
