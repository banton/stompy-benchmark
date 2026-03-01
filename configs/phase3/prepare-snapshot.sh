#!/usr/bin/env bash
set -euo pipefail

# Prepare dollar-flights snapshot for Phase 3 swarm benchmark.
# Strips .git, .env, node_modules, __pycache__, and other non-essential files.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
SOURCE_DIR="$HOME/Sites/dollar-flights"
SNAPSHOT_DIR="$PROJECT_ROOT/dollar-flights-snapshot"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: dollar-flights not found at $SOURCE_DIR"
  exit 1
fi

echo "Creating dollar-flights snapshot..."
echo "  Source:  $SOURCE_DIR"
echo "  Target:  $SNAPSHOT_DIR"

# Remove old snapshot
rm -rf "$SNAPSHOT_DIR"

# Copy with exclusions
rsync -a \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='.env*' \
  --exclude='.DS_Store' \
  --exclude='.claude-memory*' \
  --exclude='*.log' \
  --exclude='*.png' \
  --exclude='*.html' \
  --exclude='server.log' \
  --exclude='test_results/' \
  --exclude='test_reports/' \
  --exclude='saved_responses/' \
  --exclude='research_data/' \
  --exclude='research/' \
  --exclude='archive/' \
  --exclude='southwest_playwright/' \
  --exclude='frontend/dist/' \
  --exclude='frontend/node_modules/' \
  --exclude='.pytest_cache' \
  --exclude='.vscode' \
  --exclude='*.json.backup' \
  --exclude='Capture-*' \
  "$SOURCE_DIR/" "$SNAPSHOT_DIR/"

# Verify
SNAPSHOT_SIZE=$(du -sh "$SNAPSHOT_DIR" | cut -f1)
FILE_COUNT=$(find "$SNAPSHOT_DIR" -type f | wc -l | tr -d ' ')
PY_COUNT=$(find "$SNAPSHOT_DIR" -name '*.py' -type f | wc -l | tr -d ' ')
JS_COUNT=$(find "$SNAPSHOT_DIR" \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' \) -type f | wc -l | tr -d ' ')

echo ""
echo "Snapshot created:"
echo "  Size:        $SNAPSHOT_SIZE"
echo "  Total files: $FILE_COUNT"
echo "  Python:      $PY_COUNT files"
echo "  JS/TS:       $JS_COUNT files"
echo ""

# Safety checks
if [ -d "$SNAPSHOT_DIR/.git" ]; then
  echo "WARNING: .git directory found in snapshot — removing"
  rm -rf "$SNAPSHOT_DIR/.git"
fi

if find "$SNAPSHOT_DIR" -name '.env*' -type f | grep -q .; then
  echo "WARNING: .env files found in snapshot — removing"
  find "$SNAPSHOT_DIR" -name '.env*' -type f -delete
fi

echo "✓ Snapshot ready for Phase 3 benchmark"
