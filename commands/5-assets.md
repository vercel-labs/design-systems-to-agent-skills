# Stage 5: Asset Catalog Generation

## Required Capabilities

- File read/write
- Shell command execution (bash scripts, git)
- User interaction (confirming asset source locations)

## Objective

Run Stage 5 of the design system skill generation pipeline: asset catalog generation.

Produce exhaustive asset catalogs (icons, logos, illustrations, etc.) for every asset system identified in Stage 1. Asset catalogs are lookup tables — every name, every import path — that eliminate name hallucination by giving agents a complete enumeration to search instead of guessing.

This stage combines extraction and generation in one step because:
- Asset extraction is mechanical (read name arrays or scan directories) — no AI interpretation needed
- Catalog format is standardized — no PRD needed
- Output is tables not prose — minimal hallucination risk

The pipeline stages:
1. **Interview** — Scope decisions through conversation.
2. **Extract** — Extract verified facts from source code.
3. **PRD** — Generate a closed PRD with zero open questions.
4. **Generate** — Parallel skill file generation.
5. **Assets** — YOU ARE HERE. Exhaustive asset catalog generation.
6. **Verify** — Programmatic verification (no agent session needed).

## Process

### Step 1: Load inputs

Read the following files from disk:

1. **`context/{ds}/01-decisions.md`** — Check the Asset Systems section for:
   - Which asset types are in scope (icons, logos, illustrations, pixels, etc.)
   - Source package names and paths for each asset system
   - Whether assets live in the main package or a separate assets package

2. **`context/{ds}/02-verified-facts/`** — Check if any asset data was already extracted in Stage 2:
   - `assets/icons.md`, `assets/logos.md`, etc.
   - If these exist, they contain partial or complete inventories to build on

3. **Existing skill output** — Check `skills/{ds}/` for:
   - `SKILL.md` — routing matrix to update
   - `references/{ds}/v{N}/` — versioned namespace to place catalogs in

If decisions don't include an Asset Systems section, ask the user:

> Does this design system include icon, logo, illustration, or other asset systems? If so, what are the package names and where is the source code?

### Step 2: Discover asset sources

For each asset type identified in decisions, locate the source data. Asset names in design systems are typically found in one of these locations:

1. **Auto-generated name arrays** — Files like `icon-names.ts`, `logo-names.ts`, `pixel-names.ts` in a `__generated__/` or `src/` directory. These contain TypeScript arrays of all asset names.

2. **Barrel/index files** — Files that re-export all assets: `src/icons/index.ts`, `src/logos/index.ts`. Each export line contains a name.

3. **Asset directories** — Directories containing one file per asset: `src/icons/named/arrow-up.tsx`. The directory listing IS the inventory.

4. **Package exports map** — `package.json` `exports` field with per-asset entries.

Search strategy per asset type:

```bash
# Look for generated name files
find {source_path}/src -name "*-names.ts" -o -name "*-names.js" 2>/dev/null

# Look for barrel files in asset directories
find {source_path}/src -path "*/icons/index.ts" -o -path "*/logos/index.ts" 2>/dev/null

# Look for asset directories
ls {source_path}/src/icons/named/ 2>/dev/null
ls {source_path}/src/icons/ 2>/dev/null
```

If the source location isn't obvious, ask the user:

> I can't find the {type} name list in the source. Where should I look? Common locations:
> - `src/__generated__/{type}-names.ts`
> - `src/{type}/index.ts`
> - `src/{type}/named/` (directory of individual files)

### Step 3: Extract asset inventories

For each asset type, produce a verified-facts file. Use the companion extraction script for mechanical extraction from TypeScript name arrays:

```bash
./scripts/extract-asset-names.sh \
  --src {path_to_names_file} \
  --type {icons|logos|pixels|illustrations} \
  --package "{package_name}" \
  --prefix "{asset_prefix}" \
  --export-style {named|default}
```

The script reads the TypeScript array and outputs markdown table rows to stdout. Capture its output and write to:

- `context/{ds}/02-verified-facts/assets/icons.md`
- `context/{ds}/02-verified-facts/assets/logos.md`
- etc.

Each verified-facts file should contain:

```markdown
# {Type} — Verified Asset Names

Source: `{path_to_source_file}`
Package: `{package_name}`
Count: {N}
Extracted: {date}

## Names

| Name | Component | Import Path |
|---|---|---|
{rows from extraction script}
```

If the extraction script can't handle the source format (non-standard array structure, barrel file exports instead of name arrays), extract manually by reading the source file and listing entries. The script handles the common case; the agent handles exceptions.

**For multi-package design systems:** Run extraction separately for each package. Create separate verified-facts directories:

```
02-verified-facts/
├── assets/
│   ├── icons.md          # From main package (if applicable)
│   └── ...
├── {ds}-assets/
│   ├── icons.md          # From assets package
│   ├── logos.md
│   └── pixels.md
```

### Step 4: Generate catalog files

For each asset type, produce a catalog file at the appropriate location in the skill output:

**Single-package:** `skills/{ds}/references/{ds}/v{N}/assets/{type}/{platform}/api.md`

**Multi-package:** Separate namespaces per package:
```
skills/{ds}/references/{ds}/v{N}/assets/{type}/{platform}/api.md
skills/{ds}/references/{ds}-assets/v{N}/assets/{type}/{platform}/api.md
```

Each catalog file follows this format:

```markdown
# {Type} Catalog — {DS Name}

{count} {type}s. Import pattern: `import { ComponentName } from '{package}/{type}/component-name'`

> Load this file whenever you need to use a {type} from {DS Name}. Do NOT guess {type} names — pick from the table below.

## Import

```tsx
// Direct import (preferred)
import { ArrowUp } from '{package}/icons/arrow-up'

// Barrel import (if supported)
import { ArrowUp } from '{package}/icons'
```

## Props

| Prop | Type | Default | Description |
|---|---|---|---|
| size | number | 24 | Width and height in pixels |
| color | string | 'currentColor' | Icon color (inherits from parent by default) |
| className | string | — | Additional CSS classes |
| ...rest | SVGProps | — | Passed to underlying SVG element |

(Adjust props based on the actual TypeScript interface from source. Read one asset component file to extract the shared props interface.)

## All {Type}s ({count})

| Name | Component | Import Path |
|---|---|---|
| arrow-up | ArrowUp | `{package}/icons/arrow-up` |
| check-circle | CheckCircle | `{package}/icons/check-circle` |
...

(Complete table from verified-facts extraction.)

## Anti-patterns

- **DON'T** guess icon names — use this catalog as a lookup table
- **DON'T** import from barrel `{package}/icons` if the DS recommends direct imports — use `{package}/icons/{name}`
- **DON'T** hardcode SVG paths — use the component import
- **DO** search this file for the closest matching name if unsure
```

For asset types with variants (e.g., logos with light/dark/monochrome variants), add a Variants column:

```markdown
| Name | Component | Variants | Import Path |
|---|---|---|---|
| vercel | VercelLogo | light, dark, mono | `{package}/logos/vercel` |
```

### Step 5: Update routing

**SKILL.md routing matrix** — Add entries for each asset catalog:

```markdown
| Use an icon | `{ds}/v{N}/assets/icons/{platform}/api.md` |
| Use a logo | `{ds}/v{N}/assets/logos/{platform}/api.md` |
```

For multi-package systems, add the assets package routing:

```markdown
| Use an icon ({ds}-assets) | `{ds}-assets/v{N}/assets/icons/{platform}/api.md` |
```

**index.md navigation** — Add an Assets section linking to the catalogs:

```markdown
## Assets

| Type | Count | Reference |
|---|---|---|
| Icons | {N} | [Icon Catalog](assets/icons/{platform}/api.md) |
| Logos | {N} | [Logo Catalog](assets/logos/{platform}/api.md) |
```

For multi-package systems, create an `index.md` in the assets package namespace:

```markdown
# {DS}-Assets — v{N}

Assets package for {DS Name}. Contains icons, logos, and other visual assets.

## Catalogs

| Type | Count | Reference |
|---|---|---|
| Icons | {N} | [Icon Catalog](assets/icons/{platform}/api.md) |
| Logos | {N} | [Logo Catalog](assets/logos/{platform}/api.md) |
```

### Step 6: Commit

```bash
git add context/{ds}/02-verified-facts/assets/
git add skills/{ds}/references/*/v*/assets/
git add skills/{ds}/SKILL.md
git add skills/{ds}/references/*/v*/index.md
git commit -m "{DS} Stage 5: asset catalogs ({N} icons, {M} logos, ...)"
```

For multi-package:

```bash
git add context/{ds}/02-verified-facts/{ds}-assets/
git add skills/{ds}/references/{ds}-assets/
git commit -m "{DS} Stage 5: asset catalogs ({summary})"
```

## Rules

- **Exhaustive enumeration.** Every asset name must appear in the catalog. A missing name means an agent will guess it. Verify the catalog count matches the source count.
- **Script-first extraction.** Use `scripts/extract-asset-names.sh` for the mechanical part. Only read source files manually if the script can't handle the format.
- **Verify counts.** After extraction, compare: `wc -l` on the catalog table vs the known asset count from the source name array. They must match.
- **Props from source, not memory.** Read one actual asset component file to extract the shared props interface. Don't generate props from training data.
- **Don't modify Stages 1–4 output.** Asset catalogs are additive — they go in `assets/` directories, not in `components/` or `guides/`.
- **Multi-package awareness.** If decisions mention multiple packages with assets, create separate namespaces. Don't merge different packages into one catalog.
- **Write to disk immediately.** Write verified-facts files after extraction, catalog files after formatting. If the session crashes, completed catalogs are preserved.
- **Do NOT proceed to Stage 6.** The user must explicitly run `verify-skills.sh`.
