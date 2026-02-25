#!/usr/bin/env bash
set -euo pipefail

# Usage: ./clone-for-run.sh MODEL CONDITION [SESSION_NUM]
# MODEL: anthropic/claude-opus-4-6, openai/gpt-5.1-codex, google/gemini-2.5-pro
# CONDITION: stompy, file, nomemory
# SESSION_NUM: 1, 2, or 3 (default: 1)

MODEL="${1:?Usage: $0 MODEL CONDITION [SESSION_NUM]}"
CONDITION="${2:?Usage: $0 MODEL CONDITION [SESSION_NUM]}"
SESSION="${3:-1}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BASE_DIR="$PROJECT_ROOT/meridian-base"

# Derive short model name for directory
MODEL_SHORT="${MODEL##*/}"  # e.g., "claude-opus-4-6" from "anthropic/claude-opus-4-6"

RUN_DIR="$PROJECT_ROOT/runs/${MODEL_SHORT}-${CONDITION}"

# Determine source directory
if [ "$SESSION" -eq 1 ]; then
  SOURCE="$BASE_DIR"
  echo "Session 1: Copying from meridian-base/"
elif [ "$SESSION" -le 3 ]; then
  PREV_SESSION=$((SESSION - 1))
  SOURCE="$RUN_DIR"
  if [ ! -d "$SOURCE/src" ]; then
    echo "Error: Previous session output not found at $SOURCE"
    exit 1
  fi
  echo "Session $SESSION: Building on previous session at $SOURCE"
else
  echo "Error: SESSION_NUM must be 1, 2, or 3"
  exit 1
fi

# Create run directory
mkdir -p "$RUN_DIR"

if [ "$SESSION" -eq 1 ]; then
  # Fresh copy from base
  cp -r "$SOURCE/"* "$RUN_DIR/" 2>/dev/null || true
  cp "$SOURCE/.gitignore" "$RUN_DIR/" 2>/dev/null || true
fi

# Copy appropriate opencode.json
CONFIG_SRC="$SCRIPT_DIR/${CONDITION}-condition/opencode.json"
if [ ! -f "$CONFIG_SRC" ]; then
  echo "Error: Config not found at $CONFIG_SRC"
  exit 1
fi

# Copy config and override model
cp "$CONFIG_SRC" "$RUN_DIR/opencode.json"

# Update model in config using sed (portable)
# Map full model name to provider
case "$MODEL" in
  anthropic/*)
    PROVIDER="anthropic"
    ;;
  openai/*)
    PROVIDER="openai"
    ;;
  google/*)
    PROVIDER="google"
    ;;
  *)
    PROVIDER="anthropic"
    ;;
esac

# Use a temp file for sed compatibility across platforms
TMP_FILE=$(mktemp)
sed "s|\"model\": \"[^\"]*\"|\"model\": \"${MODEL##*/}\"|" "$RUN_DIR/opencode.json" > "$TMP_FILE"
sed "s|\"provider\": \"[^\"]*\"|\"provider\": \"${PROVIDER}\"|" "$TMP_FILE" > "$RUN_DIR/opencode.json"
rm "$TMP_FILE"

echo ""
echo "Run directory ready: $RUN_DIR"
echo "  Model:     $MODEL"
echo "  Provider:  $PROVIDER"
echo "  Condition: $CONDITION"
echo "  Session:   $SESSION"
echo ""
echo "Next: cd $RUN_DIR && opencode"
