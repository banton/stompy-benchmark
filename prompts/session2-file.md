# Session 2 — Auth & State Machine (File Memory Condition)

You are continuing work on the **Meridian Logistics API**. This is session 2 of a multi-session build. A previous session set up the project, database schema, and CRUD endpoints for hubs and shipments.

## Before You Start

1. **Read `MEMORY.md`** in the project root. It contains architecture decisions, patterns, file locations, and conventions from the previous session.
2. **Read `TASKS.md`** in the project root. It lists remaining work items and their priority.
3. Read `SPEC.md` for the full specification if you need additional detail.

Use the information in these files to understand what has already been built and how it works before writing any code.

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

Once all tests pass, **update the memory files**:

**Update `MEMORY.md`** with:
- Auth middleware implementation details (file location, how HMAC works, test clients)
- State machine logic (transitions map, role restrictions, terminal states)
- New file locations added
- Any patterns or conventions you established
- Test helper patterns

**Update `TASKS.md`** with:
- Mark completed tasks as DONE
- Add any new tasks you identified (validation gaps, edge cases, future improvements)
- Note what remains for session 3

## Important

- Maintain all existing tests — they must continue to pass
- Follow the same conventions established in session 1 (response envelope, ID format, timestamps)
- Do not modify the database schema for existing tables — only add if needed
- All new endpoints must use the response envelope wrapper
