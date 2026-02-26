#!/usr/bin/env bash
set -euo pipefail

# Usage: ./clone-for-run.sh MODEL CONDITION [SESSION_NUM]
# MODEL: claude-opus-4-6, claude-sonnet-4-6, claude-haiku-4-5 (Claude Code --model values)
# CONDITION: stompy, file, nomemory
# SESSION_NUM: 1, 2, or 3 (default: 1)

MODEL="${1:?Usage: $0 MODEL CONDITION [SESSION_NUM]}"
CONDITION="${2:?Usage: $0 MODEL CONDITION [SESSION_NUM]}"
SESSION="${3:-1}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BASE_DIR="$PROJECT_ROOT/meridian-base"

RUN_DIR="$PROJECT_ROOT/runs/${MODEL}-${CONDITION}"

# Validate condition
case "$CONDITION" in
  stompy|file|nomemory) ;;
  *)
    echo "Error: CONDITION must be stompy, file, or nomemory (got: $CONDITION)"
    exit 1
    ;;
esac

# Validate session
if [ "$SESSION" -lt 1 ] || [ "$SESSION" -gt 3 ]; then
  echo "Error: SESSION_NUM must be 1, 2, or 3 (got: $SESSION)"
  exit 1
fi

# Determine source directory
if [ "$SESSION" -eq 1 ]; then
  SOURCE="$BASE_DIR"
  echo "Session 1: Copying fresh from meridian-base/"
elif [ "$SESSION" -le 3 ]; then
  SOURCE="$RUN_DIR"
  if [ ! -d "$SOURCE/src" ]; then
    echo "Error: Previous session output not found at $SOURCE"
    exit 1
  fi
  echo "Session $SESSION: Building on previous session at $SOURCE"
fi

# Create run directory and copy base files for session 1
mkdir -p "$RUN_DIR"

if [ "$SESSION" -eq 1 ]; then
  # Fresh copy from base
  cp -r "$SOURCE/"* "$RUN_DIR/" 2>/dev/null || true
  cp "$SOURCE/.gitignore" "$RUN_DIR/" 2>/dev/null || true
fi

# Set up Claude Code config: .claude/settings.local.json
CLAUDE_DIR="$RUN_DIR/.claude"
mkdir -p "$CLAUDE_DIR"

SETTINGS_SRC="$SCRIPT_DIR/${CONDITION}-condition/settings.json"
if [ ! -f "$SETTINGS_SRC" ]; then
  echo "Error: Settings not found at $SETTINGS_SRC"
  exit 1
fi
cp "$SETTINGS_SRC" "$CLAUDE_DIR/settings.local.json"

# For stompy condition: copy .mcp.json into run directory root
if [ "$CONDITION" = "stompy" ]; then
  MCP_SRC="$SCRIPT_DIR/stompy-condition/.mcp.json"
  if [ ! -f "$MCP_SRC" ]; then
    echo "Error: .mcp.json not found at $MCP_SRC"
    exit 1
  fi
  cp "$MCP_SRC" "$RUN_DIR/.mcp.json"
else
  # Ensure no .mcp.json in non-stompy conditions
  rm -f "$RUN_DIR/.mcp.json"
fi

echo ""
echo "Run directory ready: $RUN_DIR"
echo "  Model:     $MODEL"
echo "  Condition: $CONDITION"
echo "  Session:   $SESSION"
echo "  Config:    $CLAUDE_DIR/settings.local.json"
[ "$CONDITION" = "stompy" ] && echo "  MCP:       $RUN_DIR/.mcp.json"
echo ""
echo "Next: cd $RUN_DIR && claude -p '...' --model $MODEL"
