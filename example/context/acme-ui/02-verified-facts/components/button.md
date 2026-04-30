# Button

## Import
```tsx
import { Button } from '@acme/ui/components/button'
```

## TypeScript Interface
```tsx
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  /** Visual style variant */
  variant?: 'primary' | 'secondary' | 'destructive' | 'ghost';
  /** Button size */
  size?: 'sm' | 'md' | 'lg';
  /** Show loading spinner */
  loading?: boolean;
  /** Element before children */
  prefix?: React.ReactNode;
  /** Element after children */
  suffix?: React.ReactNode;
}
```

## Named Exports
| Export | Kind |
|---|---|
| Button | Component |
| ButtonProps | Type |

## Props (explicit)
| Prop | Type | Default | Required | Description |
|---|---|---|---|---|
| variant | `'primary' \| 'secondary' \| 'destructive' \| 'ghost'` | `'primary'` | No | Visual style variant |
| size | `'sm' \| 'md' \| 'lg'` | `'md'` | No | Button size |
| loading | `boolean` | `false` | No | Show loading spinner |
| prefix | `React.ReactNode` | — | No | Element before children |
| suffix | `React.ReactNode` | — | No | Element after children |

## Inherited Props
Also accepts all standard HTML button attributes via `React.ButtonHTMLAttributes<HTMLButtonElement>`.

## Tokens
- `--acme-blue-600`: Primary button background
- `--acme-gray-200`: Secondary button background
- `--acme-red-500`: Destructive button background
- `--acme-radius-md`: Button border radius

## Uncertainties
- None
