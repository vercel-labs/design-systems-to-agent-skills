# Stage 2b: Usage Analysis (Optional)

## Required Capabilities

- File read/write
- Shell command execution (git, file existence checks, grep)
- Sub-agent spawning (recommended for parallelism; can run serially without it)

## Objective

Run Stage 2b of the design system skill generation pipeline: usage pattern analysis.

This stage analyzes how developers actually use DS components in a **consuming codebase**. It detects wrapper components, overridden defaults, workaround comments, and transform utilities — signals that only appear in usage, not in the DS source code.

Stage 2b is **optional**. It only runs when the user provides a consuming repo path. If no consuming repo is available, skip directly to Stage 3.

**Critical:** Report only patterns verifiable from the consuming codebase. Do not infer intent or generate from training data. If a pattern is unclear, flag it as [AMBIGUOUS].

## Process

### Step 1: Load inputs and validate

Read `context/{ds}/01-decisions.md` where `{ds}` is determined by scanning the `context/` directory for available design systems.

Extract from decisions:
- DS package name (for import detection)
- Source repo path (for same-repo detection)
- In-scope component list

Scan `context/{ds}/02-verified-facts/components/` — list component names and read each file's `## Import` section to extract import paths. These import paths are used to find DS component usage in the consuming repo.

Validate the consuming repo path (provided as argument):
1. The path exists and is readable
2. It contains source files (`.tsx`, `.ts`, `.jsx`, `.js`)
3. It has DS package imports (grep for the package name in source files)

If `context/{ds}/02-verified-facts/` is missing or empty:
> Stage 2 verified facts not found. Run Stage 2 (extract) first.

If zero DS imports found in the consuming repo:
> No {package} imports found in {consuming_repo_path}. This codebase does not appear to use {DS name}. Stage 2b requires a codebase that imports the design system.

Report and stop.

### Step 2: Detect same-repo scenario

Compare the consuming repo path with the DS source path from decisions.

**Different repos:** Search the entire consuming repo for DS usage.

**Same repo:** The DS library and consuming code live in the same repository. Exclude:
- The DS library directory (from decisions source path)
- `node_modules/`
- Build output directories: `dist/`, `build/`, `.next/`, `out/`

Report the scenario to the user:
```
Scenario: {different repos | same repo}
Consuming repo: {path}
DS source path: {path} {(excluded from search) if same repo}
Search scope: {description}
```

### Step 3: Prepare output structure

Ensure these directories exist:
```
context/{ds}/02b-usage-patterns/
├── components/         # one file per in-scope component
└── summary.md          # cross-component summary (Stage 3 reads this)
```

### Step 4: Analyze usage with sub-agents

Process in-scope components in **batches of 8**.

For each batch, dispatch parallel sub-agents (background mode if available).

**Context management:** Do NOT read sub-agent transcripts back into the orchestrator. Each sub-agent's search work (grepping consuming code, reading wrapper files, counting prop usage) is large. Instead:
1. Launch all sub-agents in the batch
2. Poll for file existence on disk: check that `context/{ds}/02b-usage-patterns/components/{name}.md` exists and is non-empty for each component in the batch
3. Use a simple bash loop with `sleep` to wait, e.g.: `while [ ! -f "path/to/file.md" ]; do sleep 5; done`
4. Once all files exist, proceed to commit — do not read the sub-agent output

#### Sub-agent prompt template

```
You are analyzing usage patterns for the {component_name} component of the {ds_name} design system in a consuming codebase.

**Component import paths (from verified facts):**
{import_paths}

**Consuming repo path:** {consuming_repo_path}
**Search scope:** {search_scope_description}
{exclusion_rules_if_same_repo}

Search the consuming codebase for all usages of {component_name}. Exclude test files (*.(test|spec).(ts|tsx|js|jsx)), storybook files (*.stories.(ts|tsx|js|jsx)), and mock files.

ANALYZE THE FOLLOWING 4 SIGNAL TYPES:

1. **Wrapper components** — Files that import the DS component and re-export a wrapped version.
   Look for: files that import {component_name}, define a new component around it, and export that wrapper.
   For each wrapper found, identify:
   - The wrapper component name and file path
   - What the wrapper adds (default props, additional logic, layout, context)
   - What gap in the raw DS component the wrapper fills

2. **Overridden defaults** — Props explicitly set in the majority of usages.
   Look for: JSX usage of {component_name} and tally which props are explicitly set.
   For each prop set in >50% of usages, record:
   - The prop name
   - The default value (from DS)
   - The common override value
   - The override rate (e.g., "set in 8/10 usages")
   - What this implies about the default

3. **Workaround comments** — Comments near DS component usage containing signal words.
   Look for: comments within 3 lines of {component_name} JSX containing:
   workaround, hack, TODO, FIXME, NOTE, BUG, CAVEAT, XXX, NB
   For each comment found, record:
   - The exact comment text
   - The file path and line number
   - What insight it provides about the component

4. **Transform utilities** — Functions that prepare data for DS component props.
   Look for: utility or helper functions whose return values are passed directly to {component_name} props.
   For each utility found, record:
   - The function name and file path
   - What transformation it performs
   - Which prop receives the transformed value
   - What this reveals about expected input format

WRITE your findings to: context/{ds}/02b-usage-patterns/components/{component_name}.md

Use this format:
---
# {ComponentName} — Usage Patterns

## Source
- **Consuming repo:** {path}
- **Total usages found:** {N}

## Wrapper Components
| Wrapper | File | What it adds | Gap it fills |
|---|---|---|---|

## Overridden Defaults
| Prop | Default (from DS) | Common override | Override rate | Implication |
|---|---|---|---|---|

## Workaround Comments
| Comment | File:Line | Insight |
|---|---|---|

## Transform Utilities
| Function | File | Transforms | Target prop | Insight |
|---|---|---|---|---|

## Summary
{1-3 sentences summarizing the most significant usage patterns for this component. If nothing notable was found, write: "No significant usage patterns detected."}
---

RULES:
- Search the consuming codebase ONLY. Do not re-analyze the DS source.
- If you can't determine a pattern's significance, flag it with [AMBIGUOUS].
- Exclude test files, storybook files, and mock files — these are not real usage patterns.
- Count actual usages, not just imports. An import without JSX usage is not a usage pattern.
- If the component is not used in the consuming repo, write "Component not used in consuming codebase." in the Summary and leave tables empty.
```

#### After each batch

1. Verify all sub-agents wrote their files by checking file existence on disk:
   ```bash
   for comp in {component1} {component2} ...; do
     [ -s "context/{ds}/02b-usage-patterns/components/${comp}.md" ] && echo "✓ $comp" || echo "✗ $comp MISSING"
   done
   ```
   If any file is missing after a reasonable wait, note it in the report and move on.

2. **Commit the batch immediately.** This is mandatory — not optional.
   ```bash
   git add context/{ds}/02b-usage-patterns/components/{component1}.md context/{ds}/02b-usage-patterns/components/{component2}.md ...
   git commit -m "{DS} usage analysis: batch N ({component1}, {component2}, ...)"
   ```

3. Report to user: "Batch N complete: {list of components} — committed. {remaining} components pending."

4. Continue to next batch.

### Step 5: Compile summary

After all components are analyzed, read all per-component files and write `context/{ds}/02b-usage-patterns/summary.md`:

```markdown
# {DS Name} — Usage Pattern Summary

## Source
- **Consuming repo:** {path}
- **Scenario:** {different repos | same repo}
- **Components analyzed:** {N}
- **Components with notable patterns:** {M}

## Wrapper Components
| Wrapper | Wraps | File | Gap it fills |
|---|---|---|---|

## Most Overridden Defaults
| Component | Prop | DS Default | Common Override | Override Rate | Implication |
|---|---|---|---|---|---|

## Workaround Themes
| Theme | Occurrences | Components | Representative comment |
|---|---|---|---|

## Transform Utilities
| Function | Component | Target Prop | What it reveals |
|---|---|---|---|

## High-Impact Findings

1. {Finding 1 — the most significant pattern with actionable implications}
2. {Finding 2}
3. {Finding 3}
{Up to 5 findings. Focus on patterns that should influence skill documentation.}

## Components Without Notable Patterns
{List components where no significant usage patterns were detected.}
```

### Step 6: Commit and report

```bash
git add context/{ds}/02b-usage-patterns/summary.md
git commit -m "{DS} usage analysis: summary ({N} components analyzed, {M} with patterns)"
```

Print a summary:
```
Stage 2b complete.
- Components analyzed: N
- Wrapper components found: W
- Overridden defaults found: D
- Workaround comments found: C
- Transform utilities found: T
- Components with notable patterns: M
- Components without patterns: N-M
```

Suggest:
> Usage analysis output has been committed. Run Stage 3 (PRD) to continue — it will automatically incorporate the usage patterns.

## Rules

- **Consuming code only.** Do not re-analyze the DS source code. Stage 2 already handled that.
- **[AMBIGUOUS] is better than wrong.** Flag uncertain patterns explicitly.
- **Batch size 8.** Don't overload the context with too many concurrent sub-agents.
- **Commit after every batch.** Never let more than one batch of output sit uncommitted.
- **No false positives.** Test files, storybook stories, and mock files are not "usage patterns." Exclude them from analysis.
- **Same-repo exclusion is mandatory.** If consuming repo == DS source repo, always exclude the DS library directory and build dirs.
- **Ignore stale notifications.** If a background sub-agent completion notification arrives after you've already verified the file on disk, ignore it silently.
- **Do NOT proceed to Stage 3 automatically.** The user invokes Stage 3 separately.
