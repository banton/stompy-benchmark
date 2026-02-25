# Post-Session 1: Write Memory Files

You just finished building the initial Meridian Logistics API (project setup, database schema, hub and shipment CRUD). Now you need to document what you built so that a future session (with no access to this conversation) can pick up where you left off.

## Create `MEMORY.md`

Write a `MEMORY.md` file in the project root that documents everything a developer would need to know to continue working on this project. Include:

### Architecture & Project Structure
- Tech stack: Express, TypeScript, SQLite (better-sqlite3), Vitest
- Full file tree with descriptions of what each file does
- How the app bootstraps (entry point, middleware chain, route mounting)
- How the database is initialized (schema creation, seeding)

### Database Schema
- All tables with their columns, types, and constraints
- Foreign key relationships
- Naming convention (mrd_ prefix on tables)
- How seed data is loaded

### API Patterns & Conventions
- Base URL pattern (`/api/v1/`)
- Response envelope format with example: `{ ok, ts, data, error, meta }`
- ID generation: MRD- prefix + 8-char nanoid, and which utility function generates them
- Timestamp format: Unix epoch milliseconds
- File naming convention: `{resource}.routes.ts`, `{resource}.service.ts`, `{resource}.model.ts`
- Error handling pattern

### Endpoints Implemented
- List every endpoint with method, path, request body shape, and response shape
- Note which endpoints require auth (none yet) and which are public

### Testing Patterns
- Test framework: Vitest + supertest
- How test database isolation works (in-memory SQLite or separate DB file)
- Test file naming and location
- How to run tests
- Any test helpers or utilities

### What Is NOT Yet Implemented
- Authentication (HMAC-based, X-Meridian-Auth header)
- State machine transitions (the full lifecycle)
- Transition endpoint (PATCH /api/v1/shipments/:id/transition)
- Event logging for transitions
- Input validation (weight, priority, manifest_ref format)

## Create `TASKS.md`

Write a `TASKS.md` file in the project root tracking remaining work:

```markdown
# Meridian Logistics API — Task Tracker

## Completed
- [x] Project setup (Express + TypeScript + SQLite)
- [x] Database schema (mrd_hubs, mrd_shipments, mrd_events)
- [x] Hub CRUD (GET /api/v1/hubs, POST /api/v1/hubs)
- [x] Shipment CRUD (POST, GET list, GET by ID)
- [x] Response envelope helper
- [x] ID generation (MRD- prefix)
- [x] Seed data (3 test hubs)
- [x] Tests for all CRUD endpoints

## TODO — Session 2: Auth & State Machine
- [ ] HMAC authentication middleware (X-Meridian-Auth header)
- [ ] Client credential store (admin, dispatcher, viewer roles)
- [ ] Auth required on all endpoints except GET /hubs
- [ ] State machine: DRAFT → MANIFESTED → IN_TRANSIT → AT_HUB → OUT_FOR_DELIVERY → DELIVERED
- [ ] Exception path: OUT_FOR_DELIVERY → EXCEPTION → RETURNED
- [ ] Role-based transition restrictions
- [ ] Terminal states (DELIVERED, RETURNED)
- [ ] PATCH /api/v1/shipments/:id/transition endpoint
- [ ] Event logging in mrd_events on each transition
- [ ] Include events in GET /shipments/:id response
- [ ] Auth tests (valid, invalid, expired, wrong role)
- [ ] State machine tests (happy path, exception path, invalid transitions, role checks)

## TODO — Future: Validation & Polish
- [ ] weight_kg must be positive
- [ ] priority must be STANDARD, EXPRESS, or CRITICAL
- [ ] manifest_ref format validation
- [ ] Hub code format validation (HUB-XXX)
- [ ] Integration tests for full shipment lifecycle
```

## Important

- Be thorough. The person reading these files will have zero context about this project.
- Include actual code snippets for patterns that are non-obvious (like the response envelope helper signature, or how IDs are generated).
- Include the exact commands to run tests, start the server, etc.
- Do not include implementation code — just enough to understand the patterns and make informed decisions.
