# Session 3 — Scope Change: Multi-Leg Routing (Stompy Memory Condition)

You are continuing work on the **Meridian Logistics API**. This is session 3, the final session. Previous sessions built CRUD, auth, and the state machine. There is a **scope change** in this session.

## Before You Start

1. **Check Stompy MCP for context from previous sessions:**
   - `recall_context("meridian_architecture")` — project structure, conventions
   - `recall_context("meridian_db_schema")` — database tables and columns
   - `recall_context("meridian_api_patterns")` — endpoint patterns, response format
   - `recall_context("meridian_auth")` — authentication implementation
   - `recall_context("meridian_state_machine")` — state machine transitions and rules
   - `ticket_search("meridian")` — pending tickets and remaining work

2. Review any open tickets. Address critical bugs or gaps before starting the new feature.

3. Read `SPEC.md` for reference, but note that the spec has been **updated** with a new section on multi-leg routing.

## SCOPE CHANGE: Multi-Leg Routing

The product team has added a new requirement. Shipments now support **multi-leg routing** — a shipment can travel through multiple intermediate hubs rather than going directly from origin to destination.

Read `prompts/scope-change.md` (or the updated section in SPEC.md) for the full multi-leg specification. Here is a summary of what you need to build:

### New Database Table

```sql
CREATE TABLE mrd_shipment_legs (
  id                TEXT PRIMARY KEY,
  shipment_id       TEXT NOT NULL REFERENCES mrd_shipments(id),
  sequence          INTEGER NOT NULL,
  origin_hub        TEXT NOT NULL REFERENCES mrd_hubs(id),
  dest_hub          TEXT NOT NULL REFERENCES mrd_hubs(id),
  status            TEXT NOT NULL DEFAULT 'PENDING',
  carrier           TEXT,
  estimated_arrival INTEGER,
  actual_arrival    INTEGER,
  created_at        INTEGER NOT NULL,
  updated_at        INTEGER NOT NULL,
  UNIQUE(shipment_id, sequence)
);
```

### New Endpoints

#### Add a Leg
```
POST /api/v1/shipments/:id/legs
Auth: Required (dispatcher or admin)
Body: { origin_hub, dest_hub, carrier?, estimated_arrival? }
```

The sequence number is auto-assigned (next after the highest existing leg). Validation:
- The shipment must exist and not be in a terminal state (DELIVERED, RETURNED)
- For the first leg: `origin_hub` must match the shipment's `origin_hub`
- For subsequent legs: `origin_hub` must match the previous leg's `dest_hub`
- The `dest_hub` must be a valid hub

#### Transition a Leg
```
PATCH /api/v1/shipments/:id/legs/:legId/transition
Auth: Required
Body: { action: "START" | "ARRIVE" | "FAIL" }
```

Leg state machine:
- `PENDING → IN_TRANSIT` (action: START) — requires dispatcher or admin
- `IN_TRANSIT → ARRIVED` (action: ARRIVE) — any authenticated role
- `IN_TRANSIT → FAILED` (action: FAIL) — requires admin, must include `reason` in metadata

Leg transitions affect the parent shipment:
- When a leg starts (first leg only): shipment moves to IN_TRANSIT (if currently MANIFESTED)
- When a leg arrives: if it's the last leg, shipment moves to AT_HUB at destination
- When a leg fails: shipment moves to EXCEPTION

#### Get Shipment (Updated)
```
GET /api/v1/shipments/:id
```

Response now includes a `legs` array, ordered by sequence ascending. Each leg includes all fields from `mrd_shipment_legs`.

### Derived Status Logic

When legs exist, the shipment's overall status considers leg statuses:
- If any leg has status `FAILED` → shipment should be `EXCEPTION`
- If all legs are `ARRIVED` → shipment is ready for next stage (AT_HUB at final destination)
- If any leg is `IN_TRANSIT` → shipment should be `IN_TRANSIT`

### Validation Rules

While implementing multi-leg routing, also add these validations if not already present:
- `weight_kg` must be positive if provided
- `priority` must be one of: `STANDARD`, `EXPRESS`, `CRITICAL`
- `manifest_ref` format: alphanumeric with hyphens, 6-20 chars
- Hub `code` format: `HUB-` prefix followed by 2-4 uppercase letters

### Tests

Write comprehensive tests (`tests/legs.test.ts` or `tests/multi-leg.test.ts`):

**Leg CRUD:**
- Create a leg on a shipment
- Create multiple legs in sequence
- Validation: first leg origin must match shipment origin
- Validation: subsequent leg origin must match previous leg dest
- Cannot add legs to a delivered shipment

**Leg transitions:**
- Happy path: PENDING → IN_TRANSIT → ARRIVED for each leg
- Fail path: IN_TRANSIT → FAILED
- Role restrictions on leg transitions
- Invalid transitions (e.g., PENDING → ARRIVED directly)

**Integration (full flow):**
- Create shipment → manifest → add 3 legs → start leg 1 → arrive leg 1 → start leg 2 → arrive leg 2 → start leg 3 → arrive leg 3 → dispatch → deliver
- Verify events are recorded for each transition
- Verify GET shipment includes legs array
- Verify shipment status derives correctly from leg statuses

**Regression:**
- All existing tests must still pass
- Auth still works on all endpoints
- Direct transitions (no legs) still work

### After You Finish

Store your final state in Stompy:
- Update contexts with multi-leg implementation details
- Close completed tickets
- Note any remaining edge cases or improvements as tickets
- Record the final architecture state for future reference

## Important

- Maintain backward compatibility — shipments without legs must still work exactly as before
- Auth is required on all new endpoints
- Use the same response envelope, ID format (MRD- prefix), and timestamp conventions
- Use the same file organization patterns (`legs.routes.ts`, `legs.service.ts`, `legs.model.ts` or nest under shipments)
- All new SQL must use parameterized queries (no string interpolation)
- Run ALL tests (existing + new) before finishing
