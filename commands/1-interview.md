# Stage 1: Discovery Interview

## Required Capabilities

- File read/write
- Shell command execution (mkdir, git)
- User interaction (asking questions, receiving answers)

## Objective

Run Stage 1 of the design system skill generation pipeline: interactive discovery.

You are the entry point of a 6-stage pipeline that transforms design systems into agent-consumable skills. Your job is to interview the user about every scoping decision, then persist those decisions to disk so subsequent stages can run from a fresh session if needed.

The pipeline stages:
1. **Interview** — YOU ARE HERE. Scope decisions through conversation.
2. **Extract** — Extract verified facts from source code.
3. **PRD** — Generate a closed PRD with zero open questions.
4. **Generate** — Parallel skill file generation (fresh session recommended).
5. **Assets** — Exhaustive asset catalog generation (icons, logos, etc.).
6. **Verify** — Programmatic verification (no agent session needed).

## Process

### Step 1: Identify the source

If the user provided a source repo path, use that. Otherwise ask:

> Where is the design system source code on disk?

Once you have the path, verify it exists, then read ONLY these high-level files:
- `README.md` or equivalent
- `available-components.md` or equivalent component inventory
- `instructions/` directory (if present — may contain AI-friendly docs)
- Root `package.json` (for name, version, peer dependencies)

**Do NOT read individual component source files** (TypeScript interfaces, style files). That is Stage 2's job. Budget ~15% of your context window for this entire interview.

### Step 2: Setup

Determine the design system short name (lowercase, no spaces — e.g., "andes", "geistcn"). Ask the user to confirm.

Then create the output structure:

```bash
mkdir -p context/{ds}/01-decisions
mkdir -p context/{ds}/02-verified-facts/components
mkdir -p skills/{ds}/references/{guides,components}
```

Create the initial decisions file at `context/{ds}/01-decisions.md`:

```markdown
# {DS Name} — Stage 1 Decisions

## Status: In Progress

## Identity
- **Name:** [pending]
- **Package:** [pending]
- **Version:** [pending]
- **Source:** [pending]
- **Output:** skills/{ds}/

## Scope
[pending]

## Categories
[pending]

## Technical
[pending]

## Output Structure
[pending]

## Environment
[pending]
```

### Step 3: Run the interview

Follow the grill-with-docs protocol:

#### Interview protocol

1. **One question at a time.** Wait for feedback before advancing.
2. **Explore before asking.** When the codebase can answer a question, read the relevant file instead of asking the user. For example: if you need to know the styling approach, check the source for `.scss`, `.module.css`, or `tailwind.config` files before asking.
3. **Recommended answer with reasoning.** Don't propose neutral defaults — give an opinionated recommendation and explain why. Example: "I recommend including all 68 components. Excluding some now creates scope ambiguity in Stage 4. We can always skip individual components later if they're trivial."
4. **Terminology validation.** If the user's language conflicts with the source code naming (e.g., user says "popup" but source exports `Modal`), flag it and propose the canonical term from source.
5. **Challenge vague answers.** If the user says "whatever" or "I don't know", don't accept it. Propose a specific recommendation and ask if it works. Every decision must be concrete.
6. **Stress-test with edge cases.** After key decisions, probe boundaries: "What about components that are both compound AND have responsive variants? Should those get extra documentation?" This catches gaps before Stage 4.
7. **Write immediately.** Update `context/{ds}/01-decisions.md` after each confirmed answer — don't batch writes. If the session crashes, the decisions file reflects everything confirmed so far.

#### Block 1: Identity

**Q1: What is this design system?**
Read the package.json and README. Confirm:
- Full name (e.g., "Andes Design System")
- npm package name (e.g., `@andes/react`)
- Version being documented
- Source code path (already known)

**Q2: Where should generated skills be written?**
Default: `skills/{ds}/` in this repo. Confirm or override.

#### Block 2: Scope

**Q3: Component inventory**
List ALL components found in the source (from available-components.md or by scanning the component directories). Present the full list. Ask:
- Are all of these in scope?
- Any to exclude? Why?
- Total count confirmation.

**Q4: Component categories**
Propose categories based on the component names (common groupings: Form, Layout, Feedback, Navigation, Data Display, Overlay, Typography, Media). Ask the user to confirm or adjust. Assign each in-scope component to a category.

#### Block 3: Technical characteristics

**Q5: Styling approach**
Based on what you read, propose one of: Tailwind, CSS Modules, SCSS/BEM, styled-components, CSS-in-JS, vanilla CSS.
This affects how the tokens guide will be structured.

**Q5b: Consumer styling pattern**

This is critical for the generated skills. The skills must tell consuming agents *how to apply design tokens* when building UI with the design system. Investigate:

1. **Does the DS export class composition utilities?** Check for exports like `cn()`, `classnames`, `clsx`, `bem()`, or similar functions. Look in the package exports map or barrel files for utility exports.

2. **Does the DS use a variant system?** Check if components use CVA (class-variance-authority), styled-components variants, SCSS mixins for variants, or another pattern for variant-driven styling.

3. **What's the intended consumer styling pattern?** Based on the DS architecture, determine which pattern consumers should follow:
   - **Tailwind with token mapping** — tokens mapped via `@theme inline`, consumers use utility classes
   - **SCSS variables** — consumers use `$ds-*` variables in `.scss` files
   - **CSS custom properties** — consumers use `var(--ds-*)` in stylesheets or inline styles
   - **Theme object** — consumers access tokens via a theme provider
   - **CSS Modules with token imports** — consumers write `.module.css` referencing token variables
   - **Class utility + Tailwind** — consumers use the DS's class composition utility with Tailwind
   - **Other** — describe the pattern

Record in decisions under **Technical > Consumer Styling**:
```markdown
### Consumer Styling
- **Class utilities:** {utility function exported from X / none}
- **Token application:** {approach}
- **Rationale:** {why this pattern}
```

**Q6: Compound components**
Check if the design system uses compound components. If so, what pattern?
- Dot-notation: `Card.Header`, `Card.Content`
- Separate exports: `CardHeader`, `CardContent`
- Render props or slots
- None

**Q7: Design tokens**
How are tokens organized?
- CSS custom properties (`--ds-*`)
- SCSS variables (`$ds-*`)
- JavaScript/TypeScript objects
- Tailwind config
- Other

**Q8: Provider or setup**
Does the design system require a Provider, context wrapper, or global setup?
- Theme provider
- Locale/i18n
- Registry/CDN configuration
- Import of global styles

#### Block 4: Output structure

**Q9: Which guides should be generated?**
Propose based on the design system's characteristics. Common guides:
- Tokens (colors, spacing, typography, sizing)
- Import paths (how to import components correctly)
- Common mistakes / anti-patterns
- Accessibility patterns
- Icons (if the DS has an icon system)
- Getting started / setup

Ask the user to confirm which ones.

**Q9b: Asset systems inventory**

Probe specifically for asset systems that need exhaustive catalogs (Stage 5). These are different from component docs — they're lookup tables of every name + import path.

- **Icon system:** Does the DS have an icon system? If so:
  - Package name (same as components, or a separate `{ds}-assets` package?)
  - Source path on disk (may differ from the component source)
  - Where are icon names defined? (e.g., `src/__generated__/icon-names.ts`, barrel file, or directory scan)
  - Approximate count
- **Logo system:** Does the DS ship logos? Same questions as above.
- **Illustration / pixel art / other assets:** Any other named-asset systems?
- **Multi-package:** Are assets in the same npm package as components, or a separate package? If separate, capture both package names and source paths.

Record in decisions under **Asset Systems**:

```markdown
## Asset Systems

### Icons
- **Package:** {package name}
- **Source:** {path on disk}
- **Name source:** {path to names array or barrel file}
- **Count:** ~{N}

### Logos
- **Package:** {package name}
- **Source:** {path on disk}
- **Name source:** {path to names array or barrel file}
- **Count:** ~{N}

(Repeat per asset type)
```

If the DS has no asset systems, record `## Asset Systems: None` so Stage 5 knows to skip.

**Q9c: Domain-specific guides**
After asset systems, probe for other domain-specific content:

- **Design spec workflow:** Does the team use a design tool → code pipeline? If so, should the skill include a guide documenting how to translate design specs into DS component usage?
- **Organization-specific patterns:** Are there any internal guidelines, conventions, or patterns beyond the DS source code that the skill should reference?

Record any additional guides in the decisions under **Output Structure > Guides**.

**Q10: Component documentation structure**
Default for each component:
- `api.md` — import statement, props table with types and defaults, compound sub-components, anti-patterns
- `examples/` — directory with numbered example files (01-basic-usage.md, 02-common-patterns.md, etc.) — full code blocks

Ask if anything should be added or changed.

**Q11: Known anti-patterns**
Ask about common mistakes developers make with this design system. These will be documented in a guide and per-component where relevant.

#### Block 5: Environment

**Q12: Public or private registry?**
If private: note that `npm install` won't work in generation. All fact extraction must be from disk.

**Q13: Any other considerations?**
Locale, SSR, browser support, framework requirements (React version, Next.js), etc.

### Step 4: Finalize

After all questions are answered:

1. Update `01-decisions.md` — set Status to "Complete", ensure all sections are filled
2. Read back the complete file to the user
3. Ask: **"Are all decisions final? Any changes before Stage 2 (Fact Extraction)?"**
4. If changes needed, update and re-confirm
5. Once confirmed, suggest:

> Stage 1 complete. To commit and continue:
> ```
> git add context/{ds}/01-decisions.md
> git commit -m "{DS} Stage 1: scope decisions (N components, M guides)"
> ```
> Then run Stage 2 (extract) to start fact extraction.

## Rules

- **ONE question at a time.** Never batch questions. Wait for each answer.
- **Explore before asking.** If the codebase can answer the question (file structure, package.json, config files), read it first. Only ask the user for decisions that require human judgment.
- **Recommend, don't just suggest.** Be opinionated. "I recommend X because Y" is better than "what would you like?"
- **Write to disk after EVERY answer.** Not all at the end. If the session crashes, the file should reflect all confirmed decisions.
- **Validate terminology.** If the user uses a term that doesn't match source code naming, flag it and propose the canonical name.
- **Challenge vague answers.** "Whatever" is not a decision. Propose something specific and get explicit confirmation.
- **Stress-test after key decisions.** Probe edge cases: "What about [unusual component]? Does this rule still apply?"
- **Do NOT read component source code.** Only high-level docs (README, inventory, config, instructions/). Context budget: ~15%.
- **Do NOT proceed to Stage 2.** The user must explicitly invoke Stage 2.
- **No framework artifacts.** No planning directories, no status files, no manifest. Just `01-decisions.md`.
