# Dialog — Basic Usage

```tsx
'use client'

import { useState } from 'react'
import { Dialog, DialogHeader, DialogBody, DialogActions } from '@acme/ui/components/dialog'
import { Button } from '@acme/ui/components/button'

export default function BasicDialog() {
  const [open, setOpen] = useState(false)

  return (
    <>
      <Button onClick={() => setOpen(true)}>Open dialog</Button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogHeader title="Welcome" description="This is a basic dialog." />
        <DialogBody>
          <p>Dialog content goes here.</p>
        </DialogBody>
        <DialogActions>
          <Button variant="ghost" onClick={() => setOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>
    </>
  )
}
```
