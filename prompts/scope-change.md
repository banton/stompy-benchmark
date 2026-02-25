# Scope Change: Multi-Leg Shipment Routing

## Overview

Shipments now support **multi-leg routing**. Instead of a single origin-to-destination movement, a shipment can travel through a series of intermediate hubs. Each segment of the journey is a "leg" with its own status tracking.

Example: A shipment from Atlanta (HUB-ATL) to Los Angeles (HUB-LAX) might route through Chicago:
- Leg 1: HUB-ATL → HUB-ORD (Atlanta to Chicago)
- Leg 2: HUB-ORD → HUB-LAX (Chicago to Los Angeles)

## Database Schema

### New Table: `mrd_shipment_legs`

```sql
CREATE TABLE mrd_shipment_legs (
  id                TEXT PRIMARY KEY,        -- MRD- prefix + 8-char nanoid
  shipment_id       TEXT NOT NULL REFERENCES mrd_shipments(id),
  sequence          INTEGER NOT NULL,        -- 1, 2, 3... ordering
  origin_hub        TEXT NOT NULL REFERENCES mrd_hubs(id),
  dest_hub          TEXT NOT NULL REFERENCES mrd_hubs(id),
  status            TEXT NOT NULL DEFAULT 'PENDING',
  carrier           TEXT,                    -- optional carrier name
  estimated_arrival INTEGER,                 -- Unix epoch ms
  actual_arrival    INTEGER,                 -- Unix epoch ms, set on ARRIVED
  created_at        INTEGER NOT NULL,        -- Unix epoch ms
  updated_at        INTEGER NOT NULL,        -- Unix epoch ms
  UNIQUE(shipment_id, sequence)
);
```

IDs use the same `MRD-` prefix + 8-character nanoid format as all other entities.

## Leg State Machine

Each leg has its own independent state machine:

```
PENDING → IN_TRANSIT → ARRIVED
                     → FAILED
```

**Transitions:**
| Action   | From       | To         | Required Role      | Constraints                          |
|----------|------------|------------|--------------------|--------------------------------------|
| START    | PENDING    | IN_TRANSIT | dispatcher, admin  | Previous leg must be ARRIVED (or first leg) |
| ARRIVE   | IN_TRANSIT | ARRIVED    | any authenticated  | Sets `actual_arrival` to current time |
| FAIL     | IN_TRANSIT | FAILED     | admin              | Must include `reason` in request body metadata |

**Terminal states:** ARRIVED and FAILED. No transitions allowed from these.

## How Leg Transitions Affect Shipment Status

Leg status changes can automatically update the parent shipment's status:

| Leg Event | Condition | Shipment Effect |
|-----------|-----------|-----------------|
| First leg starts | Shipment is MANIFESTED | Shipment → IN_TRANSIT |
| Any leg fails | - | Shipment → EXCEPTION |
| Last leg arrives | All legs ARRIVED | Shipment → AT_HUB (at final destination) |

These automatic updates should also create entries in `mrd_events` for the shipment.

## API Endpoints

### Add a Leg

```
POST /api/v1/shipments/:id/legs
```

**Auth:** Required. Dispatcher or admin role.

**Request body:**
```json
{
  "origin_hub": "MRD-abc12345",
  "dest_hub": "MRD-def67890",
  "carrier": "FastFreight Inc",
  "estimated_arrival": 1700100000000
}
```

`carrier` and `estimated_arrival` are optional.

**Behavior:**
- Auto-assigns the next sequence number (max existing sequence + 1, or 1 if no legs exist)
- Validates the shipment exists and is not in a terminal state
- Validates hub chain continuity:
  - First leg: `origin_hub` must equal the shipment's `origin_hub`
  - Subsequent legs: `origin_hub` must equal the previous leg's `dest_hub`
- Validates both hubs exist in `mrd_hubs`
- Returns the created leg in the standard response envelope

**Response (201):**
```json
{
  "ok": true,
  "ts": 1700000000000,
  "data": {
    "id": "MRD-leg12345",
    "shipment_id": "MRD-shp12345",
    "sequence": 1,
    "origin_hub": "MRD-abc12345",
    "dest_hub": "MRD-def67890",
    "status": "PENDING",
    "carrier": "FastFreight Inc",
    "estimated_arrival": 1700100000000,
    "actual_arrival": null,
    "created_at": 1700000000000,
    "updated_at": 1700000000000
  },
  "error": null,
  "meta": null
}
```

### Transition a Leg

```
PATCH /api/v1/shipments/:id/legs/:legId/transition
```

**Auth:** Required. Role depends on action (see state machine table above).

**Request body:**
```json
{
  "action": "START",
  "metadata": {}
}
```

**Behavior:**
- Validates the shipment and leg both exist, and the leg belongs to the shipment
- Validates the transition is allowed from the current leg status
- Validates the actor's role is permitted for this transition
- For START: validates that all previous legs (lower sequence numbers) are ARRIVED
- Updates leg status and `updated_at`
- For ARRIVE: sets `actual_arrival` to current time
- Triggers shipment status update if applicable (see table above)
- Logs an event in `mrd_events` for the leg transition
- If shipment status changed, logs a separate event for the shipment transition

**Response (200):**
```json
{
  "ok": true,
  "ts": 1700000000000,
  "data": {
    "id": "MRD-leg12345",
    "shipment_id": "MRD-shp12345",
    "sequence": 1,
    "status": "IN_TRANSIT",
    "...": "..."
  },
  "error": null,
  "meta": null
}
```

### Get Shipment (Updated)

```
GET /api/v1/shipments/:id
```

Response now includes a `legs` array:

```json
{
  "ok": true,
  "ts": 1700000000000,
  "data": {
    "id": "MRD-shp12345",
    "origin_hub": "MRD-abc12345",
    "dest_hub": "MRD-ghi11111",
    "status": "IN_TRANSIT",
    "priority": "EXPRESS",
    "weight_kg": 25.5,
    "manifest_ref": "MNF-2024-001",
    "created_at": 1700000000000,
    "updated_at": 1700050000000,
    "events": [ ... ],
    "legs": [
      {
        "id": "MRD-leg12345",
        "sequence": 1,
        "origin_hub": "MRD-abc12345",
        "dest_hub": "MRD-def67890",
        "status": "ARRIVED",
        "carrier": "FastFreight Inc",
        "estimated_arrival": 1700100000000,
        "actual_arrival": 1700095000000,
        "created_at": 1700000000000,
        "updated_at": 1700095000000
      },
      {
        "id": "MRD-leg67890",
        "sequence": 2,
        "origin_hub": "MRD-def67890",
        "dest_hub": "MRD-ghi11111",
        "status": "IN_TRANSIT",
        "carrier": null,
        "estimated_arrival": 1700200000000,
        "actual_arrival": null,
        "created_at": 1700010000000,
        "updated_at": 1700150000000
      }
    ]
  },
  "error": null,
  "meta": null
}
```

Legs are ordered by `sequence` ascending. If no legs exist, `legs` is an empty array `[]`.

## Validation Rules

These validations should be enforced across the API (add them now if not already present):

| Field | Rule |
|-------|------|
| `weight_kg` | Must be a positive number if provided |
| `priority` | Must be one of: `STANDARD`, `EXPRESS`, `CRITICAL` |
| `manifest_ref` | Alphanumeric with hyphens, 6-20 characters |
| Hub `code` | Must start with `HUB-` followed by 2-4 uppercase letters |
| Leg `origin_hub` | Must reference an existing hub |
| Leg `dest_hub` | Must reference an existing hub, must differ from `origin_hub` |
| Leg `sequence` | Must be sequential with no gaps |

## Backward Compatibility

- Shipments without legs must continue to work exactly as before
- The direct transition endpoint (`PATCH /api/v1/shipments/:id/transition`) must still function
- All existing tests must pass without modification
- The `legs` array in GET response is simply empty `[]` when no legs exist

## Error Responses

All errors use the standard response envelope:

```json
{
  "ok": false,
  "ts": 1700000000000,
  "data": null,
  "error": "Leg origin hub must match previous leg destination hub",
  "meta": null
}
```

Common error cases:
- 400: Invalid transition, validation failure, hub chain broken
- 401: Missing or invalid auth
- 403: Insufficient role for the requested action
- 404: Shipment or leg not found
