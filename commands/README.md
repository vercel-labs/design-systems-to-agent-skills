# Pipeline Commands — Installation Guide

The 6 `.md` files in this directory are agent prompts (5 stages + 1 utility). Each file contains the full instructions for one pipeline stage or utility. Your agent reads the file and follows the instructions. (Stage 6: Verify is a shell script, not an agent command — see `scripts/verify-skills.sh`.)

## Files

| File | Stage | What it does |
|---|---|---|
| `1-interview.md` | Stage 1 | Interviews the user about design system scope |
| `2-extract.md` | Stage 2 | Extracts verified facts from source code |
| `3-prd.md` | Stage 3 | Generates a closed PRD with zero open questions |
| `4-generate.md` | Stage 4 | Generates skill files in parallel batches |
| `5-assets.md` | Stage 5 | Generates exhaustive asset catalogs (icons, logos, etc.) |

### Utilities

| File | What it does |
|---|---|
| `port.md` | Ports a generated skill to a target codebase (runs in target repo) |

## Installation by Runtime

### Claude Code

Copy the command files into your project's Claude Code commands directory:

```bash
mkdir -p .claude/commands/ds
cp commands/*.md .claude/commands/ds/

# Rename to match slash-command convention
mv .claude/commands/ds/1-interview.md .claude/commands/ds/interview.md
mv .claude/commands/ds/2-extract.md .claude/commands/ds/extract.md
mv .claude/commands/ds/3-prd.md .claude/commands/ds/prd.md
mv .claude/commands/ds/4-generate.md .claude/commands/ds/generate.md
mv .claude/commands/ds/5-assets.md .claude/commands/ds/assets.md
cp commands/port.md .claude/commands/ds/port.md
```

Then invoke as slash commands:
```
/ds:interview /path/to/design-system
/ds:extract
/ds:prd
/ds:generate
/ds:assets
/ds:port /path/to/skills/your-design-system
```

### Codex CLI

Pass the command file content as the prompt:

```bash
# Stage 1 — interactive, needs user input
codex --prompt "$(cat commands/1-interview.md)" "Source: /path/to/design-system"

# Stage 2 — can run with less interaction
codex --prompt "$(cat commands/2-extract.md)"

# Stage 3
codex --prompt "$(cat commands/3-prd.md)"

# Stage 4 — run once per batch, fresh process each time
codex --prompt "$(cat commands/4-generate.md)"

# Stage 5 — asset catalogs
codex --prompt "$(cat commands/5-assets.md)"

# Port — deploy to target repo (run from target repo)
codex --prompt "$(cat /path/to/pipeline/commands/port.md)" "/path/to/skills/your-design-system"
```

### OpenCode

Copy to your OpenCode commands directory:

```bash
mkdir -p .opencode/commands/ds
cp commands/*.md .opencode/commands/ds/
```

Or pass as a prompt to the CLI.

### Aider

Use `/read` to load the command as context:

```
/read commands/1-interview.md
```

Note: Aider doesn't support sub-agent spawning. For Stages 2 and 4, the agent will need to process components serially instead of in parallel batches. See [docs/adapting.md](../docs/adapting.md) for the serial workflow.

### Generic / Any Agent

The command content IS the prompt — feed it to any agent that accepts a system prompt or instruction file. The commands are plain markdown with no runtime-specific syntax.

```bash
# Example: pipe to any CLI agent
your-agent --system-prompt "$(cat commands/1-interview.md)"

# Example: use as a context file
your-agent --context commands/1-interview.md
```

## Using the Port Command

The port command is different from pipeline stages — it runs in the **target repo**, not the pipeline repo. It takes the path to a generated skill as its argument.

### Claude Code

From the target repo:
```
/ds:port /path/to/ds-skills-pipeline/skills/geistcn
```

The port command must be installed in the target repo's commands directory (not just the pipeline repo). Copy it during setup:
```bash
# In the target repo
mkdir -p .claude/commands/ds
cp /path/to/ds-skills-pipeline/commands/port.md .claude/commands/ds/port.md
```

### Codex CLI

From the target repo:
```bash
codex --prompt "$(cat /path/to/ds-skills-pipeline/commands/port.md)" "/path/to/skills/geistcn"
```

### OpenCode

Copy `port.md` to the target repo's commands directory:
```bash
# In the target repo
mkdir -p .opencode/commands/ds
cp /path/to/ds-skills-pipeline/commands/port.md .opencode/commands/ds/port.md
```

### Generic / Any Agent

From the target repo:
```bash
your-agent --system-prompt "$(cat /path/to/ds-skills-pipeline/commands/port.md)" "/path/to/skills/geistcn"
```

The command discovers the target's conventions (skill directory, frontmatter format, settings file, import patterns), reconciles differences, copies the skill, and verifies the deployment. It will ask for confirmation before changing import paths.

## Automation

For Stage 4, which requires running one batch per fresh session, use the automation script:

```bash
./scripts/generate-loop.sh --ds your-design-system
```

This script spawns a fresh agent process per batch, validates progress between iterations, and auto-commits. See the script for configuration options including how to set your agent command.
