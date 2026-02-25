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

# mrd_ prefix on legs table
check 1 "mrd_ prefix on legs table" "grep -r 'mrd_shipment_legs' '$RUN_DIR/src/' 2>/dev/null | head -1 | grep -q '.'"

# MRD- prefix on leg IDs
check 1 "MRD- prefix on leg IDs" "grep -r 'MRD-' '$RUN_DIR/src/' 2>/dev/null | grep -qi 'leg'"

# Auth on new endpoints
check 1 "auth on leg endpoints" "grep -r 'legs' '$RUN_DIR/src/routes/' 2>/dev/null | grep -qi 'auth\|middleware\|protect'"

# Response wrapper on new endpoints
check 1 "response wrapper on leg endpoints" "
  LEG_FILES=\$(grep -rl 'legs' '$RUN_DIR/src/routes/' 2>/dev/null);
  if [ -z \"\$LEG_FILES\" ]; then exit 1; fi;
  echo \"\$LEG_FILES\" | head -1 | xargs grep -q 'ok:'
"

# Existing tests preserved (test files from S2 still exist)
check 1 "existing tests preserved" "
  TEST_COUNT=\$(find '$RUN_DIR' -name '*.test.ts' 2>/dev/null | wc -l);
  [ \"\$TEST_COUNT\" -ge 2 ]
"

# Backward compatibility (original endpoints still defined)
check 1 "backward compat maintained" "
  grep -r 'shipments' '$RUN_DIR/src/routes/' 2>/dev/null | grep -qi 'get\|post' &&
  grep -r 'hubs' '$RUN_DIR/src/routes/' 2>/dev/null | grep -qi 'get\|post'
"

DETAILS_JSON=$(printf '%s\n' "${DETAILS[@]}" | paste -sd ',' -)
echo "{\"score\": $SCORE, \"max\": 6, \"checks\": [$DETAILS_JSON]}"
