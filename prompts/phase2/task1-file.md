# Task 1 — project_delete Preview with Data Counts (File Memory Condition)

You are working on the **Stompy MCP Server** codebase (`dementia-production`). This is a Python/FastAPI/PostgreSQL application with ~5000 lines in the main `stompy_server.py` file.

## Before You Start

1. **Read `MEMORY.md`** in the project root. It contains comprehensive architecture notes, database schema, service patterns, and MCP tool reference accumulated over many development sessions.

2. **Read `TASKS.md`** in the project root. It contains the project ticket board with all open and completed tasks. Look for ticket #162 which describes this task.

3. Use the information in these files to understand the codebase architecture before writing any code. Only explore files directly if MEMORY.md doesn't cover what you need.

## Task Specification

### Overview

The `project_delete` MCP tool in `stompy_server.py` currently accepts a `confirm` parameter. When `confirm=false` (the default), it shows a generic warning message about what will be deleted. When `confirm=true`, it performs the actual deletion.

**The problem:** The preview mode (`confirm=false`) doesn't tell the user *how much* data will be deleted. Users want to see actual counts before confirming a destructive operation.

### Requirements

1. **Add a data count preview to `project_delete`** when `confirm=false`:
   - Count the number of **context locks** (contexts) in the project schema
   - Count the number of **memory entries** (memories) in the project schema
   - Count the number of **tickets** in the project schema (if the tickets table exists)
   - Count the number of **file tags** (files) in the project schema
   - Count the number of **sessions** referencing this project
   - Return these counts in a structured preview response

2. **Add a count method to the project service** (`src/services/project_service.py` or `src/services/project_tools_service.py`):
   - Create a method like `get_project_data_counts(project_name)` that queries each table
   - Handle cases where tables don't exist (e.g., tickets table may not exist for all projects)
   - Use the existing database access patterns (postgres_adapter, get_db helpers)

3. **Preserve backward compatibility:**
   - `confirm=true` must still perform the full deletion as before
   - The tool signature and basic behavior must not change
   - The preview response should be a superset of the current preview response

4. **Handle edge cases:**
   - Empty project (all counts are 0)
   - Project that doesn't exist (appropriate error)
   - Tables that don't exist in the project schema (count as 0, don't error)

### Files to Modify

- `stompy_server.py` — modify the `project_delete` tool function
- `src/services/project_service.py` or `src/services/project_tools_service.py` — add count method
- Create test file(s) in `tests/` directory

### Testing Requirements

Write pytest tests covering:
- Preview returns correct counts for a project with data
- Preview returns zeros for an empty project
- Preview handles missing/non-existent tables gracefully
- `confirm=true` still performs deletion (backward compat)
- Error handling for non-existent project
- Mock the database layer — do not require a real PostgreSQL connection

### Acceptance Criteria

- [ ] `project_delete(confirm=false)` returns data counts (contexts, memories, tickets, files, sessions)
- [ ] New count method exists in a service file
- [ ] At least 5 test functions covering happy path, empty project, error cases
- [ ] All modified Python files have valid syntax
- [ ] No new dependencies required
- [ ] Backward compatible — existing `confirm=true` behavior unchanged
