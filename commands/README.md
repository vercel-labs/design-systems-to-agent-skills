# Pipeline Commands — Installation Guide

The 4 `.md` files in this directory are agent prompts. Each file contains the full instructions for one pipeline stage. Your agent reads the file and follows the instructions.

## Files

| File | Stage | What it does |
|---|---|---|
| `1-interview.md` | Stage 1 | Interviews the user about design system scope |
| `2-extract.md` | Stage 2 | Extracts verified facts from source code |
| `3-prd.md` | Stage 3 | Generates a closed PRD with zero open questions |
| `4-generate.md` | Stage 4 | Generates skill files in parallel batches |

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
```

Then invoke as slash commands:
```
/ds:interview /path/to/design-system
/ds:extract
/ds:prd
/ds:generate
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

## Automation

For Stage 4, which requires running one batch per fresh session, use the automation script:

```bash
./scripts/generate-loop.sh --ds your-design-system
```

This script spawns a fresh agent process per batch, validates progress between iterations, and auto-commits. See the script for configuration options including how to set your agent command.
