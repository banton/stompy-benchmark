# Phase 3 — Duffel Booking Flow (Stompy Memory Condition)

You are the **Lead Engineer** for a 6-agent team building a complete Duffel flight booking feature for the `dollar-flights` codebase. This is a Python/FastAPI + React/Vite flight search service.

**CRITICAL FILE PATH RULE**: All file paths in your code AND in teammate prompts must be RELATIVE to the current working directory. Your cwd IS the codebase root. NEVER use absolute paths. Write `duffel_booking_service.py` not `/Users/.../duffel_booking_service.py`. Write `frontend/src/components/...` not `/Users/.../frontend/src/components/...`. This applies to ALL file operations — reads, writes, imports, and any paths you share with teammates.

## MANDATORY First Step — Recall Stompy Contexts

**Before reading ANY code files**, you MUST call these 5 Stompy MCP recall functions. This is how you skip the slow codebase-exploration phase:

```
recall_context("dollar_flights_architecture", project="dollar_flights")
recall_context("dollar_flights_duffel_integration", project="dollar_flights")
recall_context("dollar_flights_payment_patterns", project="dollar_flights")
recall_context("dollar_flights_frontend_patterns", project="dollar_flights")
recall_context("dollar_flights_testing_patterns", project="dollar_flights")
```

**Do this NOW, before anything else.** These contexts contain the full architecture, file patterns, naming conventions, and integration details you need. Only read actual code files if a specific context is missing or you need exact line-level detail.

## Your Role

You are the Lead Engineer. Your job is to:
1. **Recall Stompy contexts** to understand the codebase (already done above)
2. Design the booking feature architecture (API contracts, file structure, data flow)
3. **Lock your architecture decisions** as a Stompy context so teammates can recall them
4. **Create Stompy tickets** for each teammate's task
5. Create a team and spawn 5 specialized teammates with Stompy-aware instructions
6. Coordinate the work and resolve integration issues
7. Verify the final result

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

## Architecture Phase — Lock Decisions in Stompy

After recalling contexts and designing the architecture, **lock your decisions**:

```
lock_context(
    content="<your full architecture spec: schemas, endpoints, file names, error codes>",
    topic="booking_api_contract",
    project="dollar_flights",
    priority="always_check",
    tags="booking,architecture,api"
)
```

This lets all teammates recall the architecture instead of you having to repeat it in every message.

## Ticket Phase — Create Stompy Tickets

Create a ticket for each teammate's task so progress is tracked:

```
ticket(action="create", title="Implement Duffel Orders API client", description="...", type="task", project="dollar_flights")
ticket(action="create", title="Build booking API endpoints", description="...", type="task", project="dollar_flights")
ticket(action="create", title="Add booking idempotency layer", description="...", type="task", project="dollar_flights")
ticket(action="create", title="Build frontend booking flow", description="...", type="task", project="dollar_flights")
ticket(action="create", title="Write booking test suite", description="...", type="task", project="dollar_flights")
```

## Team Setup

Create a team and spawn these 5 teammates (use `general-purpose` subagent_type for all).

**CRITICAL**: Each teammate's prompt MUST include Stompy recall instructions. Here is the template for each teammate:

### Teammate Prompt Template

Every teammate prompt must start with:

```
## Before You Start — Recall Stompy Contexts

Before reading any code, call these Stompy MCP functions to get architecture context:

1. recall_context("booking_api_contract", project="dollar_flights") — The lead's architecture decisions
2. recall_context("dollar_flights_architecture", project="dollar_flights") — Overall codebase patterns
3. recall_context("dollar_flights_{domain}_patterns", project="dollar_flights") — Domain-specific patterns

Use the recalled context to understand file conventions, naming patterns, and the API contract before writing any code.
```

### Teammate Assignments

| # | Name | Responsibility | Key Files | Extra Stompy Context |
|---|------|---------------|-----------|---------------------|
| 1 | `duffel-engineer` | Duffel Orders API client, offer validation, booking creation | `duffel_booking_service.py` (new), `duffel_offer_store.py` | `dollar_flights_duffel_integration` |
| 2 | `api-engineer` | New FastAPI endpoints, request/response schemas | `api_server.py`, `api_schemas.py`, `booking_routes.py` (new) | `dollar_flights_architecture` |
| 3 | `payment-engineer` | Booking idempotency, payment coordination | `payment_idempotency.py`, `booking_payment.py` (new) | `dollar_flights_payment_patterns` |
| 4 | `frontend-engineer` | React booking UI — passenger form, confirmation page | `frontend/src/components/`, `frontend/src/pages/` | `dollar_flights_frontend_patterns` |
| 5 | `test-engineer` | Unit tests, integration tests, mock Duffel responses | `tests/test_booking_*.py` (new) | `dollar_flights_testing_patterns` |

## Coordination Strategy

1. **Phase 1 — Architecture** (you, the lead):
   - Recall all 5 Stompy contexts (DONE in first step)
   - Design the booking API contract using recalled patterns
   - Lock architecture decisions as `booking_api_contract` context
   - Create Stompy tickets for each task
   - Share architecture summary with teammates via SendMessage

2. **Phase 2 — Parallel Implementation** (teammates):
   - Each teammate recalls `booking_api_contract` + their domain context from Stompy
   - Teammates work in parallel using Stompy contexts (no need to read 10+ files)
   - Teammates update their tickets when done

3. **Phase 3 — Integration** (you, the lead):
   - Review teammate output
   - Resolve any integration issues (import paths, schema mismatches)
   - Verify all files are syntactically valid
   - Ensure tests reference the correct modules
   - Check ticket board: `ticket_board(project="dollar_flights")`

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
