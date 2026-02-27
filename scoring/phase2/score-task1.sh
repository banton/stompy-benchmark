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

check 1 "project_delete tool modified" \
  "grep -qi 'preview\|count\|data_counts\|confirm.*false' '$RUN_DIR/stompy_server.py'"

check 1 "count/preview method in service" \
  "find '$RUN_DIR/src/services' -name '*.py' -exec grep -li 'count\|preview\|data_count' {} + 2>/dev/null | head -1 | grep -q '.'"

check 1 "test file exists" \
  "find '$RUN_DIR/tests' -name '*.py' 2>/dev/null | xargs grep -li 'project.*delete\|project.*preview\|delete.*preview\|preview.*project' 2>/dev/null | head -1 | grep -q '.'"

check 1 "python syntax valid" \
  "python3 -c \"import py_compile; py_compile.compile('$RUN_DIR/stompy_server.py', doraise=True)\""

check 1 "no new non-test dependencies" \
  "[ ! -f '$RUN_DIR/requirements.txt' ] || diff <(grep -v 'pytest\|mock\|faker\|coverage\|hypothesis' '$RUN_DIR/requirements.txt' 2>/dev/null || true) <(grep -v 'pytest\|mock\|faker\|coverage\|hypothesis' '$RUN_DIR/requirements.txt.orig' 2>/dev/null || grep -v 'pytest\|mock\|faker\|coverage\|hypothesis' '$RUN_DIR/requirements.txt' 2>/dev/null || true) >/dev/null 2>&1"

# ── Functionality (10 pts) ──

check 2 "counts contexts" \
  "grep -rqi 'context_locks\|COUNT.*context' '$RUN_DIR/src/services/' '$RUN_DIR/stompy_server.py' 2>/dev/null"

check 2 "counts memories" \
  "grep -rqi 'memory_entries\|COUNT.*memor' '$RUN_DIR/src/services/' '$RUN_DIR/stompy_server.py' 2>/dev/null"

check 2 "counts tickets" \
  "grep -rqi 'tickets\|COUNT.*ticket' '$RUN_DIR/src/services/' '$RUN_DIR/stompy_server.py' 2>/dev/null"

check 2 "counts files" \
  "grep -rqi 'file_tags\|COUNT.*file' '$RUN_DIR/src/services/' '$RUN_DIR/stompy_server.py' 2>/dev/null"

check 2 "returns counts in preview response" \
  "grep -rqi 'preview\|counts\|data_counts' '$RUN_DIR/src/services/' '$RUN_DIR/stompy_server.py' 2>/dev/null && grep -rqi 'dict\|Dict\|return.*{' '$RUN_DIR/src/services/' '$RUN_DIR/stompy_server.py' 2>/dev/null"

# ── Testing (5 pts) ──

check 1 "more than 3 test functions" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -c 'def test_' {} + 2>/dev/null | awk -F: '{s+=\$NF} END {exit (s>3?0:1)}'"

check 1 "tests happy path" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -li 'test.*preview\|test.*count' {} + 2>/dev/null | xargs grep -l 'assert' 2>/dev/null | head -1 | grep -q '.'"

check 1 "tests empty project" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -li 'empty\|no_data\|zero' {} + 2>/dev/null | head -1 | grep -q '.'"

check 1 "tests error case" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -li 'error\|invalid\|not_found\|exception' {} + 2>/dev/null | head -1 | grep -q '.'"

check 1 "uses mock/patch for DB" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -li 'mock\|patch\|Mock\|MagicMock' {} + 2>/dev/null | head -1 | grep -q '.'"

# ── Integration (5 pts) ──

check 1 "confirm=true still deletes" \
  "grep -rqi 'confirm.*True\|confirm.*true' '$RUN_DIR/stompy_server.py' '$RUN_DIR/src/services/' 2>/dev/null && grep -rqi 'delete' '$RUN_DIR/stompy_server.py' '$RUN_DIR/src/services/' 2>/dev/null"

check 1 "backward compatible signature" \
  "grep -qE 'def project_delete|async def project_delete' '$RUN_DIR/stompy_server.py' '$RUN_DIR/src/services/'*.py 2>/dev/null"

check 1 "no circular imports (AST parses)" \
  "python3 -c \"import ast; ast.parse(open('$RUN_DIR/stompy_server.py').read())\""

check 1 "uses existing DB patterns" \
  "find '$RUN_DIR/src/services' -name '*.py' -newer '$RUN_DIR/stompy_server.py' -exec grep -li 'get_db\|_get_db\|postgres_adapter\|execute\|fetchone\|fetchall' {} + 2>/dev/null | head -1 | grep -q '.' || grep -qi 'get_db\|_get_db\|postgres_adapter\|execute\|fetchone\|fetchall' '$RUN_DIR/stompy_server.py' 2>/dev/null"

check 1 "logging preserved" \
  "grep -rqi 'logger\|logging\|log\.' '$RUN_DIR/stompy_server.py' '$RUN_DIR/src/services/' 2>/dev/null"

# ── Output JSON ──
DETAILS_JSON=$(printf '%s\n' "${DETAILS[@]}" | paste -sd ',' -)
echo "{\"score\": $SCORE, \"max\": 25, \"checks\": [$DETAILS_JSON]}"
