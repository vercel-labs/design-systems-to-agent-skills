# Stage-by-Stage Reference

## Stage 1: Discovery Interview

**Command:** `commands/1-interview.md`
**Input:** Source repo path
**Output:** `context/{ds}/01-decisions.md`
**Context usage:** ~15%

### What it does

The agent interviews the user about every scoping decision for the design system skill generation. Questions are asked one at a time, with the agent reading source files to make informed recommendations rather than asking the user to provide information the codebase already contains.

### What it reads

- `README.md` or equivalent high-level docs
- `package.json` (name, version, dependencies)
- Component inventory file (if available)
- `instructions/` directory (if present)
- Config files (to detect styling approach, framework)

It does NOT read individual component source files — that is Stage 2's job.

### What it writes

- `context/{ds}/01-decisions.md` — updated after every confirmed answer

### Decision categories

1. **Identity** — DS name, package, version, source path
2. **Scope** — in-scope components, exclusions
3. **Categories** — component groupings (Form, Layout, Feedback, etc.)
4. **Technical** — styling approach, consumer styling pattern, compound components, tokens, provider setup
5. **Output structure** — which guides, component doc structure, anti-patterns
6. **Environment** — public/private registry, framework requirements

### When to start a fresh session

Stage 1 is lightweight. It can share a session with Stages 2-3 if the design system is small (<30 components). For larger systems, a fresh session for Stage 2 is recommended.

### Common issues

- **Vague user answers:** The command instructs the agent to challenge vague responses. If the agent accepts "whatever" as a decision, re-run with the instruction to be more opinionated.
- **Missing component inventory:** If the source has no inventory file, the agent scans component directories. Verify the scan is complete.
- **Large component count:** The pipeline handles any number of components — the loop script spawns a fresh session per batch, and multi-file PRDs keep context usage low.

---

## Stage 2: Fact Extraction

**Command:** `commands/2-extract.md`
**Input:** `01-decisions.md` + source repo
**Output:** `context/{ds}/02-verified-facts/`
**Context usage:** ~25%

### What it does

Dispatches sub-agents in batches of 8 to read component source code and extract verified facts: TypeScript interfaces, props with defaults, import paths, compound component structures, design tokens, and named exports.

### What it reads

- `context/{ds}/01-decisions.md`
- Component source files (TypeScript interfaces, function bodies, barrel files)
- `package.json` exports map

### What it writes

- `context/{ds}/02-verified-facts/components/{name}.md` — one file per component
- `context/{ds}/02-verified-facts/imports.md` — compiled import reference
- `context/{ds}/02-verified-facts/tokens.md` — token catalog
- `context/{ds}/02-verified-facts/compound-components.md` — nesting rules
- `context/{ds}/02-verified-facts/styles.md` — style import paths (if applicable)

### Context management

Each sub-agent reads source files and writes findings to disk. The orchestrator checks for file existence (not content) and commits each batch. This prevents sub-agent transcripts from bloating the orchestrator's context.

### When to start a fresh session

Stage 2 can share a session with Stage 1 if the interview was short. For large design systems (>50 components), start fresh.

### Common issues

- **[UNVERIFIED] flags:** If many props are flagged, the source code structure may not match what the sub-agent expects. Check a few component files manually and adjust the sub-agent prompt.
- **Missing component directories:** If the component-to-source mapping fails, the agent asks for guidance. Provide the correct path pattern.
- **Import path validation:** The sub-agent checks `package.json` exports. If the package uses a non-standard export pattern, imports may need manual verification.

---

## Stage 3: Closed PRD

**Command:** `commands/3-prd.md`
**Input:** `01-decisions.md` + `02-verified-facts/` (summary files only)
**Output:** `context/{ds}/03-closed-prd/` (directory of 5 files)
**Context usage:** ~10% incremental

### What it does

Synthesizes decisions and verified facts into a PRD that specifies every file to generate, its exact content structure, the wave/batch plan, success criteria, and the sub-agent prompt template. The PRD must have zero open questions.

### What it reads

- `context/{ds}/01-decisions.md`
- `context/{ds}/02-verified-facts/imports.md`
- `context/{ds}/02-verified-facts/tokens.md`
- `context/{ds}/02-verified-facts/compound-components.md`
- File list from `context/{ds}/02-verified-facts/components/` (count only, not contents)

It does NOT read individual component fact files — the summaries contain everything needed.

### What it writes

- `context/{ds}/03-closed-prd/` directory with 5 files:
  1. `01-file-manifest.md` — every file path to generate
  2. `02-content-structure.md` — templates and section specs per file type
  3. `03-wave-plan.md` — component ordering by category
  4. `04-success-criteria.md` — quality checkpoints
  5. `05-subagent-template.md` — prompt template for Stage 4 subagents

### When to start a fresh session

Each file in the directory is a clean checkpoint. For small design systems, all 5 files fit in one session. For large systems, commit after each file and continue in a fresh session — resume detection checks which files exist.

### Common issues

- **Resume detection:** If the directory exists but some files are missing, the command continues from where it left off.
- **Open questions remain:** The command instructs the agent to resolve ALL ambiguities before finalizing. If any "[TBD]" appears, the agent must ask the user.
- **Component count mismatch:** If the extracted component count doesn't match decisions, the agent reports the discrepancy.

---

## Stage 4: Parallel Generation

**Command:** `commands/4-generate.md`
**Input:** All context from disk (decisions, facts, PRD)
**Output:** `skills/{ds}/`
**Context usage:** ~12% per batch, starting from 0%

### What it does

Generates all skill files following the PRD's specifications. Executes in waves: infrastructure first, then guides, then component batches. Each component batch runs in its own fresh session.

### What it reads

- `context/{ds}/01-decisions.md`
- `context/{ds}/02-verified-facts/imports.md`
- `context/{ds}/02-verified-facts/tokens.md`
- `context/{ds}/02-verified-facts/compound-components.md`
- `context/{ds}/03-closed-prd/` — selective file loading by phase:
  - Wave 1: `01-file-manifest.md` + `02-content-structure.md` + `03-wave-plan.md`
  - Wave 2: `02-content-structure.md` + `03-wave-plan.md`
  - Wave 3+: `05-subagent-template.md` + `03-wave-plan.md`
- `context/{ds}/stage4-progress.md` (for resume)
- `context/{ds}/02-verified-facts/components/{name}.md` (per batch, only current 8 components)

(Legacy single-file `03-closed-prd.md` is also supported — the command auto-detects the format.)

### What it writes

- `skills/{ds}/SKILL.md`
- `skills/{ds}/references/{ds}/v{N}/index.md`
- `skills/{ds}/references/{ds}/v{N}/components.md`
- `skills/{ds}/references/guidelines/` (a11y, performance, security)
- `skills/{ds}/references/{ds}/v{N}/guides/` (tokens, imports, etc.)
- `skills/{ds}/references/{ds}/v{N}/components/{name}/{platform}/api.md`
- `skills/{ds}/references/{ds}/v{N}/components/{name}/{platform}/examples/`
- `context/{ds}/stage4-progress.md` (updated after every batch)

### Session strategy

- Wave 1 (infrastructure) + Wave 2 (guides): one session
- Each component batch: fresh session
- The `scripts/generate-loop.sh` script automates the session cycling

### Common issues

- **Import path hallucination:** The Batch 1 import spot-check catches this early. If wrong patterns are found, strengthen the sub-agent prompt before continuing.
- **Context accumulation:** If the agent tries to run multiple batches in one session, quality degrades. End the session after each batch.
- **Progress file corruption:** If the progress file is malformed, delete it and re-run. Already-generated files on disk are preserved.

---

## Stage 5: Asset Catalog Generation

**Command:** `commands/5-assets.md`
**Input:** `01-decisions.md` + design system source + `02-verified-facts/` (if asset data exists)
**Output:** `skills/{ds}/references/{ds}/v{N}/assets/`
**Context usage:** Low (mechanical extraction + table generation)

### What it does

Produces exhaustive asset catalogs (icons, logos, illustrations, pixels) for every asset system identified in Stage 1. Asset catalogs are lookup tables — every name, every import path — that eliminate name hallucination by giving agents a complete enumeration to search.

This stage combines extraction and generation because asset data is structured and needs no AI interpretation. A companion shell script (`scripts/extract-asset-names.sh`) handles the mechanical extraction from TypeScript name arrays; the agent handles source discovery, props extraction, and routing updates.

### What it reads

- `context/{ds}/01-decisions.md` — asset systems in scope, source paths
- Design system source code — TypeScript name arrays, barrel files, or asset directories
- `context/{ds}/02-verified-facts/` — any already-extracted asset data from Stage 2
- `skills/{ds}/SKILL.md` — routing matrix to update
- `skills/{ds}/references/{ds}/v{N}/index.md` — navigation to update

### What it writes

- `context/{ds}/02-verified-facts/assets/{type}.md` — verified name lists per asset type
- `skills/{ds}/references/{ds}/v{N}/assets/{type}/{platform}/api.md` — catalog files
- Updates to `SKILL.md` routing matrix and `index.md` navigation

For multi-package systems (e.g., separate assets package):
- `context/{ds}/02-verified-facts/{ds}-assets/{type}.md`
- `skills/{ds}/references/{ds}-assets/v{N}/assets/{type}/{platform}/api.md`
- `skills/{ds}/references/{ds}-assets/v{N}/index.md`

### When to start a fresh session

Stage 5 is lightweight. It can share a session with post-Stage-4 work or run standalone. No batch cycling is needed — asset catalogs are generated in a single pass.

### Common issues

- **Name array not found:** The source structure may not follow common conventions. Ask the user for the path to asset name lists.
- **Count mismatch:** If the catalog has fewer rows than the source array, some names were filtered by the extraction script's regex. Re-run with adjusted patterns.
- **Multi-package confusion:** If the design system has a separate assets package, ensure each package gets its own namespace under `references/`.

---

## Stage 6: Programmatic Verification

**Script:** `scripts/verify-skills.sh`
**Input:** `skills/{ds}/` + `context/{ds}/02-verified-facts/`
**Output:** `context/{ds}/stage6-verification.md`
**Context usage:** 0% (no agent session)

### What it does

Runs mechanical checks on the generated output:
1. File completeness — every in-scope component has api.md + examples/
2. Import paths — all match verified facts
3. Structural requirements — ## Import sections, 'use client' directives, anti-patterns
4. Cross-references — all components listed in index.md

### Usage

```bash
./scripts/verify-skills.sh your-design-system
./scripts/verify-skills.sh your-design-system --fix  # Suggests fix approach
```

### Common issues

- **High import error count:** Usually means the sub-agent prompt didn't enforce import paths strongly enough. Fix: create a search-and-replace script using the verified import paths.
- **Missing structural sections:** Usually means the PRD's content structure was incomplete. Fix: update the missing sections manually or re-run generation for affected components.
