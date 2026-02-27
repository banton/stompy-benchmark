# Stompy Project — Task Board

> Auto-generated from project ticket system. 161 tickets across all categories.
> Last updated: 2026-02-27

## Summary
- Total tickets: 161 (+ 4 archived)
- Backlog: 69 | Proposed: 17 | Triage: 1 | Done: 15 | Resolved: 34 | Shipped: 2 | Cancelled: 1 | Rejected: 1 | Won't Fix: 21

---

## By Status

### Backlog (69)

| # | Title | Type | Priority | Tags |
|---|-------|------|----------|------|
| 5 | [DEM-11] Email Delivery via Forwardemail | task | urgent | — |
| 4 | [DEM-12] Stripe Webhook Endpoint | task | urgent | — |
| 3 | [DEM-7] Stripe Customer Portal Integration | task | urgent | — |
| 2 | [DEM-6] Payment failure dunning and suspension flow | task | urgent | — |
| 1 | [DEM-5] Stripe subscription billing integration | task | urgent | billing, linear-import |
| 132 | Tests: Implement Parallel DB Isolation for Integration Tests | task | high | — |
| 129 | Tests: Migrate external API mocks to httpx/respx and handle BackgroundTasks | task | high | — |
| 126 | Performance: Use Async DB calls in Admin endpoints | task | high | — |
| 125 | Performance: Replace synchronous `requests` with async `httpx` in external API calls | task | high | — |
| 124 | Performance: Migrate EmailNotificationService to use BackgroundTasks | task | high | — |
| 119 | Reduce Auth0 token validation latency on cache misses | task | high | — |
| 109 | Integrate Shannon AI Pentester for automated security testing | task | high | security, testing, pentest, shannon, automation |
| 73 | Register CLI OAuth client in Auth0 | task | high | — |
| 72 | Set up GitHub Actions CI/CD for stompy-cli releases | task | high | — |
| 13 | [DEM-163] MCP Directory Submissions: Public Beta Launch Campaign | task | high | — |
| 11 | [DEM-16] Usage Dashboard with Quota Tracking | task | high | — |
| 10 | [DEM-271] Frontend: Handle error stages in file upload progress | task | high | — |
| 9 | [DEM-251] Fix SSL certificate for status.stompy.ai | task | high | — |
| 8 | [DEM-266] Increase project storage quota - 507 errors blocking uploads | task | high | — |
| 146 | detect_conflicts cold start takes 241s — needs performance investigation | task | medium | — |
| 133 | Tests: Fix PytestDeprecationWarning for asyncio_default_fixture_loop_scope | task | medium | — |
| 130 | Tests: Fix Asyncio Event Loop Collisions with Session-Scoped Fixtures | task | medium | — |
| 128 | Performance: Add Redis caching for frequently accessed Bug Report stats | task | medium | — |
| 127 | Performance: Implement async batching for `execute_many` bulk inserts | task | medium | — |
| 123 | Paginate and compress large JSON responses | task | medium | — |
| 122 | Index provisioning_jobs for faster scheduler pickup | task | medium | — |
| 121 | Add read-through caching for frequent REST reads | task | medium | — |
| 120 | Optimize DB session setup for PgBouncer transaction pooling | task | medium | — |
| 118 | Enforce HTTPS for API URL in frontend auth fetches | task | medium | — |
| 117 | Restrict E2E test auth mode in production builds | task | medium | — |
| 57 | [DEM-228] Operational Runbooks | task | medium | — |
| 56 | [DEM-227] Fleet Health Monitoring | task | medium | — |
| 55 | [DEM-226] Admin User Management Dashboard | task | medium | — |
| 54 | [DEM-78] Implement System Health page | task | medium | — |
| 46 | [DEM-235] Account Closure - Backend API | task | medium | — |
| 45 | [DEM-233] Data Export - Backend service | task | medium | — |
| 44 | [DEM-232] Schema: Account deletion state management | task | medium | — |
| 43 | [DEM-267] Test presigned URL implementation for per-user storage | task | medium | — |
| 42 | [DEM-206] Neon Management API Client | task | medium | — |
| 41 | [DEM-205] User Catalog Schema (mcp_global) | task | medium | — |
| 40 | [DEM-186] Enable autoscaling for production infrastructure | task | medium | — |
| 39 | [DEM-77] Implement Context Browser page | task | medium | — |
| 38 | [DEM-224] Account Deletion (GDPR) | task | medium | — |
| 37 | [DEM-141] Defer embedding generation until first search or batch job | task | medium | — |
| 36 | [DEM-139] Implement chunk hash deduplication to reduce VoyageAI API calls | task | medium | — |
| 30 | [DEM-244] Task Memory System: Project View and Admin UI | task | medium | — |
| 29 | [DEM-243] Task Memory System: Database Migration and MCP Tools | task | medium | — |
| 28 | [DEM-225] Closed Beta Invite System | task | medium | — |
| 27 | [DEM-22] PostHog Product Analytics | task | medium | — |
| 26 | [DEM-181] Multi-Tenant Stress Testing (Phase 2) | task | medium | — |
| 25 | [DEM-173] Implement S3 file cleanup on project deletion | task | medium | — |
| 24 | [DEM-25] Load Testing with k6 | task | medium | — |
| 23 | [DEM-19] Admin Dashboard (Internal) | task | medium | — |
| 22 | [DEM-18] Plain.com Support Ticket System | task | medium | — |
| 21 | [DEM-229] Frontend: User Usage Dashboard Page | task | medium | — |
| 20 | [DEM-222] Usage Metering | task | medium | — |
| 19 | [DEM-203] Create Billing API Endpoints | task | medium | — |
| 18 | [DEM-202] Build Tier Change Workflow | task | medium | — |
| 17 | [DEM-201] Implement Subscription Management | task | medium | — |
| 16 | [DEM-200] Integrate Stripe Customer Creation | task | medium | — |
| 15 | [DEM-270] Implement MCP session auth expiry awareness | task | medium | — |
| 14 | [DEM-275] Refactor deprecated global_embedding_service to use tenant-isolated get_embedding_service() | task | medium | — |
| 53 | [DEM-177] Show context/session/file counts in delete project confirmation dialog | task | low | — |
| 52 | [DEM-175] Disable file stats in project page until file ingestion is implemented | task | low | — |
| 51 | [DEM-169] User profile dropdown - add settings access | task | low | — |
| 50 | [DEM-170] Add legend for priority color indicators on contexts page | task | low | — |
| 49 | [DEM-152] Cloud-based context summarization | task | low | — |
| 48 | [DEM-151] Admin Panel: Project export/import | task | low | — |
| 47 | [DEM-245] Account Settings Page | task | low | — |

### Proposed (17)

| # | Title | Type | Priority | Tags |
|---|-------|------|----------|------|
| 71 | Build CLI downloads page on stompy-web | feature | high | — |
| 59 | feat: Bridge semantic search to vectorized post corpus | feature | high | — |
| 58 | feat: Add batch recall_contexts() for multi-topic loading | feature | high | — |
| 162 | project_delete preview doesn't show data counts before destructive action | feature | medium | ux, project_delete, staging-dogfood |
| 74 | Add waitlist signup link and CLI announcement to stompy-web landing page | feature | medium | — |
| 70 | Wire up error reference codes to real error tracking | feature | medium | — |
| 69 | OAuth post-login redirect and thank-you page | feature | medium | — |
| 68 | Per-account rate limiting with age-based thresholds | feature | medium | beta, security, rate-limiting, deferred |
| 63 | fix: Improve semantic search for conceptual adjacency queries | feature | medium | — |
| 61 | feat: Add similar_posts() tool for content deduplication | feature | medium | — |
| 60 | feat: Implement tiered context loading with compact summaries | feature | medium | — |
| 35 | [DEM-254] Admin Dashboard - Privacy-First User Management | feature | medium | — |
| 34 | [DEM-56] [Epic] Batch Processing Infrastructure | feature | medium | — |
| 33 | [DEM-48] [Epic] Project Schema Templates | feature | medium | — |
| 32 | [DEM-40] [Epic] Temporal Knowledge Graph | feature | medium | — |
| 31 | [DEM-36] [Epic] Hierarchical Summarization Engine | feature | medium | — |
| 62 | feat: Add context size warnings when total loaded exceeds threshold | feature | low | — |

### Triage (1)

| # | Title | Type | Priority | Tags |
|---|-------|------|----------|------|
| 145 | get_query_page: query_ids never returned — dead feature? | bug | low | — |

### Resolved (34)

| # | Title | Type | Priority | Tags |
|---|-------|------|----------|------|
| 89 | CRITICAL: Deleted project data accessible via cache | bug | urgent | dogfood, security, cache, deletion, privacy |
| 154 | SAVEPOINT error on context_search for brand new projects (semantic path) | bug | high | — |
| 150 | schema_patcher deletes properties named 'title' and skips plugin tools | bug | high | — |
| 113 | Enforce read-only guarantees for db_query tool | bug | high | — |
| 114 | Invalidate Redis token cache on logout | bug | high | — |
| 112 | Harden OAuth state handling when DB unavailable | bug | high | — |
| 115 | Avoid shared-DB fallback for unprovisioned users | bug | high | — |
| 111 | Harden OAuth state handling when DB unavailable | bug | high | — |
| 110 | Harden OAuth state handling when DB unavailable | bug | high | — |
| 139 | Ticket history not tracking state transitions | bug | high | — |
| 138 | Tags column always NULL — stored in metadata JSON only | bug | high | — |
| 104 | HIGH: TruffleHog --only-verified flag ignores internal secrets and database passwords | bug | high | — |
| 103 | HIGH: CI/CD Security Workflows Fail-Open, Allowing Vulnerabilities to Merge | bug | high | — |
| 101 | HIGH: Lack of Tenant Authorization Checks Allows Cross-Schema Data Access (IDOR) | bug | high | — |
| 100 | HIGH: Non-deterministic hash() used for distributed advisory locks defeats concurrency protection | bug | high | — |
| 99 | HIGH: Masking Exceptions Causes Transaction Cascades in migration_runner | bug | high | — |
| 98 | HIGH: Unbounded Thread-Local Connection Leak in postgres_adapter | bug | high | — |
| 90 | Priority system exists in two divergent layers (API vs DB) | bug | high | — |
| 87 | db_query markdown format returns empty output for valid queries | bug | high | — |
| 86 | detect_conflicts evaluates 0 pairs despite contradictory content | bug | high | — |
| 85 | lock_context shows [embedding deferred] even when lazy=false | bug | high | — |
| 158 | recall_context silently accepts nonexistent projects — no INVALID_PROJECT error | bug | medium | — |
| 88 | get_query_page requires project but schema says optional; tool is orphaned | bug | medium | — |
| 91 | resolve_conflict shows wrong previous_status | bug | medium | — |
| 135 | lock_context _get_next_version should fail if version already exists | bug | medium | — |
| 134 | project_list memories count differs from project_info | bug | medium | — |
| 141 | Conflict detection misses factual contradictions in short texts | bug | medium | — |
| 142 | SAVEPOINT error on context_search with complex queries | bug | medium | — |
| 105 | MEDIUM: Unpinned Dependencies and Git Plugin URLs Introduce Supply Chain Risks | bug | medium | — |
| 102 | MEDIUM: OAuth and MCP rate limiting fails completely open when Redis is unavailable | bug | medium | — |
| 140 | context_dashboard least_accessed shows most-accessed items | bug | medium | — |
| 96 | unlock_context leaks raw ForeignKeyViolation error | bug | medium | — |
| 164 | recall_batch fails entirely when one topic is empty string instead of skipping it | bug | low | — |
| 136 | context_explore should label user_global contexts separately | bug | low | — |

### Done (15)

| # | Title | Type | Priority | Tags |
|---|-------|------|----------|------|
| 12 | [DEM-149] Add GET /api/v1/me endpoint for connection testing | task | high | — |
| 108 | Set up staging environment for security testing and QA | task | high | — |
| 131 | Tests: Implement Parallel DB Isolation for Integration Tests | task | high | — |
| 107 | External Codebase Audit — OpenAI Codex 5.3 Deep Review | task | high | — |
| 77 | Move db_execute to admin plugin only, remove from core server | task | medium | — |
| 116 | Pin production Python dependencies | task | medium | — |
| 148 | Dogfood Test Ticket - MCP Ticket System Verification | task | medium | — |
| 137 | Dogfood Feb 23 2026 — ticket creation test | task | medium | — |
| 82 | CLI dogfood v3 link target | task | medium | — |
| 79 | Dogfood v2 test ticket | task | medium | — |
| 84 | Dogfood link target ticket | task | low | — |
| 83 | Dogfood test ticket — verify creation works | task | low | — |
| 81 | CLI dogfood v3 test ticket | task | low | — |
| 80 | Dogfood v2 link target | task | low | — |
| 75 | CLI dogfood test ticket | task | low | — |

### Shipped (2)

| # | Title | Type | Priority | Tags |
|---|-------|------|----------|------|
| 76 | Bug reports should be tickets, not a write-only table | feature | high | cli, mcp, bug-reports, ticketing |
| 78 | Implement CLI self-update mechanism | feature | high | — |

### Cancelled (1)

| # | Title | Type | Priority | Tags |
|---|-------|------|----------|------|
| 92 | Test with SQL injection: '; DROP TABLE tickets; -- | task | medium | — |

### Rejected (1)

| # | Title | Type | Priority | Tags |
|---|-------|------|----------|------|
| 147 | Add batch ticket operations (batch_close, batch_move) | feature | medium | — |

### Won't Fix (21)

| # | Title | Type | Priority | Tags |
|---|-------|------|----------|------|
| 165 | recall_batch returns v1.0 for butter_vs_margarine while recall_context returns v1.1 | bug | urgent | — |
| 153 | recall_context version="latest" still returns v1.0 instead of actual latest | bug | urgent | — |
| 97 | CRITICAL: SQL Injection in stompy-ticketing schema interpolation | bug | urgent | — |
| 161 | context_search returns superseded v1.0 with HIGHER relevance than latest v1.1 | bug | high | — |
| 159 | db_query allows multiple SQL statements via semicolons | bug | high | — |
| 155 | check_violations=true changes search behavior — finds 0 results when same query without it finds matches | bug | high | — |
| 152 | check_violations returns nothing for obvious rule violations | bug | high | — |
| 151 | Semantic search always falls back to keyword — never finds matches above threshold | bug | high | — |
| 7 | [DEM-269] File deletion lacks transaction safety - potential for orphaned files | bug | high | — |
| 6 | [DEM-273] Backend: File upload hangs - ingest endpoint not responding | bug | high | — |
| 156 | lock_context accepts contradictory v1.1 silently — no warning when new version contradicts previous | bug | medium | — |
| 157 | Cloudflare WAF blocks legitimate content containing SQL-like strings | bug | medium | — |
| 163 | batch_close defaults to negative statuses (wont_fix, rejected) instead of positive | bug | medium | — |
| 160 | db_query JSON format dumps full embedding vectors (1024 floats) | bug | medium | — |
| 106 | MEDIUM: Frontend Dependabot Ignores Minor Security Updates for Production Packages | bug | medium | — |
| 93 | ticket close action sets status to "cancelled" not "done" | bug | medium | — |
| 144 | context_explore verbose mode missing full content previews | bug | low | — |
| 143 | Delta evaluation not catching near-duplicate content | bug | low | — |
| 95 | project_info shows phantom memory count on new projects | bug | low | — |
| 94 | get_breadcrumbs tool filter returns empty for lock_context calls | bug | low | — |
| 149 | Dogfood Test Ticket 2 - For Linking | bug | low | — |

---

## Ticket Details

### #162 — project_delete preview doesn't show data counts before destructive action
**Status**: proposed | **Type**: feature | **Priority**: medium
**Tags**: ux, project_delete, staging-dogfood
**Created**: 2026-02-27

**Description**:
project_delete(confirm=false) only says "Deleting project will permanently delete ALL data!" but doesn't tell the user WHAT or HOW MUCH data would be deleted. Before confirming a destructive delete, users should see: "This will delete: 7 contexts, 0 tickets, 3 archived items" etc. Currently there's no way to know what you're about to lose without manually querying first. Tested on sarahs_cookbook project with 7 contexts.

---

### #68 — Per-account rate limiting with age-based thresholds
**Status**: proposed | **Type**: feature | **Priority**: medium
**Tags**: beta, security, rate-limiting, deferred
**Created**: 2026-02-09

**Description**:

## Context

Current rate limiting is tier-based (beta: 60 req/min MCP, 20 req/min REST). All beta users get the same limits regardless of account age. If a bad actor gets a beta invite, they can immediately hammer the API at full rate.

**Trigger**: Implement if we see abuse patterns during beta. Not needed day-one.

## Design

### Account Age Tiers

| Account Age | MCP Rate | REST Rate | File Upload | Notes |
|-------------|----------|-----------|-------------|-------|
| 0-24h | 10/min | 5/min | 2/hour | Warm-up period |
| 1-7 days | 30/min | 10/min | 10/hour | Ramping up |
| 7-30 days | 60/min | 20/min | 30/hour | Full beta limits |
| 30+ days | 60/min | 20/min | 30/hour | Same as full beta |

Account age = `NOW() - users.created_at` from `mcp_global.users`.

### Daily/Monthly Usage Budgets

| Budget | Beta Limit | Admin |
|--------|-----------|-------|
| MCP calls/day | 5,000 | unlimited |
| REST calls/day | 1,000 | unlimited |
| File uploads/day | 50 | unlimited |
| Storage/month | 100MB | 10GB |

### User Web UI — Account Usage Dashboard

Add a usage/limits section to the user's account page in stompy-web. Users should see their current limits and usage transparently.

**Account page (`/account` or `/settings`):**

1. **Current Tier & Age** — show account age tier (Warm-up / Ramping / Full) with progress indicator toward next tier unlock
2. **Rate Limits** — display current MCP and REST rate limits for their tier, with a note explaining they increase automatically over time
3. **Daily Usage** — progress bars showing today's usage vs daily budget:
   - MCP calls: 342 / 5,000
   - REST calls: 18 / 1,000
   - File uploads: 3 / 50
4. **Monthly Storage** — storage used vs quota: 12.4 MB / 100 MB
5. **Budget Reset Timer** — "Daily limits reset in 4h 23m" countdown
6. **Rate Limit Events** — last 7 days of 429 responses (if any), so users can see when they hit limits

**API endpoint:** `GET /api/v1/account/usage` returns:
```json
{
  "tier": "beta",
  "age_tier": "ramping",
  "account_age_days": 4,
  "next_tier_unlock_days": 3,
  "rate_limits": {
    "mcp_per_min": 30,
    "rest_per_min": 10,
    "file_uploads_per_hour": 10
  },
  "daily_usage": {
    "mcp_calls": 342,
    "mcp_budget": 5000,
    "rest_calls": 18,
    "rest_budget": 1000,
    "file_uploads": 3,
    "file_upload_budget": 50,
    "resets_at": "2026-02-09T00:00:00Z"
  },
  "monthly_usage": {
    "storage_bytes": 13003776,
    "storage_budget_bytes": 104857600,
    "resets_at": "2026-03-01T00:00:00Z"
  }
}
```

**Frontend files to add/modify:**
| File | Change |
|------|--------|
| `stompy-web/src/app/account/page.tsx` | New or extend account page with usage section |
| `stompy-web/src/components/usage-dashboard.tsx` | New component: progress bars, tier badge, reset timer |
| `stompy-web/src/lib/api.ts` | Add `getAccountUsage()` API client function |

### Implementation Approach

1. **Redis counters** — already have Redis for rate limiting. Add daily/monthly counters keyed by `user:{internal_id}:daily:{date}` and `user:{internal_id}:monthly:{month}`.

2. **Account age lookup** — cache `users.created_at` in Redis (TTL 1h). Compute age tier on each request. Cost: 1 Redis GET per request (sub-ms).

3. **Middleware integration** — extend existing `MCPRateLimitMiddleware` and `OAuthRateLimitMiddleware` in `src/middleware/rate_limit.py`. Add age-tier lookup before checking limits.

4. **Budget enforcement** — new middleware or extend existing. Check daily counter, return 429 with `Retry-After` header and budget reset time.

5. **Admin override** — admin tier bypasses all age/budget limits (existing pattern).

6. **Usage API** — new `GET /api/v1/account/usage` endpoint reads Redis counters + user record. Lightweight, cacheable (30s TTL).

### Backend Files to Modify

| File | Change |
|------|--------|
| `src/middleware/rate_limit.py` | Add age-tier lookup, daily/monthly counters |
| `server_hosted.py` | Wire new middleware (if separate) |
| `src/api/dependencies.py` | Add `get_account_age_tier()` dependency |
| `src/api/routes/account.py` | New: `GET /api/v1/account/usage` endpoint |
| `src/_config.py` | Add budget constants |

### Anomaly Detection (Phase 2)

If needed, add basic anomaly detection:
- Flag accounts making >3x their tier limit in attempts (even if blocked)
- Alert on accounts that hit budget ceiling 3 days in a row
- Auto-suspend accounts with >10x normal error rates (possible credential stuffing)

Store alerts in `mcp_global.security_events` table. Surface via admin dashboard.

### Monitoring

- Structured log field `rate_limit_tier: "warmup" | "ramping" | "full"` on every request
- Redis counter `rate_limit:budget_exhausted:{user_id}` for budget hits
- Admin endpoint `GET /admin/rate-limits` to view per-user usage

## Acceptance Criteria

- [ ] New beta accounts start with warm-up limits (10 req/min MCP)
- [ ] Limits increase automatically after 24h and 7 days
- [ ] Daily budget enforced with clear 429 response including reset time
- [ ] Admin accounts unaffected
- [ ] `GET /api/v1/account/usage` returns current limits, usage, and reset times
- [ ] Web UI shows tier badge, usage progress bars, and budget reset timer
- [ ] Users can see their rate limit history (last 7 days of 429s)
- [ ] Existing rate limit tests still pass
- [ ] New tests for age-tier transitions and budget enforcement

## Dependencies

- Redis (already deployed)
- `mcp_global.users.created_at` column (already exists)
- stompy-web account page (may need new route)
- No new infrastructure needed

---

### #89 — CRITICAL: Deleted project data accessible via cache
**Status**: resolved | **Type**: bug | **Priority**: urgent
**Tags**: dogfood, security, cache, deletion, privacy

**Description**:
After project_delete(name="dogfood_test_project_2026"), recall_context(topic="ephemeral_test", project="dogfood_test_project_2026") still returns the full content with "Served from cache". Project deletion does not invalidate the Redis/response cache. This is a data privacy and security issue.

RESOLVED: Fixed — cache invalidation before DROP SCHEMA, test exists

---

### #109 — Integrate Shannon AI Pentester for automated security testing
**Status**: backlog | **Type**: task | **Priority**: high
**Tags**: security, testing, pentest, shannon, automation

**Description**:

## Overview

Adopt [Shannon](https://github.com/KeygraphHQ/shannon) (AGPL-3.0) as our autonomous AI pentesting tool. Shannon runs 13 coordinated Claude agents via Temporal.io to find and prove exploits in web applications. White-box only — reads source code, then executes real browser-based attacks.

**Blocked by**: #108 (staging environment) — Shannon creates accounts, deletes data, and runs real exploits. MUST NOT run against production.

## What Shannon Tests
- SQL Injection (including parameterized query bypasses)
- XSS (reflected, stored, DOM-based)
- Authentication bypass, credential stuffing, session issues
- SSRF (internal service access)
- Authorization flaws (IDOR, privilege escalation)

## Cost and Frequency
- ~$50/run (claude-sonnet-4.5), 1-1.5 hours runtime
- Recommended: weekly or pre-release against staging
- NOT per-PR (too expensive, too slow)

## Acceptance Criteria
- [ ] Shannon cloned and configured in workspace
- [ ] Staging environment available (#108)
- [ ] Auth config working against staging Auth0
- [ ] First successful run against staging backend
- [ ] Report reviewed and findings triaged as tickets
- [ ] Recurring schedule established (weekly or pre-release)

---

### #132 — Tests: Implement Parallel DB Isolation for Integration Tests
**Status**: backlog | **Type**: task | **Priority**: high

**Description**:
The current test suite runs all 3580 tests sequentially, but the integration tests (specifically those loading `server_hosted.py`) cause significant delays. We need to implement parallel DB test isolation to allow running tests safely across multiple git worktrees without DB schema collisions. This involves setting up dynamic schema creation per test worker or dedicated DB instances per worktree.

---

### #1 — [DEM-5] Stripe subscription billing integration
**Status**: backlog | **Type**: task | **Priority**: urgent
**Tags**: billing, linear-import

**Description**: Integrate Stripe subscription billing for user accounts. Core billing infrastructure ticket.

---

### #2 — [DEM-6] Payment failure dunning and suspension flow
**Status**: backlog | **Type**: task | **Priority**: urgent

**Description**: Handle Stripe payment failures with dunning emails and account suspension flow.

---

### #3 — [DEM-7] Stripe Customer Portal Integration
**Status**: backlog | **Type**: task | **Priority**: urgent

**Description**: Integrate Stripe Customer Portal for self-service billing management.

---

### #4 — [DEM-12] Stripe Webhook Endpoint
**Status**: backlog | **Type**: task | **Priority**: urgent

**Description**: Implement Stripe webhook endpoint for payment event processing.

---

### #5 — [DEM-11] Email Delivery via Forwardemail
**Status**: backlog | **Type**: task | **Priority**: urgent

**Description**: Set up transactional email delivery using Forwardemail service.

---

### #76 — Bug reports should be tickets, not a write-only table
**Status**: shipped | **Type**: feature | **Priority**: high
**Tags**: cli, mcp, bug-reports, ticketing

**Description**:
Bug reports should be tickets, not a write-only table. The bug_report MCP tool writes to mcp_global.bug_reports, a separate system from ticketing.

RESOLVED: bug_report now creates tickets via TicketService (fixed in PR #143). Option A implemented.

---

### #97 — CRITICAL: SQL Injection in stompy-ticketing schema interpolation
**Status**: wont_fix | **Type**: bug | **Priority**: urgent

**Description**: SQL injection vulnerability identified in stompy-ticketing schema interpolation. Marked as won't fix (likely false positive or mitigated by other controls).

---

### #98 — HIGH: Unbounded Thread-Local Connection Leak in postgres_adapter
**Status**: resolved | **Type**: bug | **Priority**: high

**Description**: Thread-local connection storage in postgres_adapter can leak connections without bound. Fixed.

---

### #99 — HIGH: Masking Exceptions Causes Transaction Cascades in migration_runner
**Status**: resolved | **Type**: bug | **Priority**: high

**Description**: Exception masking in migration_runner leads to cascading transaction failures. Fixed.

---

### #100 — HIGH: Non-deterministic hash() used for distributed advisory locks
**Status**: resolved | **Type**: bug | **Priority**: high

**Description**: Python's built-in hash() is non-deterministic across processes, defeating advisory lock concurrency protection. Fixed.

---

### #101 — HIGH: Lack of Tenant Authorization Checks Allows Cross-Schema Data Access (IDOR)
**Status**: resolved | **Type**: bug | **Priority**: high

**Description**: Missing tenant authorization checks allow cross-schema data access (Insecure Direct Object Reference). Fixed.

---

### #102 — MEDIUM: OAuth and MCP rate limiting fails completely open when Redis is unavailable
**Status**: resolved | **Type**: bug | **Priority**: medium

**Description**: When Redis is down, rate limiting fails open instead of failing closed. Fixed.

---

### #103 — HIGH: CI/CD Security Workflows Fail-Open
**Status**: resolved | **Type**: bug | **Priority**: high

**Description**: Security CI/CD workflows allow vulnerabilities to merge when scans fail. Fixed to fail-closed.

---

### #104 — HIGH: TruffleHog --only-verified flag ignores internal secrets
**Status**: resolved | **Type**: bug | **Priority**: high

**Description**: TruffleHog's --only-verified flag skips internal secrets and database passwords. Fixed.

---

### #113 — Enforce read-only guarantees for db_query tool
**Status**: resolved | **Type**: bug | **Priority**: high

**Description**: The db_query MCP tool did not enforce read-only guarantees, allowing mutation queries. Fixed.

---

### #114 — Invalidate Redis token cache on logout
**Status**: resolved | **Type**: bug | **Priority**: high

**Description**: Redis token cache was not invalidated on user logout, allowing stale tokens. Fixed.

---

### #119 — Reduce Auth0 token validation latency on cache misses
**Status**: backlog | **Type**: task | **Priority**: high

**Description**: Auth0 token validation on cache misses adds significant latency. Needs optimization (pre-fetch, background refresh, or longer cache TTL).

---

### #125 — Performance: Replace synchronous `requests` with async `httpx`
**Status**: backlog | **Type**: task | **Priority**: high

**Description**: Replace synchronous `requests` library with async `httpx` in external API calls to avoid blocking the event loop.

---

### #126 — Performance: Use Async DB calls in Admin endpoints
**Status**: backlog | **Type**: task | **Priority**: high

**Description**: Admin endpoints use synchronous DB calls. Migrate to async for better concurrency.

---

### #129 — Tests: Migrate external API mocks to httpx/respx
**Status**: backlog | **Type**: task | **Priority**: high

**Description**: Migrate external API mocks from requests-mock to httpx/respx and handle BackgroundTasks properly in tests.

---

### #146 — detect_conflicts cold start takes 241s
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: The detect_conflicts operation takes 241 seconds on cold start. Needs performance investigation and optimization.

---

### #53 — [DEM-177] Show context/session/file counts in delete project confirmation dialog
**Status**: backlog | **Type**: task | **Priority**: low

**Description**: The delete project confirmation dialog should show counts of contexts, sessions, and files that will be deleted. Related to #162 (project_delete preview).

---

### #71 — Build CLI downloads page on stompy-web
**Status**: proposed | **Type**: feature | **Priority**: high

**Description**: Create a downloads page on stompy-web for the CLI binary releases.

---

### #59 — feat: Bridge semantic search to vectorized post corpus
**Status**: proposed | **Type**: feature | **Priority**: high

**Description**: Bridge the semantic search system to work with vectorized post corpus for content discovery.

---

### #58 — feat: Add batch recall_contexts() for multi-topic loading
**Status**: proposed | **Type**: feature | **Priority**: high

**Description**: Add a batch recall_contexts() API for loading multiple topics in a single call, reducing round trips.

---

### #70 — Wire up error reference codes to real error tracking
**Status**: proposed | **Type**: feature | **Priority**: medium

**Description**: Connect the error reference codes shown to users to actual error tracking/logging system.

---

### #69 — OAuth post-login redirect and thank-you page
**Status**: proposed | **Type**: feature | **Priority**: medium

**Description**: After OAuth login, redirect users to a thank-you/welcome page instead of dropping them at root.

---

### #63 — fix: Improve semantic search for conceptual adjacency queries
**Status**: proposed | **Type**: feature | **Priority**: medium

**Description**: Semantic search misses conceptually adjacent results. Improve embedding similarity thresholds and query expansion.

---

### #61 — feat: Add similar_posts() tool for content deduplication
**Status**: proposed | **Type**: feature | **Priority**: medium

**Description**: Add a similar_posts() MCP tool for finding near-duplicate content across contexts.

---

### #60 — feat: Implement tiered context loading with compact summaries
**Status**: proposed | **Type**: feature | **Priority**: medium

**Description**: Implement tiered context loading that returns compact summaries first, with option to load full content.

---

### #35 — [DEM-254] Admin Dashboard - Privacy-First User Management
**Status**: proposed | **Type**: feature | **Priority**: medium

**Description**: Build admin dashboard for user management with privacy-first design (no PII exposure in UI).

---

### #34 — [DEM-56] [Epic] Batch Processing Infrastructure
**Status**: proposed | **Type**: feature | **Priority**: medium

**Description**: Epic for batch processing infrastructure — background jobs, queues, worker management.

---

### #33 — [DEM-48] [Epic] Project Schema Templates
**Status**: proposed | **Type**: feature | **Priority**: medium

**Description**: Epic for project schema templates — pre-built schemas users can apply to new projects.

---

### #32 — [DEM-40] [Epic] Temporal Knowledge Graph
**Status**: proposed | **Type**: feature | **Priority**: medium

**Description**: Epic for temporal knowledge graph — track how context evolves over time.

---

### #31 — [DEM-36] [Epic] Hierarchical Summarization Engine
**Status**: proposed | **Type**: feature | **Priority**: medium

**Description**: Epic for hierarchical summarization — multi-level summaries of large context sets.

---

### #62 — feat: Add context size warnings when total loaded exceeds threshold
**Status**: proposed | **Type**: feature | **Priority**: low

**Description**: Warn users when total loaded context size exceeds a threshold that may degrade LLM performance.

---

### #108 — Set up staging environment for security testing and QA
**Status**: done | **Type**: task | **Priority**: high

**Description**: Set up a staging environment for security testing (Shannon pentester) and QA. Completed.

---

### #107 — External Codebase Audit — OpenAI Codex 5.3 Deep Review
**Status**: done | **Type**: task | **Priority**: high

**Description**: External codebase audit performed by OpenAI Codex 5.3. Findings triaged as tickets #97-#106.

---

### #116 — Pin production Python dependencies
**Status**: done | **Type**: task | **Priority**: medium

**Description**: Pin all production Python dependencies to exact versions for reproducible builds. Completed.

---

### #78 — Implement CLI self-update mechanism
**Status**: shipped | **Type**: feature | **Priority**: high

**Description**: CLI self-update mechanism for the stompy CLI binary. Shipped.

---

### #40 — [DEM-186] Enable autoscaling for production infrastructure
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: Enable autoscaling for production DigitalOcean infrastructure to handle traffic spikes.

---

### #38 — [DEM-224] Account Deletion (GDPR)
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: Implement GDPR-compliant account deletion flow — data export, grace period, permanent deletion.

---

### #28 — [DEM-225] Closed Beta Invite System
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: Build invite system for closed beta — invite codes, referral tracking, waitlist management.

---

### #25 — [DEM-173] Implement S3 file cleanup on project deletion
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: When a project is deleted, clean up associated S3 files. Currently orphaned.

---

### #24 — [DEM-25] Load Testing with k6
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: Set up k6 load testing for API endpoints and MCP transport.

---

### #117 — Restrict E2E test auth mode in production builds
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: E2E test auth bypass mode should not be available in production builds.

---

### #118 — Enforce HTTPS for API URL in frontend auth fetches
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: Frontend auth fetches should enforce HTTPS for the API URL, not allow HTTP.

---

### #120 — Optimize DB session setup for PgBouncer transaction pooling
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: DB session setup needs optimization for PgBouncer transaction pooling mode.

---

### #121 — Add read-through caching for frequent REST reads
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: Implement read-through Redis caching for frequently accessed REST endpoints.

---

### #122 — Index provisioning_jobs for faster scheduler pickup
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: Add database index to provisioning_jobs table for faster scheduler polling.

---

### #123 — Paginate and compress large JSON responses
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: Large JSON responses from API should be paginated and optionally compressed.

---

### #124 — Performance: Migrate EmailNotificationService to use BackgroundTasks
**Status**: backlog | **Type**: task | **Priority**: high

**Description**: Email notification service blocks request handlers. Migrate to FastAPI BackgroundTasks.

---

### #127 — Performance: Implement async batching for execute_many bulk inserts
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: Implement async batching for bulk insert operations using execute_many.

---

### #128 — Performance: Add Redis caching for Bug Report stats
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: Bug report statistics are computed on every request. Add Redis caching.

---

### #130 — Tests: Fix Asyncio Event Loop Collisions with Session-Scoped Fixtures
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: Session-scoped async fixtures collide with test-scoped event loops in pytest-asyncio.

---

### #133 — Tests: Fix PytestDeprecationWarning for asyncio_default_fixture_loop_scope
**Status**: backlog | **Type**: task | **Priority**: medium

**Description**: Fix pytest deprecation warnings related to asyncio_default_fixture_loop_scope configuration.

---
