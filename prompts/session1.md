# Session 1 — Project Setup & Core CRUD

You are building the **Meridian Logistics API**, a shipment tracking system. This is the first session of a multi-session build.

## Before You Start

Read `SPEC.md` in the project root thoroughly. It contains the full API specification, database schema, and conventions you must follow. Everything you build must conform to that spec.

## Your Task

Set up the project from scratch and implement the core CRUD endpoints for hubs and shipments.

### 1. Project Structure

Initialize an **Express + TypeScript** project with **SQLite** (via `better-sqlite3`) as the database. Use **Vitest** for testing.

Install these dependencies:
- `express`, `better-sqlite3`, `nanoid` (v3 for CJS compat), `cors`, `helmet`
- Dev: `typescript`, `vitest`, `supertest`, `@types/express`, `@types/better-sqlite3`, `@types/supertest`, `tsx`

Set up `tsconfig.json` with strict mode enabled. Create a `src/` directory with this layout:

```
src/
  index.ts              # Express app bootstrap
  database.ts           # SQLite connection + schema init
  middleware/
    errorHandler.ts     # Global error handler
  utils/
    response.ts         # Response envelope helper
    ids.ts              # MRD- ID generator
  hubs/
    hubs.routes.ts
    hubs.service.ts
    hubs.model.ts
  shipments/
    shipments.routes.ts
    shipments.service.ts
    shipments.model.ts
tests/
  hubs.test.ts
  shipments.test.ts
  setup.ts              # Test setup (in-memory DB or test DB)
```

### 2. Database Schema

Create these tables using **raw SQL** (no ORM):

```sql
CREATE TABLE mrd_hubs (
  id          TEXT PRIMARY KEY,
  code        TEXT UNIQUE NOT NULL,
  name        TEXT NOT NULL,
  lat         REAL,
  lon         REAL,
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL
);

CREATE TABLE mrd_shipments (
  id            TEXT PRIMARY KEY,
  origin_hub    TEXT NOT NULL REFERENCES mrd_hubs(id),
  dest_hub      TEXT NOT NULL REFERENCES mrd_hubs(id),
  status        TEXT NOT NULL DEFAULT 'DRAFT',
  priority      TEXT NOT NULL DEFAULT 'STANDARD',
  weight_kg     REAL,
  manifest_ref  TEXT,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);

CREATE TABLE mrd_events (
  id            TEXT PRIMARY KEY,
  shipment_id   TEXT NOT NULL REFERENCES mrd_shipments(id),
  event_type    TEXT NOT NULL,
  from_status   TEXT,
  to_status     TEXT,
  actor         TEXT,
  metadata      TEXT,
  created_at    INTEGER NOT NULL
);
```

### 3. Conventions

- **IDs**: Use `MRD-` prefix followed by 8 characters from nanoid. Example: `MRD-a8f3k2x9`
- **Timestamps**: Unix epoch in milliseconds (e.g., `Date.now()`)
- **Response envelope**: Every response must use this shape:
  ```json
  {
    "ok": true,
    "ts": 1700000000000,
    "data": { ... },
    "error": null,
    "meta": { "count": 1 }
  }
  ```
  On error: `ok: false`, `data: null`, `error: "message"`.
- **File naming**: `{resource}.routes.ts`, `{resource}.service.ts`, `{resource}.model.ts`

### 4. Endpoints to Implement

#### Hubs
- `GET /api/v1/hubs` — List all hubs. Return array in `data`.
- `POST /api/v1/hubs` — Create a hub. Body: `{ code, name, lat?, lon? }`. Return created hub in `data`.

#### Shipments
- `POST /api/v1/shipments` — Create a shipment. Body: `{ origin_hub, dest_hub, priority?, weight_kg?, manifest_ref? }`. Status defaults to `DRAFT`. Validate that origin_hub and dest_hub exist.
- `GET /api/v1/shipments` — List all shipments. Return array in `data`. Include `meta.count`.
- `GET /api/v1/shipments/:id` — Get a single shipment by ID. Return 404 envelope if not found.

### 5. Seed Data

Seed the database with at least 3 hubs on startup (or via a seed script):
- `HUB-ATL` — "Atlanta Gateway"
- `HUB-ORD` — "Chicago O'Hare Hub"
- `HUB-LAX` — "Los Angeles Distribution Center"

### 6. Tests

Write Vitest tests covering:
- Creating a hub and retrieving it
- Creating a shipment with valid hub references
- Creating a shipment with invalid hub reference (should 400)
- Listing shipments
- Getting a shipment by ID
- Getting a non-existent shipment (should 404)
- Response envelope structure (ok, ts, data fields present)

Use `supertest` to make HTTP requests against the Express app. Each test file should use a fresh database (in-memory SQLite) so tests are isolated and deterministic.

### 7. What NOT to Do

- Do **NOT** implement authentication yet. That comes in session 2.
- Do **NOT** implement the state machine or transition endpoint. That comes in session 2.
- Do **NOT** use an ORM. Use raw SQL with parameterized queries.
- Do **NOT** add any middleware for auth headers.

### 8. Validation

Run all tests before finishing. Every test must pass. The app should start without errors via `npx tsx src/index.ts`.
