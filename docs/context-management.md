# Context Management

Rules for managing agent context windows across pipeline stages. These rules exist to prevent quality degradation from context accumulation.

## Batch size ceiling

**8 components maximum per batch** for Stages 2 (extraction) and 4 (generation). Each sub-agent's work (reading source files, generating output) consumes context. With 8 sub-agents, the orchestrator's overhead for dispatching, polling, and committing is ~12% of the context window. Larger batches push this higher and leave less room for the sub-agent prompt content.

Smaller batches are fine. If components are complex (30+ props, compound structures, responsive patterns), consider batches of 4-6.

## One batch per session

For Stage 4 (generation), each component batch should run in a **fresh agent session**. Context accumulates faster than expected:

- Batch 1: ~12% context usage
- Batch 2 (same session): ~28% cumulative
- Batch 3 (same session): ~48% cumulative
- Batch 4 (same session): approaching context limits

By Batch 3-4 in the same session, the agent may start hallucinating import paths, dropping props from tables, or generating incomplete examples — even though the correct information is in the sub-agent prompt.

A fresh session starts at 0% and loads only what it needs from disk.

## Progress file protocol

Externalize state to disk. Every batch updates the progress file. Fresh sessions resume from it.

The progress file (`context/{ds}/stage4-progress.md`) tracks:
- Overall status (In Progress / Complete)
- Which run is active (for multi-run design systems)
- Checkbox list of all files, grouped by wave and batch
- Issues encountered

After every batch:
1. Mark completed items with `[x]`
2. Note any issues in the Issues section
3. Commit the progress file alongside the generated files

The next session reads the progress file and skips completed work automatically.

## 50-component session ceiling

Design systems with more than 50 in-scope components should be split into multiple Stage 4 runs. This split is planned upfront during Stage 1 (interview) and encoded in Stage 3 (PRD).

Stages 1-3 (interview, extraction, PRD) still cover ALL components — only Stage 4 generation is split.

Recommended grouping: by category (all form components in one run, all layout/navigation in another). This improves context coherence within each run.

## Verification is code, not agents

Use the `scripts/verify-skills.sh` script to check generated output — not an agent. Agent-based verification inherits the same hallucination risks as generation. A script catches mechanical errors deterministically: wrong import paths, missing file sections, absent 'use client' directives.

## Don't read sub-agent transcripts

When sub-agents write directly to disk, the orchestrator only needs to verify the files exist. Checking file existence on disk is cheap. Reading full sub-agent transcripts (which contain all the source code reads, type parsing, and generation work) bloats the orchestrator's context significantly.

Pattern:
```bash
# Good: check file exists
[ -s "context/{ds}/02-verified-facts/components/{name}.md" ] && echo "done"

# Bad: read sub-agent output back into the orchestrator
# (This consumes context proportional to the sub-agent's entire work)
```

## Stage context budgets

| Stage | Context budget | What consumes it |
|---|---|---|
| Stage 1 (Interview) | ~15% | High-level file reads, interview conversation |
| Stage 2 (Extract) | ~25% | Batch dispatching, file existence polling, committing |
| Stage 3 (PRD) | ~10% | Summary file reads, PRD writing |
| Stage 4 (Generate) | ~12% per batch | PRD loading, verified facts per batch, sub-agent dispatching |
| Stage 5 (Verify) | 0% | Shell script, no agent |

These are approximate. Actual usage depends on design system size, component complexity, and agent runtime.
