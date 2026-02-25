# Post-Session 1: Store Context in Stompy MCP

You just finished building the initial Meridian Logistics API (project setup, database schema, hub and shipment CRUD). Now store the project state in Stompy so future sessions can retrieve it.

## Store Contexts

Use `lock_context` to store each of these contexts. Use `project="meridian-benchmark"` for all calls.

### 1. Architecture Overview

```
lock_context(
  topic="meridian_architecture",
  content="""
  Meridian Logistics API — Express + TypeScript + SQLite (better-sqlite3)

  Project structure:
  src/
    index.ts              — Express app bootstrap, mounts routes at /api/v1
    database.ts           — SQLite connection, schema init, seed data
    middleware/
      errorHandler.ts     — Global error handler
    utils/
      response.ts         — Response envelope helper: wrapResponse(data, meta?) and wrapError(error, status)
      ids.ts              — generateId() returns MRD- prefix + 8-char nanoid
    hubs/
      hubs.routes.ts      — GET /api/v1/hubs, POST /api/v1/hubs
      hubs.service.ts     — Business logic for hub operations
      hubs.model.ts       — Type definitions for Hub
    shipments/
      shipments.routes.ts — POST /api/v1/shipments, GET /api/v1/shipments, GET /api/v1/shipments/:id
      shipments.service.ts— Business logic for shipment operations
      shipments.model.ts  — Type definitions for Shipment
  tests/
    setup.ts              — Test setup with in-memory SQLite
    hubs.test.ts          — Hub endpoint tests
    shipments.test.ts     — Shipment endpoint tests

  Conventions:
  - IDs: MRD- prefix + 8 char nanoid
  - Timestamps: Unix epoch milliseconds (Date.now())
  - Response envelope: { ok: boolean, ts: number, data: T | null, error: string | null, meta: object | null }
  - File naming: {resource}.routes.ts, {resource}.service.ts, {resource}.model.ts
  - Raw SQL with parameterized queries, no ORM
  - Tests: Vitest + supertest, in-memory SQLite for isolation
  """,
  priority="always_check",
  tags="meridian,architecture,structure"
)
```

### 2. Database Schema

```
lock_context(
  topic="meridian_db_schema",
  content="""
  SQLite database with 3 tables (mrd_ prefix convention):

  mrd_hubs:
    id TEXT PK, code TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
    lat REAL, lon REAL, created_at INTEGER, updated_at INTEGER

  mrd_shipments:
    id TEXT PK, origin_hub TEXT FK→mrd_hubs, dest_hub TEXT FK→mrd_hubs,
    status TEXT DEFAULT 'DRAFT', priority TEXT DEFAULT 'STANDARD',
    weight_kg REAL, manifest_ref TEXT, created_at INTEGER, updated_at INTEGER

  mrd_events:
    id TEXT PK, shipment_id TEXT FK→mrd_shipments, event_type TEXT,
    from_status TEXT, to_status TEXT, actor TEXT, metadata TEXT (JSON),
    created_at INTEGER

  Seed data: 3 hubs — HUB-ATL (Atlanta Gateway), HUB-ORD (Chicago O'Hare Hub), HUB-LAX (Los Angeles Distribution Center)

  Valid statuses for shipments: DRAFT, MANIFESTED, IN_TRANSIT, AT_HUB, OUT_FOR_DELIVERY, DELIVERED, EXCEPTION, RETURNED
  Valid priorities: STANDARD, EXPRESS, CRITICAL
  """,
  priority="important",
  tags="meridian,database,schema"
)
```

### 3. API Patterns

```
lock_context(
  topic="meridian_api_patterns",
  content="""
  Base path: /api/v1

  Implemented endpoints:
  - GET  /api/v1/hubs                — List all hubs (public, no auth needed)
  - POST /api/v1/hubs                — Create hub { code, name, lat?, lon? }
  - POST /api/v1/shipments           — Create shipment { origin_hub, dest_hub, priority?, weight_kg?, manifest_ref? }
  - GET  /api/v1/shipments           — List all shipments
  - GET  /api/v1/shipments/:id       — Get single shipment (404 if not found)

  Response envelope (every response):
  Success: { ok: true,  ts: <epoch_ms>, data: <payload>, error: null, meta: { count: N } }
  Error:   { ok: false, ts: <epoch_ms>, data: null, error: "message", meta: null }

  NOT YET IMPLEMENTED:
  - Authentication (HMAC via X-Meridian-Auth header)
  - PATCH /api/v1/shipments/:id/transition (state machine)
  - Event history in GET /shipments/:id response
  - Input validation (weight, priority values, manifest_ref format)
  """,
  priority="important",
  tags="meridian,api,endpoints"
)
```

## Create Tickets

Create tickets for remaining work using `ticket()`:

### Ticket 1: Implement HMAC Authentication

```
ticket(
  title="Implement HMAC authentication middleware",
  description="""
  Create auth middleware at src/middleware/auth.ts.
  - X-Meridian-Auth header with base64-encoded token
  - Token format: {clientId}:{timestamp}:{signature}
  - Signature: HMAC-SHA256 of {clientId}:{timestamp} with shared secret
  - 5-minute replay window
  - 3 test clients: client-admin (admin), client-dispatch (dispatcher), client-viewer (viewer)
  - Attach req.auth = { clientId, role }
  - Required on all endpoints except GET /api/v1/hubs
  - Write tests: valid auth, missing header, expired, invalid signature, invalid client
  """,
  type="feature",
  priority="high",
  tags="meridian,auth,session2"
)
```

### Ticket 2: Implement State Machine

```
ticket(
  title="Implement shipment state machine transitions",
  description="""
  Create PATCH /api/v1/shipments/:id/transition endpoint.
  Actions: MANIFEST, SHIP, ARRIVE, DISPATCH, DELIVER, EXCEPTION, RETURN
  Transitions: DRAFT→MANIFESTED→IN_TRANSIT→AT_HUB→OUT_FOR_DELIVERY→DELIVERED, OUT_FOR_DELIVERY→EXCEPTION→RETURNED
  Role restrictions: MANIFEST/SHIP/DISPATCH need dispatcher+, EXCEPTION/RETURN need admin
  Terminal states: DELIVERED, RETURNED
  Log each transition in mrd_events.
  Include events array in GET /shipments/:id response.
  Write tests: happy path, exception path, invalid transitions, role checks, terminal states.
  """,
  type="feature",
  priority="high",
  tags="meridian,state-machine,session2"
)
```

### Ticket 3: Input Validation

```
ticket(
  title="Add input validation for shipments and hubs",
  description="""
  Validate: weight_kg > 0, priority in [STANDARD,EXPRESS,CRITICAL],
  manifest_ref alphanumeric+hyphens 6-20 chars, hub code HUB-[A-Z]{2,4}.
  Return 400 with descriptive error messages.
  """,
  type="feature",
  priority="medium",
  tags="meridian,validation,session3"
)
```

## Important

- Use `project="meridian-benchmark"` consistently for all Stompy calls
- The contexts should be self-contained — someone reading them with no other context should understand the project
- Tickets should have enough detail to implement without asking questions
