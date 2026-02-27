# Task 3 — Per-Account Rate Limiting with Age-Based Thresholds (Stompy Memory Condition)

You are working on the **Stompy MCP Server** codebase (`dementia-production`). This is a Python/FastAPI/PostgreSQL application with Redis for caching and rate limiting. This is a complex full-stack feature that touches middleware, Redis, API routes, and configuration.

## Before You Start

1. **Recall relevant contexts from Stompy MCP:**
   - `recall_context("devops_infrastructure_overview")` — infrastructure overview including Redis
   - `context_search("rate limit")` — find any context about rate limiting architecture
   - `context_search("middleware")` — understand the middleware chain
   - `context_search("auth")` — understand authentication and user identification
   - `context_search("Redis")` — understand Redis usage patterns
   - `context_search("API routes")` — understand how routes are registered
   - `context_search("configuration")` — understand config patterns
   - `context_search("user tier")` — understand user tier/account system
   - `ticket(action="read", ticket_id=68, project="stompy")` — read the ticket for this task
   - `ticket_board(project="stompy")` — see related tickets and priorities

2. Use the recalled context to understand the codebase architecture before writing any code.

3. Only explore the codebase directly if Stompy doesn't have the context you need.

## Task Specification

### Overview

The current rate limiting in `src/middleware/rate_limit.py` uses a simple global rate limit. We need per-account rate limiting with age-based thresholds: new accounts start with conservative limits that ramp up over time.

### Requirements

1. **Age-based rate limit tiers:**
   - **Warm-up tier** (account age 0-7 days): 10 requests/minute, 500 requests/day, 5,000 requests/month
   - **Standard tier** (account age 7-30 days): 30 requests/minute, 2,000 requests/day, 30,000 requests/month
   - **Established tier** (account age 30+ days): 60 requests/minute, 5,000 requests/day, 100,000 requests/month
   - **Admin tier**: unlimited (bypass all rate limits)

2. **Redis-based counters:**
   - Per-account counters with appropriate TTLs: `rate:{account_id}:min`, `rate:{account_id}:day`, `rate:{account_id}:month`
   - Use Redis INCR + EXPIRE for atomic counter management
   - Minute counter: 60s TTL, Day counter: 86400s TTL, Month counter: 2592000s TTL

3. **New API endpoint — `GET /api/v1/account/usage`:**
   - Returns current usage counts (minute/day/month) for the authenticated account
   - Returns the account's current tier and limits
   - Returns account age and when the next tier upgrade happens
   - Requires authentication
   - Response format: `{ "tier": "standard", "account_age_days": 15, "next_tier_at_days": 30, "usage": { "minute": { "current": 5, "limit": 30 }, "day": { "current": 150, "limit": 2000 }, "month": { "current": 3000, "limit": 30000 } } }`

4. **Configuration externalization:**
   - Move tier thresholds and limits to configuration (e.g., `src/config/thresholds.py` or `src/_config.py`)
   - Allow override via environment variables
   - Default values as specified above

5. **Admin bypass:**
   - Admin-tier accounts skip all rate limit checks
   - Determine admin status from the authenticated user's role/tier
   - Log rate limit bypasses for admin accounts at DEBUG level

6. **Graceful Redis failure:**
   - If Redis is unavailable, fall back to allowing requests (fail-open)
   - Log Redis connection failures
   - Do not crash the application if Redis goes down

### Files to Modify/Create

- `src/middleware/rate_limit.py` — enhance with per-account, age-based logic
- `src/config/thresholds.py` or `src/_config.py` — rate limit configuration
- Create `src/api/routes/account.py` — new usage endpoint
- `src/api/dependencies.py` or equivalent — wire up the new route
- `server_hosted.py` — register the new route if needed
- Create test file(s) in `tests/` directory

### Testing Requirements

Write pytest tests covering:
- Tier calculation based on account age (0, 7, 15, 30, 60 days)
- Rate limit enforcement per tier (minute/day/month limits)
- Admin bypass (no rate limiting)
- Redis counter increment and TTL behavior (mock Redis)
- Usage endpoint returns correct data
- Usage endpoint requires authentication
- Redis failure fallback (mock Redis ConnectionError)
- Tier transition at boundary days
- At least 8 test functions

### Acceptance Criteria

- [ ] Per-account rate limiting with 3 tiers + admin bypass
- [ ] Redis counters with correct TTLs (minute/day/month)
- [ ] `GET /api/v1/account/usage` endpoint works and requires auth
- [ ] Tier thresholds externalized to config
- [ ] Admin accounts bypass rate limits
- [ ] Graceful Redis failure (fail-open)
- [ ] At least 8 test functions covering tiers, limits, Redis, admin, usage endpoint
- [ ] All modified Python files have valid syntax
- [ ] Existing rate limiting functionality preserved
- [ ] Config allows environment variable overrides
