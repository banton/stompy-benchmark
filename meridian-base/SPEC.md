# Meridian Logistics API — Specification

## Overview

Meridian is a shipment lifecycle management API for hub-based logistics networks. It tracks shipments from draft through delivery, enforces a strict state machine, and logs every status transition as an immutable event.

---

## Tech Stack

- **Runtime**: Node.js 20+
- **Framework**: Express 4.x
- **Language**: TypeScript (strict mode)
- **Database**: SQLite via `better-sqlite3` (synchronous, embedded)
- **Testing**: Vitest
- **ID Generation**: nanoid

---

## Authentication

### Token Format

HMAC-based token sent in the `X-Meridian-Auth` header.

```
base64(org_id:user_id:expiry_epoch:hmac_sha256)
```

**Components:**
- `org_id` — Organization identifier (string)
- `user_id` — User identifier (string)
- `expiry_epoch` — Token expiration as Unix epoch milliseconds
- `hmac_sha256` — HMAC-SHA256 signature of `org_id:user_id:expiry_epoch` using the shared secret

**Secret**: Read from environment variable `MERIDIAN_AUTH_SECRET`.

### Roles

| Role         | Description                              |
|-------------|------------------------------------------|
| `operator`  | Can create shipments, view data          |
| `dispatcher`| Can manifest shipments, advance states   |
| `admin`     | Full access, can force exceptions        |

### Token Expiry

- Standard tokens (operator, dispatcher): **24 hours**
- Admin tokens: **72 hours**

### Authentication Errors

```json
{
  "ok": false,
  "ts": 1700000000000,
  "error": {
    "code": "AUTH_INVALID",
    "message": "Missing or malformed authentication token"
  }
}
```

```json
{
  "ok": false,
  "ts": 1700000000000,
  "error": {
    "code": "AUTH_EXPIRED",
    "message": "Token has expired"
  }
}
```

```json
{
  "ok": false,
  "ts": 1700000000000,
  "error": {
    "code": "AUTH_FORBIDDEN",
    "message": "Insufficient role for this operation"
  }
}
```

---

## ID Format

All entity IDs use the format:

```
MRD-{8-char nanoid}
```

Example: `MRD-a1b2c3d4`, `MRD-xK9mPq2R`

The nanoid alphabet is the default nanoid character set. IDs are generated server-side and are immutable after creation.

---

## Timestamps

All timestamps are **Unix epoch milliseconds** (integer). ISO 8601 strings are never used.

Example: `1700000000000` represents 2023-11-14T22:13:20.000Z.

---

## Response Envelope

Every API response follows this envelope format:

### Success Response

```json
{
  "ok": true,
  "ts": 1700000000000,
  "data": { ... }
}
```

### Success Response with Pagination

```json
{
  "ok": true,
  "ts": 1700000000000,
  "data": [ ... ],
  "meta": {
    "total": 100,
    "offset": 0,
    "limit": 20
  }
}
```

### Error Response

```json
{
  "ok": false,
  "ts": 1700000000000,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable description of the error"
  }
}
```

### Error Codes

| Code                | HTTP Status | Description                          |
|--------------------|-------------|--------------------------------------|
| `VALIDATION_ERROR` | 400         | Request body or params are invalid   |
| `AUTH_INVALID`     | 401         | Missing or malformed token           |
| `AUTH_EXPIRED`     | 401         | Token has expired                    |
| `AUTH_FORBIDDEN`   | 403         | Insufficient role                    |
| `NOT_FOUND`        | 404         | Resource does not exist              |
| `TRANSITION_ERROR` | 409         | Invalid state transition             |
| `INTERNAL_ERROR`   | 500         | Unexpected server error              |

---

## Database Schema

Raw SQL. No ORM. All table names use `mrd_` prefix. All column names use snake_case.

### `mrd_shipments`

```sql
CREATE TABLE mrd_shipments (
  id           TEXT PRIMARY KEY,
  org_id       TEXT NOT NULL,
  origin_hub   TEXT NOT NULL REFERENCES mrd_hubs(code),
  dest_hub     TEXT NOT NULL REFERENCES mrd_hubs(code),
  weight_g     INTEGER NOT NULL,
  priority     INTEGER NOT NULL CHECK (priority IN (1, 2, 3)),
  status       TEXT NOT NULL DEFAULT 'DRAFT',
  manifest_ref TEXT,
  created_by   TEXT NOT NULL,
  created_at   INTEGER NOT NULL,
  updated_at   INTEGER NOT NULL
);
```

### `mrd_events`

```sql
CREATE TABLE mrd_events (
  id          TEXT PRIMARY KEY,
  shipment_id TEXT NOT NULL REFERENCES mrd_shipments(id),
  from_status TEXT NOT NULL,
  to_status   TEXT NOT NULL,
  changed_by  TEXT NOT NULL,
  changed_at  INTEGER NOT NULL,
  reason      TEXT
);

CREATE INDEX idx_events_shipment ON mrd_events(shipment_id);
```

### `mrd_hubs`

```sql
CREATE TABLE mrd_hubs (
  code       TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  lat        REAL NOT NULL,
  lng        REAL NOT NULL,
  active     INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL
);
```

---

## State Machine

```
DRAFT → MANIFESTED → IN_TRANSIT → AT_HUB → OUT_FOR_DELIVERY → DELIVERED
                                                              ↘
Any state ──────────────────────────────→ EXCEPTION → RETURNED
```

### Valid Transitions

| From              | To                | Required Role          | Additional Rules                                       |
|-------------------|-------------------|------------------------|-------------------------------------------------------|
| `DRAFT`           | `MANIFESTED`      | `dispatcher`, `admin`  | `manifest_ref` must be set and match `/^MF-\d{8}$/`  |
| `MANIFESTED`      | `IN_TRANSIT`      | `dispatcher`, `admin`  |                                                        |
| `IN_TRANSIT`      | `AT_HUB`          | `operator`, `dispatcher`, `admin` |                                              |
| `AT_HUB`          | `OUT_FOR_DELIVERY` | `dispatcher`, `admin` |                                                        |
| `OUT_FOR_DELIVERY` | `DELIVERED`       | `operator`, `dispatcher`, `admin` |                                              |
| Any non-terminal  | `EXCEPTION`       | `admin`                | `reason` is required                                   |
| `EXCEPTION`       | `RETURNED`        | `admin`                |                                                        |

### Terminal States

`DELIVERED` and `RETURNED` are terminal. No further transitions are allowed from these states.

### Transition Rules

- Every transition creates a record in `mrd_events` containing: who made the change, when, from which status, to which status, and an optional reason.
- The `reason` field is required when transitioning to `EXCEPTION`.
- The shipment's `updated_at` field is set to the current epoch milliseconds on every transition.

---

## File Naming Convention

```
src/routes/{resource}.routes.ts
src/services/{resource}.service.ts
src/models/{resource}.model.ts
src/middleware/auth.ts
src/types/index.ts
src/utils/id.ts
src/utils/response.ts
```

---

## API Routes

All routes are under `/api/v1/`.

---

### POST /api/v1/shipments

Create a new shipment. Status is always set to `DRAFT` on creation.

**Required Role**: `operator`, `dispatcher`, `admin`

**Request Body**:

```json
{
  "origin_hub": "LAX",
  "dest_hub": "JFK",
  "weight_g": 15000,
  "priority": 2,
  "manifest_ref": "MF-00012345"
}
```

| Field         | Type    | Required | Validation                                      |
|--------------|---------|----------|-------------------------------------------------|
| `origin_hub` | string  | yes      | Must exist in `mrd_hubs` and be active          |
| `dest_hub`   | string  | yes      | Must exist in `mrd_hubs` and be active          |
| `weight_g`   | integer | yes      | 1 to 500000 inclusive                            |
| `priority`   | integer | yes      | 1, 2, or 3                                      |
| `manifest_ref` | string | no     | If provided, must match `/^MF-\d{8}$/`         |

**Additional Rules**:
- `origin_hub` must not equal `dest_hub`
- `created_by` is extracted from the auth token (`user_id`)
- `org_id` is extracted from the auth token
- `status` is always set to `DRAFT`
- `created_at` and `updated_at` are set to current epoch milliseconds

**Success Response** (201):

```json
{
  "ok": true,
  "ts": 1700000000000,
  "data": {
    "id": "MRD-a1b2c3d4",
    "org_id": "org_acme",
    "origin_hub": "LAX",
    "dest_hub": "JFK",
    "weight_g": 15000,
    "priority": 2,
    "status": "DRAFT",
    "manifest_ref": "MF-00012345",
    "created_by": "user_jane",
    "created_at": 1700000000000,
    "updated_at": 1700000000000
  }
}
```

**Error Response** (400):

```json
{
  "ok": false,
  "ts": 1700000000000,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "weight_g must be between 1 and 500000"
  }
}
```

**Error Response** (400 — same hub):

```json
{
  "ok": false,
  "ts": 1700000000000,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "origin_hub and dest_hub must be different"
  }
}
```

---

### GET /api/v1/shipments

List shipments with pagination and optional filtering. Results are scoped to the authenticated user's `org_id`.

**Required Role**: `operator`, `dispatcher`, `admin`

**Query Parameters**:

| Param        | Type    | Default | Description                                      |
|-------------|---------|---------|--------------------------------------------------|
| `offset`    | integer | 0       | Number of records to skip                        |
| `limit`     | integer | 20      | Number of records to return (max 100)            |
| `status`    | string  | —       | Filter by status (e.g., `DRAFT`, `IN_TRANSIT`)   |
| `origin_hub`| string  | —       | Filter by origin hub code                        |
| `dest_hub`  | string  | —       | Filter by destination hub code                   |
| `priority`  | integer | —       | Filter by priority (1, 2, or 3)                  |

**Success Response** (200):

```json
{
  "ok": true,
  "ts": 1700000000000,
  "data": [
    {
      "id": "MRD-a1b2c3d4",
      "org_id": "org_acme",
      "origin_hub": "LAX",
      "dest_hub": "JFK",
      "weight_g": 15000,
      "priority": 2,
      "status": "DRAFT",
      "manifest_ref": null,
      "created_by": "user_jane",
      "created_at": 1700000000000,
      "updated_at": 1700000000000
    }
  ],
  "meta": {
    "total": 42,
    "offset": 0,
    "limit": 20
  }
}
```

---

### GET /api/v1/shipments/:id

Get a single shipment by ID, including its full event history.

**Required Role**: `operator`, `dispatcher`, `admin`

**Success Response** (200):

```json
{
  "ok": true,
  "ts": 1700000000000,
  "data": {
    "id": "MRD-a1b2c3d4",
    "org_id": "org_acme",
    "origin_hub": "LAX",
    "dest_hub": "JFK",
    "weight_g": 15000,
    "priority": 2,
    "status": "IN_TRANSIT",
    "manifest_ref": "MF-00012345",
    "created_by": "user_jane",
    "created_at": 1700000000000,
    "updated_at": 1700050000000,
    "events": [
      {
        "id": "MRD-ev01ab02",
        "shipment_id": "MRD-a1b2c3d4",
        "from_status": "DRAFT",
        "to_status": "MANIFESTED",
        "changed_by": "user_dispatch1",
        "changed_at": 1700010000000,
        "reason": null
      },
      {
        "id": "MRD-ev03cd04",
        "shipment_id": "MRD-a1b2c3d4",
        "from_status": "MANIFESTED",
        "to_status": "IN_TRANSIT",
        "changed_by": "user_dispatch1",
        "changed_at": 1700050000000,
        "reason": null
      }
    ]
  }
}
```

**Error Response** (404):

```json
{
  "ok": false,
  "ts": 1700000000000,
  "error": {
    "code": "NOT_FOUND",
    "message": "Shipment MRD-a1b2c3d4 not found"
  }
}
```

---

### PATCH /api/v1/shipments/:id/transition

Advance a shipment to a new status according to the state machine rules.

**Required Role**: Depends on the transition (see State Machine table above)

**Request Body**:

```json
{
  "to_status": "MANIFESTED",
  "reason": "Ready for dispatch"
}
```

| Field       | Type   | Required | Description                                          |
|------------|--------|----------|------------------------------------------------------|
| `to_status` | string | yes     | Target status (must be a valid transition)           |
| `reason`   | string | no      | Reason for transition (required for EXCEPTION)       |
| `manifest_ref` | string | conditional | Required when transitioning DRAFT → MANIFESTED, must match `/^MF-\d{8}$/` |

**DRAFT to MANIFESTED** — the `manifest_ref` field is required in the request body (or must already be set on the shipment). If provided in the transition request, it updates the shipment's `manifest_ref`.

**Success Response** (200):

```json
{
  "ok": true,
  "ts": 1700010000000,
  "data": {
    "id": "MRD-a1b2c3d4",
    "org_id": "org_acme",
    "origin_hub": "LAX",
    "dest_hub": "JFK",
    "weight_g": 15000,
    "priority": 2,
    "status": "MANIFESTED",
    "manifest_ref": "MF-00012345",
    "created_by": "user_jane",
    "created_at": 1700000000000,
    "updated_at": 1700010000000,
    "event": {
      "id": "MRD-ev01ab02",
      "shipment_id": "MRD-a1b2c3d4",
      "from_status": "DRAFT",
      "to_status": "MANIFESTED",
      "changed_by": "user_dispatch1",
      "changed_at": 1700010000000,
      "reason": "Ready for dispatch"
    }
  }
}
```

**Error Response** (409 — invalid transition):

```json
{
  "ok": false,
  "ts": 1700000000000,
  "error": {
    "code": "TRANSITION_ERROR",
    "message": "Cannot transition from DRAFT to DELIVERED"
  }
}
```

**Error Response** (409 — terminal state):

```json
{
  "ok": false,
  "ts": 1700000000000,
  "error": {
    "code": "TRANSITION_ERROR",
    "message": "Shipment is in terminal state DELIVERED"
  }
}
```

**Error Response** (400 — missing manifest_ref):

```json
{
  "ok": false,
  "ts": 1700000000000,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "manifest_ref is required for DRAFT to MANIFESTED transition and must match /^MF-\\d{8}$/"
  }
}
```

**Error Response** (400 — missing reason for EXCEPTION):

```json
{
  "ok": false,
  "ts": 1700000000000,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "reason is required when transitioning to EXCEPTION"
  }
}
```

---

### GET /api/v1/hubs

List all hubs. No pagination (hubs are a small, bounded dataset).

**Required Role**: `operator`, `dispatcher`, `admin`

**Query Parameters**:

| Param    | Type    | Default | Description                    |
|---------|---------|---------|--------------------------------|
| `active` | boolean | —      | Filter by active status (true/false) |

**Success Response** (200):

```json
{
  "ok": true,
  "ts": 1700000000000,
  "data": [
    {
      "code": "LAX",
      "name": "Los Angeles Hub",
      "lat": 33.9425,
      "lng": -118.4081,
      "active": true,
      "created_at": 1699000000000
    },
    {
      "code": "JFK",
      "name": "New York JFK Hub",
      "lat": 40.6413,
      "lng": -73.7781,
      "active": true,
      "created_at": 1699000000000
    },
    {
      "code": "ORD",
      "name": "Chicago O'Hare Hub",
      "lat": 41.9742,
      "lng": -87.9073,
      "active": true,
      "created_at": 1699000000000
    }
  ]
}
```

---

### POST /api/v1/hubs

Create a new hub. Admin only.

**Required Role**: `admin`

**Request Body**:

```json
{
  "code": "SFO",
  "name": "San Francisco Hub",
  "lat": 37.6213,
  "lng": -122.3790,
  "active": true
}
```

| Field    | Type    | Required | Validation                              |
|---------|---------|----------|-----------------------------------------|
| `code`  | string  | yes      | 2-10 uppercase alphanumeric characters  |
| `name`  | string  | yes      | 1-200 characters                        |
| `lat`   | number  | yes      | -90 to 90                               |
| `lng`   | number  | yes      | -180 to 180                             |
| `active`| boolean | no       | Defaults to `true`                      |

**Success Response** (201):

```json
{
  "ok": true,
  "ts": 1700000000000,
  "data": {
    "code": "SFO",
    "name": "San Francisco Hub",
    "lat": 37.6213,
    "lng": -122.3790,
    "active": true,
    "created_at": 1700000000000
  }
}
```

**Error Response** (400 — duplicate):

```json
{
  "ok": false,
  "ts": 1700000000000,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Hub with code SFO already exists"
  }
}
```

**Error Response** (403 — insufficient role):

```json
{
  "ok": false,
  "ts": 1700000000000,
  "error": {
    "code": "AUTH_FORBIDDEN",
    "message": "Insufficient role for this operation"
  }
}
```

---

## Validation Rules Summary

| Rule                                 | Applies To                         |
|--------------------------------------|------------------------------------|
| `weight_g` between 1 and 500000     | POST /shipments                    |
| Hub codes must exist and be active   | POST /shipments (origin, dest)     |
| `origin_hub` != `dest_hub`          | POST /shipments                    |
| `priority` must be 1, 2, or 3       | POST /shipments                    |
| `manifest_ref` matches `/^MF-\d{8}$/` | POST /shipments (if provided), PATCH transition to MANIFESTED |
| `reason` required for EXCEPTION      | PATCH /shipments/:id/transition    |
| Terminal states block transitions    | PATCH /shipments/:id/transition    |

---

## Seed Data

The database should be initialized with the following hubs:

```sql
INSERT INTO mrd_hubs (code, name, lat, lng, active, created_at) VALUES
  ('LAX', 'Los Angeles Hub', 33.9425, -118.4081, 1, 1699000000000),
  ('JFK', 'New York JFK Hub', 40.6413, -73.7781, 1, 1699000000000),
  ('ORD', 'Chicago O''Hare Hub', 41.9742, -87.9073, 1, 1699000000000),
  ('DFW', 'Dallas Fort Worth Hub', 32.8998, -97.0403, 1, 1699000000000),
  ('MIA', 'Miami Hub', 25.7959, -80.2870, 1, 1699000000000);
```
