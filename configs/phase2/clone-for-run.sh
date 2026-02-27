#!/usr/bin/env bash
set -euo pipefail

# Usage: ./clone-for-run.sh MODEL CONDITION TASK_NUM
#
# Prepares a fresh run directory for a Phase 2 benchmark run.
# Each run gets an independent copy of dementia-snapshot/ (no state bleed).
#
# MODEL:     claude-opus-4-6 (Claude Code --model value)
# CONDITION: stompy, file, nomemory
# TASK_NUM:  1, 2, or 3

MODEL="${1:?Usage: $0 MODEL CONDITION TASK_NUM}"
CONDITION="${2:?Usage: $0 MODEL CONDITION TASK_NUM}"
TASK_NUM="${3:?Usage: $0 MODEL CONDITION TASK_NUM}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
SNAPSHOT_DIR="$PROJECT_ROOT/dementia-snapshot"
CONFIGS_DIR="$PROJECT_ROOT/configs"

RUN_DIR="$PROJECT_ROOT/runs/p2-${MODEL}-${CONDITION}/task${TASK_NUM}"

# Validate inputs
case "$CONDITION" in
  stompy|file|nomemory) ;;
  *)
    echo "Error: CONDITION must be stompy, file, or nomemory (got: $CONDITION)"
    exit 1
    ;;
esac

if [ "$TASK_NUM" -lt 1 ] || [ "$TASK_NUM" -gt 3 ]; then
  echo "Error: TASK_NUM must be 1, 2, or 3 (got: $TASK_NUM)"
  exit 1
fi

if [ ! -d "$SNAPSHOT_DIR" ]; then
  echo "Error: Snapshot directory not found: $SNAPSHOT_DIR"
  echo "  Run: cp -r ~/Sites/stompy/dementia-production/ dementia-snapshot/ && rm -rf dementia-snapshot/.git"
  exit 1
fi

# ─── Fresh copy from snapshot ────────────────────────────────────────

echo "Phase 2: Creating fresh copy from dementia-snapshot/"

# Remove any previous run for this task+condition
rm -rf "$RUN_DIR"
mkdir -p "$RUN_DIR"

# Copy snapshot (excludes .git since it was already stripped)
rsync -a --exclude='__pycache__' --exclude='*.pyc' \
  "$SNAPSHOT_DIR/" "$RUN_DIR/"

# Ensure no .git directory (safety check)
rm -rf "$RUN_DIR/.git"

# Ensure no .env files (prevent secret leakage)
find "$RUN_DIR" -name '.env*' -delete 2>/dev/null || true

# ─── Inject condition-specific files ─────────────────────────────────

# Claude Code config directory
CLAUDE_DIR="$RUN_DIR/.claude"
mkdir -p "$CLAUDE_DIR"

# Settings — use condition-specific settings (reuse from Phase 1)
SETTINGS_SRC="$CONFIGS_DIR/${CONDITION}-condition/settings.json"
if [ ! -f "$SETTINGS_SRC" ]; then
  echo "Error: Settings not found at $SETTINGS_SRC"
  exit 1
fi
cp "$SETTINGS_SRC" "$CLAUDE_DIR/settings.local.json"

# Stompy condition: inject .mcp.json
if [ "$CONDITION" = "stompy" ]; then
  MCP_SRC="$CONFIGS_DIR/stompy-condition/.mcp.json"
  if [ ! -f "$MCP_SRC" ]; then
    echo "Error: .mcp.json not found at $MCP_SRC"
    exit 1
  fi
  cp "$MCP_SRC" "$RUN_DIR/.mcp.json"
else
  # Ensure no .mcp.json in non-stompy conditions
  rm -f "$RUN_DIR/.mcp.json"
fi

# File condition: inject MEMORY.md and TASKS.md
if [ "$CONDITION" = "file" ]; then
  FILE_COND_DIR="$CONFIGS_DIR/phase2/file-condition"
  if [ ! -f "$FILE_COND_DIR/MEMORY.md" ]; then
    echo "Error: MEMORY.md not found at $FILE_COND_DIR/MEMORY.md"
    exit 1
  fi
  if [ ! -f "$FILE_COND_DIR/TASKS.md" ]; then
    echo "Error: TASKS.md not found at $FILE_COND_DIR/TASKS.md"
    exit 1
  fi
  cp "$FILE_COND_DIR/MEMORY.md" "$RUN_DIR/MEMORY.md"
  cp "$FILE_COND_DIR/TASKS.md" "$RUN_DIR/TASKS.md"
else
  # Ensure no MEMORY.md/TASKS.md in non-file conditions
  rm -f "$RUN_DIR/MEMORY.md" "$RUN_DIR/TASKS.md"
fi

# ─── Summary ─────────────────────────────────────────────────────────

echo ""
echo "Run directory ready: $RUN_DIR"
echo "  Model:     $MODEL"
echo "  Condition: $CONDITION"
echo "  Task:      $TASK_NUM"
echo "  Config:    $CLAUDE_DIR/settings.local.json"
[ "$CONDITION" = "stompy" ] && echo "  MCP:       $RUN_DIR/.mcp.json"
[ "$CONDITION" = "file" ] && echo "  Memory:    $RUN_DIR/MEMORY.md + $RUN_DIR/TASKS.md"
echo ""

# Neutrality verification
echo "Neutrality checks:"
[ "$CONDITION" = "stompy" ] && echo "  ✓ .mcp.json injected for Stompy MCP access"
[ "$CONDITION" != "stompy" ] && echo "  ✓ No .mcp.json — Stompy MCP NOT available"
[ "$CONDITION" = "file" ] && echo "  ✓ MEMORY.md + TASKS.md injected"
[ "$CONDITION" != "file" ] && echo "  ✓ No MEMORY.md/TASKS.md"
echo "  ✓ Fresh snapshot copy (no state from other runs)"
echo "  ✓ No .git directory (prevents history-based knowledge)"
echo "  ✓ No .env files (prevents secret leakage)"
echo ""
