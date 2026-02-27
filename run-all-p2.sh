#!/usr/bin/env bash
set -euo pipefail

# Usage: ./run-all-p2.sh [--model MODEL] [--condition CONDITION] [--task TASK_NUM] [--dry-run]
#
# Phase 2 orchestrator. Runs all 9 benchmark sessions (3 tasks × 3 conditions).
# Tasks are independent — can run in any order (parallelization possible).
#
# Examples:
#   ./run-all-p2.sh                              # All 9 runs
#   ./run-all-p2.sh --condition stompy            # 3 tasks, stompy only
#   ./run-all-p2.sh --task 1                      # Task 1, all conditions
#   ./run-all-p2.sh --task 2 --condition file     # Single specific run
#   ./run-all-p2.sh --dry-run                     # Preview all 9 without executing

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Parse arguments ────────────────────────────────────────────────

FILTER_MODEL=""
FILTER_CONDITION=""
FILTER_TASK=""
DRY_RUN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      FILTER_MODEL="$2"
      shift 2
      ;;
    --condition)
      FILTER_CONDITION="$2"
      shift 2
      ;;
    --task)
      FILTER_TASK="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="--dry-run"
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--model MODEL] [--condition CONDITION] [--task TASK_NUM] [--dry-run]"
      echo ""
      echo "Phase 2 — Scaled Benchmark on Real Codebase (dementia-production)"
      echo ""
      echo "Models:     claude-opus-4-6 (default)"
      echo "Conditions: stompy, file, nomemory"
      echo "Tasks:      1 (project_delete preview, 30min)"
      echo "            2 (service extraction, 45min)"
      echo "            3 (rate limiting, 60min)"
      echo ""
      echo "Environment:"
      echo "  DEMENTIA_API_KEY        — required for stompy condition"
      echo "  MAX_TURNS_OVERRIDE      — override max turns"
      echo "  MAX_BUDGET_OVERRIDE     — override per-task budget"
      echo "  TIMEOUT_OVERRIDE        — override timeout seconds"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# ─── Define the matrix ──────────────────────────────────────────────

MODELS=("claude-opus-4-6")
CONDITIONS=("stompy" "file" "nomemory")
TASKS=(1 2 3)
TASK_NAMES=("project_delete_preview" "service_extraction" "rate_limiting")

# Apply filters
if [ -n "$FILTER_MODEL" ]; then
  MODELS=("$FILTER_MODEL")
fi
if [ -n "$FILTER_CONDITION" ]; then
  CONDITIONS=("$FILTER_CONDITION")
fi
if [ -n "$FILTER_TASK" ]; then
  TASKS=("$FILTER_TASK")
fi

# ─── Pre-flight checks ──────────────────────────────────────────────

echo "═══════════════════════════════════════════════════════════════════"
echo "  STOMPY BENCHMARK — Phase 2 Orchestrator"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Check claude CLI is available
if ! command -v claude &>/dev/null; then
  echo "Error: 'claude' CLI not found. Install Claude Code first."
  echo "  npm install -g @anthropic-ai/claude-code"
  exit 1
fi

# Check dementia-snapshot exists
if [ ! -d "$SCRIPT_DIR/dementia-snapshot" ]; then
  echo "Error: dementia-snapshot/ not found."
  echo "  Run snapshot preparation step first."
  exit 1
fi

# Check DEMENTIA_API_KEY for stompy condition
for cond in "${CONDITIONS[@]}"; do
  if [ "$cond" = "stompy" ] && [ -z "${DEMENTIA_API_KEY:-}" ]; then
    echo "Error: DEMENTIA_API_KEY required for stompy condition"
    echo "  source ~/Sites/stompy/dementia-production/.env"
    exit 1
  fi
done

# Check condition files
for cond in "${CONDITIONS[@]}"; do
  if [ "$cond" = "stompy" ] && [ ! -f "$SCRIPT_DIR/configs/stompy-condition/.mcp.json" ]; then
    echo "Error: configs/stompy-condition/.mcp.json not found"
    exit 1
  fi
  if [ "$cond" = "file" ]; then
    [ ! -f "$SCRIPT_DIR/configs/phase2/file-condition/MEMORY.md" ] && echo "Error: MEMORY.md not found" && exit 1
    [ ! -f "$SCRIPT_DIR/configs/phase2/file-condition/TASKS.md" ] && echo "Error: TASKS.md not found" && exit 1
  fi
done

# Count total runs
TOTAL=0
for m in "${MODELS[@]}"; do
  for c in "${CONDITIONS[@]}"; do
    for t in "${TASKS[@]}"; do
      TOTAL=$((TOTAL + 1))
    done
  done
done

echo "  Models:     ${MODELS[*]}"
echo "  Conditions: ${CONDITIONS[*]}"
echo "  Tasks:      ${TASKS[*]}"
echo "  Total runs: $TOTAL"
echo ""

# Budget estimation
ESTIMATED_COST=0
for t in "${TASKS[@]}"; do
  case "$t" in
    1) PER_TASK=15 ;;
    2) PER_TASK=20 ;;
    3) PER_TASK=25 ;;
  esac
  COND_COUNT=${#CONDITIONS[@]}
  ESTIMATED_COST=$((ESTIMATED_COST + PER_TASK * COND_COUNT))
done
echo "  Max budget: \$$ESTIMATED_COST (upper bound, actual will be lower)"
echo ""

# ─── Run sessions ───────────────────────────────────────────────────

CURRENT=0
PASSED=0
FAILED=0
RESULTS=()
ALL_START=$(date +%s)

for model in "${MODELS[@]}"; do
  for task in "${TASKS[@]}"; do
    TASK_IDX=$((task - 1))
    TASK_LABEL="${TASK_NAMES[$TASK_IDX]}"

    for condition in "${CONDITIONS[@]}"; do
      CURRENT=$((CURRENT + 1))
      echo ""
      echo "┌─────────────────────────────────────────────────────────────"
      echo "│ Run $CURRENT/$TOTAL: $model / $condition / task $task ($TASK_LABEL)"
      echo "└─────────────────────────────────────────────────────────────"
      echo ""

      if "$SCRIPT_DIR/run-session-p2.sh" "$model" "$condition" "$task" $DRY_RUN; then
        PASSED=$((PASSED + 1))
        RESULTS+=("✓ $model/$condition/task$task ($TASK_LABEL)")
      else
        FAILED=$((FAILED + 1))
        RESULTS+=("✗ $model/$condition/task$task ($TASK_LABEL)")
        echo "⚠ Run failed but continuing..."
      fi
    done
  done
done

ALL_END=$(date +%s)
ALL_DURATION=$((ALL_END - ALL_START))

# ─── Generate summary ───────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  PHASE 2 BENCHMARK COMPLETE"
echo "═══════════════════════════════════════════════════════════════════"
echo "  Total time: $((ALL_DURATION / 60))m $((ALL_DURATION % 60))s"
echo "  Passed:     $PASSED/$TOTAL"
echo "  Failed:     $FAILED/$TOTAL"
echo ""

for r in "${RESULTS[@]}"; do
  echo "  $r"
done
echo ""

# Skip summary generation for dry runs
if [ -n "$DRY_RUN" ]; then
  echo "  [DRY RUN] No summary generated."
  exit 0
fi

# Generate results-summary-p2.json
SUMMARY_FILE="$SCRIPT_DIR/runs/results-summary-p2.json"
mkdir -p "$SCRIPT_DIR/runs"

python3 -c "
import json, os, glob

runs_dir = '$SCRIPT_DIR/runs'
summary = {
    'generated_at': $(date +%s),
    'phase': 2,
    'total_duration_seconds': $ALL_DURATION,
    'total_runs': $TOTAL,
    'passed': $PASSED,
    'failed': $FAILED,
    'sessions': []
}

# Collect all Phase 2 score files
for score_file in sorted(glob.glob(os.path.join(runs_dir, 'p2-*/task*-scores.json'))):
    try:
        with open(score_file) as f:
            scores = json.load(f)
        # Try to get token data from result file
        result_file = score_file.replace('-scores.json', '-result.json')
        tokens = {}
        if os.path.exists(result_file):
            try:
                with open(result_file) as f:
                    result = json.load(f)
                tokens = {
                    'input_tokens': result.get('usage', {}).get('input_tokens', 0),
                    'output_tokens': result.get('usage', {}).get('output_tokens', 0),
                    'cost_usd': result.get('total_cost_usd', 0),
                    'duration_ms': result.get('duration_ms', 0),
                    'num_turns': result.get('num_turns', 0),
                    'session_id': result.get('session_id', ''),
                }
            except:
                pass
        session_entry = {**scores, **tokens, 'score_file': score_file}
        summary['sessions'].append(session_entry)
    except:
        pass

# Compute effectiveness metrics per condition
by_condition = {}
for s in summary['sessions']:
    cond = s.get('condition', 'unknown')
    if cond not in by_condition:
        by_condition[cond] = {'scores': [], 'times': [], 'costs': [], 'points_per_min': []}
    by_condition[cond]['scores'].append(s.get('score_pct', 0))
    by_condition[cond]['times'].append(s.get('wall_clock_seconds', 0))
    by_condition[cond]['costs'].append(s.get('cost_usd', 0))
    by_condition[cond]['points_per_min'].append(s.get('points_per_minute', 0))

# Compute effectiveness metrics per task
by_task = {}
for s in summary['sessions']:
    task = s.get('task_num', 0)
    if task not in by_task:
        by_task[task] = {}
    cond = s.get('condition', 'unknown')
    by_task[task][cond] = {
        'score_pct': s.get('score_pct', 0),
        'wall_clock_seconds': s.get('wall_clock_seconds', 0),
        'cost_usd': s.get('cost_usd', 0),
        'points_per_minute': s.get('points_per_minute', 0),
        'num_turns': s.get('num_turns', 0),
    }

def avg(lst):
    return round(sum(lst) / len(lst), 4) if lst else 0

summary['effectiveness_by_condition'] = {}
for cond, data in by_condition.items():
    summary['effectiveness_by_condition'][cond] = {
        'avg_score_pct': avg(data['scores']),
        'avg_wall_clock_seconds': avg(data['times']),
        'avg_cost_usd': avg(data['costs']),
        'avg_points_per_minute': avg(data['points_per_min']),
    }

summary['effectiveness_by_task'] = {}
for task_num, conditions in by_task.items():
    summary['effectiveness_by_task'][str(task_num)] = conditions

print(json.dumps(summary, indent=2))
" > "$SUMMARY_FILE"

echo "  Summary: $SUMMARY_FILE"
echo ""
