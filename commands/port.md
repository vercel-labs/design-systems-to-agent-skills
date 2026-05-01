# Port: Deploy Skill to Target Codebase

## Required Capabilities

- File read/write
- Shell command execution (cp, directory creation)
- User interaction (for import path reconciliation)

## Objective

Port a generated skill to a target codebase. This command runs in the **target repo** and takes the skill source path as an argument.

This is a post-pipeline utility — not a numbered stage. It runs after Stages 1–6 have produced and verified a skill in the pipeline repo, and deploys that skill to a consuming codebase.

## Process

### Step 1: Discover target conventions

Read the target codebase to understand its conventions. Check for:

1. **Skill directory location** — which of these exists?
   - `.claude/skills/`
   - `.agents/skills/`
   - `.opencode/skills/`
   - `.opencode/commands/`
   - Other (ask user)

2. **Settings file format** — check `.claude/settings.json` for existing `Skill()` entries in the `permissions.allow` array. Note the pattern used.

3. **Frontmatter pattern** — read any existing SKILL.md files in the target's skill directory. Note:
   - Required YAML fields (`name`, `description`, others?)
   - Field format (single-line vs multi-line `description`)
   - Any additional metadata fields

4. **Import convention discovery** — search the target codebase for existing imports from the design system package:
   ```bash
   grep -rn "from ['\"]@{package}" --include="*.tsx" --include="*.ts" | head -20
   ```
   Note whether the target uses:
   - Barrel imports (`from '@package'`) vs deep imports (`from '@package/components/button'`)
   - Named exports vs default exports
   - Any re-export patterns or local wrappers

Report all findings before proceeding.

### Step 2: Reconcile differences

Compare the generated skill's conventions with the target's conventions:

- **Frontmatter:** If the target uses different or additional frontmatter fields, note what needs to change. Adapt the copy (never modify the source).
- **Import paths:** If the target uses different import patterns than what the skill documents, **REPORT the differences and ASK the user**. Never auto-replace import paths — they were verified from source code in Stage 2. The target may have a wrapper, a re-export, or a different package version.
- **Export styles:** If the target uses default exports where the skill documents named exports (or vice versa), report the difference.

Present a reconciliation summary and get user confirmation before copying.

### Step 3: Copy skill files

Copy the skill directory to the target's skill location:

```bash
cp -r {source_skill_path} {target_skill_directory}/{ds}/
```

If the target directory already contains a skill with the same name, warn the user:
> A skill named `{ds}` already exists at `{target_path}`. Overwrite?

### Step 4: Update target settings

If the target uses `.claude/settings.json` with `Skill()` permission entries:

1. Read the current settings file
2. Check if a `Skill({ds})` entry already exists in `permissions.allow`
3. If not present, add it following the existing pattern
4. Write the updated settings file

If the target uses a different registration mechanism, report what manual step the user needs to take.

### Step 5: Verify

After copying, verify the deployment:

1. **SKILL.md exists** at the target path
2. **Frontmatter is valid YAML** — parse the `---` block and check for required fields
3. **Routing matrix links resolve** — for each path in the routing matrix table, verify the file exists relative to SKILL.md
4. **File count report** — count total files copied and compare to source

Report any issues found.

### Step 6: Report

Print a summary:
```
Port complete: {ds} → {target_skill_path}

Files copied: {N}
Frontmatter: {adapted | unchanged}
Settings: {updated | already present | manual step needed}
Import paths: {matching | {N} differences reported}
Routing links: {all resolve | {N} broken}
```

If import path differences were found, remind the user:
> Import paths in the skill were verified from source code. The target codebase uses different patterns for {N} imports. Review the differences reported in Step 2 and update the skill copy if needed.

## Rules

- **Never modify source skill files** — copy to target, then adapt the copy.
- **Ask before changing import paths** — they were verified from source code in Stage 2. The user must confirm any import path changes.
- **Idempotent** — running twice overwrites the previous copy, doesn't duplicate files.
- **Target-first discovery** — read the target's conventions before making any changes. Don't assume the target matches the pipeline's defaults.
- **Report, don't fix** — for import path mismatches, report the differences. The user decides whether to adapt the skill or the target.
