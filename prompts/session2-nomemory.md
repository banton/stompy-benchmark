# Session 2 — Auth & State Machine (No Memory Condition)

You are continuing work on the **Meridian Logistics API**. This is session 2. A previous session already set up the project with Express, TypeScript, and SQLite, including CRUD endpoints for hubs and shipments. You have no notes or context from that session.

## Before You Start

You need to understand what already exists before writing any code. Explore the codebase:

1. Look at the project structure — list files in `src/` and `tests/`
2. Read `SPEC.md` for the full API specification
3. Read the database setup code to understand the schema (tables, columns, types)
4. Read the existing route files to understand the URL patterns and response format
5. Read the existing test files to understand testing patterns and setup
6. Read the utility files to understand ID generation and response helpers

Take your time to understand the conventions before implementing anything. Consistency with the existing code is critical.

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

## Important

- Maintain all existing tests — they must continue to pass
- Match the conventions you find in the existing code (response envelope, ID format, timestamps, file naming)
- Do not modify the database schema for existing tables — only add if needed
- All new endpoints must use the same response wrapper as existing endpoints
