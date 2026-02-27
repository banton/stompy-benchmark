# Task 2 — Extract context_explore & context_dashboard to Services (No Memory Condition)

You are working on the **Stompy MCP Server** codebase (`dementia-production`). This is a Python/FastAPI/PostgreSQL application. The main file `stompy_server.py` is ~4900 lines and contains complex inline logic that should be extracted to service files.

## Before You Start

You have no notes or context from previous sessions. You need to explore the codebase to understand it before implementing anything.

1. Look at the project structure — list files in `src/`, `src/services/`, `src/middleware/`, `tests/`
2. Read `CLAUDE.md` for project-level guidance
3. Read `stompy_server.py` — specifically find `context_explore` (~line 3989) and `context_dashboard` (~line 4190)
4. **Critically**: Read existing extracted services to understand the pattern:
   - `src/services/context_service.py` — how context operations were extracted
   - `src/services/context_search_service.py` — another extraction example
   - `src/services/context_helpers_service.py` — helper patterns
5. Read `postgres_adapter.py` to understand database access patterns
6. Read existing test files (especially for context services) to understand testing conventions
7. Look at `src/services/service_registry.py` to understand how services are registered

Take your time to understand the conventions before implementing anything. Consistency with the existing code is critical.

## Task Specification

### Overview

The `stompy_server.py` monolith contains two complex MCP tools with significant inline logic:

1. **`context_explore`** (~line 3989) — Browses and filters stored contexts by priority, topic, tags, and date ranges. Contains complex SQL query building, pagination, and formatting logic.

2. **`context_dashboard`** (~line 4190) — Generates a summary dashboard of all contexts in the project, with statistics, category breakdowns, and health metrics.

Both tools have their core logic inline in `stompy_server.py` rather than in dedicated service files.

### Requirements

1. **Extract `context_explore` logic to `src/services/context_explore_service.py`:**
   - Create a new service class (e.g., `ContextExploreService`)
   - Move the query building, filtering, pagination, and formatting logic into service methods
   - The MCP tool function in `stompy_server.py` should become a thin wrapper that delegates to the service
   - Follow the same patterns as `context_service.py` and `context_search_service.py`

2. **Extract `context_dashboard` logic to `src/services/context_dashboard_service.py`:**
   - Create a new service class (e.g., `ContextDashboardService`)
   - Move the statistics calculation, category breakdown, and formatting logic into service methods
   - The MCP tool function in `stompy_server.py` should become a thin wrapper that delegates to the service

3. **Follow established extraction patterns:**
   - Use the same class structure as existing services (constructor with db adapter/helpers)
   - Use the same error handling patterns (try/except with logging)
   - Use the same DB access patterns (postgres_adapter, parameterized queries)
   - Maintain the same logging patterns
   - Use dataclass or Pydantic models for structured return types where appropriate

4. **Preserve all existing behavior:**
   - The MCP tool signatures must not change
   - The tool responses must be identical
   - Error handling must be preserved
   - Logging must be preserved

### Files to Modify/Create

- `stompy_server.py` — reduce by extracting inline logic, replace with service calls
- Create `src/services/context_explore_service.py`
- Create `src/services/context_dashboard_service.py`
- Create test file(s) in `tests/` directory (e.g., `tests/test_context_explore_service.py`, `tests/test_context_dashboard_service.py`)

### Testing Requirements

Write pytest tests covering:
- Main explore method with various filter combinations (priority, topic, tags)
- Explore pagination behavior
- Explore with empty results
- Dashboard statistics calculation
- Dashboard with empty project
- Dashboard error handling
- Mock the database layer — do not require a real PostgreSQL connection
- At least 5 test functions per service (10+ total)

### Acceptance Criteria

- [ ] `src/services/context_explore_service.py` exists with extracted logic
- [ ] `src/services/context_dashboard_service.py` exists with extracted logic
- [ ] `stompy_server.py` line count decreased (logic moved out)
- [ ] MCP tool behavior unchanged (thin wrapper delegates to service)
- [ ] No circular imports
- [ ] At least 10 test functions total
- [ ] All Python files have valid syntax
- [ ] Services follow existing naming and structural conventions
- [ ] Logging preserved in new service files
- [ ] DB queries moved from server to service layer
