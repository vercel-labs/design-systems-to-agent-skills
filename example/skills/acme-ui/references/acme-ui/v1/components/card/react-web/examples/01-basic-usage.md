# Card — Basic Usage

```tsx
'use client'

import { Card } from '@acme/ui/components/card'

export default function BasicCard() {
  return (
    <Card>
      <h3>Card title</h3>
      <p>Card content goes here.</p>
    </Card>
  )
}
```

## Variants

```tsx
'use client'

import { Card } from '@acme/ui/components/card'

export default function CardVariants() {
  return (
    <div className="flex flex-col gap-acme-4">
      <Card variant="default">Default card</Card>
      <Card variant="outlined">Outlined card</Card>
      <Card variant="elevated">Elevated card</Card>
    </div>
  )
}
```

## With padding options

```tsx
'use client'

import { Card } from '@acme/ui/components/card'

export default function CardPadding() {
  return (
    <div className="flex flex-col gap-acme-4">
      <Card padding="none">No padding</Card>
      <Card padding="sm">Small padding</Card>
      <Card padding="md">Medium padding (default)</Card>
      <Card padding="lg">Large padding</Card>
    </div>
  )
}
```

## Card with button

```tsx
'use client'

import { Card } from '@acme/ui/components/card'
import { Button } from '@acme/ui/components/button'

export default function CardWithAction() {
  return (
    <Card variant="outlined">
      <h3>Confirm action</h3>
      <p>Are you sure you want to proceed?</p>
      <div className="mt-acme-4 flex justify-end gap-acme-2">
        <Button variant="ghost">Cancel</Button>
        <Button>Confirm</Button>
      </div>
    </Card>
  )
}
```
