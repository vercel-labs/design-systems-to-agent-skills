# Stage 2: Fact Extraction

## Required Capabilities

- File read/write
- Shell command execution (git, file existence checks)
- Sub-agent spawning (recommended for parallelism; can run serially without it)

## Objective

Run Stage 2 of the design system skill generation pipeline: fact extraction.

Read the decisions from Stage 1, then systematically extract verified facts from source code for every in-scope component. Write per-component fact files and summary files to disk.

**Critical:** Only write facts verifiable from source code. Do not infer, guess, or generate from training data. If a type, default, or path is unclear, flag it as [UNVERIFIED].

## Process

### Step 1: Load decisions

Read `context/{ds}/01-decisions.md` where `{ds}` is determined by scanning the `context/` directory for available design systems.

Extract from decisions:
- Source repo path
- In-scope component list
- Component categories
- Styling approach (Tailwind, SCSS, CSS Modules, etc.)
- Compound component pattern (dot-notation, separate exports, etc.)
- Token format (CSS custom properties, SCSS variables, etc.)

If `01-decisions.md` doesn't exist or Status is not "Complete", tell the user:
> Stage 1 decisions not found. Run Stage 1 (interview) first.

### Step 2: Prepare output structure

Ensure these directories exist:
```
context/{ds}/02-verified-facts/
├── components/         (one file per in-scope component)
├── imports.md          (all validated import paths)
├── tokens.md           (design token catalog)
├── compound-components.md  (nesting rules for compound components)
└── styles.md           (style import paths, if applicable)
```

### Step 3: Validate source access

Before dispatching sub-agents, verify:
1. The source repo path exists and is readable
2. Component source files can be found (scan for directories matching component names)
3. `package.json` is readable (for import path validation)

Report the component-to-source-directory mapping. If any components can't be located, flag them and ask the user for guidance.

### Step 4: Extract facts using sub-agents

Process in-scope components in **batches of 8**.

For each batch, dispatch parallel sub-agents (background mode if available).

**Context management:** Do NOT read sub-agent transcripts back into the orchestrator. Each sub-agent's full extraction transcript (source file reads, type parsing, etc.) is large — reading 8 transcripts back bloats context usage significantly. Instead:
1. Launch all sub-agents in the batch
2. Poll for file existence on disk: check that `context/{ds}/02-verified-facts/components/{name}.md` exists and is non-empty for each component in the batch
3. Use a simple bash loop with `sleep` to wait, e.g.: `while [ ! -f "path/to/file.md" ]; do sleep 5; done`
4. Once all files exist, proceed to commit — do not read the sub-agent output

The sub-agents write directly to disk. The orchestrator only needs to know the files were written, not what the sub-agents did internally.

Each sub-agent receives:

#### Sub-agent prompt template

```
You are extracting verified facts for the {component_name} component of the {ds_name} design system.

Source directory: {component_source_path}

EXTRACT THE FOLLOWING (from source code ONLY):

1. **Raw TypeScript interface**: Extract the complete TypeScript interface/type definition text as-is from source code, including any JSDoc comments. Copy the raw text verbatim — do not paraphrase or reformat.

2. **Props interface**: Read the TypeScript interface/type definition. For each prop:
   - Name
   - Type (exact TypeScript type)
   - Default value — NOT in the type definition. Look in:
     (a) Destructuring in the component function parameters: `const { size = 'medium' } = props`
     (b) `defaultProps` static property
     (c) Conditional/fallback logic in the component body
     Read the function body, not just the type file.
   - Required or optional (? in interface)
   - Brief description (from JSDoc comments if available)

   IMPORTANT — Separate props into two groups:
   - **Explicit props**: Props defined in THIS component's own interface/type
   - **Inherited props**: Props from the HTML element or parent type (via extends, Omit, Pick, etc.)
   Only list explicit props in the main table. Note inherited props as:
   "Also accepts all standard HTML {element} attributes via {ParentType}."

3. **Type restrictions and exclusions**: For union types, document BOTH:
   - What values ARE allowed
   - What values are EXCLUDED (especially `never` type patterns that restrict a parent type)

4. **Import path**: How should this component be imported?
   - Check package.json "exports" field first
   - If no exports field, check the barrel file (index.ts/index.tsx)
   - Validate the actual path exists
   - Format: `import { ComponentName } from '{package}/{path}'`

5. **Named exports inventory**: List ALL named exports from the component module — not just the main component. Include:
   - Components (main + sub-components)
   - Types/interfaces
   - Hooks
   - Utility functions
   Scan the barrel file (index.ts/index.tsx) and the component source for all `export` statements.

6. **Compound components** (if applicable):
   - List all sub-components exported
   - Document the nesting pattern (which sub-components go inside which)
   - Note any required vs optional sub-components

7. **Responsive patterns**: If any prop accepts BOTH a single value and a responsive object, document both forms.

8. **Design tokens**: List any CSS custom properties, SCSS variables, or theme tokens this component references.

9. **Style imports**: Any separate style file that needs importing.

10. **Data attributes**: Scan the component's rendered output (JSX return statements) for any `data-*` attributes set on elements.

11. **Behavioral notes**: Read the component implementation (not just types). Look for:
    - Default values with UX implications (auto-casing, auto-focus, auto-scroll)
    - Internal transforms applied to props (title-casing labels, formatting numbers)
    - Context consumption (what contexts does the component read? what changes behavior?)
    - Conditional rendering (when does the component show/hide sub-elements?)
    - Event handler remapping (e.g., onClick → PressEvent instead of MouseEvent)
    Only note behaviors that have UX implications an agent consumer should know about.
    If no notable behavioral patterns, write "None observed."

WRITE your findings to: context/{ds}/02-verified-facts/components/{component_name}.md

Use this format:
---
# {ComponentName}

## Import
\`\`\`tsx
import { ComponentName } from '{validated_import_path}'
\`\`\`

## TypeScript Interface
\`\`\`tsx
{raw TypeScript interface/type definition text, verbatim from source}
\`\`\`

## Named Exports
| Export | Kind |
|---|---|
| ComponentName | Component |
| ComponentNameProps | Type |
| useComponentHook | Hook |
| helperFunction | Utility |

## Props (explicit)
| Prop | Type | Default | Required | Description |
|---|---|---|---|---|
| propName | `type` | `default` | Yes/No | description |

## Inherited Props
Also accepts all standard HTML {element} attributes via `{ParentType}`.

## Type Restrictions
(if any union types have excluded values)
| Prop | Excluded Values | Mechanism |
|---|---|---|
| variant | `'success' \| 'ghost'` | `never` type restriction |

## Responsive Props
(if any props accept responsive objects)
| Prop | Single Value | Responsive Object | Breakpoint Keys |
|---|---|---|---|
| size | `'small'` | `{ xs: 'small', md: 'large' }` | xs, sm, md, lg, xl |

## Compound Components
(if applicable)
| Sub-component | Purpose | Required |
|---|---|---|
| ComponentName.Sub | description | Yes/No |

## Nesting Pattern
(if compound)
\`\`\`tsx
<Component>
  <Component.SubA>...</Component.SubA>
  <Component.SubB>...</Component.SubB>
</Component>
\`\`\`

## Tokens
- `--token-name`: description

## Style Imports
(if applicable)
\`\`\`tsx
import '{style_import_path}'
\`\`\`

## Data Attributes
(if any data-* attributes found in rendered output)
| Attribute | Element | Dynamic Values |
|---|---|---|
| `data-ds-component` | root element | — |

## Behavioral Notes
- {behavior}: {description and implication}

## Uncertainties
- [List anything that couldn't be verified from source]
---

RULES:
- Read the actual source files. Do NOT generate from memory.
- If you can't find a prop's default value, write "unknown" — not a guess.
- If the import path is unclear, check the package.json exports map.
- Flag anything uncertain with [UNVERIFIED].
```

#### After each batch

1. Verify all sub-agents wrote their files by checking file existence on disk:
   ```bash
   for comp in {component1} {component2} ...; do
     [ -s "context/{ds}/02-verified-facts/components/${comp}.md" ] && echo "✓ $comp" || echo "✗ $comp MISSING"
   done
   ```
   If any file is missing after a reasonable wait, note it in the report and move on.

2. **Commit the batch immediately.** This is mandatory — not optional.
   ```bash
   git add context/{ds}/02-verified-facts/components/{component1}.md context/{ds}/02-verified-facts/components/{component2}.md ...
   git commit -m "{DS} extract: batch N ({component1}, {component2}, ...)"
   ```
   Without intermediate commits, large extractions (50+ components) bloat the working tree and lose all progress on session failure.

3. Report to user: "Batch N complete: {list of components} — committed. {remaining} components pending."

4. Continue to next batch.

### Step 5: Compile summary files

After all components are extracted:

#### imports.md
Read all per-component files and compile a single imports reference:

```markdown
# {DS Name} — Validated Import Paths

| Component | Import Statement |
|---|---|
| ComponentA | `import { ComponentA } from '{package}/path'` |
| ComponentB | `import { ComponentB } from '{package}/path'` |
```

#### tokens.md
Merge all tokens referenced across components into a single catalog, organized by category (color, spacing, typography, etc.).

#### compound-components.md
List all compound components with their sub-component structures and nesting rules.

#### styles.md (if applicable)
List all style import paths.

### Step 6: Commit summary files and report

```bash
git add context/{ds}/02-verified-facts/imports.md context/{ds}/02-verified-facts/tokens.md context/{ds}/02-verified-facts/compound-components.md context/{ds}/02-verified-facts/styles.md
git commit -m "{DS} extract: summary files (imports, tokens, compound-components, styles)"
```

Print a summary:
```
Stage 2 complete.
- Components extracted: N
- Fact files written: M (committed in K batches)
- Compound components found: K
- Tokens cataloged: L
- Uncertainties flagged: X
```

Check for any components with [UNVERIFIED] or [SOURCE NOT FOUND] flags. Report these to the user and ask if they should be resolved before continuing.

Suggest:
> All extraction output has been committed incrementally. Run Stage 3 (PRD) to continue.

## Rules

- **Source code only.** Every fact must come from reading actual files. Never generate from training data.
- **[UNVERIFIED] is better than wrong.** Flag uncertainties explicitly.
- **Batch size 8.** Don't overload the context with too many concurrent sub-agents.
- **Per-component files.** Each component gets its own fact file. This survives session boundaries and enables selective re-extraction.
- **Commit after every batch.** Never let more than one batch of output sit uncommitted.
- **Ignore stale notifications.** If a background sub-agent completion notification arrives after you've already verified the file on disk, ignore it silently. Do not respond, acknowledge, or log it. Each acknowledgment wastes context.
- **Do NOT generate skill content.** This stage extracts facts. Stage 4 generates skills.
- **Do NOT proceed to Stage 3 automatically.** The user invokes Stage 3 separately.
