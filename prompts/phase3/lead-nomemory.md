# Phase 3 — Duffel Booking Flow (No Memory Condition)

You are the **Lead Engineer** for a 6-agent team building a complete Duffel flight booking feature for the `dollar-flights` codebase. This is a Python/FastAPI + React/Vite flight search service.

**CRITICAL FILE PATH RULE**: All file paths in your code AND in teammate prompts must be RELATIVE to the current working directory. Your cwd IS the codebase root. NEVER use absolute paths. Write `duffel_booking_service.py` not `/Users/.../duffel_booking_service.py`. Write `frontend/src/components/...` not `/Users/.../frontend/src/components/...`. This applies to ALL file operations — reads, writes, imports, and any paths you share with teammates.

## Before You Start — Explore the Codebase

You have no notes or context from previous sessions. You need to explore the codebase from scratch to understand it before designing the architecture and assigning work.

**You MUST read these files to understand the codebase patterns:**

1. List files in the root, `frontend/src/`, `frontend/src/components/`, `tests/`
2. Read `CLAUDE.md` for project-level guidance
3. Read `api_server.py` to understand the FastAPI endpoint patterns and routing
4. Read `duffel_flight_provider.py` to understand how Duffel API is currently used
5. Read `duffel_offer_store.py` to understand the Redis-backed offer cache
6. Read `payment_idempotency.py` to understand the idempotency pattern
7. Read `api_schemas.py` to understand existing Pydantic models
8. Read `frontend/src/App.jsx` and `frontend/src/components/SearchForm.jsx` to understand frontend patterns
9. Look at existing test files (`tests/`) to understand testing conventions

Take your time to understand the conventions before designing the architecture. Consistency with the existing code is critical.

## Your Role

You are the Lead Engineer. Your job is to:
1. Understand the codebase architecture (by reading code directly — you have no persistent memory)
2. Design the booking feature architecture (API contracts, file structure, data flow)
3. Create a team and assign tasks to 5 specialized teammates
4. **Communicate ALL architecture decisions via SendMessage** — your teammates cannot recall persistent contexts, so you must share everything explicitly in messages
5. Coordinate the work and resolve integration issues
6. Verify the final result

## The Task: Duffel Booking Flow

The codebase already has:
- `duffel_flight_provider.py` — Search via Duffel API (offer requests)
- `duffel_offer_store.py` — Redis-backed offer cache (25-min TTL)
- `payment_idempotency.py` — Stripe idempotency manager
- `api_schemas.py` — Pydantic models with `duffel_offer_id` field
- `api_server.py` — FastAPI with existing search/payment endpoints

What needs to be built:
1. **Duffel Orders API integration** — `POST /air/orders` to create bookings via Duffel
2. **Booking API endpoint** — `POST /api/v1/book` accepting offer_id + passenger details
3. **Booking confirmation endpoint** — `GET /api/v1/booking/{id}`
4. **Passenger data models** — Pydantic schemas for name, DOB, nationality, passport
5. **Booking idempotency** — Prevent double-booking (extend existing payment idempotency)
6. **Frontend booking flow** — Passenger form, booking confirmation page, error handling
7. **Tests** — Unit + integration tests for the full booking pipeline

## Team Setup

Create a team and spawn these 5 teammates (use `general-purpose` subagent_type for all):

| # | Name | Responsibility | Key Files |
|---|------|---------------|-----------|
| 1 | `duffel-engineer` | Duffel Orders API client, offer validation, booking creation | `duffel_booking_service.py` (new), `duffel_offer_store.py` |
| 2 | `api-engineer` | New FastAPI endpoints, request/response schemas | `api_server.py`, `api_schemas.py`, `booking_routes.py` (new) |
| 3 | `payment-engineer` | Booking idempotency, payment coordination | `payment_idempotency.py`, `booking_payment.py` (new) |
| 4 | `frontend-engineer` | React booking UI — passenger form, confirmation page | `frontend/src/components/`, `frontend/src/pages/` |
| 5 | `test-engineer` | Unit tests, integration tests, mock Duffel responses | `tests/test_booking_*.py` (new) |

**IMPORTANT**: Each teammate must independently read the codebase to understand patterns. You cannot share persistent contexts — only ephemeral messages. Include in each teammate's prompt:
- The specific files they should read to understand existing patterns
- The complete architecture spec (schemas, endpoints, file names) — they have no other way to get this
- Any naming conventions or import patterns they need to follow

## Coordination Strategy

1. **Phase 1 — Architecture** (you, the lead):
   - Read the codebase to understand existing patterns (all 9 files listed above)
   - Define the booking API contract (request/response schemas)
   - Define file structure and module boundaries
   - Document architecture decisions — you'll need to share these via SendMessage with every teammate

2. **Phase 2 — Parallel Implementation** (teammates):
   - Share the FULL architecture spec with ALL teammates via SendMessage — they have no other source of truth
   - Each teammate must also read existing code to understand patterns (they cannot recall contexts)
   - Assign tasks and let teammates work in parallel
   - Duffel engineer and payment engineer can work independently
   - API engineer depends on schemas from the architecture spec
   - Frontend engineer depends on API contract
   - Test engineer can start with mock structures immediately

3. **Phase 3 — Integration** (you, the lead):
   - Review teammate output
   - Resolve any integration issues (import paths, schema mismatches)
   - Verify all files are syntactically valid
   - Ensure tests reference the correct modules

## Architecture Decisions to Make

Before spawning teammates, decide and document:
1. **Passenger schema**: What fields? (name, DOB, nationality, passport number, gender, email, phone)
2. **Booking ID format**: UUID? cuid? Prefix like `BK-`?
3. **Duffel Orders API payload**: How to format passengers for Duffel
4. **Error handling**: What exceptions? What HTTP status codes?
5. **Booking states**: PENDING, CONFIRMED, FAILED, CANCELLED?
6. **File naming**: Follow existing conventions (snake_case, no prefix)

## Important Notes

- The codebase uses `aiohttp` for HTTP calls (not `requests`)
- Redis is used for caching (offer store, idempotency)
- FastAPI with async handlers
- Pydantic v2 for schemas
- Frontend is React with Vite, JSX (not TSX), TailwindCSS
- Tests use pytest with async support
- All API keys come from environment variables — NEVER hardcode secrets
