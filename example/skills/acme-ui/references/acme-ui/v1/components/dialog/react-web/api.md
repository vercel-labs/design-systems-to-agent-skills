# Dialog

Modal dialog with header, body, and actions.

## Import

```tsx
import { Dialog, DialogHeader, DialogBody, DialogActions } from '@acme/ui/components/dialog'
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

## Props

### Dialog

| Prop | Type | Default | Required | Description |
|---|---|---|---|---|
| `open` | `boolean` | — | Yes | Whether the dialog is open |
| `onOpenChange` | `(open: boolean) => void` | — | Yes | Callback when dialog should close |

### DialogHeader

| Prop | Type | Default | Required | Description |
|---|---|---|---|---|
| `title` | `string` | — | Yes | Header title |
| `description` | `string` | — | No | Description below title |

### DialogBody

| Prop | Type | Default | Required | Description |
|---|---|---|---|---|
| `children` | `React.ReactNode` | — | Yes | Body content |

### DialogActions

| Prop | Type | Default | Required | Description |
|---|---|---|---|---|
| `children` | `React.ReactNode` | — | Yes | Action buttons |

## Compound Components

| Sub-component | Purpose | Required |
|---|---|---|
| DialogHeader | Title and description | Yes |
| DialogBody | Main content area | Yes |
| DialogActions | Action buttons (right-aligned) | No |

### Nesting Pattern

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

## Anti-patterns

### Wrong: missing required sub-components
```tsx
// WRONG — DialogHeader and DialogBody are required
<Dialog open={open} onOpenChange={setOpen}>
  <p>Just some text</p>
</Dialog>
```

### Correct: use required sub-components
```tsx
// CORRECT
<Dialog open={open} onOpenChange={setOpen}>
  <DialogHeader title="Confirmation" />
  <DialogBody>
    <p>Are you sure?</p>
  </DialogBody>
</Dialog>
```

### Wrong: controlling open state without onOpenChange
```tsx
// WRONG — dialog can't close via escape key or backdrop click
<Dialog open={true} onOpenChange={() => {}}>
```

### Correct: provide a real onOpenChange handler
```tsx
// CORRECT
const [open, setOpen] = useState(false)
<Dialog open={open} onOpenChange={setOpen}>
```

## Related

- [Button](../button/react-web/api.md) — used in DialogActions
- [Card](../card/react-web/api.md) — for non-modal content containers
