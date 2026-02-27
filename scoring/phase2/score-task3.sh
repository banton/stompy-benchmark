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

check 1 "rate_limit.py modified" \
  "[ -f '$RUN_DIR/src/middleware/rate_limit.py' ] && [ -s '$RUN_DIR/src/middleware/rate_limit.py' ]"

check 1 "account route file exists" \
  "find '$RUN_DIR/src' -name '*.py' -path '*/routes/*' -exec grep -li 'account\|usage' {} + 2>/dev/null | head -1 | grep -q '.' || find '$RUN_DIR/src' -name 'account*.py' 2>/dev/null | head -1 | grep -q '.'"

check 1 "config externalized" \
  "grep -rqi 'rate.*limit\|RATE.*LIMIT\|rate_config\|limit_config' '$RUN_DIR/src/config/'*.py '$RUN_DIR/src/_config.py' 2>/dev/null || find '$RUN_DIR/src' -name '*.py' -exec grep -li 'RATE_LIMIT.*config\|rate_limit.*settings\|RateLimitConfig' {} + 2>/dev/null | head -1 | grep -q '.'"

check 1 "python syntax valid" \
  "python3 -c \"import py_compile; py_compile.compile('$RUN_DIR/src/middleware/rate_limit.py', doraise=True)\""

check 1 "no hardcoded secrets" \
  "! grep -rqiE '(api_key|password|secret)\s*=\s*[\"'\''][A-Za-z0-9]{8,}' '$RUN_DIR/src/middleware/rate_limit.py' 2>/dev/null"

# ── Functionality (10 pts) ──

check 2 "age-based tier calculation" \
  "grep -rqi 'age\|created_at\|timedelta\|days\|warm.up\|tier' '$RUN_DIR/src/middleware/rate_limit.py' '$RUN_DIR/src/' 2>/dev/null"

check 2 "Redis counters for rate limiting" \
  "grep -rqi 'redis\|incr\|expire\|ttl\|counter\|REDIS' '$RUN_DIR/src/middleware/rate_limit.py' 2>/dev/null || find '$RUN_DIR/src' -name '*.py' -exec grep -li 'redis.*rate\|rate.*redis\|Redis.*limit\|limit.*Redis' {} + 2>/dev/null | head -1 | grep -q '.'"

check 2 "per-account limits" \
  "grep -rqi 'account\|user_id\|per.account\|individual' '$RUN_DIR/src/middleware/rate_limit.py' 2>/dev/null"

check 2 "usage endpoint" \
  "find '$RUN_DIR/src' -name '*.py' -exec grep -li 'usage\|account.*GET\|GET.*account' {} + 2>/dev/null | head -1 | grep -q '.'"

check 2 "admin tier bypass" \
  "grep -rqi 'admin\|bypass\|unlimited\|skip.*rate\|exempt' '$RUN_DIR/src/middleware/rate_limit.py' 2>/dev/null"

# ── Testing (5 pts) ──

check 1 "test file exists for rate limiting" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -li 'rate.*limit\|rate_limit\|RateLimit' {} + 2>/dev/null | head -1 | grep -q '.'"

check 1 "more than 5 test functions" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -c 'def test_' {} + 2>/dev/null | awk -F: '{s+=\$NF} END {exit (s>5?0:1)}'"

check 1 "mocks Redis" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -li 'mock.*redis\|patch.*redis\|Mock.*Redis\|fakeredis\|mock.*Redis\|patch.*Redis' {} + 2>/dev/null | head -1 | grep -q '.' || find '$RUN_DIR/tests' -name '*.py' -exec grep -li 'redis' {} + 2>/dev/null | xargs grep -li 'mock\|patch\|Mock' 2>/dev/null | head -1 | grep -q '.'"

check 1 "tests tier transitions" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -li 'tier\|warm.up\|age\|threshold' {} + 2>/dev/null | head -1 | grep -q '.'"

check 1 "tests usage endpoint" \
  "find '$RUN_DIR/tests' -name '*.py' -exec grep -li 'usage\|GET.*account' {} + 2>/dev/null | head -1 | grep -q '.'"

# ── Integration (5 pts) ──

check 1 "existing rate limits still work" \
  "grep -qE 'def rate_limit|class RateLimit|def check_rate|RateLimiter' '$RUN_DIR/src/middleware/rate_limit.py'"

check 1 "new endpoint requires auth" \
  "find '$RUN_DIR/src' -name '*.py' -path '*account*' -exec grep -li 'auth\|Depends\|require.*auth\|verify' {} + 2>/dev/null | head -1 | grep -q '.' || find '$RUN_DIR/src' -name '*.py' -path '*route*' -exec grep -li 'auth.*account\|account.*auth' {} + 2>/dev/null | head -1 | grep -q '.'"

check 1 "Redis fallback handling" \
  "grep -rqi 'except\|fallback\|default\|ConnectionError' '$RUN_DIR/src/middleware/rate_limit.py' 2>/dev/null"

check 1 "config uses environment vars" \
  "grep -rqi 'os.environ\|os.getenv\|settings\|config' '$RUN_DIR/src/middleware/rate_limit.py' 2>/dev/null || find '$RUN_DIR/src' -name '*.py' -exec grep -li 'RATE.*LIMIT.*env\|rate.*limit.*getenv' {} + 2>/dev/null | head -1 | grep -q '.'"

check 1 "middleware registered properly" \
  "grep -rqi 'rate_limit\|RateLimit' '$RUN_DIR/server_hosted.py' 2>/dev/null || find '$RUN_DIR/src' -name '*.py' -exec grep -li 'rate_limit.*middleware\|middleware.*rate_limit\|add_middleware.*rate' {} + 2>/dev/null | head -1 | grep -q '.'"

# ── Output JSON ──
DETAILS_JSON=$(printf '%s\n' "${DETAILS[@]}" | paste -sd ',' -)
echo "{\"score\": $SCORE, \"max\": 25, \"checks\": [$DETAILS_JSON]}"
