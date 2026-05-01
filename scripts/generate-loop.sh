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
#   3. Agent dispatches subagents to generate component files
#   4. Script detects newly created component dirs and updates progress file
#   5. Script auto-commits everything (generated files + updated progress)
#   6. Loop continues until all components are done
#
# Host-side bookkeeping: the script owns progress updates and commits,
# so the loop works even if the agent exits before post-batch steps.
#
# Usage:
#   ./scripts/generate-loop.sh [options]
#
# Options:
#   --ds <name>         Design system name (default: auto-detect from context/)
#   --max <N>           Maximum iterations / safety limit (default: 20)
#   --max-turns <N>     Agent --max-turns per iteration (default: 50, Claude-specific)
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
#   - Git repo with context/{ds}/03-closed-prd/ or 03-closed-prd.md (Stage 3 complete)

set -e

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

DS_NAME=""
MAX_ITERATIONS=20
MAX_TURNS=50
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
    --max-turns)
      MAX_TURNS="$2"
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
      echo "Usage: $0 [--ds <name>] [--max <N>] [--max-turns <N>] [--dry-run] [--agent <cmd>] [--unattended]"
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
    if [[ -d "context/$name/03-closed-prd" ]] || [[ -f "context/$name/03-closed-prd.md" ]]; then
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

# Detect the components directory (skills/{ds}/references/{ds}/v{N}/components/)
COMPONENTS_DIR=$(find "skills/$DS_NAME/references/$DS_NAME" -type d -name "components" -maxdepth 3 2>/dev/null | head -1)

# =============================================================================
# BUILD AGENT COMMAND
# =============================================================================

# The prompt content — tells the agent to run Stage 4 for the specific DS.
# For Claude Code with slash commands installed, use the command directly.
# For other agents, use the descriptive prompt as fallback.
if [[ "$AGENT_CMD" == claude* ]] && [[ -f ".claude/commands/ds/generate.md" ]]; then
  STAGE4_PROMPT="/ds:generate $DS_NAME"
else
  STAGE4_PROMPT="Run Stage 4 of the design system skill generation pipeline for $DS_NAME. Read the progress file and PRD from disk, execute the next batch, commit, then exit."
fi

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

# Claude-specific: bound turns to prevent runaway sessions
# The script handles bookkeeping, so Claude doesn't need to complete post-batch steps
case "$AGENT_CMD" in
  claude*)
    AGENT_EXTRA_ARGS="$AGENT_EXTRA_ARGS --max-turns $MAX_TURNS"
    ;;
esac

# =============================================================================
# PREFLIGHT CHECKS
# =============================================================================

echo "========================================="
echo "DS Generate Loop"
echo "========================================="
echo "  Project:    $PROJECT_ROOT"
echo "  DS:         $DS_NAME"
echo "  Progress:   $PROGRESS_FILE"
echo "  Components: ${COMPONENTS_DIR:-"(not yet created)"}"
echo "  Max iters:  $MAX_ITERATIONS"
echo "  Max turns:  $MAX_TURNS"
echo "  Agent:      $AGENT_CMD"

# Check agent CLI exists (first word of AGENT_CMD)
AGENT_BIN=$(echo "$AGENT_CMD" | awk '{print $1}')
if ! command -v "$AGENT_BIN" &>/dev/null; then
  echo "ERROR: '$AGENT_BIN' not found. Install your agent CLI first."
  exit 1
fi
echo "  Agent CLI:  OK"

if [[ -d "context/$DS_NAME/03-closed-prd" ]]; then
  echo "  PRD:        OK (directory format)"
elif [[ -f "context/$DS_NAME/03-closed-prd.md" ]]; then
  echo "  PRD:        OK (single-file format)"
else
  echo "ERROR: context/$DS_NAME/03-closed-prd.md (or 03-closed-prd/) not found."
  echo "  Stage 3 (PRD) must be complete before running Stage 4."
  exit 1
fi

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

update_progress_from_disk() {
  if [[ ! -f "$PROGRESS_FILE" ]] || [[ -z "$COMPONENTS_DIR" ]]; then
    return
  fi

  local updated=0
  # Read each unchecked component name
  grep "\- \[ \]" "$PROGRESS_FILE" | while read -r line; do
    # Extract component name (after "- [ ] ")
    comp_name=$(echo "$line" | sed 's/.*- \[ \] //' | xargs)

    # Check if component directory exists with at least one file
    if [[ -d "$COMPONENTS_DIR/$comp_name" ]] && [[ -n "$(ls -A "$COMPONENTS_DIR/$comp_name/" 2>/dev/null)" ]]; then
      # Mark as complete in progress file
      sed -i '' "s/- \[ \] $comp_name/- [x] $comp_name/" "$PROGRESS_FILE"
      updated=$((updated + 1))
    fi
  done
}

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

    # In dry-run mode, still run update_progress_from_disk to show what it would detect
    COMPONENTS_DIR=$(find "skills/$DS_NAME/references/$DS_NAME" -type d -name "components" -maxdepth 3 2>/dev/null | head -1)
    if [[ -n "$COMPONENTS_DIR" ]]; then
      echo "  [DRY RUN] Checking generated dirs against progress file..."
      PROGRESS_HASH_BEFORE_UPDATE=""
      if [[ -f "$PROGRESS_FILE" ]]; then
        PROGRESS_HASH_BEFORE_UPDATE=$(shasum "$PROGRESS_FILE" | awk '{print $1}')
      fi
      update_progress_from_disk
      PROGRESS_HASH_AFTER_UPDATE=""
      if [[ -f "$PROGRESS_FILE" ]]; then
        PROGRESS_HASH_AFTER_UPDATE=$(shasum "$PROGRESS_FILE" | awk '{print $1}')
      fi
      if [[ "$PROGRESS_HASH_BEFORE_UPDATE" != "$PROGRESS_HASH_AFTER_UPDATE" ]]; then
        echo "  [DRY RUN] Progress file WOULD be updated (detected generated component dirs)"
      else
        echo "  [DRY RUN] No new component dirs detected"
      fi
    fi
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
  # Post-iteration: host-side bookkeeping
  # -------------------------------------------------------------------------
  echo ""
  echo "  Post-iteration:"

  # Re-detect COMPONENTS_DIR in case it was created by this iteration
  COMPONENTS_DIR=$(find "skills/$DS_NAME/references/$DS_NAME" -type d -name "components" -maxdepth 3 2>/dev/null | head -1)

  # 1. Script updates progress file based on actual generated dirs
  update_progress_from_disk
  echo "  Progress file: synced with disk"

  # 2. Check if ANY new files were written (untracked or modified)
  NEW_FILES=$(git status --porcelain 2>/dev/null | grep -c "^?" || true)
  MODIFIED_FILES=$(git status --porcelain 2>/dev/null | grep -c "^ M\|^M " || true)
  PROGRESS_HASH_AFTER=""
  if [[ -f "$PROGRESS_FILE" ]]; then
    PROGRESS_HASH_AFTER=$(shasum "$PROGRESS_FILE" | awk '{print $1}')
  fi

  if [[ "$NEW_FILES" -eq 0 ]] && [[ "$MODIFIED_FILES" -eq 0 ]] && [[ "$PROGRESS_HASH_BEFORE" == "$PROGRESS_HASH_AFTER" ]]; then
    echo "  WARNING: No new files and progress unchanged."
    echo "  Stopping to avoid infinite loop."
    notify "DS Generate Loop stopped — no progress on iteration $i"
    break
  fi
  echo "  New files: $NEW_FILES, Modified: $MODIFIED_FILES"

  # 3. Auto-commit everything (generated files + updated progress)
  git add -A
  git commit -m "$DS_NAME generate: batch iteration $i (loop-managed)" 2>/dev/null || true
  COMMIT_AFTER=$(git rev-parse HEAD 2>/dev/null || echo "")
  echo "  HEAD: ${COMMIT_BEFORE:0:8} → ${COMMIT_AFTER:0:8}"

  # 4. Check completion
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
