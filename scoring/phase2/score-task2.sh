#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="${1:?Usage: $0 <run-directory>}"
SCORE=0
DETAILS=()

# Helper function
check() {
  local points=$1
  local name=$2
  local test=$3
  if ( eval "$test" ) 2>/dev/null; then
    SCORE=$((SCORE + points))
    DETAILS+=("{\"check\": \"$name\", \"points\": $points, \"passed\": true}")
  else
    DETAILS+=("{\"check\": \"$name\", \"points\": 0, \"passed\": false}")
  fi
}

# ── Structure (5 pts) ──

check 1 "context_explore_service.py exists" \
  "[ -f '$RUN_DIR/src/services/context_explore_service.py' ] && [ -s '$RUN_DIR/src/services/context_explore_service.py' ]"

check 1 "context_dashboard_service.py exists" \
  "[ -f '$RUN_DIR/src/services/context_dashboard_service.py' ] && [ -s '$RUN_DIR/src/services/context_dashboard_service.py' ]"

check 1 "stompy_server.py reduced in size" \
  "[ \$(wc -l < '$RUN_DIR/stompy_server.py') -lt 4895 ]"

check 1 "follows naming convention" \
  "ls '$RUN_DIR/src/services/'*_service.py 2>/dev/null | grep -q 'context_explore_service\|context_dashboard_service'"

check 1 "python syntax valid for new files" \
  "python3 -c \"import py_compile; py_compile.compile('$RUN_DIR/src/services/context_explore_service.py', doraise=True)\" && python3 -c \"import py_compile; py_compile.compile('$RUN_DIR/src/services/context_dashboard_service.py', doraise=True)\""

# ── Functionality (10 pts) ──

check 2 "context_explore logic moved to service" \
  "grep -qi 'priority\|topic\|version\|explore' '$RUN_DIR/src/services/context_explore_service.py'"

check 2 "context_dashboard logic moved to service" \
  "grep -qi 'dashboard\|summary\|statistics\|metric' '$RUN_DIR/src/services/context_dashboard_service.py'"

check 2 "service uses proper class/function structure" \
  "grep -qE 'class.*Service|def ' '$RUN_DIR/src/services/context_explore_service.py' && grep -qE 'class.*Service|def ' '$RUN_DIR/src/services/context_dashboard_service.py'"

check 2 "DB queries in service not server" \
  "grep -qi 'SELECT\|INSERT\|execute\|fetchall' '$RUN_DIR/src/services/context_explore_service.py' || grep -qi 'SELECT\|INSERT\|execute\|fetchall' '$RUN_DIR/src/services/context_dashboard_service.py'"

check 2 "error handling preserved" \
  "grep -qi 'try\|except\|raise\|Error\|Exception' '$RUN_DIR/src/services/context_explore_service.py' && grep -qi 'try\|except\|raise\|Error\|Exception' '$RUN_DIR/src/services/context_dashboard_service.py'"

# ── Testing (5 pts) ──

check 1 "test file for explore service exists" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -li 'explore.*service\|context_explore' {} + 2>/dev/null | head -1 | grep -q '.'"

check 1 "test file for dashboard service exists" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -li 'dashboard.*service\|context_dashboard' {} + 2>/dev/null | head -1 | grep -q '.'"

check 1 "more than 5 total test functions" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -c 'def test_' {} + 2>/dev/null | awk -F: '{s+=\$NF} END {exit (s>5?0:1)}'"

check 1 "mocks DB layer" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -li 'mock\|patch\|Mock' {} + 2>/dev/null | head -1 | grep -q '.'"

check 1 "tests cover main methods and errors" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -li 'error\|exception\|raise\|invalid' {} + 2>/dev/null | head -1 | grep -q '.'"

# ── Integration (5 pts) ──

check 1 "stompy_server imports new services" \
  "grep -qi 'context_explore_service\|context_dashboard_service' '$RUN_DIR/stompy_server.py'"

check 1 "MCP tool registration preserved" \
  "grep -qE '@mcp\.tool|context_explore|context_dashboard' '$RUN_DIR/stompy_server.py'"

check 1 "no circular imports (AST parses)" \
  "python3 -c \"import ast; ast.parse(open('$RUN_DIR/stompy_server.py').read())\""

check 1 "logging preserved in services" \
  "grep -qi 'logger' '$RUN_DIR/src/services/context_explore_service.py' || grep -qi 'logger' '$RUN_DIR/src/services/context_dashboard_service.py'"

check 1 "service follows existing patterns" \
  "grep -qE 'def __init__|self\.|adapter|get_db' '$RUN_DIR/src/services/context_explore_service.py' || grep -qE 'def __init__|self\.|adapter|get_db' '$RUN_DIR/src/services/context_dashboard_service.py'"

# ── Output JSON ──
DETAILS_JSON=$(printf '%s\n' "${DETAILS[@]}" | paste -sd ',' -)
echo "{\"score\": $SCORE, \"max\": 25, \"checks\": [$DETAILS_JSON]}"
