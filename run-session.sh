#!/usr/bin/env bash
set -euo pipefail

# Usage: ./run-session.sh MODEL CONDITION SESSION_NUM [--dry-run]
#
# Runs a single benchmark session via Claude Code headless mode.
#
# MODEL:       Claude Code --model value (e.g., claude-opus-4-6)
# CONDITION:   stompy, file, nomemory
# SESSION_NUM: 1, 2, or 3
#
# Environment:
#   STOMPY_API_KEY  — required for stompy condition
#   MAX_TURNS       — override max turns (default: 200)
#   MAX_BUDGET      — override max budget USD (default: 10)
#   TIMEOUT         — override timeout in seconds (default: 1800 = 30min)

MODEL="${1:?Usage: $0 MODEL CONDITION SESSION_NUM [--dry-run]}"
CONDITION="${2:?Usage: $0 MODEL CONDITION SESSION_NUM [--dry-run]}"
SESSION="${3:?Usage: $0 MODEL CONDITION SESSION_NUM [--dry-run]}"
DRY_RUN="${4:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
CONFIGS_DIR="$PROJECT_ROOT/configs"
PROMPTS_DIR="$PROJECT_ROOT/prompts"
SCORING_DIR="$PROJECT_ROOT/scoring"

MAX_TURNS="${MAX_TURNS:-200}"
MAX_BUDGET="${MAX_BUDGET:-10}"
TIMEOUT="${TIMEOUT:-1800}"

RUN_DIR="$PROJECT_ROOT/runs/${MODEL}-${CONDITION}"
RESULTS_DIR="$RUN_DIR"

ALLOWED_TOOLS="Read,Write,Edit,Bash,Glob,Grep"

# ─── Validate inputs ───────────────────────────────────────────────

case "$CONDITION" in
  stompy|file|nomemory) ;;
  *)
    echo "Error: CONDITION must be stompy, file, or nomemory"
    exit 1
    ;;
esac

if [ "$SESSION" -lt 1 ] || [ "$SESSION" -gt 3 ]; then
  echo "Error: SESSION_NUM must be 1, 2, or 3"
  exit 1
fi

if [ "$CONDITION" = "stompy" ] && [ -z "${STOMPY_API_KEY:-}" ]; then
  echo "Error: STOMPY_API_KEY required for stompy condition"
  exit 1
fi

# ─── Select prompt file ────────────────────────────────────────────

select_prompt() {
  local session="$1"
  local condition="$2"

  case "$session" in
    1)
      echo "$PROMPTS_DIR/session1.md"
      ;;
    2)
      echo "$PROMPTS_DIR/session2-${condition}.md"
      ;;
    3)
      echo "$PROMPTS_DIR/session3-${condition}.md"
      ;;
  esac
}

select_memory_write_prompt() {
  local session="$1"
  local condition="$2"

  case "$condition" in
    stompy)
      if [ "$session" -le 2 ]; then
        echo "$PROMPTS_DIR/stompy-store-s${session}.md"
      fi
      ;;
    file)
      if [ "$session" -le 2 ]; then
        echo "$PROMPTS_DIR/memory-prompt-s${session}.md"
      fi
      ;;
    nomemory)
      # No memory write for nomemory condition
      echo ""
      ;;
  esac
}

PROMPT_FILE=$(select_prompt "$SESSION" "$CONDITION")
MEMORY_PROMPT_FILE=$(select_memory_write_prompt "$SESSION" "$CONDITION")

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Error: Prompt file not found: $PROMPT_FILE"
  exit 1
fi

# ─── Prepare run directory ──────────────────────────────────────────

echo "═══════════════════════════════════════════════════════════════════"
echo "  STOMPY BENCHMARK — Session Runner"
echo "═══════════════════════════════════════════════════════════════════"
echo "  Model:     $MODEL"
echo "  Condition: $CONDITION"
echo "  Session:   $SESSION"
echo "  Prompt:    $PROMPT_FILE"
echo "  Max turns: $MAX_TURNS"
echo "  Budget:    \$$MAX_BUDGET"
echo "  Timeout:   ${TIMEOUT}s"
[ -n "$MEMORY_PROMPT_FILE" ] && echo "  Memory:    $MEMORY_PROMPT_FILE"
echo "═══════════════════════════════════════════════════════════════════"

# Clone/prepare the run directory
bash "$CONFIGS_DIR/clone-for-run.sh" "$MODEL" "$CONDITION" "$SESSION"

# ─── Dry run check ──────────────────────────────────────────────────

if [ "$DRY_RUN" = "--dry-run" ]; then
  echo ""
  echo "[DRY RUN] Would execute:"
  echo "  cd $RUN_DIR"
  echo "  claude -p \"\$(cat $PROMPT_FILE)\" \\"
  echo "    --model $MODEL \\"
  echo "    --output-format json \\"
  echo "    --max-turns $MAX_TURNS \\"
  echo "    --max-budget-usd $MAX_BUDGET \\"
  echo "    --no-session-persistence \\"
  echo "    --allowedTools \"$ALLOWED_TOOLS\""
  echo ""
  echo "  Output → $RESULTS_DIR/session-${SESSION}-result.json"
  if [ -n "$MEMORY_PROMPT_FILE" ]; then
    echo "  Memory → $RESULTS_DIR/session-${SESSION}-memory-write.json"
  fi
  echo "  Scores → $RESULTS_DIR/session-${SESSION}-scores.json"
  echo ""
  echo "Neutrality checks:"
  echo "  ✓ --no-session-persistence prevents session bleed"
  echo "  ✓ --allowedTools identical across conditions: $ALLOWED_TOOLS"
  echo "  ✓ --max-turns=$MAX_TURNS, --max-budget-usd=$MAX_BUDGET"
  [ "$CONDITION" = "stompy" ] && echo "  ✓ .mcp.json present for Stompy MCP access"
  [ "$CONDITION" != "stompy" ] && echo "  ✓ No .mcp.json — Stompy MCP NOT available"
  echo "  ✓ Memory write is separate invocation (not --continue)"
  exit 0
fi

# ─── Run implementation session ─────────────────────────────────────

echo ""
echo "▶ Running implementation session $SESSION..."
START_TIME=$(date +%s)

PROMPT_CONTENT=$(cat "$PROMPT_FILE")

RESULT_FILE="$RESULTS_DIR/session-${SESSION}-result.json"

# Run Claude Code headless — capture JSON output
cd "$RUN_DIR"
timeout "$TIMEOUT" claude -p "$PROMPT_CONTENT" \
  --model "$MODEL" \
  --output-format json \
  --max-turns "$MAX_TURNS" \
  --max-budget-usd "$MAX_BUDGET" \
  --no-session-persistence \
  --allowedTools "$ALLOWED_TOOLS" \
  > "$RESULT_FILE" 2>"$RESULTS_DIR/session-${SESSION}-stderr.log" || {
    EXIT_CODE=$?
    echo "⚠ Claude Code exited with code $EXIT_CODE"
    # Still continue to scoring — partial results are valuable
  }

END_TIME=$(date +%s)
WALL_CLOCK=$((END_TIME - START_TIME))

echo "  Duration: ${WALL_CLOCK}s"
echo "  Output:   $RESULT_FILE"

# Inject wall_clock_seconds from our timer into the result
if [ -f "$RESULT_FILE" ] && command -v python3 &>/dev/null; then
  python3 -c "
import json, sys
try:
    with open('$RESULT_FILE', 'r') as f:
        data = json.load(f)
    data['benchmark_wall_clock_seconds'] = $WALL_CLOCK
    with open('$RESULT_FILE', 'w') as f:
        json.dump(data, f, indent=2)
except:
    pass  # Don't fail if result isn't valid JSON
"
fi

# ─── Memory write phase (separate invocation) ──────────────────────

if [ -n "$MEMORY_PROMPT_FILE" ] && [ -f "$MEMORY_PROMPT_FILE" ]; then
  echo ""
  echo "▶ Running memory write (separate invocation)..."

  MEMORY_CONTENT=$(cat "$MEMORY_PROMPT_FILE")
  MEMORY_RESULT="$RESULTS_DIR/session-${SESSION}-memory-write.json"

  cd "$RUN_DIR"
  timeout "$TIMEOUT" claude -p "$MEMORY_CONTENT" \
    --model "$MODEL" \
    --output-format json \
    --max-turns 50 \
    --max-budget-usd 3 \
    --no-session-persistence \
    --allowedTools "$ALLOWED_TOOLS" \
    > "$MEMORY_RESULT" 2>"$RESULTS_DIR/session-${SESSION}-memory-stderr.log" || {
      echo "⚠ Memory write exited with non-zero code"
    }

  echo "  Output: $MEMORY_RESULT"
fi

# ─── Scoring ────────────────────────────────────────────────────────

echo ""
echo "▶ Running scoring..."

SCORES_FILE="$RESULTS_DIR/session-${SESSION}-scores.json"

# Run all 3 scoring scripts and merge results
FUNC_SCORE=$("$SCORING_DIR/score.sh" "$RUN_DIR" 2>/dev/null || echo '{"score":0,"max":25,"checks":[]}')
CONSISTENCY_SCORE=$("$SCORING_DIR/score-consistency.sh" "$RUN_DIR" 2>/dev/null || echo '{"score":0,"max":6,"checks":[]}')
CURVEBALL_SCORE=$("$SCORING_DIR/score-curveball-quality.sh" "$RUN_DIR" 2>/dev/null || echo '{"score":0,"max":6,"checks":[]}')

# Merge scores into one JSON
python3 -c "
import json
func = json.loads('''$FUNC_SCORE''')
consistency = json.loads('''$CONSISTENCY_SCORE''')
curveball = json.loads('''$CURVEBALL_SCORE''')

total_score = func['score'] + consistency['score'] + curveball['score']
total_max = func['max'] + consistency['max'] + curveball['max']

result = {
    'model': '$MODEL',
    'condition': '$CONDITION',
    'session': $SESSION,
    'wall_clock_seconds': $WALL_CLOCK,
    'total_score': total_score,
    'total_max': total_max,
    'score_pct': round(total_score / total_max * 100, 2) if total_max > 0 else 0,
    'points_per_minute': round(total_score / ($WALL_CLOCK / 60), 4) if $WALL_CLOCK > 0 else 0,
    'functional': func,
    'consistency': consistency,
    'curveball': curveball,
}

print(json.dumps(result, indent=2))
" > "$SCORES_FILE"

echo "  Scores: $SCORES_FILE"

# ─── Summary ────────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  Session $SESSION complete"
if [ -f "$SCORES_FILE" ]; then
  python3 -c "
import json
with open('$SCORES_FILE') as f:
    s = json.load(f)
print(f\"  Score:    {s['total_score']}/{s['total_max']} ({s['score_pct']}%)\")
print(f\"  Time:     ${WALL_CLOCK}s\")
print(f\"  Eff:      {s['points_per_minute']} pts/min\")
"
fi
echo "═══════════════════════════════════════════════════════════════════"
