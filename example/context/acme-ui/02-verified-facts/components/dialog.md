# Dialog

## Import
```tsx
import { Dialog, DialogHeader, DialogBody, DialogActions } from '@acme/ui/components/dialog'
```

## TypeScript Interface
```tsx
export interface DialogProps {
  /** Whether the dialog is open */
  open: boolean;
  /** Callback when dialog should close */
  onOpenChange: (open: boolean) => void;
  /** Dialog content */
  children: React.ReactNode;
}

export interface DialogHeaderProps {
  /** Header title */
  title: string;
  /** Optional description below title */
  description?: string;
}

export interface DialogBodyProps {
  children: React.ReactNode;
}

export interface DialogActionsProps {
  children: React.ReactNode;
}
```

## Named Exports
| Export | Kind |
|---|---|
| Dialog | Component |
| DialogHeader | Component |
| DialogBody | Component |
| DialogActions | Component |
| DialogProps | Type |
| DialogHeaderProps | Type |
| DialogBodyProps | Type |
| DialogActionsProps | Type |

## Props (explicit)
| Prop | Type | Default | Required | Description |
|---|---|---|---|---|
| open | `boolean` | — | Yes | Whether the dialog is open |
| onOpenChange | `(open: boolean) => void` | — | Yes | Callback when dialog should close |

## Compound Components
| Sub-component | Purpose | Required |
|---|---|---|
| DialogHeader | Title and description | Yes |
| DialogBody | Main content area | Yes |
| DialogActions | Action buttons | No |

## Nesting Pattern
```tsx
<Dialog open={open} onOpenChange={setOpen}>
  <DialogHeader title="Title" description="Optional description" />
  <DialogBody>
    {/* Content */}
  </DialogBody>
  <DialogActions>
    <Button variant="ghost" onClick={() => setOpen(false)}>Cancel</Button>
    <Button>Confirm</Button>
  </DialogActions>
</Dialog>
```

## Tokens
- `--acme-shadow-lg`: Dialog shadow
- `--acme-radius-lg`: Dialog border radius
- `--acme-gray-900`: Overlay backdrop color (with opacity)

## Uncertainties
- None
