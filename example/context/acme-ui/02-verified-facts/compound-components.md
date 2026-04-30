# Acme UI — Compound Components

## Dialog

**Exports:** Dialog, DialogHeader, DialogBody, DialogActions
**Pattern:** Separate named exports from shared barrel file

### Required structure
```tsx
<Dialog open={open} onOpenChange={setOpen}>
  <DialogHeader title="..." />        {/* Required */}
  <DialogBody>...</DialogBody>         {/* Required */}
  <DialogActions>...</DialogActions>   {/* Optional */}
</Dialog>
```

### Sub-components
| Sub-component | Required | Props |
|---|---|---|
| DialogHeader | Yes | `title: string`, `description?: string` |
| DialogBody | Yes | `children: ReactNode` |
| DialogActions | No | `children: ReactNode` |

### Notes
- DialogHeader and DialogBody must be direct children of Dialog
- DialogActions renders buttons in a right-aligned flex container
- Dialog manages focus trap and escape key handling internally

## Non-compound components
- **Button** — standalone, no sub-components
- **Card** — standalone, accepts children directly
