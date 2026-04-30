# Architecture

## Design Principles

### 1. Session isolation via disk

Every stage reads inputs from `context/{ds}/` and writes outputs there. No stage depends on conversation history from a previous stage. Any stage can start in a fresh session by reading state from disk.

### 2. Interview-first, read-later

Stage 1 asks about design decisions without reading source code deeply. Stage 2 does the extraction. This keeps the interview lightweight on context and prevents burning significant context budget on codebase research before a single decision is made.

### 3. Thin orchestrator

Stage 4's orchestrator dispatches batches, updates a progress file, and ends the session. It does not accumulate monitoring logs, extraction output, or stale notification responses in its context.

### 4. Verification is code, not agents

Stage 5 is a shell script, not an agent task. Import paths, structural requirements, and file completeness are checked mechanically. Agent-based verification inherits the same hallucination risks as generation — a script catches errors deterministically.

### 5. Progress file as state machine

`stage4-progress.md` tracks completed and pending components, extraction issues, and batch numbers. Written to disk after every batch. Survives session boundaries, context limits, and crashes.

### 6. Multi-run by design for large design systems

A single Stage 4 run can reliably process ~40-50 components before context accumulation degrades output quality. Design systems with more than 50 components require multiple runs planned upfront in the PRD, not discovered mid-session.

The split happens at the PRD level: Stages 1-3 cover ALL components. The PRD includes a run plan that groups components into runs of 40-50. Each run gets a fresh Stage 4 session.

## Pipeline Overview

```
Stage 1            Stage 2            Stage 3            Stage 4            Stage 5
Interview          Extract            PRD                Generate           Verify
   │                  │                  │                  │                  │
   ▼                  ▼                  ▼                  ▼                  ▼
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────────┐   ┌──────────┐
│ Scope    │   │ Read     │   │ Plan     │   │ Write skill  │   │ Check    │
│ decisions│──▶│ source   │──▶│ every    │──▶│ files in     │──▶│ output   │
│ with user│   │ code     │   │ file     │   │ batches of 8 │   │ mechani- │
│          │   │          │   │          │   │              │   │ cally    │
└──────────┘   └──────────┘   └──────────┘   └──────────────┘   └──────────┘
      │              │              │                │                │
      ▼              ▼              ▼                ▼                ▼
01-decisions   02-verified-   03-closed-       skills/{ds}/     verification
   .md         facts/           prd.md         + progress file    report

◄──── Can share one session ────►  ◄─ Fresh session ─►  ◄── No session ──►
```

## Context Budget

| Stage | Context Usage | Session Strategy |
|---|---|---|
| 1: Interview | ~15% | Can share with Stages 2-3 |
| 2: Extraction | ~25% | Can share with Stages 1, 3 |
| 3: PRD | ~10% incremental | Can share with Stages 1-2 |
| 4: Generation | ~12% per batch | **Fresh session per batch** |
| 5: Verification | 0% (shell script) | No agent session needed |

Stages 1-3 fit in one session (~50% total). Stage 4 gets a fresh session with full context budget. Stage 5 runs outside any agent session.

## Comparison

| Approach | Import accuracy | Maintenance cost | Agent dependency |
|---|---|---|---|
| Hand-crafted docs | High (manual review) | High (manual updates) | None |
| One-shot agent generation | Low (hallucination-prone) | Low (regenerate) | High |
| **This pipeline** | High (verified from source) | Low (re-run pipeline) | Low (agent-agnostic) |

The pipeline combines the accuracy of source-verified information with the automation of agent-based generation. The key difference from one-shot generation: facts are extracted in a separate stage and written to disk before any skill content is generated, creating a verifiable checkpoint.
