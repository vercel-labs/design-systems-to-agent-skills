# Architecture

## Design Principles

### 1. Session isolation via disk

Every stage reads inputs from `context/{ds}/` and writes outputs there. No stage depends on conversation history from a previous stage. Any stage can start in a fresh session by reading state from disk.

### 2. Interview-first, read-later

Stage 1 asks about design decisions without reading source code deeply. Stage 2 does the extraction. This keeps the interview lightweight on context and prevents burning significant context budget on codebase research before a single decision is made.

### 3. Thin orchestrator

Stage 4's orchestrator dispatches batches, updates a progress file, and ends the session. It does not accumulate monitoring logs, extraction output, or stale notification responses in its context.

### 4. Verification is code, not agents

Stage 6 is a shell script, not an agent task. Import paths, structural requirements, and file completeness are checked mechanically. Agent-based verification inherits the same hallucination risks as generation — a script catches errors deterministically.

### 5. Progress file as state machine

`stage4-progress.md` tracks completed and pending components, extraction issues, and batch numbers. Written to disk after every batch. Survives session boundaries, context limits, and crashes.

### 6. Asset catalogs as hallucination defense

Models hallucinate asset names — icons, logos, illustrations — even when correct import patterns are in context. The specific name is guessed from training data. Asset catalogs (exhaustive name-to-import-path lookup tables) eliminate this by giving agents a complete enumeration to search.

Stage 5 handles asset catalogs separately from component documentation because:
- Components need AI interpretation (props, behavior, composition patterns)
- Assets are flat name registries — the only question is "does this name exist?"
- A shell script can extract names deterministically from TypeScript arrays
- No PRD, no batching, no multi-session cycling — one pass produces the catalog

### 7. Multi-file PRD for selective loading

The PRD is a directory of 5 files (`context/{ds}/03-closed-prd/`) rather than a monolithic document. This enables two things:

1. **Session-friendly generation:** Each file is a clean checkpoint. For large design systems, the PRD can be generated across multiple sessions without needing a resume protocol within a single file.
2. **Selective loading in Stage 4:** Component batches only load the subagent template and wave plan — not the full file manifest, content structure, or success criteria. This keeps context usage low during the heaviest phase.

Stage 4 handles any number of components without run splitting. The loop script (`generate-loop.sh`) spawns a fresh session per batch, and each session loads only the PRD files and verified facts needed for its 8 components.

## Pipeline Overview

```
Stage 1         Stage 2         Stage 3         Stage 4         Stage 5       Stage 6
Interview       Extract         PRD             Generate        Assets        Verify
   │               │               │               │               │            │
   ▼               ▼               ▼               ▼               ▼            ▼
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌────────────┐  ┌─────────┐  ┌─────────┐
│ Scope   │  │ Read    │  │ Plan   │  │Write skill │  │ Catalog │  │ Check  │
│ decis-  │─▶│ source  │─▶│ every  │─▶│ files in   │─▶│ icons,  │─▶│ output │
│ ions    │  │ code    │  │ file   │  │ batches    │  │ logos   │  │ mech-  │
│         │  │         │  │        │  │ of 8       │  │ etc.    │  │ anical │
└─────────┘  └─────────┘  └─────────┘  └────────────┘  └─────────┘  └─────────┘
      │            │            │              │              │            │
      ▼            ▼            ▼              ▼              ▼            ▼
01-decisions 02-verified- 03-closed-     skills/{ds}/    assets/     verification
   .md       facts/         prd/        + progress file  catalogs      report

◄──── Can share one session ────►  ◄─ Fresh per batch ─►  ◄─── No session ──►
```

## Context Budget

| Stage | Context Usage | Session Strategy |
|---|---|---|
| 1: Interview | ~15% | Can share with Stages 2-3 |
| 2: Extraction | ~25% | Can share with Stages 1, 3 |
| 3: PRD | ~10% incremental | Can share with Stages 1-2 |
| 4: Generation | ~12% per batch | **Fresh session per batch** |
| 5: Assets | ~5% (mechanical) | Can share or run standalone |
| 6: Verification | 0% (shell script) | No agent session needed |

Stages 1-3 fit in one session (~50% total). Stage 4 gets a fresh session with full context budget. Stage 5 is lightweight — script-assisted extraction with minimal AI interpretation. Stage 6 runs outside any agent session.

## Comparison

| Approach | Import accuracy | Maintenance cost | Agent dependency |
|---|---|---|---|
| Hand-crafted docs | High (manual review) | High (manual updates) | None |
| One-shot agent generation | Low (hallucination-prone) | Low (regenerate) | High |
| **This pipeline** | High (verified from source) | Low (re-run pipeline) | Low (agent-agnostic) |

The pipeline combines the accuracy of source-verified information with the automation of agent-based generation. The key difference from one-shot generation: facts are extracted in a separate stage and written to disk before any skill content is generated, creating a verifiable checkpoint.
