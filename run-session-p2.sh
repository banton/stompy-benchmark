#!/usr/bin/env bash
set -euo pipefail

# Usage: ./run-session-p2.sh MODEL CONDITION TASK_NUM [--dry-run]
#
# Runs a single Phase 2 benchmark session via Claude Code headless mode.
#
# Phase 2 differs from Phase 1:
#   - Tasks are independent (not sequential) — each starts from fresh snapshot
#   - No memory write phase (memory is pre-loaded)
#   - Per-task budget/turns/timeout scaling
#   - Python codebase (dementia-production) instead of TypeScript (meridian)
#
# MODEL:       Claude Code --model value (e.g., claude-opus-4-6)
# CONDITION:   stompy, file, nomemory
# TASK_NUM:    1, 2, or 3
#
# Environment:
#   DEMENTIA_API_KEY — required for stompy condition
#   MAX_TURNS_OVERRIDE — override max turns
#   MAX_BUDGET_OVERRIDE — override max budget USD
#   TIMEOUT_OVERRIDE    — override timeout in seconds

MODEL="${1:?Usage: $0 MODEL CONDITION TASK_NUM [--dry-run]}"
CONDITION="${2:?Usage: $0 MODEL CONDITION TASK_NUM [--dry-run]}"
TASK_NUM="${3:?Usage: $0 MODEL CONDITION TASK_NUM [--dry-run]}"
DRY_RUN="${4:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
CONFIGS_DIR="$PROJECT_ROOT/configs"
PROMPTS_DIR="$PROJECT_ROOT/prompts/phase2"
SCORING_DIR="$PROJECT_ROOT/scoring/phase2"

# ─── Per-task scaling ──────────────────────────────────────────────────

case "$TASK_NUM" in
  1)
    DEFAULT_TURNS=250
    DEFAULT_BUDGET=15
    DEFAULT_TIMEOUT=1800   # 30 min
    TASK_NAME="project_delete_preview"
    ;;
  2)
    DEFAULT_TURNS=300
    DEFAULT_BUDGET=20
    DEFAULT_TIMEOUT=2700   # 45 min
    TASK_NAME="service_extraction"
    ;;
  3)
    DEFAULT_TURNS=400
    DEFAULT_BUDGET=25
    DEFAULT_TIMEOUT=3600   # 60 min
    TASK_NAME="rate_limiting"
    ;;
  *)
    echo "Error: TASK_NUM must be 1, 2, or 3"
    exit 1
    ;;
esac

MAX_TURNS="${MAX_TURNS_OVERRIDE:-$DEFAULT_TURNS}"
MAX_BUDGET="${MAX_BUDGET_OVERRIDE:-$DEFAULT_BUDGET}"
TIMEOUT="${TIMEOUT_OVERRIDE:-$DEFAULT_TIMEOUT}"

RUN_DIR="$PROJECT_ROOT/runs/p2-${MODEL}-${CONDITION}/task${TASK_NUM}"
RESULTS_DIR="$RUN_DIR"

# ─── Validate inputs ───────────────────────────────────────────────

case "$CONDITION" in
  stompy|file|nomemory) ;;
  *)
    echo "Error: CONDITION must be stompy, file, or nomemory"
    exit 1
    ;;
esac

if [ "$CONDITION" = "stompy" ] && [ -z "${DEMENTIA_API_KEY:-}" ]; then
  echo "Error: DEMENTIA_API_KEY required for stompy condition"
  echo "  source ~/Sites/stompy/dementia-production/.env"
  exit 1
fi

# ─── Select prompt file ────────────────────────────────────────────

PROMPT_FILE="$PROMPTS_DIR/task${TASK_NUM}-${CONDITION}.md"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Error: Prompt file not found: $PROMPT_FILE"
  exit 1
fi

# ─── Banner ────────────────────────────────────────────────────────

echo "═══════════════════════════════════════════════════════════════════"
echo "  STOMPY BENCHMARK — Phase 2 Session Runner"
echo "═══════════════════════════════════════════════════════════════════"
echo "  Model:     $MODEL"
echo "  Condition: $CONDITION"
echo "  Task:      $TASK_NUM ($TASK_NAME)"
echo "  Prompt:    $PROMPT_FILE"
echo "  Max turns: $MAX_TURNS"
echo "  Budget:    \$$MAX_BUDGET"
echo "  Timeout:   ${TIMEOUT}s"
echo "═══════════════════════════════════════════════════════════════════"

# ─── Prepare run directory (fresh snapshot per run) ────────────────

bash "$CONFIGS_DIR/phase2/clone-for-run.sh" "$MODEL" "$CONDITION" "$TASK_NUM"

# ─── Dry run check ────────────────────────────────────────────────

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
  echo "    --permission-mode bypassPermissions"
  echo ""
  echo "  Output → $RESULTS_DIR/task${TASK_NUM}-result.json"
  echo "  Scores → $RESULTS_DIR/task${TASK_NUM}-scores.json"
  echo ""
  echo "Neutrality checks:"
  echo "  ✓ --no-session-persistence prevents session bleed"
  echo "  ✓ --max-turns=$MAX_TURNS, --max-budget-usd=$MAX_BUDGET"
  echo "  ✓ Fresh snapshot copy for this run"
  [ "$CONDITION" = "stompy" ] && echo "  ✓ .mcp.json present for Stompy MCP access"
  [ "$CONDITION" != "stompy" ] && echo "  ✓ No .mcp.json — Stompy MCP NOT available"
  [ "$CONDITION" = "file" ] && echo "  ✓ MEMORY.md + TASKS.md injected"
  [ "$CONDITION" != "file" ] && echo "  ✓ No MEMORY.md/TASKS.md"
  echo "  ✓ No memory write phase (memory is pre-loaded)"
  echo "  ✓ No .git directory in run dir"
  exit 0
fi

# ─── Run implementation session ─────────────────────────────────────

# Unset CLAUDECODE to allow nested headless invocations
unset CLAUDECODE 2>/dev/null || true

echo ""
echo "▶ Running task $TASK_NUM ($TASK_NAME)..."
START_TIME=$(date +%s)

PROMPT_CONTENT=$(cat "$PROMPT_FILE")
RESULT_FILE="$RESULTS_DIR/task${TASK_NUM}-result.json"

# Run Claude Code headless — capture JSON output
cd "$RUN_DIR"
timeout "$TIMEOUT" claude -p "$PROMPT_CONTENT" \
  --model "$MODEL" \
  --output-format json \
  --max-turns "$MAX_TURNS" \
  --max-budget-usd "$MAX_BUDGET" \
  --no-session-persistence \
  --permission-mode bypassPermissions \
  > "$RESULT_FILE" 2>"$RESULTS_DIR/task${TASK_NUM}-stderr.log" || {
    EXIT_CODE=$?
    echo "⚠ Claude Code exited with code $EXIT_CODE"
    # Still continue to scoring — partial results are valuable
  }

END_TIME=$(date +%s)
WALL_CLOCK=$((END_TIME - START_TIME))

echo "  Duration: ${WALL_CLOCK}s"
echo "  Output:   $RESULT_FILE"

# Inject wall_clock_seconds and phase metadata into the result
if [ -f "$RESULT_FILE" ] && command -v python3 &>/dev/null; then
  python3 -c "
import json, sys
try:
    with open('$RESULT_FILE', 'r') as f:
        data = json.load(f)
    data['benchmark_wall_clock_seconds'] = $WALL_CLOCK
    data['benchmark_phase'] = 2
    data['benchmark_task_num'] = $TASK_NUM
    data['benchmark_task_name'] = '$TASK_NAME'
    with open('$RESULT_FILE', 'w') as f:
        json.dump(data, f, indent=2)
except:
    pass  # Don't fail if result isn't valid JSON
"
fi

# ─── Scoring ────────────────────────────────────────────────────────

echo ""
echo "▶ Running scoring..."

SCORES_FILE="$RESULTS_DIR/task${TASK_NUM}-scores.json"
SCORE_SCRIPT="$SCORING_DIR/score-task${TASK_NUM}.sh"

if [ ! -f "$SCORE_SCRIPT" ]; then
  echo "Error: Scoring script not found: $SCORE_SCRIPT"
  exit 1
fi

TASK_SCORE=$("$SCORE_SCRIPT" "$RUN_DIR" 2>/dev/null || echo '{"score":0,"max":25,"checks":[]}')

# Wrap score with metadata
python3 -c "
import json
task_score = json.loads('''$TASK_SCORE''')

result = {
    'model': '$MODEL',
    'condition': '$CONDITION',
    'phase': 2,
    'task_num': $TASK_NUM,
    'task_name': '$TASK_NAME',
    'wall_clock_seconds': $WALL_CLOCK,
    'total_score': task_score['score'],
    'total_max': task_score['max'],
    'score_pct': round(task_score['score'] / task_score['max'] * 100, 2) if task_score['max'] > 0 else 0,
    'points_per_minute': round(task_score['score'] / ($WALL_CLOCK / 60), 4) if $WALL_CLOCK > 0 else 0,
    'task_scoring': task_score,
}

print(json.dumps(result, indent=2))
" > "$SCORES_FILE"

echo "  Scores: $SCORES_FILE"

# ─── Summary ────────────────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  Task $TASK_NUM ($TASK_NAME) complete"
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
