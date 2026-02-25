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

# Structure (4 pts)
check 1 "index.ts exists" "[ -f '$RUN_DIR/src/index.ts' ] && [ -s '$RUN_DIR/src/index.ts' ] && grep -q 'express\|app\|listen' '$RUN_DIR/src/index.ts'"
check 1 "routes file exists" "ls '$RUN_DIR/src/routes/'*.routes.ts 2>/dev/null | head -1 | grep -q '.'"
check 1 "auth middleware exists" "find '$RUN_DIR/src' -name '*auth*' -o -name '*middleware*' 2>/dev/null | head -1 | grep -q '.'"
check 1 "service file exists" "ls '$RUN_DIR/src/services/'*.service.ts 2>/dev/null | head -1 | grep -q '.'"

# Database (4 pts)
check 1 "mrd_shipments table" "grep -r 'mrd_shipments' '$RUN_DIR/src/' 2>/dev/null | grep -qi 'create\|table'"
check 1 "mrd_events table" "grep -r 'mrd_events' '$RUN_DIR/src/' 2>/dev/null | grep -qi 'create\|table'"
check 1 "mrd_hubs table" "grep -r 'mrd_hubs' '$RUN_DIR/src/' 2>/dev/null | grep -qi 'create\|table'"
check 1 "mrd_shipment_legs table" "grep -r 'mrd_shipment_legs' '$RUN_DIR/src/' 2>/dev/null | grep -qi 'create\|table'"

# API (3 pts)
check 1 "hubs endpoint returns ok:true" "grep -r 'ok.*true\|ok:.*true' '$RUN_DIR/src/' 2>/dev/null | grep -qi 'hub\|route'"
check 1 "shipments returns meta.total" "grep -r 'meta\|total\|offset\|limit' '$RUN_DIR/src/' 2>/dev/null | grep -qi 'shipment\|route'"
check 1 "ts field uses epoch ms" "grep -r 'Date.now()\|epoch\|ts:' '$RUN_DIR/src/' 2>/dev/null | head -1 | grep -q '.'"

# Auth (3 pts)
check 1 "401 on no token" "grep -r '401\|Unauthorized\|unauthorized' '$RUN_DIR/src/' 2>/dev/null | head -1 | grep -q '.'"
check 1 "token validation logic" "grep -r 'hmac\|HMAC\|X-Meridian-Auth\|x-meridian-auth' '$RUN_DIR/src/' 2>/dev/null | head -1 | grep -q '.'"
check 1 "expiry check" "grep -r 'expir\|expire\|expired' '$RUN_DIR/src/' 2>/dev/null | head -1 | grep -q '.'"

# State Machine (4 pts)
check 1 "DRAFT to MANIFESTED transition" "grep -r 'MANIFESTED\|manifested' '$RUN_DIR/src/' 2>/dev/null | head -1 | grep -q '.'"
check 1 "dispatcher role check" "grep -r 'dispatcher' '$RUN_DIR/src/' 2>/dev/null | head -1 | grep -q '.'"
check 1 "terminal state enforcement" "grep -r 'DELIVERED\|RETURNED\|terminal' '$RUN_DIR/src/' 2>/dev/null | head -1 | grep -q '.'"
check 1 "creates event on transition" "grep -r 'mrd_events\|INSERT.*event\|event.*INSERT' '$RUN_DIR/src/' 2>/dev/null | grep -qi 'insert\|create'"

# Multi-Leg (4 pts)
check 1 "POST legs endpoint" "grep -r 'legs\|leg' '$RUN_DIR/src/' 2>/dev/null | grep -qi 'post\|router\|route'"
check 1 "PATCH leg transition" "grep -r 'legs\|leg' '$RUN_DIR/src/' 2>/dev/null | grep -qi 'patch\|transition'"
check 1 "GET includes legs" "grep -r 'legs\|shipment_legs' '$RUN_DIR/src/' 2>/dev/null | grep -qi 'select\|get\|find\|include'"
check 1 "status derives from legs" "grep -r 'leg.*status\|derive\|latest.*leg' '$RUN_DIR/src/' 2>/dev/null | head -1 | grep -q '.'"

# Tests (3 pts)
check 1 "npm test script exists" "[ -f '$RUN_DIR/package.json' ] && grep -q '\"test\"' '$RUN_DIR/package.json'"
check 1 "more than 10 test cases" "find '$RUN_DIR' -name '*.test.ts' -exec grep -c 'it(\|test(' {} + 2>/dev/null | awk -F: '{s+=\$NF} END {exit (s>10?0:1)}'"
check 1 "integration test exists" "find '$RUN_DIR' -name '*.test.ts' -exec grep -l 'supertest\|request\|fetch\|integration' {} + 2>/dev/null | head -1 | grep -q '.'"

# Output JSON
DETAILS_JSON=$(printf '%s\n' "${DETAILS[@]}" | paste -sd ',' -)
echo "{\"score\": $SCORE, \"max\": 25, \"checks\": [$DETAILS_JSON]}"
