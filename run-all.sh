#!/usr/bin/env bash
set -euo pipefail

# Usage: ./run-all.sh [--model MODEL] [--condition CONDITION] [--session SESSION]
#
# Orchestrates all benchmark sessions. By default runs all 9 Claude sessions
# (3 conditions × 3 sessions). Use flags to filter.
#
# Examples:
#   ./run-all.sh                                    # All 9 sessions
#   ./run-all.sh --model claude-opus-4-6            # All 9 for opus
#   ./run-all.sh --condition stompy                 # All 3 sessions, stompy only
#   ./run-all.sh --model claude-opus-4-6 --session 1  # One specific session

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Parse arguments ────────────────────────────────────────────────

FILTER_MODEL=""
FILTER_CONDITION=""
FILTER_SESSION=""

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
    --session)
      FILTER_SESSION="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--model MODEL] [--condition CONDITION] [--session SESSION]"
      echo ""
      echo "Models (Claude Code native):"
      echo "  claude-opus-4-6     (default, most capable)"
      echo "  claude-sonnet-4-6   (faster, cheaper)"
      echo "  claude-haiku-4-5    (fastest, cheapest)"
      echo ""
      echo "Deferred models (require proxy, not yet supported):"
      echo "  gpt-5.1-codex, gemini-2.5-pro"
      echo ""
      echo "Conditions: stompy, file, nomemory"
      echo "Sessions:   1, 2, 3"
      echo ""
      echo "Environment:"
      echo "  STOMPY_API_KEY  — required for stompy condition"
      echo "  MAX_TURNS       — override max turns (default: 200)"
      echo "  MAX_BUDGET      — override per-session budget (default: 10)"
      echo "  TIMEOUT         — override timeout seconds (default: 1800)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# ─── Define the matrix ──────────────────────────────────────────────

# Claude Code natively supports only Anthropic models.
# OpenAI/Google deferred until proxy layer is available.
MODELS=("claude-opus-4-6")
CONDITIONS=("stompy" "file" "nomemory")
SESSIONS=(1 2 3)

# Apply filters
if [ -n "$FILTER_MODEL" ]; then
  MODELS=("$FILTER_MODEL")
fi
if [ -n "$FILTER_CONDITION" ]; then
  CONDITIONS=("$FILTER_CONDITION")
fi
if [ -n "$FILTER_SESSION" ]; then
  SESSIONS=("$FILTER_SESSION")
fi

# ─── Pre-flight checks ──────────────────────────────────────────────

echo "═══════════════════════════════════════════════════════════════════"
echo "  STOMPY BENCHMARK — Full Run Orchestrator"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Check claude CLI is available
if ! command -v claude &>/dev/null; then
  echo "Error: 'claude' CLI not found. Install Claude Code first."
  echo "  npm install -g @anthropic-ai/claude-code"
  exit 1
fi

# Check STOMPY_API_KEY for stompy condition
for cond in "${CONDITIONS[@]}"; do
  if [ "$cond" = "stompy" ] && [ -z "${STOMPY_API_KEY:-}" ]; then
    echo "Error: STOMPY_API_KEY required for stompy condition"
    echo "  export STOMPY_API_KEY=your-key-here"
    exit 1
  fi
done

# Count total sessions
TOTAL=0
for m in "${MODELS[@]}"; do
  for c in "${CONDITIONS[@]}"; do
    for s in "${SESSIONS[@]}"; do
      TOTAL=$((TOTAL + 1))
    done
  done
done

echo "  Models:     ${MODELS[*]}"
echo "  Conditions: ${CONDITIONS[*]}"
echo "  Sessions:   ${SESSIONS[*]}"
echo "  Total runs: $TOTAL"
echo ""

# ─── Run sessions ───────────────────────────────────────────────────

CURRENT=0
PASSED=0
FAILED=0
RESULTS=()
ALL_START=$(date +%s)

for model in "${MODELS[@]}"; do
  for condition in "${CONDITIONS[@]}"; do
    # Sessions MUST run sequentially (session 2 depends on session 1 output)
    for session in "${SESSIONS[@]}"; do
      CURRENT=$((CURRENT + 1))
      echo ""
      echo "┌─────────────────────────────────────────────────────────────"
      echo "│ Run $CURRENT/$TOTAL: $model / $condition / session $session"
      echo "└─────────────────────────────────────────────────────────────"
      echo ""

      if "$SCRIPT_DIR/run-session.sh" "$model" "$condition" "$session"; then
        PASSED=$((PASSED + 1))
        RESULTS+=("✓ $model/$condition/s$session")
      else
        FAILED=$((FAILED + 1))
        RESULTS+=("✗ $model/$condition/s$session")
        echo "⚠ Session failed but continuing..."
      fi
    done
  done
done

ALL_END=$(date +%s)
ALL_DURATION=$((ALL_END - ALL_START))

# ─── Generate summary ───────────────────────────────────────────────

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  BENCHMARK COMPLETE"
echo "═══════════════════════════════════════════════════════════════════"
echo "  Total time: $((ALL_DURATION / 60))m $((ALL_DURATION % 60))s"
echo "  Passed:     $PASSED/$TOTAL"
echo "  Failed:     $FAILED/$TOTAL"
echo ""

for r in "${RESULTS[@]}"; do
  echo "  $r"
done
echo ""

# Generate results-summary.json
SUMMARY_FILE="$SCRIPT_DIR/runs/results-summary.json"
mkdir -p "$SCRIPT_DIR/runs"

python3 -c "
import json, os, glob

runs_dir = '$SCRIPT_DIR/runs'
summary = {
    'generated_at': $(date +%s),
    'total_duration_seconds': $ALL_DURATION,
    'total_runs': $TOTAL,
    'passed': $PASSED,
    'failed': $FAILED,
    'sessions': []
}

# Collect all score files
for score_file in sorted(glob.glob(os.path.join(runs_dir, '*/session-*-scores.json'))):
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
                    'input_tokens': result.get('input_tokens', 0),
                    'output_tokens': result.get('output_tokens', 0),
                    'cost_usd': result.get('cost_usd', 0),
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

print(json.dumps(summary, indent=2))
" > "$SUMMARY_FILE"

echo "  Summary: $SUMMARY_FILE"
echo ""
