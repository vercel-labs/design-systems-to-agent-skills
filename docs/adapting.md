# Adapting to Different Agent Runtimes

The pipeline commands are plain markdown files with no runtime-specific syntax. Any agent that can read files, write files, and run shell commands can use them.

## Required Capabilities

| Capability | Used in | Required? |
|---|---|---|
| File read | All stages | Yes |
| File write | All stages | Yes |
| Shell commands | Stages 2, 4, 5 (git, mkdir) | Yes |
| User interaction | Stage 1 (interview) | Yes |
| Sub-agent spawning | Stages 2, 4 (parallel batches) | Recommended, not required |

## Optional Capabilities

**Sub-agent spawning** improves speed in Stages 2 and 4 by processing components in parallel. If your agent doesn't support sub-agents, the pipeline still works — you just run extractions and generations serially (one component at a time). See "Without sub-agents" below.

## Runtime-Specific Notes

### Claude Code

Claude Code has native support for all pipeline features:
- Install commands as slash commands in `.claude/commands/ds/`
- Sub-agents via the Task tool with `run_in_background: true`
- Use `/clear` between Stage 4 batches for fresh sessions, or use `generate-loop.sh`
- The `--dangerously-skip-permissions` flag enables unattended batch runs

```bash
# Installation
mkdir -p .claude/commands/ds
cp commands/1-interview.md .claude/commands/ds/interview.md
cp commands/2-extract.md .claude/commands/ds/extract.md
cp commands/3-prd.md .claude/commands/ds/prd.md
cp commands/4-generate.md .claude/commands/ds/generate.md

# Usage
/ds:interview /path/to/source
/ds:extract
/ds:prd
/ds:generate
```

### Codex CLI

Codex CLI supports sub-agent dispatching and can process batches in parallel:

```bash
# Pass command content as prompt
codex --prompt "$(cat commands/1-interview.md)" "Source: /path/to/ds"
codex --prompt "$(cat commands/2-extract.md)"
codex --prompt "$(cat commands/3-prd.md)"
codex --prompt "$(cat commands/4-generate.md)"

# Automated batch loop
./scripts/generate-loop.sh --agent "codex --prompt" --ds your-ds
```

### OpenCode

Copy commands to `.opencode/commands/` or pass as prompts. OpenCode supports sub-agents for parallel processing.

### Aider

Aider doesn't support sub-agent spawning. Use `/read` to load commands as context:

```
/read commands/1-interview.md
```

For Stages 2 and 4, the agent processes components serially. See "Without sub-agents" below.

### Generic Agent

Any agent that accepts a system prompt or instruction file can use the pipeline:

```bash
your-agent --system-prompt "$(cat commands/1-interview.md)"
```

## Customizing Commands

The command files are designed to be modified. Common customizations:

### Adding runtime-specific features

If your agent has capabilities beyond the generic commands (e.g., special file watching, built-in progress tracking), add them to the relevant command file. The core logic is preserved.

### Changing commit messages

The commit message format (`{DS} extract: batch N (...)`) can be changed to match your team's conventions.

### Adjusting batch size

The default batch size of 8 can be lowered for complex design systems. Edit the batch size references in `commands/2-extract.md` and `commands/4-generate.md`.

### Modifying the sub-agent prompt

The sub-agent prompt template in the PRD (Stage 3) controls the quality of generated output. If you find consistent issues (e.g., missing sections, wrong formatting), modify the template in `commands/3-prd.md` Section 5.

## Without Sub-Agents

If your agent doesn't support parallel sub-agent dispatching, Stages 2 and 4 can run serially:

### Stage 2 (Extract) — Serial Mode

Instead of dispatching 8 sub-agents per batch, process one component at a time:

1. Read the sub-agent prompt template from the command file
2. For each component in the in-scope list:
   a. Read the component's source files
   b. Extract facts following the template
   c. Write to `context/{ds}/02-verified-facts/components/{name}.md`
   d. Move to the next component
3. After every 8 components, commit the batch

This takes longer but produces identical output. The quality depends on the extraction prompt, not the parallelism.

### Stage 4 (Generate) — Serial Mode

Instead of dispatching sub-agents, generate one component at a time:

1. Load the PRD and verified facts
2. For each component in the current batch:
   a. Read the component's verified facts file
   b. Look up the import path in `imports.md`
   c. Generate `api.md` and `examples/` files following the PRD template
   d. Write to the versioned output path
3. After each batch of 8, commit and end the session

The one-batch-per-session rule still applies — context accumulation is the constraint, not parallelism.

### Stage 4 (Generate) — Fully Serial, No Session Cycling

If your agent also doesn't support session cycling (you can't easily start fresh sessions), you can process ALL components in one session with these adjustments:

1. Lower batch size to 4 instead of 8
2. Commit after each component (not each batch)
3. Monitor context usage carefully
4. Accept that quality may degrade for components processed late in the session

This is the least-recommended approach. Use it only as a last resort.
