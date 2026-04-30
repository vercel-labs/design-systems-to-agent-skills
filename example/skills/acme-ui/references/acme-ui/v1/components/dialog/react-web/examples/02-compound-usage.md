# Dialog — Compound Usage

## Confirmation dialog

```tsx
'use client'

import { useState } from 'react'
import { Dialog, DialogHeader, DialogBody, DialogActions } from '@acme/ui/components/dialog'
import { Button } from '@acme/ui/components/button'

export default function ConfirmationDialog() {
  const [open, setOpen] = useState(false)
  const [loading, setLoading] = useState(false)

  async function handleConfirm() {
    setLoading(true)
    await fetch('/api/delete', { method: 'DELETE' })
    setLoading(false)
    setOpen(false)
  }

  return (
    <>
      <Button variant="destructive" onClick={() => setOpen(true)}>
        Delete project
      </Button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogHeader
          title="Delete project"
          description="This action cannot be undone."
        />
        <DialogBody>
          <p>All project data will be permanently removed.</p>
        </DialogBody>
        <DialogActions>
          <Button variant="ghost" onClick={() => setOpen(false)}>
            Cancel
          </Button>
          <Button variant="destructive" loading={loading} onClick={handleConfirm}>
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </>
  )
}
```

## Dialog without actions

```tsx
'use client'

import { useState } from 'react'
import { Dialog, DialogHeader, DialogBody } from '@acme/ui/components/dialog'
import { Button } from '@acme/ui/components/button'

export default function InfoDialog() {
  const [open, setOpen] = useState(false)

  return (
    <>
      <Button variant="secondary" onClick={() => setOpen(true)}>
        View details
      </Button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogHeader title="Project details" />
        <DialogBody>
          <dl className="flex flex-col gap-acme-2">
            <div>
              <dt className="text-acme-gray-500">Name</dt>
              <dd>My Project</dd>
            </div>
            <div>
              <dt className="text-acme-gray-500">Created</dt>
              <dd>April 2026</dd>
            </div>
          </dl>
        </DialogBody>
      </Dialog>
    </>
  )
}
```
