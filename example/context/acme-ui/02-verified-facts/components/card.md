# Card

## Import
```tsx
import { Card } from '@acme/ui/components/card'
```

## TypeScript Interface
```tsx
export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  /** Card padding */
  padding?: 'none' | 'sm' | 'md' | 'lg';
  /** Visual variant */
  variant?: 'default' | 'outlined' | 'elevated';
}
```

## Named Exports
| Export | Kind |
|---|---|
| Card | Component |
| CardProps | Type |

## Props (explicit)
| Prop | Type | Default | Required | Description |
|---|---|---|---|---|
| padding | `'none' \| 'sm' \| 'md' \| 'lg'` | `'md'` | No | Card padding |
| variant | `'default' \| 'outlined' \| 'elevated'` | `'default'` | No | Visual variant |

## Inherited Props
Also accepts all standard HTML div attributes via `React.HTMLAttributes<HTMLDivElement>`.

## Tokens
- `--acme-gray-100`: Default card background
- `--acme-gray-300`: Outlined card border
- `--acme-shadow-md`: Elevated card shadow
- `--acme-radius-lg`: Card border radius

## Uncertainties
- None
