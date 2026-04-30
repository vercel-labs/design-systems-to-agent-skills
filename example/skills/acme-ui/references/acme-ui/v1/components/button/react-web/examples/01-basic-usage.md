# Button — Basic Usage

```tsx
'use client'

import { Button } from '@acme/ui/components/button'

export default function BasicButton() {
  return <Button>Click me</Button>
}
```

## With variant

```tsx
'use client'

import { Button } from '@acme/ui/components/button'

export default function ButtonVariants() {
  return (
    <div className="flex gap-acme-2">
      <Button variant="primary">Primary</Button>
      <Button variant="secondary">Secondary</Button>
      <Button variant="destructive">Delete</Button>
      <Button variant="ghost">Cancel</Button>
    </div>
  )
}
```

## With size

```tsx
'use client'

import { Button } from '@acme/ui/components/button'

export default function ButtonSizes() {
  return (
    <div className="flex items-center gap-acme-2">
      <Button size="sm">Small</Button>
      <Button size="md">Medium</Button>
      <Button size="lg">Large</Button>
    </div>
  )
}
```
