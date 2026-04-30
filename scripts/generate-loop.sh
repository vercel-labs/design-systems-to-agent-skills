#!/bin/bash
# =============================================================================
# generate-loop.sh — Automate Stage 4 batch-per-session loop
# =============================================================================
#
# Stage 4 processes components in batches of 8, with each batch requiring a
# fresh agent session to avoid context accumulation. This script replaces the
# manual "end session → restart → run Stage 4" cycle by spawning a fresh
# agent process per batch.
#
# Each iteration:
#   1. Checks stage4-progress.md for remaining work
#   2. Spawns a fresh agent instance that runs Stage 4
#   3. Agent reads progress file, runs ONE batch, commits, then exits
#   4. Script validates a commit was made, then loops
#
# Usage:
#   ./scripts/generate-loop.sh [options]
#
# Options:
#   --ds <name>         Design system name (default: auto-detect from context/)
#   --max <N>           Maximum iterations / safety limit (default: 20)
#   --dry-run           Show what would run without executing
#   --agent <cmd>       Agent CLI command (default: "claude -p")
#   --unattended        Run without permission prompts (maps to agent-specific flags)
#
# Agent command examples:
#   --agent "claude -p"              # Claude Code (default)
#   --agent "codex --prompt"         # Codex CLI
#   --agent "opencode --prompt"      # OpenCode
#   --agent "your-agent --prompt"    # Any CLI agent
#
# Requires:
#   - Your agent CLI installed and configured
#   - Git repo with context/{ds}/03-closed-prd.md (Stage 3 complete)

set -e

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

DS_NAME=""
MAX_ITERATIONS=20
DRY_RUN=""
AGENT_CMD="claude -p"
UNATTENDED=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ds)
      DS_NAME="$2"
      shift 2
      ;;
    --max)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --agent)
      AGENT_CMD="$2"
      shift 2
      ;;
    --unattended)
      UNATTENDED=1
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: $0 [--ds <name>] [--max <N>] [--dry-run] [--agent <cmd>] [--unattended]"
      exit 1
      ;;
  esac
done

# =============================================================================
# PROJECT DETECTION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

if ! git rev-parse --git-dir &>/dev/null; then
  echo "ERROR: $PROJECT_ROOT is not a git repository."
  exit 1
fi

# Auto-detect design system if not specified
if [[ -z "$DS_NAME" ]]; then
  for dir in context/*/; do
    name="$(basename "$dir")"
    if [[ -f "context/$name/03-closed-prd.md" ]]; then
      DS_NAME="$name"
      break
    fi
  done
  if [[ -z "$DS_NAME" ]]; then
    echo "ERROR: No design system found in context/. Use --ds <name>."
    exit 1
  fi
fi

PROGRESS_FILE="context/$DS_NAME/stage4-progress.md"

# =============================================================================
# BUILD AGENT COMMAND
# =============================================================================

# The prompt content — tells the agent to run Stage 4 for the specific DS
STAGE4_PROMPT="Run Stage 4 of the design system skill generation pipeline for $DS_NAME. Read the progress file and PRD from disk, execute the next batch, commit, then exit."

# If --unattended, append agent-specific flags
AGENT_EXTRA_ARGS=""
if [[ -n "$UNATTENDED" ]]; then
  case "$AGENT_CMD" in
    claude*)
      AGENT_EXTRA_ARGS="--dangerously-skip-permissions"
      ;;
    *)
      # Generic: no standard flag, agent must handle unattended mode
      echo "NOTE: --unattended has no standard mapping for '$AGENT_CMD'."
      echo "  Your agent may prompt for permissions during execution."
      ;;
  esac
fi

# =============================================================================
# PREFLIGHT CHECKS
# =============================================================================

echo "========================================="
echo "DS Generate Loop"
echo "========================================="
echo "  Project:    $PROJECT_ROOT"
echo "  DS:         $DS_NAME"
echo "  Progress:   $PROGRESS_FILE"
echo "  Max iters:  $MAX_ITERATIONS"
echo "  Agent:      $AGENT_CMD"

# Check agent CLI exists (first word of AGENT_CMD)
AGENT_BIN=$(echo "$AGENT_CMD" | awk '{print $1}')
if ! command -v "$AGENT_BIN" &>/dev/null; then
  echo "ERROR: '$AGENT_BIN' not found. Install your agent CLI first."
  exit 1
fi
echo "  Agent CLI:  OK"

if [[ ! -f "context/$DS_NAME/03-closed-prd.md" ]]; then
  echo "ERROR: context/$DS_NAME/03-closed-prd.md not found."
  echo "  Stage 3 (PRD) must be complete before running Stage 4."
  exit 1
fi
echo "  PRD:        OK"

# Check for dirty working tree
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  echo "WARNING: Working tree has uncommitted changes."
  echo "  Stage 4 commits after each batch. Uncommitted changes may cause conflicts."
  echo "  Consider committing or stashing first."
  echo ""
fi

echo "========================================="
echo ""

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

is_stage4_complete() {
  if [[ ! -f "$PROGRESS_FILE" ]]; then
    return 1
  fi
  if grep -qi "## Status:.*Complete" "$PROGRESS_FILE" 2>/dev/null; then
    if grep -q "\- \[ \]" "$PROGRESS_FILE" 2>/dev/null; then
      return 1
    fi
    return 0
  fi
  if ! grep -q "\- \[ \]" "$PROGRESS_FILE" 2>/dev/null; then
    return 0
  fi
  return 1
}

count_remaining() {
  if [[ -f "$PROGRESS_FILE" ]]; then
    grep -c "\- \[ \]" "$PROGRESS_FILE" 2>/dev/null || echo "0"
  else
    echo "unknown"
  fi
}

count_completed() {
  if [[ -f "$PROGRESS_FILE" ]]; then
    grep -c "\- \[x\]" "$PROGRESS_FILE" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

notify() {
  local message="$1"
  echo "$message"
  # macOS notification (harmless on other platforms)
  osascript -e "display notification \"$message\" with title \"DS Generate Loop\"" 2>/dev/null || true
}

# =============================================================================
# MAIN LOOP
# =============================================================================

if is_stage4_complete; then
  echo "Stage 4 is already complete for $DS_NAME."
  echo "  Completed: $(count_completed) items"
  echo "  Remaining: 0"
  exit 0
fi

TOTAL_BATCHES_RUN=0

for ((i=1; i<=MAX_ITERATIONS; i++)); do
  echo "========================================="
  echo "Iteration $i of $MAX_ITERATIONS"
  echo "========================================="

  REMAINING=$(count_remaining)
  COMPLETED=$(count_completed)
  echo "  Progress: $COMPLETED done, $REMAINING remaining"

  # Pre-iteration snapshot
  COMMIT_BEFORE=$(git rev-parse HEAD 2>/dev/null || echo "")
  PROGRESS_HASH_BEFORE=""
  if [[ -f "$PROGRESS_FILE" ]]; then
    PROGRESS_HASH_BEFORE=$(shasum "$PROGRESS_FILE" | awk '{print $1}')
  fi

  if [[ -n "$DRY_RUN" ]]; then
    echo "  [DRY RUN] Would spawn: $AGENT_CMD \"$STAGE4_PROMPT\""
    echo "  [DRY RUN] Skipping."
    continue
  fi

  # -------------------------------------------------------------------------
  # Spawn fresh agent instance
  # -------------------------------------------------------------------------
  echo "  Spawning agent (batch iteration $i)..."
  echo ""

  set +e
  # shellcheck disable=SC2086
  $AGENT_CMD "$STAGE4_PROMPT" $AGENT_EXTRA_ARGS 2>&1 | tee /tmp/ds-generate-output.txt
  exit_code=${PIPESTATUS[0]}
  set -e

  if [[ $exit_code -ne 0 ]]; then
    echo ""
    echo "ERROR: Agent exited with code $exit_code on iteration $i."
    notify "DS Generate Loop failed on iteration $i (exit $exit_code)"
    exit 1
  fi

  TOTAL_BATCHES_RUN=$((TOTAL_BATCHES_RUN + 1))

  # -------------------------------------------------------------------------
  # Post-iteration validation
  # -------------------------------------------------------------------------
  COMMIT_AFTER=$(git rev-parse HEAD 2>/dev/null || echo "")
  PROGRESS_HASH_AFTER=""
  if [[ -f "$PROGRESS_FILE" ]]; then
    PROGRESS_HASH_AFTER=$(shasum "$PROGRESS_FILE" | awk '{print $1}')
  fi

  echo ""
  echo "  Post-iteration:"

  if [[ "$PROGRESS_HASH_BEFORE" == "$PROGRESS_HASH_AFTER" ]]; then
    echo "  WARNING: Progress file unchanged. Agent may not have processed a batch."
    echo "  Stopping to avoid infinite loop."
    notify "DS Generate Loop stopped — no progress on iteration $i"
    break
  fi
  echo "  Progress file: updated"

  if [[ "$COMMIT_BEFORE" == "$COMMIT_AFTER" ]]; then
    echo "  WARNING: No new commit. Auto-committing..."
    git add -A
    git commit -m "$DS_NAME generate: auto-commit iteration $i (loop-enforced)" 2>/dev/null || true
    COMMIT_AFTER=$(git rev-parse HEAD 2>/dev/null || echo "")
  fi
  echo "  HEAD: ${COMMIT_BEFORE:0:8} → ${COMMIT_AFTER:0:8}"

  REMAINING_AFTER=$(count_remaining)
  COMPLETED_AFTER=$(count_completed)
  echo "  Progress: $COMPLETED_AFTER done, $REMAINING_AFTER remaining"

  if is_stage4_complete; then
    echo ""
    echo "========================================="
    echo "Stage 4 COMPLETE for $DS_NAME"
    echo "========================================="
    echo "  Batches run this session: $TOTAL_BATCHES_RUN"
    echo "  Total components: $COMPLETED_AFTER"
    notify "DS Generate Loop complete — $COMPLETED_AFTER components in $TOTAL_BATCHES_RUN batches"
    exit 0
  fi

  echo ""
  echo "  Batch done. Looping to next iteration..."
  sleep 2
done

echo ""
echo "========================================="
echo "Reached max iterations ($MAX_ITERATIONS)."
echo "  Batches run: $TOTAL_BATCHES_RUN"
echo "  Remaining:   $(count_remaining)"
echo "  Check $PROGRESS_FILE for status."
echo "========================================="
notify "DS Generate Loop hit max iterations ($MAX_ITERATIONS). $(count_remaining) items remain."
