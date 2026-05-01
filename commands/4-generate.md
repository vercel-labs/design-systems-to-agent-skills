# Stage 4: Parallel Skill File Generation

## Required Capabilities

- File read/write
- Shell command execution (git, directory creation)
- Sub-agent spawning (recommended for parallelism; can dispatch serially without it)

## Objective

Run Stage 4 of the design system skill generation pipeline: parallel skill file generation.

**This should run in a fresh agent session.** If this session has significant conversation history from Stages 1-3, start a new session first.

Read the closed PRD, decisions, and verified facts from disk. Generate all skill files using parallel sub-agents in batches of 8. Each component batch runs in its own fresh session to avoid context accumulation — the progress file on disk provides continuity between sessions.

The PRD may be either a single file (`03-closed-prd.md`) or a directory of 5 files (`03-closed-prd/`). Both formats are supported — detect which is present and load accordingly.

## Process

### Step 0: Session check

Check if this session has existing conversation history beyond loading this command.

If yes, warn:
> This session has existing context. Stage 4 is the heaviest stage — it generates all skill files and needs maximum context budget.
>
> **Recommended:** Start a fresh agent session and run Stage 4 again.
>
> Continue anyway? (The mandatory pauses and progress file will help manage context, but fresh is better.)

### Step 1: Load context from disk

Identify the design system by scanning `context/` for available directories.

#### PRD format detection

Check which PRD format is present:
- **Directory format** (`context/{ds}/03-closed-prd/` exists): Multi-file mode. Load files selectively based on the current phase (see table below).
- **Single-file format** (`context/{ds}/03-closed-prd.md` exists): Legacy mode. Load the full file.

**Selective PRD loading (directory format only):**

| Phase | PRD files loaded |
|---|---|
| Wave 1 (infrastructure) | `01-file-manifest.md` + `02-content-structure.md` + `03-wave-plan.md` |
| Wave 2 (guides) | `02-content-structure.md` + `03-wave-plan.md` |
| Wave 3+ (component batches) | `05-subagent-template.md` + `03-wave-plan.md` |

Component batches do NOT load the full manifest, content structure, or success criteria — only the subagent template and wave plan. This keeps context usage low for the heaviest phase.

#### Common context (always loaded)

Read from disk (NOT from conversation history):
1. `context/{ds}/01-decisions.md` — scope, categories
2. `context/{ds}/02-verified-facts/imports.md` — ALL validated import paths
3. `context/{ds}/02-verified-facts/tokens.md` — token catalog
4. `context/{ds}/02-verified-facts/compound-components.md` — compound structures
5. PRD files as determined by the phase (see table above)

#### Resume check

If `context/{ds}/stage4-progress.md` exists, read it. This means a previous session was interrupted. Resume from where it left off:
- Skip completed waves and batches
- Report what's already done and what's remaining
- Ask user to confirm before continuing

### Step 2: Prepare

From the PRD, extract:
- The wave plan (which files in which order)
- The sub-agent prompt template (from `05-subagent-template.md` or PRD Section 5)
- The content structure specifications (from `02-content-structure.md` or PRD Section 2)
- The success criteria (from `04-success-criteria.md` or PRD Section 4)

Ensure output directories exist:
```
skills/{ds}/
├── SKILL.md
├── references/
│   ├── guidelines/                     # Cross-cutting: a11y, performance, security
│   └── {ds}/v{N}/                      # Versioned DS namespace
│       ├── index.md
│       ├── components.md
│       ├── guides/                     # DS-specific (tokens, icons, patterns, etc.)
│       └── components/
│           └── {name}/{platform}/
│               ├── api.md
│               ├── examples/
│               ├── {variant}/          # Multi-variant: variant subdirectories
│               │   ├── api.md
│               │   └── examples/
```

#### Dynamic batching

The wave plan orders components by category but does NOT pre-assign fixed batches. The generate command takes the next 8 unchecked items from the progress file in wave order. This is more resilient — failed components can be retried without stale batch assignments.

Initialize the progress file with a flat ordered list (no run grouping):
```markdown
# Stage 4 Progress — {DS Name}

## Status: In Progress
## Started: {timestamp}
## Total: {N} components

### Wave 1: Infrastructure
- [ ] SKILL.md
- [ ] {ds}/v{N}/index.md
- [ ] {ds}/v{N}/components.md
- [ ] guidelines/a11y.md
- [ ] guidelines/performance.md
- [ ] guidelines/security.md

### Wave 2: Guides
{list all DS-specific guides with checkboxes}

### Wave 3: Components
#### {Category 1 — e.g., Form}
- [ ] {component1}
- [ ] {component2}

#### {Category 2 — e.g., Layout}
- [ ] {component3}
- [ ] {component4}

### Issues
(none)
```

Write this to `context/{ds}/stage4-progress.md`.

### Step 3: Execute Wave 1 — Infrastructure

Generate SKILL.md, index.md, components.md, and cross-cutting files directly (no sub-agents needed — these are orchestrator-level files).

**SKILL.md content:** Follow the PRD's content structure. The file MUST begin with YAML frontmatter for skill system registration:

```yaml
---
name: {ds}
description: >
  {DS full name} component and asset reference. Use this skill when building UI
  with {package} — component props, import paths, icons, design tokens,
  and anti-patterns. All data verified from source code.
---
```

The `name` field is the DS short name from decisions. The `description` field should be a concise summary derived from decisions (package name, what the skill covers, key asset counts if known). Keep the description under 3 lines.

After the frontmatter, include:
- Design system description
- Setup/installation instructions
- Routing matrix mapping user intent → reference files (using versioned paths)
- Links to all guides and guidelines

**index.md content:** Lives at `{ds}/v{N}/index.md`. Include:
- Pre-flight checklist (version detection, required reads)
- Top mistakes table (common failure modes)
- Task-to-file navigation matrix

**components.md content:** Lives at `{ds}/v{N}/components.md`. Categorized component catalog with reference paths to api.md for each component.

**guidelines/ content:** Cross-cutting, DS-agnostic files (a11y.md, performance.md, security.md).

After writing all infrastructure files:
1. Update progress file (mark Wave 1 complete)
2. Commit:
   ```bash
   git add skills/{ds}/ context/{ds}/stage4-progress.md
   git commit -m "{DS} generate: Wave 1 — infrastructure"
   ```
3. Report: **"Wave 1 complete: infrastructure files written and committed."**
4. Continue to Wave 2 (infrastructure + guides are lightweight enough for one session).

### Step 4: Execute Wave 2 — Guides

Generate all DS-specific guide files. If there are many (>4), use sub-agents for parallelism. Otherwise, write directly.

After writing all guide files:
1. Update progress file (mark Wave 2 complete)
2. Commit:
   ```bash
   git add skills/{ds}/references/{ds}/ context/{ds}/stage4-progress.md
   git commit -m "{DS} generate: Wave 2 — guides"
   ```
3. Report:
   ```
   Wave 2 complete: guide files written and committed.
   Infrastructure and guides are done.

   END THIS SESSION.
   Component batches are context-heavy — each batch must run in a fresh session.
   Start a fresh agent session and run Stage 4 again to continue with Batch 1.
   ```
4. **STOP. Do not start component batches in this session.**

### Step 5: Execute Wave 3+ — Components

Process components in batches of 8. Read the progress file and take the next 8 unchecked component items in wave order. Scope verified facts loading to only the current batch (8 components), not the full component list.

#### For each batch:

**5a. Dispatch sub-agents**

For each component in the batch, dispatch a sub-agent using the PRD's sub-agent prompt template. Fill in the variables:

- `{COMPONENT_NAME}` — component name
- `{DS_NAME}` — design system name
- `{CONTENTS_OF_VERIFIED_FACTS_FILE}` — read `02-verified-facts/components/{name}.md` and include its full contents
- `{IMPORT_LINE_FROM_IMPORTS_MD}` — find this component's import in `imports.md`

If the verified facts file contains a `## Behavioral Notes` section with entries (not just "None observed."), include those notes in the sub-agent prompt:

"The following behavioral observations were extracted from source code. Turn each into a WRONG/CORRECT anti-pattern pair in the Anti-patterns section.

Behavioral Notes:
{CONTENTS_OF_BEHAVIORAL_NOTES_SECTION}"

This is backward-compatible: components without a `## Behavioral Notes` section continue to work unchanged.

Each sub-agent writes directly to the versioned path.

**5b. Wait for all sub-agents to complete**

Check that all files were written. If any sub-agent failed, note the component name in the Issues section of the progress file.

**5b-extra. AFTER BATCH 1 ONLY — Import path spot-check**

This is the most critical quality gate. Catch import path hallucinations early:

```bash
grep -rn "from ['\"]" skills/{ds}/references/{ds}/v{N}/components/{batch1-components}/ | grep -v "expected-import-pattern" | grep -v "react" | grep -v "next/"
```

If ANY wrong import paths are found in Batch 1:
1. Report the exact wrong patterns to the user
2. DO NOT dispatch Batch 2 until the sub-agent prompt is strengthened
3. Consider wrapping the import in the sub-agent prompt with: `COPY THIS IMPORT EXACTLY — DO NOT MODIFY: {import line}`
4. Re-generate the affected Batch 1 files

This check is cheaper on 8 files than on all files. Do not skip it.

**5c. Update progress file and commit**

Mark the batch complete:
```markdown
### Batch {N} — Complete
Components: {list}
Files written: {count}
Issues: {none or list}
```

Then commit immediately:
```bash
git add skills/{ds}/references/{ds}/v{N}/components/{component1}/ ... context/{ds}/stage4-progress.md
git commit -m "{DS} generate: batch {N} ({component1}, {component2}, ...)"
```

**5d. Report and end session**

Print:
```
Batch {N} complete and committed: {component list}.
Progress: {X}/{Y} components done. {Z} files written.
Remaining: {list remaining batches}.

END THIS SESSION.
Start a fresh agent session and run Stage 4 to continue with Batch {N+1}.
Progress is saved in the progress file — the new session will resume automatically.
```

**STOP. Do NOT dispatch the next batch in this session.** Each component batch must run in its own fresh session. Context accumulates across batches and degrades quality. A fresh session starts with full context budget and loads only what it needs from disk.

### Step 6: Completion

After all waves and batches are done:

1. Update progress file: set Status to "Complete"
2. Report final summary:
   ```
   Stage 4 complete.
   - Infrastructure: SKILL.md + index.md + components.md + guidelines
   - Guides: {N} files
   - Components: {M} component families, {L} total files
   - Total files generated: {T}
   - Issues: {count or "none"}
   ```
3. All output has been committed incrementally. No final bulk commit needed.
4. Suggest verification:
   > Run `./scripts/verify-skills.sh {ds}` to verify import paths, structural requirements, and file completeness.

## Execution Rules

These rules prevent context accumulation, hallucination cascades, and loss of progress.

1. **BATCH SIZE: 8 maximum.** No exceptions. Smaller batches are fine.

2. **ONE BATCH PER SESSION.** After completing a component batch, end the session. Start a fresh session to continue. Infrastructure (Wave 1) and guides (Wave 2) can share one session, but component batches cannot.

3. **PROGRESS FILE updated after every batch.** This is the session-continuity mechanism. Each new session reads the progress file and resumes from where the previous session left off.

4. **NEVER COMPACT TO CONTINUE.** If context usage is high, end the session — don't try to compact. A fresh session with full context budget is always better.

5. **SUB-AGENTS WRITE DIRECTLY.** No intermediate format. Each sub-agent writes api.md and examples/ files to the final versioned path.

6. **IMPORT PATHS FROM VERIFIED FACTS ONLY.** Copy the import statement from `imports.md` verbatim into each sub-agent prompt. Import path hallucination is the #1 quality issue.

7. **WAVE ORDER IS STRICT.** Infrastructure → guides → components. Complete each wave fully before starting the next.

8. **IGNORE STALE NOTIFICATIONS.** If a sub-agent notification arrives for an already-completed component, ignore it silently. Do not respond or log it.

9. **COMMIT AFTER EVERY WAVE AND BATCH.** Never let more than one batch of output sit uncommitted. Large uncommitted diffs bloat context and lose progress on session failure.
