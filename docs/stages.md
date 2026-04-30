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
2. **Scope** — in-scope components, exclusions, run plan (if >50 components)
3. **Categories** — component groupings (Form, Layout, Feedback, etc.)
4. **Technical** — styling approach, consumer styling pattern, compound components, tokens, provider setup
5. **Output structure** — which guides, component doc structure, anti-patterns
6. **Environment** — public/private registry, framework requirements

### When to start a fresh session

Stage 1 is lightweight. It can share a session with Stages 2-3 if the design system is small (<30 components). For larger systems, a fresh session for Stage 2 is recommended.

### Common issues

- **Vague user answers:** The command instructs the agent to challenge vague responses. If the agent accepts "whatever" as a decision, re-run with the instruction to be more opinionated.
- **Missing component inventory:** If the source has no inventory file, the agent scans component directories. Verify the scan is complete.
- **Run plan disagreement:** The agent recommends splitting at 50+ components. The user can override, but should be aware of quality degradation in long runs.

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
**Output:** `context/{ds}/03-closed-prd.md`
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

- `context/{ds}/03-closed-prd.md` with 5 sections:
  1. File manifest (every file path)
  2. Content structure per file type
  3. Wave plan (batch assignments)
  4. Success criteria
  5. Sub-agent prompt template

### When to start a fresh session

For <50 components, the PRD fits in one session. For 50+ components, split: write Sections 1-3 in session A, commit, then Sections 4-5 in session B.

### Common issues

- **PRD too large for one session:** The command handles this with resume detection. If the PRD exists but lacks Section 5, the agent continues from where it left off.
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
- `context/{ds}/03-closed-prd.md`
- `context/{ds}/stage4-progress.md` (for resume)
- `context/{ds}/02-verified-facts/components/{name}.md` (per batch, only active components)

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

## Stage 5: Programmatic Verification

**Script:** `scripts/verify-skills.sh`
**Input:** `skills/{ds}/` + `context/{ds}/02-verified-facts/`
**Output:** `context/{ds}/stage5-verification.md`
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
