# Stage 3: Closed PRD Generation

## Required Capabilities

- File read/write
- User interaction (resolving ambiguities)
- Shell command execution (git)

## Objective

Run Stage 3 of the design system skill generation pipeline: closed PRD generation.

Synthesize decisions from Stage 1 and verified facts from Stage 2 into a PRD that specifies every file to generate, its exact content structure, the wave/batch plan, and the sub-agent prompt template. The PRD must have ZERO open questions.

The PRD is the load-bearing checkpoint of the pipeline. Every file generated in Stage 4 is only as good as this document. Errors or ambiguities here multiply across ALL component files — if 68 components are in scope, one bad decision in the PRD produces 68 bad files.

The PRD also serves as the specification for Stage 4 sub-agents. A well-specified PRD means every sub-agent gets identical, unambiguous instructions — preventing prompt drift across batches.

## Process

### Step 1: Load inputs

Read **summary files only** — do NOT read individual component fact files. The summaries contain everything needed for the PRD. Reading 50+ component files wastes context budget.

- `context/{ds}/01-decisions.md` — scope, categories, guides, conventions
- `context/{ds}/02-verified-facts/imports.md` — all validated import paths
- `context/{ds}/02-verified-facts/compound-components.md` — compound structures
- `context/{ds}/02-verified-facts/tokens.md` — token catalog
- Scan `context/{ds}/02-verified-facts/components/` — **count** extracted components (list filenames, don't read contents)

If any input is missing, tell the user which previous stage needs to complete first.

Verify: the number of extracted component files matches the in-scope component list from decisions. Report any discrepancies.

### Large DS session management (50+ components)

For design systems with 50+ components, the PRD is large enough that generating it in one session risks exceeding context limits. Split into two sessions:

**Session A:** Write Sections 1-3 (file manifest, content structure, wave plan). After writing, commit the partial PRD:
```bash
git add context/{ds}/03-closed-prd.md
git commit -m "{DS} Stage 3: partial PRD (sections 1-3)"
```
Then tell the user:
> Sections 1-3 written and committed. Start a fresh agent session and run Stage 3 again to continue with sections 4-5 and approval.

**Session B:** Read the partial PRD from disk, generate Sections 4-5 (success criteria, sub-agent template), resolve ambiguities, and get user approval.

**Resume detection:** If `context/{ds}/03-closed-prd.md` exists but lacks Section 5 (sub-agent template), this is a resumed session. Read the partial PRD and continue from where it left off.

For design systems with <50 components, write the full PRD in one session.

### Step 2: Generate the PRD

Write `context/{ds}/03-closed-prd.md` with the following sections:

#### Section 1: File manifest

List EVERY file that will be generated, with exact paths:

```markdown
## File Manifest

### Infrastructure
| File | Path |
|---|---|
| SKILL.md | `skills/{ds}/SKILL.md` |
| index.md | `skills/{ds}/references/{ds}/v{N}/index.md` |
| components.md | `skills/{ds}/references/{ds}/v{N}/components.md` |

### Guidelines (cross-cutting, DS-agnostic)
| File | Path |
|---|---|
| a11y.md | `skills/{ds}/references/guidelines/a11y.md` |
| performance.md | `skills/{ds}/references/guidelines/performance.md` |
| security.md | `skills/{ds}/references/guidelines/security.md` |

### Guides (DS-specific)
| File | Path |
|---|---|
| {guide-name}.md | `skills/{ds}/references/{ds}/v{N}/guides/{name}.md` |

### Components (api.md + examples/ per component)
| Component | Variant Type | Path Pattern |
|---|---|---|
| {name} (single-variant) | — | `skills/{ds}/references/{ds}/v{N}/components/{name}/{platform}/api.md` + `examples/` |
| {name} (multi-variant) | {variant} | `skills/{ds}/references/{ds}/v{N}/components/{name}/{platform}/{variant}/api.md` + `examples/` |

**Total files: N** (infrastructure + guidelines + guides + components)
```

#### Section 2: Content structure per file type

For EACH file type, specify the exact sections, order, and content:

**SKILL.md:**
- Description of the design system
- Setup/installation instructions (Provider, registry, dependencies)
- Routing matrix: maps user intent → reference file (using versioned paths)
- Links to all guides and guidelines

**index.md** (at `{ds}/v{N}/index.md`):
- Pre-flight checklist (version detection, required reads)
- Top mistakes table (common failure modes)
- Task-to-file navigation matrix

**components.md** (at `{ds}/v{N}/components.md`):
- Categorized component catalog: name, atomic level, category, description
- Reference path to api.md (accounting for variant structure)
- "When NOT to use" guidance per component

**Guide files:** Specify content per guide — tokens, imports, anti-patterns, etc.

The tokens guide MUST include a **Consumer Styling Patterns** section. This section tells consuming agents HOW to apply tokens when building custom UI alongside the design system's components. The content depends on the design system's styling approach:

- **Tailwind-based:** `@theme inline` setup, token utilities, `cn()` usage, anti-patterns (raw Tailwind colors)
- **SCSS/BEM-based:** SCSS import, variable usage, mixins, anti-patterns (hardcoded hex values)
- **CSS-in-JS-based:** Theme provider, styled import, anti-patterns (bypassing theme object)
- **Vanilla CSS:** CSS import, `var()` references, anti-patterns (hardcoded values)

**api.md (per component):**
- ## Import — exact import statement + style import from verified facts
- ## Named Exports — table of all exports with Kind (Component, Type, Hook, Utility)
- ## Props — table with Type, Default, Required, Description
- ## TypeScript Interface — raw TS interface from verified facts (fenced code block)
- ## Inherited Props — what the component extends
- ## Compound Components — sub-component table and nesting pattern (if applicable)
- ## Controlled vs Uncontrolled — discriminator pattern (if interactive component)
- ## Data Attributes — testing attributes from verified facts (if extracted)
- ## Anti-patterns — common mistakes with WRONG/CORRECT code blocks
- ## Related — links to related components

**examples/ directory (per component):**

Examples use progressive disclosure via numbered files:
- `01-basic-usage.md` — minimal working example
- `02-common-patterns.md` — 2-3 real-world patterns
- `03-compound-usage.md` — sub-component composition (if applicable)
- `04-composition.md` — combining with other DS components (if applicable)

Every example file must include:
- `'use client'` directive at top of every code block (if the DS targets Next.js/RSC — check decisions)
- Full imports in every example (component import + style import)
- Every example is a complete functional component with `export default` — not a JSX snippet

#### Section 3: Wave plan

Check `01-decisions.md` for a **Run Plan** section. If the design system was split into multiple runs, the wave plan must respect run boundaries.

Assign files to ordered waves:

```markdown
## Wave Plan

### Wave 1: Infrastructure
- SKILL.md
- index.md
- components.md

### Wave 2: Guides
- {list all guide files}

### Wave 3+: Components — Batch 1
- {8 components, listed by name}

### Wave 4: Components — Batch 2
- {next 8 components}
```

For multi-run design systems, include run boundaries. Each run boundary is a **session boundary**. Infrastructure (Wave 1) and guides (Wave 2) are generated once in Run 1 only.

#### Section 4: Success criteria

```markdown
## Success Criteria

### api.md
- [ ] Import statement matches 02-verified-facts/imports.md exactly
- [ ] Every prop from verified facts is in the table
- [ ] Types match source TypeScript interfaces
- [ ] Compound sub-components documented (if applicable)
- [ ] No props added that aren't in verified facts
- [ ] Named exports table present with all exports
- [ ] Anti-patterns section with WRONG/CORRECT code blocks

### examples/ directory
- [ ] 'use client' directive in every code block (if applicable)
- [ ] Import paths match verified facts exactly
- [ ] Minimum 3 example files
- [ ] All examples are syntactically valid TSX
- [ ] Every example is a complete functional component (not a snippet)

### SKILL.md
- [ ] Routing matrix covers every component and guide
- [ ] Setup instructions are complete
- [ ] All links are valid relative paths

### index.md
- [ ] Every in-scope component is listed
- [ ] Categories match decisions
- [ ] Links to api.md are correct relative paths
```

#### Section 5: Sub-agent prompt template

Write the EXACT prompt that every Stage 4 component sub-agent will receive. This is critical — it prevents prompt drift across batches.

```markdown
## Sub-agent Prompt Template

The following prompt is sent to each sub-agent. Variables in {braces} are replaced per component.

---

You are generating skill documentation for {COMPONENT_NAME} ({DS_NAME} design system).

**Verified facts (use these — do not generate from memory):**
{CONTENTS_OF_VERIFIED_FACTS_FILE}

**Import path (use EXACTLY this):**
{IMPORT_LINE_FROM_IMPORTS_MD}

**Write files to the versioned path.** For single-variant components:
1. `skills/{ds}/references/{ds}/v{N}/components/{name}/{platform}/api.md`
2. `skills/{ds}/references/{ds}/v{N}/components/{name}/{platform}/examples/01-basic-usage.md`

For multi-variant components, repeat per variant:
1. `skills/{ds}/references/{ds}/v{N}/components/{name}/{platform}/{variant}/api.md`
2. `skills/{ds}/references/{ds}/v{N}/components/{name}/{platform}/{variant}/examples/01-basic-usage.md`

**api.md structure:**
{content structure from Section 2}

**examples/ directory structure:**
{example requirements from Section 2}

**Rules:**
- Import paths: copy EXACTLY from the import path above. Do not modify, guess, or generate alternatives.
- Props: include ONLY props from the verified facts. Do not add, rename, or modify.
- Types: match TypeScript types from verified facts exactly.
- If verified facts say [UNVERIFIED], include the information but note the uncertainty.
- Every example must be a complete, copy-paste-ready functional component with export default.

---
```

### Step 3: Resolve all ambiguities

Before finalizing, systematically check for open questions:

1. Are there components with [UNVERIFIED] facts?
2. Are there components that need special treatment?
3. Should examples use TypeScript or JavaScript?
4. Are there responsive patterns to document per-component or in a guide?
5. Should the SKILL.md include installation/registry instructions?

If ANY question lacks a clear answer — ask the user NOW. Do not write "[TBD]" in the PRD.

### Step 4: Commit, then get user approval

After writing the PRD, commit it immediately — before asking for approval:

```bash
git add context/{ds}/03-closed-prd.md
git commit -m "{DS} Stage 3: closed PRD (N files, W waves, 0 open questions)"
```

Then:

1. Print a summary:
   ```
   PRD written and committed:
   - Total files to generate: N
   - Waves: W
   - Open questions: 0
   ```

2. Ask: **"Is this PRD complete and approved? Any changes before Stage 4 generation?"**

3. Incorporate any changes, re-commit.

4. Once approved:
   ```
   Stage 3 complete. PRD is committed.

   Start a FRESH agent session and run Stage 4 (generate).
   Each component batch will run in its own session — the progress file tracks continuity.
   ```

## Rules

- **Zero open questions.** Every "[TBD]" is a failure of this stage.
- **Self-contained PRD.** A reader with no conversation history should understand every file to generate.
- **Sub-agent template is mandatory.** Don't skip it — it's the quality control mechanism for Stage 4.
- **If facts are incomplete**, flag them and ask the user whether to proceed or re-run extraction.
- **Do NOT read individual component fact files.** Use only the summary files (imports.md, tokens.md, compound-components.md).
- **Commit before approval.** The PRD must be on disk before asking the user to review it.
- **For 50+ components, split PRD generation across two sessions.**
- **Do NOT generate any skill files.** This stage is planning only.
- **Do NOT proceed to Stage 4.** The user must start a fresh session.
