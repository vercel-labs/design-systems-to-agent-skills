# DS Skills Pipeline

A pipeline that transforms design systems into structured skill files any CLI-based coding agent can use.

## Why

Coding agents hallucinate token names, invent icons that don't exist, and get import paths wrong. These failures happen because agents generate design system knowledge from training data instead of reading it from source code.

This pipeline extracts verified facts from your design system's actual source code and generates structured references that prevent these failures. Every token is enumerated. Every icon is cataloged. Every import path is validated against the package's export map.

## How It Works

The pipeline has 5 stages. Each stage produces a persisted artifact on disk. Stages are session-isolated — any stage can start in a fresh agent session by reading state from disk.

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Stage 1  │     │ Stage 2  │     │ Stage 3  │     │ Stage 4  │     │ Stage 5  │
│Interview │────▶│ Extract  │────▶│   PRD    │────▶│ Generate │────▶│  Verify  │
│          │     │          │     │          │     │          │     │          │
│ Scope    │     │ Read     │     │ Plan     │     │ Write    │     │ Check    │
│ decisions│     │ source   │     │ every    │     │ skill    │     │ output   │
│ with user│     │ code     │     │ file     │     │ files    │     │ mechan-  │
│          │     │          │     │          │     │          │     │ ically   │
└──────────┘     └──────────┘     └──────────┘     └──────────┘     └──────────┘
      │                │                │                │                │
      ▼                ▼                ▼                ▼                ▼
 01-decisions    02-verified-      03-closed-       skills/{ds}/    verification
    .md          facts/              prd.md         (all files)       report
```

| Stage | What it does | Output |
|---|---|---|
| 1. Interview | Asks the user scoping questions about the design system | `01-decisions.md` |
| 2. Extract | Reads source code and extracts verified facts per component | `02-verified-facts/` (per-component files) |
| 3. PRD | Generates a closed spec for every file to create (zero open questions) | `03-closed-prd.md` |
| 4. Generate | Produces skill files in parallel batches of 8, one batch per session | `skills/{ds}/` |
| 5. Verify | Runs a shell script to catch import errors, missing files, structural issues | Verification report |

## Quickstart

### 1. Get the pipeline

```bash
git clone https://github.com/your-org/ds-skills-pipeline.git
cd ds-skills-pipeline
```

Or copy just the `commands/` directory into your existing project.

### 2. Install the commands for your agent runtime

See [`commands/README.md`](commands/README.md) for setup instructions per runtime (Claude Code, Codex CLI, OpenCode, Aider, or any generic agent).

### 3. Run Stage 1 (Interview)

Point the interview command at your design system's source code:

```
# Example with Claude Code
/ds:interview /path/to/your-design-system

# Example with Codex CLI
codex --prompt "$(cat commands/1-interview.md)" "Source: /path/to/your-design-system"
```

The agent will ask you scoping questions one at a time. Decisions are written to disk after each answer.

### 4. Follow the pipeline

Run each subsequent stage in order. The commands tell the agent exactly what to do:

```
Stage 2: Extract verified facts from source code
Stage 3: Generate the closed PRD
Stage 4: Generate skill files (one batch per session)
Stage 5: Run verify-skills.sh (no agent session needed)
```

Each stage reads its inputs from disk, so you can start a fresh agent session between stages.

### Automating Stage 4 with the loop script

Stage 4 generates components in batches of 8, with each batch requiring a fresh agent session to avoid context window accumulation. For design systems with many components, the manual cycle (clear session → re-run generate → wait → repeat) gets tedious.

The `ds-generate-loop.sh` script automates this by spawning a fresh `claude -p` process per batch:

```bash
./scripts/ds-generate-loop.sh --ds myds --max 25 --skip-permissions
```

Each iteration: spawn fresh Claude → Claude reads progress file → runs one batch → commits → exits → script validates progress → loops.

The script requires two flags on the Claude invocation:
- **DS name in the prompt** (`/ds:generate $DS_NAME`) — without it, Claude may auto-detect the wrong design system from `context/`
- **`--max-turns 15`** — ensures Claude has enough turns to complete the full batch cycle (dispatch subagents → process results → update progress → commit). Without this, Claude exits mid-batch after dispatching subagents but before the post-batch bookkeeping.

Options:
- `--ds <name>` — design system name (auto-detected from `context/` if omitted)
- `--max <N>` — safety limit on iterations (default: 20)
- `--skip-permissions` — adds `--dangerously-skip-permissions` for fully unattended runs
- `--dry-run` — shows what would run without executing

## Output

The pipeline generates a structured skill file hierarchy:

```
skills/{ds}/
├── SKILL.md                              # Entry point + routing matrix
├── references/
│   └── {ds}/v1/
│       ├── index.md                      # Component catalog
│       ├── components.md                 # Categorized reference
│       ├── guides/                       # Tokens, imports, setup, etc.
│       └── components/{name}/{platform}/
│           ├── api.md                    # Props, types, anti-patterns
│           └── examples/                 # Numbered usage examples
│               ├── 01-basic-usage.md
│               └── 02-common-patterns.md
```

See [`example/`](example/) for a complete 3-component demo and [`docs/output-structure.md`](docs/output-structure.md) for the full specification.

## Agent Compatibility

The pipeline works with any agent that can read/write files, run shell commands, and follow multi-step instructions. Sub-agent spawning is recommended for Stages 2 and 4 but not required.

| Runtime | Status | Sub-agents | Notes |
|---|---|---|---|
| Claude Code | Tested | Yes (Task tool) | Install as slash commands |
| Codex CLI | Expected | Yes | Pass command files as `--prompt` |
| OpenCode | Expected | Yes | Copy to `.opencode/commands/` |
| Aider | Expected | No | Pass as `/read` or system prompt; run Stages 2/4 serially |
| Generic | Expected | Varies | Any agent that accepts a system prompt |

See [`docs/adapting.md`](docs/adapting.md) for runtime-specific instructions and how to run without sub-agents.

## Requirements

Your agent runtime must support:
- **File read/write** — reading source code, writing output files
- **Shell command execution** — running git commits, verification scripts
- **User interaction** — answering interview questions (Stage 1)

Recommended:
- **Sub-agent spawning** — parallel extraction (Stage 2) and generation (Stage 4) run faster with sub-agents, but can run serially without them

## Documentation

- [`docs/architecture.md`](docs/architecture.md) — Design principles and pipeline overview
- [`docs/stages.md`](docs/stages.md) — Detailed stage-by-stage reference
- [`docs/context-management.md`](docs/context-management.md) — Context window rules and batch sizing
- [`docs/output-structure.md`](docs/output-structure.md) — What the pipeline produces
- [`docs/adapting.md`](docs/adapting.md) — How to use with different agent runtimes

## License

MIT
