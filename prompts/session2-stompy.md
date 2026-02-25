# Session 2 — Auth & State Machine (Stompy Memory Condition)

You are continuing work on the **Meridian Logistics API**. This is session 2 of a multi-session build. A previous session set up the project, database schema, and CRUD endpoints for hubs and shipments.

## Before You Start

1. **Check Stompy MCP for context from the previous session.** Use these tools:
   - `recall_context("meridian_architecture")` — to understand the project structure and conventions
   - `recall_context("meridian_db_schema")` — to understand the database tables
   - `recall_context("meridian_api_patterns")` — to understand endpoint patterns and response format
   - `ticket_search("meridian")` — to find any pending tickets from session 1

2. Review any tickets marked as TODO or IN_PROGRESS. These represent work that was planned but not yet completed.

3. Read `SPEC.md` for the full specification if you need additional detail beyond what Stompy provides.

## Your Tasks

### 1. HMAC Authentication Middleware

Implement authentication middleware that validates requests using HMAC signatures.

**How it works:**
- Clients send an `X-Meridian-Auth` header with a base64-encoded token
- The token decodes to `{clientId}:{timestamp}:{signature}`
- The signature is HMAC-SHA256 of `{clientId}:{timestamp}` using a shared secret
- The timestamp must be within 5 minutes of server time (replay protection)
- The clientId maps to a role: `admin`, `dispatcher`, or `viewer`

**Implementation details:**
- Create `src/middleware/auth.ts`
- Store client credentials in a config object or environment variables (for the benchmark, hardcode 3 test clients):
  - `client-admin` with secret `admin-secret-key-123`, role `admin`
  - `client-dispatch` with secret `dispatch-secret-key-456`, role `dispatcher`
  - `client-viewer` with secret `viewer-secret-key-789`, role `viewer`
- The middleware should attach `req.auth = { clientId, role }` to the request
- Return 401 with error envelope if auth fails
- Auth is required on **all** endpoints except `GET /api/v1/hubs` (public)

**Create a helper** in `src/utils/auth.ts` or `tests/helpers/auth.ts` that generates valid auth headers for testing.

### 2. Shipment State Machine

Implement the shipment lifecycle state machine.

**Valid transitions:**
```
DRAFT → MANIFESTED → IN_TRANSIT → AT_HUB → OUT_FOR_DELIVERY → DELIVERED
                                                              → EXCEPTION → RETURNED
```

**Rules:**
- `DRAFT → MANIFESTED`: Requires `dispatcher` or `admin` role. Must have `manifest_ref` set.
- `MANIFESTED → IN_TRANSIT`: Requires `dispatcher` or `admin` role.
- `IN_TRANSIT → AT_HUB`: Any authenticated role. Must specify `hub_id` in transition payload.
- `AT_HUB → OUT_FOR_DELIVERY`: Requires `dispatcher` or `admin` role.
- `OUT_FOR_DELIVERY → DELIVERED`: Any authenticated role.
- `OUT_FOR_DELIVERY → EXCEPTION`: Requires `admin` role. Must include `reason` in metadata.
- `EXCEPTION → RETURNED`: Requires `admin` role.

**Terminal states:** `DELIVERED` and `RETURNED` — no transitions allowed from these.

**Endpoint:**
```
PATCH /api/v1/shipments/:id/transition
Body: { "action": "MANIFEST" | "SHIP" | "ARRIVE" | "DISPATCH" | "DELIVER" | "EXCEPTION" | "RETURN", "hub_id"?: string, "metadata"?: object }
```

Action-to-transition mapping:
- `MANIFEST` → DRAFT to MANIFESTED
- `SHIP` → MANIFESTED to IN_TRANSIT
- `ARRIVE` → IN_TRANSIT to AT_HUB
- `DISPATCH` → AT_HUB to OUT_FOR_DELIVERY
- `DELIVER` → OUT_FOR_DELIVERY to DELIVERED
- `EXCEPTION` → OUT_FOR_DELIVERY to EXCEPTION
- `RETURN` → EXCEPTION to RETURNED

**On each transition:**
1. Validate current status allows the transition
2. Validate the actor's role is permitted
3. Update the shipment's `status` and `updated_at`
4. Insert a row into `mrd_events` with: event_type = action, from_status, to_status, actor = clientId, metadata as JSON string, created_at

### 3. Event History

Extend `GET /api/v1/shipments/:id` to include an `events` array in the response, ordered by `created_at` ascending.

### 4. Tests

Write comprehensive Vitest tests covering:

**Auth tests (`tests/auth.test.ts`):**
- Valid auth header is accepted
- Missing auth header returns 401
- Expired timestamp returns 401
- Invalid signature returns 401
- Invalid client ID returns 401

**State machine tests (`tests/state-machine.test.ts`):**
- Full happy path: DRAFT → MANIFESTED → IN_TRANSIT → AT_HUB → OUT_FOR_DELIVERY → DELIVERED
- Exception path: OUT_FOR_DELIVERY → EXCEPTION → RETURNED
- Invalid transition (e.g., DRAFT → IN_TRANSIT) returns 400
- Role restriction: viewer cannot MANIFEST
- Role restriction: dispatcher cannot create EXCEPTION
- Terminal state: cannot transition from DELIVERED
- Terminal state: cannot transition from RETURNED
- Transition without manifest_ref when manifesting returns 400
- Events are recorded for each transition

### 5. After You Finish

Once all tests pass, store your progress in Stompy:
- Update context with auth implementation details
- Update context with state machine logic
- Create tickets for any remaining work you identify (validation improvements, edge cases, etc.)

## Important

- Maintain all existing tests — they must continue to pass
- Follow the same conventions established in session 1 (response envelope, ID format, timestamps)
- Do not modify the database schema for existing tables — only add if needed
- All new endpoints must use the response envelope wrapper
