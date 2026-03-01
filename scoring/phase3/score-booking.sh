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

# ══════════════════════════════════════════════════════════════════════
# Structure (8 pts)
# ══════════════════════════════════════════════════════════════════════

check 1 "booking service file exists" \
  "find '$RUN_DIR' -maxdepth 1 -name '*booking*service*' -o -name '*booking*client*' -o -name '*duffel*booking*' | grep -q '.py'"

check 1 "booking route/endpoint file exists" \
  "find '$RUN_DIR' -maxdepth 1 -name '*booking*route*' -o -name '*book*route*' | grep -q '.py' || grep -qiE '/api/v1/book|@router.post.*book|@app.post.*book' '$RUN_DIR/api_server.py' 2>/dev/null"

check 1 "passenger schema models exist" \
  "grep -rqi 'class.*passenger' '$RUN_DIR/api_schemas.py' '$RUN_DIR/'*booking*.py '$RUN_DIR/'*schema*.py 2>/dev/null"

check 1 "frontend booking components exist" \
  "find '$RUN_DIR/frontend/src' -name '*[Bb]ook*' -o -name '*[Pp]assenger*' 2>/dev/null | grep -q '.'"

check 1 "test files for booking exist" \
  "find '$RUN_DIR' -name '*test*booking*' -o -name '*booking*test*' 2>/dev/null | grep -q '.py'"

check 1 "python syntax valid (all new files)" \
  "find '$RUN_DIR' -maxdepth 1 -name '*booking*.py' | grep -q '.py' && find '$RUN_DIR' -maxdepth 1 -name '*booking*.py' -exec python3 -c 'import py_compile; py_compile.compile(\"{}\", doraise=True)' \\; 2>/dev/null"

check 1 "no hardcoded API keys or secrets" \
  "find '$RUN_DIR' -maxdepth 1 -name '*booking*.py' | grep -q '.py' && ! grep -rqiE '(duffl_live_|sk_live_|sk_test_|Bearer [a-zA-Z0-9]{20,})' '$RUN_DIR/'*booking*.py 2>/dev/null"

check 1 "follows existing file naming conventions" \
  "find '$RUN_DIR' -maxdepth 1 -name '*booking*.py' -exec basename {} \\; 2>/dev/null | grep -qE '^[a-z_]+\\.py$'"

# ══════════════════════════════════════════════════════════════════════
# Duffel Booking (8 pts)
# ══════════════════════════════════════════════════════════════════════

check 2 "Duffel Orders API call implemented (POST /air/orders)" \
  "grep -rqi 'air/orders\|/air/orders\|duffel.*order\|create.*order' '$RUN_DIR/'*booking*.py '$RUN_DIR/'*duffel*booking*.py 2>/dev/null"

check 2 "offer validation before booking (check expiry/exists)" \
  "grep -rqi 'offer.*exist\|offer.*expir\|get_offer\|offer_exists\|validate.*offer' '$RUN_DIR/'*booking*.py '$RUN_DIR/'*duffel*booking*.py 2>/dev/null"

check 2 "passenger data formatted for Duffel API" \
  "grep -rqi 'passenger\|given_name\|family_name\|date_of_birth\|born_on' '$RUN_DIR/'*booking*.py '$RUN_DIR/'*duffel*booking*.py 2>/dev/null"

check 2 "booking confirmation/PNR extraction from response" \
  "grep -rqi 'booking_reference\|pnr\|confirmation\|order.*id\|booking_id' '$RUN_DIR/'*booking*.py '$RUN_DIR/'*duffel*booking*.py 2>/dev/null"

# ══════════════════════════════════════════════════════════════════════
# API & Payment (8 pts)
# ══════════════════════════════════════════════════════════════════════

check 2 "POST /api/v1/book endpoint exists" \
  "grep -rqiE '@\\w+\\.(post|route).*book|/api/v1/book|post.*\"/book\"|post.*book' '$RUN_DIR/api_server.py' '$RUN_DIR/'*booking*route*.py '$RUN_DIR/'*book*route*.py 2>/dev/null"

check 2 "GET /api/v1/booking/{id} endpoint exists" \
  "grep -rqiE '@(app|router)\\.get.*booking|/api/v1/booking/|/booking/\\{' '$RUN_DIR/api_server.py' '$RUN_DIR/'*booking*route*.py '$RUN_DIR/'*book*route*.py 2>/dev/null"

check 2 "booking idempotency (prevent double-booking)" \
  "grep -rqi 'idempoten\|duplicate.*book\|double.*book\|booking.*key\|idempotency.*book' '$RUN_DIR/'*booking*.py 2>/dev/null || grep -qi 'booking.*idempoten\|book.*idempoten' '$RUN_DIR/'*payment*.py 2>/dev/null"

check 2 "error handling (expired offer, payment failure, Duffel error)" \
  "grep -rqi 'BookingError\|ExpiredOffer\|PaymentFail\|DuffelError\|raise.*book\|except.*book' '$RUN_DIR/'*booking*.py '$RUN_DIR/'*book*route*.py 2>/dev/null"

# ══════════════════════════════════════════════════════════════════════
# Frontend (8 pts)
# ══════════════════════════════════════════════════════════════════════

check 2 "passenger input form component exists" \
  "find '$RUN_DIR/frontend/src' -name '*[Pp]assenger*' -o -name '*[Bb]ooking*[Ff]orm*' -o -name '*[Bb]ooking*[Pp]age*' -o -name '*[Bb]ook*[Ff]orm*' 2>/dev/null | grep -qE '\\.(jsx|tsx|js|ts)$'"

check 2 "booking confirmation page exists" \
  "find '$RUN_DIR/frontend/src' -name '*[Cc]onfirm*' -o -name '*[Bb]ooking*[Dd]etail*' -o -name '*[Bb]ooking*[Ss]uccess*' 2>/dev/null | grep -qE '\\.(jsx|tsx|js|ts)$'"

check 2 "form validates required fields (name, DOB, etc)" \
  "grep -rqi 'required\|validate\|validation\|error.*field\|field.*error\|must.*provide\|is required' '$RUN_DIR/frontend/src/'*[Bb]ook* '$RUN_DIR/frontend/src/'*[Pp]assenger* '$RUN_DIR/frontend/src/components/'*[Bb]ook* '$RUN_DIR/frontend/src/components/'*[Pp]assenger* '$RUN_DIR/frontend/src/pages/'*[Bb]ook* '$RUN_DIR/frontend/src/pages/'*[Pp]assenger* 2>/dev/null"

check 2 "error state handling (booking failure, timeout)" \
  "grep -rqi 'error\|failed\|failure\|catch\|setError\|errorMessage\|try.*catch' '$RUN_DIR/frontend/src/'*[Bb]ook* '$RUN_DIR/frontend/src/'*[Pp]assenger* '$RUN_DIR/frontend/src/components/'*[Bb]ook* '$RUN_DIR/frontend/src/components/'*[Pp]assenger* '$RUN_DIR/frontend/src/pages/'*[Bb]ook* '$RUN_DIR/frontend/src/pages/'*[Pp]assenger* 2>/dev/null"

# ══════════════════════════════════════════════════════════════════════
# Testing (8 pts)
# ══════════════════════════════════════════════════════════════════════

check 2 "unit tests for booking service (mock Duffel API)" \
  "find '$RUN_DIR' -name '*test*booking*' -exec grep -li 'mock\|Mock\|patch\|MagicMock\|AsyncMock' {} + 2>/dev/null | xargs grep -li 'duffel\|booking\|order' 2>/dev/null | head -1 | grep -q '.'"

check 2 "unit tests for booking endpoint (mock service)" \
  "find '$RUN_DIR' -name '*test*booking*' -exec grep -li 'client\|TestClient\|httpx\|app\|endpoint\|api\|route' {} + 2>/dev/null | head -1 | grep -q '.'"

check 2 "tests cover error cases (expired offer, invalid passenger, payment failure)" \
  "find '$RUN_DIR' -name '*test*booking*' -exec grep -li 'error\|invalid\|expired\|fail\|exception\|reject' {} + 2>/dev/null | head -1 | grep -q '.'"

check 2 "more than 8 test functions total" \
  "find '$RUN_DIR' -name '*test*booking*' -exec grep -c 'def test_\|async def test_' {} + 2>/dev/null | awk -F: '{s+=\$NF} END {exit (s>8?0:1)}'"

# ── Output JSON ──
DETAILS_JSON=$(printf '%s\n' "${DETAILS[@]}" | paste -sd ',' -)
echo "{\"score\": $SCORE, \"max\": 40, \"checks\": [$DETAILS_JSON]}"
