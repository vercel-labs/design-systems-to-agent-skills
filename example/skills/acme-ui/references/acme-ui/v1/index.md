# Acme UI Reference Index

## What Do You Need?

| Task | File |
|---|---|
| Use a specific component | `components/{name}/react-web/api.md` |
| See usage examples | `components/{name}/react-web/examples/` |
| Find the right import path | [guides/imports.md](guides/imports.md) |
| Use design tokens | [guides/tokens.md](guides/tokens.md) |

## Components

| Component | Category | Compound | API | Examples |
|---|---|---|---|---|
| Button | Actions | No | [api.md](components/button/react-web/api.md) | [examples/](components/button/react-web/examples/) |
| Card | Layout | No | [api.md](components/card/react-web/api.md) | [examples/](components/card/react-web/examples/) |
| Dialog | Overlay | Yes | [api.md](components/dialog/react-web/api.md) | [examples/](components/dialog/react-web/examples/) |

## Top Mistakes

| Mistake | Fix |
|---|---|
| Using raw Tailwind colors (`bg-blue-500`) | Use token-mapped utilities (`bg-acme-blue-600`) |
| Importing from barrel `@acme/ui` | Use subpath imports: `@acme/ui/components/button` |
| Missing `@acme/ui/styles.css` import | Add to root layout |
| Dialog without required sub-components | Include DialogHeader and DialogBody |
