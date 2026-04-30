# Button — Common Patterns

## Loading state

```tsx
'use client'

import { useState } from 'react'
import { Button } from '@acme/ui/components/button'

export default function LoadingButton() {
  const [loading, setLoading] = useState(false)

  async function handleSubmit() {
    setLoading(true)
    await fetch('/api/submit', { method: 'POST' })
    setLoading(false)
  }

  return (
    <Button loading={loading} onClick={handleSubmit}>
      Submit
    </Button>
  )
}
```

## With prefix and suffix icons

```tsx
'use client'

import { Button } from '@acme/ui/components/button'

export default function ButtonWithIcons() {
  return (
    <div className="flex gap-acme-2">
      <Button prefix={<span>+</span>}>Add item</Button>
      <Button suffix={<span>&rarr;</span>}>Next</Button>
    </div>
  )
}
```

## Destructive action with confirmation

```tsx
'use client'

import { Button } from '@acme/ui/components/button'

export default function DestructiveButton() {
  return (
    <Button
      variant="destructive"
      onClick={() => {
        if (confirm('Are you sure?')) {
          // delete action
        }
      }}
    >
      Delete project
    </Button>
  )
}
```
