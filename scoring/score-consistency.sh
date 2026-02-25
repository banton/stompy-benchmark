#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="${1:?Usage: $0 <run-directory>}"
SCORE=0
DETAILS=()

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

# Response wrapper consistency - all routes use { ok, ts, data }
check 1 "response wrapper consistent" "
  ROUTE_FILES=\$(find '$RUN_DIR/src' -name '*.routes.ts' 2>/dev/null);
  if [ -z \"\$ROUTE_FILES\" ]; then exit 1; fi;
  ALL_HAVE=true;
  for f in \$ROUTE_FILES; do
    if ! grep -q 'ok:' \"\$f\" && ! grep -q 'ok,' \"\$f\"; then
      ALL_HAVE=false;
    fi;
  done;
  \$ALL_HAVE
"

# ID format - MRD- prefix used consistently
check 1 "ID format consistent" "
  grep -r 'MRD-\|mrd-' '$RUN_DIR/src/' 2>/dev/null | grep -qi 'nanoid\|MRD' &&
  ! grep -r 'uuid\|UUID\|uuidv4' '$RUN_DIR/src/' 2>/dev/null | grep -q '.'
"

# File naming convention
check 1 "file naming consistent" "
  ls '$RUN_DIR/src/routes/'*.routes.ts 2>/dev/null | head -1 | grep -q '.' &&
  ls '$RUN_DIR/src/services/'*.service.ts 2>/dev/null | head -1 | grep -q '.'
"

# Test setup pattern - consistent test infrastructure
check 1 "test setup consistent" "
  TEST_FILES=\$(find '$RUN_DIR' -name '*.test.ts' 2>/dev/null);
  if [ -z \"\$TEST_FILES\" ]; then exit 1; fi;
  echo \"\$TEST_FILES\" | head -1 | xargs grep -q 'describe\|beforeAll\|beforeEach'
"

# Error handling - consistent error responses
check 1 "error handling consistent" "
  grep -r 'error.*code\|error.*message\|VALIDATION_ERROR\|NOT_FOUND' '$RUN_DIR/src/' 2>/dev/null | wc -l | awk '{exit (\$1>=3?0:1)}'
"

# DB connection - single connection pattern
check 1 "DB connection consistent" "
  grep -r 'better-sqlite3\|Database\|sqlite' '$RUN_DIR/src/' 2>/dev/null | head -1 | grep -q '.'
"

DETAILS_JSON=$(printf '%s\n' "${DETAILS[@]}" | paste -sd ',' -)
echo "{\"score\": $SCORE, \"max\": 6, \"checks\": [$DETAILS_JSON]}"
