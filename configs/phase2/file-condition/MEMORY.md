# Dementia-Production Codebase — Accumulated Agent Memory

Accumulated over 100+ development sessions on the dementia-production backend.
This file is the single reference for navigating, modifying, and debugging this codebase.

---

## 1. Project Overview & Architecture

### What Is Stompy?

Stompy is an MCP (Model Context Protocol) server that provides AI assistants with
persistent memory between sessions. Core capabilities:
- Lock immutable versioned contexts (API specs, configs, architecture decisions)
- Search memory semantically (Voyage AI embeddings) and by keywords (BM25/tsvector)
- Track sessions with automatic handovers and breadcrumbs
- Isolate projects with per-project PostgreSQL schemas
- Scan codebases to understand file structure

### Technology Stack

```yaml
language: Python 3.11+
database: PostgreSQL 16 (NeonDB serverless, scale-to-zero)
embedding: Voyage AI (voyage-3.5-lite 1024d, voyage-4-large docs, voyage-4-lite queries)
llm: OpenRouter (google/gemini-2.5-flash-lite for summaries)
mcp_sdk: Anthropic MCP SDK (FastMCP)
web_framework: Starlette (NOT FastAPI for MCP transport; FastAPI for REST API routes)
auth: Auth0 OAuth2 + static Bearer token fallback
caching: Redis / Valkey (DigitalOcean Managed)
storage: DigitalOcean Spaces (S3-compatible) for file uploads
deployment: DigitalOcean App Platform
logging: structlog (structured JSON logging)
metrics: Prometheus (custom counters + histograms)
```

### Two Server Entry Points

The codebase has two independent entry points that share the same MCP tool definitions:

1. **`stompy_server.py`** (4895 lines) — MCP stdio server for local Claude Desktop
   - Runs via `./start-stompy.sh`
   - Creates PostgreSQL session on startup
   - Communicates via JSON-RPC over stdin/stdout
   - Registered as `@mcp.tool()` decorators on the `mcp` FastMCP instance

2. **`server_hosted.py`** — Cloud-hosted production server
   - Imports `mcp` from `stompy_server` and wraps it in Starlette
   - Adds HTTP transport (`/mcp` endpoint), authentication, rate limiting
   - Adds REST API routes mounted at `/api/v1`
   - Adds OAuth endpoints, session middleware, metrics
   - Runs via `python3 server_hosted.py`

### Deployment Architecture

- **Production URL**: `api.stompy.ai` (DigitalOcean App Platform)
- **Frontend**: `stompy.ai` / `www.stompy.ai` (Next.js on DO App Platform)
- **Database**: NeonDB serverless PostgreSQL (with PgBouncer pooler)
- **Cache**: DigitalOcean Managed Valkey (Redis-compatible)
- **Object Storage**: DigitalOcean Spaces
- **Auth Provider**: Auth0

### Key Design Decisions

- **Starlette, not FastAPI for MCP transport**: FastMCP internally uses Starlette,
  so `server_hosted.py` builds on that. FastAPI is only used for the REST API
  routes (via `APIRouter`), which are mounted as sub-applications.

- **Dual-schema PostgreSQL**: Each project gets its own schema for data isolation.
  Cross-project data (sessions, OAuth, breadcrumbs) lives in `mcp_global`.
  User-global contexts live in `user_global`.

- **Sync psycopg2 for MCP tools**: MCP tool handlers use synchronous psycopg2
  (not asyncpg), wrapped in async functions. This is intentional — the MCP SDK
  runs tools sequentially, and psycopg2 is simpler for the connection caching
  pattern used here.

- **Service extraction in progress**: Originally everything was in stompy_server.py.
  Over multiple refactoring waves, business logic has been extracted to
  `src/services/`. The MCP tool functions remain thin wrappers that delegate
  to service classes.

---

## 2. File Map & Project Structure

### Root Directory

```
dementia-production/
|-- stompy_server.py              # MCP server (4895 lines, all @mcp.tool() defs)
|-- server_hosted.py              # Production Starlette server (middleware + REST)
|-- postgres_adapter.py           # PostgreSQL adapter (schema isolation, connection caching)
|-- active_context_engine.py      # Auto-loads relevant contexts for commands
|-- claude_mcp_utils.py           # Utility functions (preview, key concepts, errors)
|-- tool_breadcrumbs.py           # Breadcrumb trail system (debug traces)
|-- auth0_integration.py          # Auth0 OAuth2 integration
|-- mcp_session_store.py          # Sync session persistence
|-- mcp_session_store_async.py    # Async session persistence
|-- mcp_session_middleware.py     # Session middleware for HTTP transport
|-- mcp_session_cleanup.py        # Background session cleanup
|-- start-stompy.sh               # Local MCP server launcher
|-- pyproject.toml                # Python project metadata
|-- requirements.txt              # Dependencies
|-- .env                          # Environment variables (gitignored)
```

### src/ Directory

```
src/
|-- __init__.py
|-- __version__.py                # Version source of truth (e.g. "6.0.0")
|-- _config.py                    # APIConfig class (env vars, feature flags)
|-- config.py                     # Re-exports; may not exist separately
|-- schema_definitions.py         # DDL for all project-scoped tables
|-- schema_filter.py              # Schema filtering utilities
|-- logging_config.py             # structlog configuration
|-- logging_utils.py              # Logging helpers
|-- metrics.py                    # Prometheus metrics (tool_invocations, etc.)
|-- session_context.py            # Thread-safe session ID context
|
|-- api/
|   |-- __init__.py
|   |-- router.py                 # Main APIRouter combining all route modules
|   |-- dependencies.py           # FastAPI deps (get_current_user, get_user_db_url)
|   |-- routes/
|       |-- admin.py              # Admin endpoints
|       |-- agent.py              # Agent framework endpoints
|       |-- audit.py              # Audit log endpoints
|       |-- auth.py               # Auth endpoints (/me, login)
|       |-- bug_reports.py        # Bug report CRUD
|       |-- conflicts.py          # Conflict detection/resolution
|       |-- contexts.py           # Context CRUD (POST/GET/PUT/DELETE)
|       |-- files.py              # File upload/download
|       |-- invites.py            # Invite system
|       |-- projects.py           # Project CRUD
|       |-- provisioning.py       # Database provisioning
|       |-- search.py             # Search endpoints
|
|-- middleware/
|   |-- auth.py                   # BearerTokenAuth, CorrelationIdMiddleware
|   |-- rate_limit.py             # MCPRateLimitMiddleware, OAuthRateLimitMiddleware, slowapi
|
|-- models/
|   |-- __init__.py
|   |-- agent.py                  # Agent models
|   |-- context.py                # ContextResponse, ContextCreateRequest, etc.
|   |-- file.py                   # File upload models
|   |-- invite.py                 # Invite models
|   |-- pagination.py             # Pagination models
|   |-- project.py                # ProjectResponse, ProjectStats, ProjectCreate
|   |-- provisioning.py           # Provisioning models
|   |-- session.py                # SessionResponse, SessionListResponse
|   |-- user.py                   # UserInfo, UserResponse, UserTier
|
|-- migrations/
|   |-- __init__.py
|   |-- definitions.py            # All migration definitions (IDs 1-38+)
|
|-- services/                     # ~90+ service files (extracted from stompy_server.py)
|   |-- __init__.py               # Re-exports core helpers
|   |-- service_registry.py       # Centralized lazy service getters
|   |-- project_service.py        # ProjectService (list, stats, resolve)
|   |-- context_service.py        # ContextService (CRUD operations)
|   |-- context_search_service.py # ContextSearchService (semantic/hybrid/keyword)
|   |-- context_lock_service.py   # Lock validation, delta evaluation
|   |-- context_helpers_service.py# Archive, delete helpers
|   |-- conflict_service.py       # ConflictService (detection, resolution)
|   |-- conflict_tools_service.py # MCP tool wrappers for conflicts
|   |-- bug_report_service.py     # BugReportService
|   |-- user_service.py           # UserService (get/create users)
|   |-- session_service.py        # Session management
|   |-- session_finalizer.py      # Session finalization/handover
|   |-- redis_cache_service.py    # RedisCacheService (context/brief/search caching)
|   |-- cache_invalidator.py      # Cache invalidation on context changes
|   |-- voyage_ai_embedding_service.py # Voyage AI embedding generation
|   |-- semantic_search.py        # Vector similarity search
|   |-- hybrid_search_service.py  # Combined BM25 + vector search
|   |-- chunking_service.py       # Content chunking for large contexts
|   |-- reranking_service.py      # Result reranking
|   |-- openrouter_llm_service.py # LLM calls via OpenRouter
|   |-- export_import_service.py  # Project export/import
|   |-- document_processor.py     # PDF/image ingestion
|   |-- storage_service.py        # S3/Spaces file storage
|   |-- file_upload_service.py    # File upload handling
|   |-- credential_storage.py     # Encrypted credential storage
|   |-- neon_management_client.py # Neon API client (database provisioning)
|   |-- provisioning_worker.py    # Async DB provisioning worker
|   |-- provisioning_state_machine.py # Provisioning state transitions
|   |-- invite_service.py         # Invite management
|   |-- email_notification_service.py # Resend email API
|   |-- database_tools_service.py # db_query, db_workspace helpers
|   |-- schema_tools_service.py   # db_schema, get_breadcrumbs helpers
|   |-- project_stats_cache.py    # Redis cache for project stats
|   |-- cold_start_helper.py      # Neon cold start detection
|   |-- circuit_breaker.py        # Circuit breaker for external services
|   |-- ... (90+ files total)
|
|-- repositories/                 # Data access layer (newer pattern)
|
|-- cache/                        # Cache-related utilities
|
|-- utils/                        # General utilities
```

### Plugin Directories (installed as packages)

```
stompy-admin/                     # Admin plugin (get_breadcrumbs, detect/resolve/list conflicts)
  stompy_admin/mcp_tools.py       # MCP tool registrations

stompy-ticketing/                 # Ticketing plugin (4 MCP tools)
  stompy_ticketing/
    mcp_tools.py                  # ticket, ticket_link, ticket_board, ticket_search
    service.py                    # TicketService
    models.py                     # Ticket, TicketListFilters, Priority, etc.
    migrations.py                 # Migration IDs 27-31
```

### Key File Naming Conventions

| Pattern | Meaning |
|---------|---------|
| `*_service.py` | Business logic service class |
| `*_tools_service.py` | MCP tool helper functions (extracted from stompy_server.py) |
| `*_helpers_service.py` | Utility functions for a specific domain |
| `src/models/*.py` | Pydantic models for REST API request/response |
| `src/api/routes/*.py` | FastAPI route handlers |
| `tests/test_*.py` | Unit tests |
| `tests/integration/test_*.py` | Integration tests |

---

## 3. Database Schema

### Dual-Schema Architecture

Stompy uses three schema types:

| Schema | Scope | Purpose |
|--------|-------|---------|
| `mcp_global` | Cross-project | Sessions, OAuth, breadcrumbs, users, project metadata |
| `user_global` | Cross-project per user | Contexts/memories shared across all projects |
| `stompy_<hash>` / `dementia_<hash>` | Per-project | Contexts, memories, sessions, files |

**Why this matters**: When adding new features, you must decide which schema
the data belongs to. Cross-project data goes in `mcp_global`. Project-specific
data goes in the per-project schema.

### Global Schema Tables (`mcp_global`)

#### mcp_sessions
```sql
CREATE TABLE mcp_global.mcp_sessions (
    id TEXT PRIMARY KEY,
    started_at TIMESTAMP WITH TIME ZONE,
    last_active TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'active',           -- active, expired, finalized
    project_name TEXT DEFAULT '__PENDING__',
    session_summary JSONB DEFAULT '{"work_done":[],"tools_used":[],"next_steps":[],"important_context":{}}',
    finalized_at TIMESTAMP WITH TIME ZONE,
    handover_text TEXT,
    client_info JSONB
);
-- Indexes:
-- idx_sessions_project_active ON (project_name, last_active DESC)
-- idx_mcp_sessions_unfinalized ON (expires_at) WHERE finalized_at IS NULL AND status = 'active'
```

#### oauth_authorization_codes
```sql
CREATE TABLE mcp_global.oauth_authorization_codes (
    code TEXT PRIMARY KEY,
    client_id TEXT NOT NULL,
    redirect_uri TEXT NOT NULL,
    code_challenge TEXT,
    code_challenge_method TEXT,
    user_id TEXT,
    scope TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    used BOOLEAN DEFAULT FALSE
);
```

#### oauth_access_tokens
```sql
CREATE TABLE mcp_global.oauth_access_tokens (
    token TEXT PRIMARY KEY,
    client_id TEXT NOT NULL,
    user_id TEXT,
    scope TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);
```

#### breadcrumbs
```sql
CREATE TABLE mcp_global.breadcrumbs (
    id SERIAL PRIMARY KEY,
    session_id TEXT NOT NULL,
    tool_name TEXT NOT NULL,
    input_summary TEXT,
    output_summary TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    duration_ms INTEGER,
    error TEXT
);
```

#### users
```sql
CREATE TABLE mcp_global.users (
    id SERIAL PRIMARY KEY,
    auth0_sub TEXT UNIQUE NOT NULL,
    email TEXT,
    name TEXT,
    picture TEXT,
    tier TEXT DEFAULT 'beta',               -- beta, free, pro, enterprise, admin
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active_at TIMESTAMP WITH TIME ZONE,
    linked_identities JSONB DEFAULT '[]',
    has_completed_onboarding BOOLEAN DEFAULT FALSE
);
```

#### project_metadata
```sql
CREATE TABLE mcp_global.project_metadata (
    schema_name TEXT PRIMARY KEY,
    display_name TEXT UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
-- Constraint: uq_project_metadata_display_name UNIQUE (display_name)
```

#### project_ownership
```sql
-- Migration 39: IDOR protection
CREATE TABLE mcp_global.project_ownership (
    schema_name TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES mcp_global.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### chunk_embeddings (global)
```sql
CREATE TABLE mcp_global.chunk_embeddings (
    id SERIAL,
    context_id INTEGER NOT NULL,
    schema_name TEXT NOT NULL,
    chunk_index INTEGER NOT NULL,
    chunk_text TEXT NOT NULL,
    embedding vector(1024),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    retrieval_count INTEGER DEFAULT 0,
    pq_codes BYTEA,
    embedding_dim INTEGER DEFAULT 1024,
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    compressed_at TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (schema_name, context_id, chunk_index)
);
```

### Project Schema Tables (per-project)

#### sessions
```sql
CREATE TABLE {schema}.sessions (
    id TEXT PRIMARY KEY,
    started_at DOUBLE PRECISION,
    last_active DOUBLE PRECISION,
    project_fingerprint TEXT,
    project_path TEXT,
    project_name TEXT,
    summary TEXT
);
```

#### context_locks (main data table)
```sql
CREATE TABLE {schema}.context_locks (
    id SERIAL PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES {schema}.sessions(id),
    label TEXT NOT NULL,                    -- topic name (e.g. 'api_auth_rules')
    version TEXT,                           -- e.g. '1.0', '1.1', '2.0'
    content TEXT,                           -- full context content
    content_hash TEXT,                      -- SHA-256 of content
    metadata TEXT,                          -- JSON string
    tags TEXT,                              -- JSON array string or comma-separated
    locked_at DOUBLE PRECISION,             -- Unix timestamp
    last_accessed DOUBLE PRECISION,         -- Unix timestamp
    access_count INTEGER DEFAULT 0,
    preview TEXT,                           -- First ~500 chars
    key_concepts TEXT,                      -- JSON array of extracted terms
    embedding vector(1024),                 -- Voyage AI embedding
    embedding_model TEXT,                   -- e.g. 'voyage-3.5-lite'
    embedding_status TEXT DEFAULT 'complete', -- complete, pending, failed
    novelty_score REAL,                     -- 0.0-1.0 delta evaluation score
    delta_status TEXT DEFAULT 'pending',
    priority TEXT DEFAULT 'reference',      -- always_check, important, reference
    content_tsvector tsvector,              -- Full-text search vector
    is_chunked BOOLEAN DEFAULT FALSE,       -- Whether content has chunk_embeddings
    embedding_retry_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(label, version)
);
```

**Priority levels** (in order of importance):
- `always_check` — Critical rules, constraints, must-follow instructions
- `important` — Significant decisions, key architecture choices
- `reference` — General documentation, notes (default)

#### memory_entries
```sql
CREATE TABLE {schema}.memory_entries (
    id SERIAL PRIMARY KEY,
    session_id TEXT REFERENCES {schema}.sessions(id),
    timestamp DOUBLE PRECISION,
    category TEXT,                           -- 'progress', 'decision', 'note', etc.
    content TEXT,
    metadata TEXT                            -- JSON string
);
```

#### context_archives
```sql
CREATE TABLE {schema}.context_archives (
    id SERIAL PRIMARY KEY,
    original_id INTEGER NOT NULL,
    session_id TEXT NOT NULL REFERENCES {schema}.sessions(id),
    label TEXT NOT NULL,
    version TEXT NOT NULL,
    content TEXT NOT NULL,
    preview TEXT,
    key_concepts TEXT,
    metadata TEXT,
    deleted_at DOUBLE PRECISION DEFAULT EXTRACT(EPOCH FROM CURRENT_TIMESTAMP),
    delete_reason TEXT
);
```

#### uploaded_files
```sql
CREATE TABLE {schema}.uploaded_files (
    id SERIAL PRIMARY KEY,
    filename TEXT NOT NULL,
    content_type TEXT,
    size_bytes BIGINT,
    s3_object_key TEXT,                     -- Nullable after migration 23
    s3_public_url TEXT,                     -- Nullable after migration 23
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_id TEXT REFERENCES {schema}.sessions(id)
);
```

#### file_semantic_model / file_tags
```sql
CREATE TABLE {schema}.file_tags (
    id SERIAL PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES {schema}.sessions(id),
    file_path TEXT NOT NULL,
    description TEXT,
    role TEXT,
    tags TEXT,
    scanned_at DOUBLE PRECISION
);
```

### Migration System

Migrations are defined in `src/migrations/definitions.py` as a list of dicts.
Each migration has:
- `id`: Unique sequential integer
- `description`: Human-readable name
- `type`: ADD_COLUMN, ADD_INDEX, ADD_CONSTRAINT, UPDATE_DATA, RENAME_COLUMN, DROP_NOT_NULL, CUSTOM
- `table`: Target table
- `schema`: "project" (per-project) or "global" (mcp_global)
- `spec`: Type-specific specification

**Migration ID ranges:**
- 1-25: Core migrations (context_locks columns, indexes, session enhancements)
- 26: Unique display_name constraint on project_metadata
- 27-31: stompy-ticketing plugin (ticket tables)
- 32: Orphan alert dedup index
- 33-34: context_archives columns (deleted_at, delete_reason)
- 35: embedding_retry_at on context_locks
- 36: has_completed_onboarding on users
- 37: Unify display_name to match schema_name
- 38: Fix context_locks version uniqueness constraint
- 39+: Project ownership, etc.

**Running migrations**: Migrations run automatically on adapter initialization.
The `postgres_adapter.py` calls `run_migrations()` when creating a schema.

**Important**: Plugin migrations are loaded dynamically:
```python
# In definitions.py
try:
    from stompy_ticketing.migrations import get_ticket_migrations
    MIGRATIONS.extend(get_ticket_migrations(start_id=27))
except ImportError:
    pass  # stompy-ticketing not installed
```

### Common Query Patterns

```python
# Get connection for a project
with _get_db_for_project(project, skip_validation=True) as conn:
    cursor = conn.execute("SELECT * FROM context_locks WHERE label = %s", [topic])
    row = cursor.fetchone()

# Get connection for user_global scope
with _get_user_global_conn() as conn:
    cursor = conn.execute("SELECT * FROM context_locks WHERE label = %s", [topic])

# Get global adapter (for mcp_global tables)
global_adapter = _get_global_adapter()
conn = global_adapter.get_connection()

# Cross-schema query (requires quoted identifiers)
cur.execute(f'SELECT COUNT(*) FROM "{schema_name}".context_locks')
```

---

## 4. stompy_server.py MCP Tools Reference

All MCP tools are defined in `stompy_server.py` using `@mcp.tool()` decorators.
Plugin tools are registered via the plugin `register_plugin()` pattern.

### Project Management Tools

#### project_create
```python
async def project_create(
    name: str,  # Project name (e.g. 'innkeeper')
) -> str
```
Creates a new project with isolated PostgreSQL schema. Validates name format
(`^[a-z0-9][a-z0-9_]*$`, max 63 chars). Blocks reserved schema names.
Creates schema, runs migrations, inserts project_metadata.

#### project_list
```python
async def project_list(
    limit: int = 20,
    offset: int = 0,
    pattern: str = "",  # fnmatch glob filter (min 5 chars)
) -> str
```
Lists all projects sorted by last activity. Returns session/context/memory counts.
Uses `ProjectService.list_projects()`. Supports pagination and glob filtering.

#### project_info
```python
async def project_info(
    name: str,
    detail: Literal["summary", "verbose"] = "summary",
) -> str
```
Get information about a specific project. Summary: name + schema + counts.
Verbose: sessions + contexts + table sizes.

#### project_delete
```python
async def project_delete(
    name: str = "",           # Single delete
    pattern: str = "",        # Bulk delete (fnmatch glob, min 5 chars)
    confirm: bool = False,    # Must be True to execute
) -> str
```
Delete project(s) and all data (DESTRUCTIVE). Preview first with `confirm=False`.
Supports single delete by name or bulk delete by pattern. Protects system schemas.
Drops the entire PostgreSQL schema (`DROP SCHEMA ... CASCADE`).

### Context Management Tools

#### lock_context
```python
async def lock_context(
    content: str,             # Content to lock
    topic: str,               # Label for retrieval (e.g. 'api_auth_rules')
    project: str,             # Project name
    tags: Optional[str] = None,   # Comma-separated tags
    priority: Optional[Literal["always_check", "important", "reference"]] = None,
    force_store: bool = False,    # Bypass delta evaluation
    lazy: bool = False,           # Defer embedding generation
    scope: Optional[Literal["project", "user_global"]] = None,
) -> str
```
Store content as immutable versioned snapshot. Edits create new versions (1.0, 1.1, ...).
Rejects content with <10% novelty unless `force_store=True`.
`scope=user_global` stores in the cross-project user_global schema.

**Key behaviors:**
- Auto-detects priority from content keywords if not specified
- Generates preview (first ~500 chars), key_concepts, content_hash
- Runs delta evaluation (novelty_score) against existing versions
- Generates Voyage AI embedding (async, unless `lazy=True`)
- Invalidates Redis cache on success

#### recall_context
```python
async def recall_context(
    topic: str,               # Context label to retrieve
    project: str,             # Project name
    version: Optional[str] = "latest",  # 'latest' or specific e.g. '1.0'
    preview_only: bool = False,  # Return ~500-char summary
) -> str
```
Retrieve locked context by topic. Searches project schema first, then user_global.
Uses cache-first pattern (Redis -> DB). Updates access_count and last_accessed.

#### recall_batch
```python
async def recall_batch(
    topics: list,             # List of topic names (max 50)
    project: str,
    preview_only: bool = False,
) -> str
```
Fetch multiple contexts in one call for faster session startup.
Deduplicates topics, skips empty strings. Returns results for each topic found.

#### unlock_context
```python
async def unlock_context(
    topic: str = "",              # Single delete
    project: str = "",
    topic_pattern: str = "",      # Batch delete (fnmatch glob, min 3 chars)
    version: str = "all",         # 'all', 'latest', or specific
    force: bool = False,          # Required for always_check contexts
    archive: bool = True,         # Archive before deletion (default True)
) -> str
```
Remove locked context(s). Provide `topic` (single) or `topic_pattern` (batch).
Archives contexts to `context_archives` table before deletion by default.
Requires `force=True` for `always_check` priority contexts.

#### context_explore
```python
async def context_explore(
    project: str,
    detail: Literal["summary", "verbose"] = "summary",
    flat: bool = True,
    confirm_full: bool = False,  # Required when flat=False and >50 contexts
) -> str
```
Browse all locked contexts organized by priority.
Summary: topic + priority + tags (fast, up to 500 entries).
Verbose: full preview + timestamps, grouped by priority.

#### context_dashboard
```python
async def context_dashboard(
    project: str,
    detail: Literal["summary", "verbose"] = "summary",
) -> str
```
Context statistics and insights. Summary: counts + top 5 topics.
Verbose: full breakdown with access patterns, stale contexts, version stats.

#### context_search
```python
async def context_search(
    query: str,               # Search term or natural language
    project: str,
    priority: Optional[Literal["always_check", "important", "reference"]] = None,
    tags: Optional[str] = None,   # Comma-separated tag filter
    limit: int = 10,
    use_semantic: bool = True,    # Try semantic search first
    check_violations: bool = False,  # Detect MUST/NEVER rule violations
) -> str
```
Hybrid semantic + keyword search over locked contexts.
Searches both project schema AND user_global schema, merges results.
`check_violations=True` activates MUST/NEVER rule violation detection.

Delegates to `ContextSearchService` which supports:
- Semantic search (Voyage AI embeddings + cosine similarity)
- BM25 keyword search (PostgreSQL tsvector)
- Hybrid search (RRF fusion of both)
- Reranking (optional, for result quality)

#### project_brief
```python
async def project_brief(
    project: str,
    refresh: bool = False,    # Force regeneration
) -> str
```
LLM-synthesized project overview. Cached 1hr in Redis, auto-invalidated
on context changes. Uses OpenRouter LLM to generate a narrative summary
from all context metadata.

### Database Tools

#### db_query
```python
async def db_query(
    query: str,               # SQL SELECT query (supports %s and ? placeholders)
    project: str,
    params: list[str] = [],
    format: Literal["table", "json", "csv", "markdown"] = "table",
    db_path: Optional[str] = None,
) -> str
```
Read-only SELECT queries against PostgreSQL. Blocks writes (INSERT/UPDATE/DELETE).
Auto-adds `LIMIT 100` if no LIMIT clause present. Converts `?` to `%s` for
PostgreSQL compatibility. Has a 10-second statement timeout.

#### db_schema
```python
async def db_schema(
    project: str,
    table: Optional[str] = None,   # Specific table (default: all)
    detail: Literal["summary", "verbose"] = "summary",
) -> str
```
PostgreSQL schema inspection. Summary: table names + row counts.
Verbose: columns + indexes + sizes. Uses `pg_stat_user_tables` for fast
approximate row counts.

#### db_workspace (not a separate @mcp.tool, called via internal routing)
Operations: `create`, `drop`, `inspect`, `list` for temporary workspace tables
(`workspace_*` prefix in the project schema).

### Bug Report Tools

#### bug_report
```python
async def bug_report(
    title: str,               # Max 500 chars
    description: str,
    severity: Literal["critical", "high", "medium", "low"],
    steps_to_reproduce: Optional[str] = None,
    expected_behavior: Optional[str] = None,
    actual_behavior: Optional[str] = None,
) -> str
```
Submit a bug report. Tracked as a ticket in the global system.
Rate limit: 10/day per user. Maps severity to ticket priority.

#### bug_report_list
```python
async def bug_report_list(
    status: Optional[Literal["triage", "confirmed", "in_progress", "resolved", "wont_fix"]] = None,
    severity: Optional[Literal["critical", "high", "medium", "low"]] = None,
    limit: int = 20,
) -> str
```
List bug reports. Non-admins see own reports only.

### Plugin Tools (stompy-admin)

#### get_breadcrumbs
```python
async def get_breadcrumbs(
    project: str,
    limit: int = 20,
) -> str
```
Get recent breadcrumb trail entries (tool invocation history with timing).

#### detect_conflicts
```python
async def detect_conflicts(
    project: str,
    context_id: Optional[int] = None,
) -> str
```
Detect contradictions between locked contexts. Runs semantic similarity
checks to find MUST/NEVER rule conflicts.

#### resolve_conflict
```python
async def resolve_conflict(
    project: str,
    conflict_id: int,
    resolution: str,          # e.g. 'keep_both', 'keep_first', 'keep_second'
    notes: Optional[str] = None,
) -> str
```
Resolve a detected conflict with the chosen resolution strategy.

#### list_conflicts
```python
async def list_conflicts(
    project: str,
    status: Optional[str] = None,
    limit: int = 20,
) -> str
```
List detected conflicts, optionally filtered by status.

### Plugin Tools (stompy-ticketing)

#### ticket
```python
async def ticket(
    action: Literal["create", "get", "update", "move", "list", "close", "archive", "batch_move", "batch_close"],
    project: str = "",
    id: Optional[int] = None,
    title: Optional[str] = None,
    description: Optional[str] = None,
    type: Optional[Literal["task", "bug", "feature", "decision"]] = None,
    priority: Optional[Literal["urgent", "high", "medium", "low"]] = None,
    status: Optional[Literal["backlog", "ready", "in_progress", "review", "done", "blocked"]] = None,
    tags: Optional[str] = None,
    # ... more params
) -> str
```
All-in-one ticket management tool. Supports CRUD, status transitions, batch operations.

#### ticket_link
```python
async def ticket_link(
    action: Literal["add", "remove", "list"],
    ticket_id: int,
    # ... params
) -> str
```
Manage ticket relationships (blocks, depends_on, relates_to).

#### ticket_board
```python
async def ticket_board(
    view: Literal["kanban", "summary", "compact"],
    project: str = "",
    # ... filter params
) -> str
```
Kanban board view of tickets. kanban=full, summary=counts, compact=id+title+priority.

#### ticket_search
```python
async def ticket_search(
    query: str,
    type: Optional[Literal["task", "bug", "feature", "decision"]] = None,
    project: str = "",
    # ... filter params
) -> str
```
Full-text search across ticket titles and descriptions.

---

## 5. Service Layer Patterns

### Service Class Pattern

Services follow a consistent pattern:

```python
# src/services/context_service.py
class ContextService:
    """Service for context operations."""

    VALID_PRIORITIES = ["always_check", "important", "reference"]

    def __init__(self, database_url: Optional[str] = None, adapter=None):
        self._database_url = database_url or get_config().database_url
        self._adapter = adapter

    def _get_connection(self, schema: str, autocommit: bool = True):
        """Get a connection with schema set."""
        if self._adapter is not None:
            conn = self._adapter.get_cached_connection()
            conn.rollback()
            conn.autocommit = autocommit
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute(f'SET search_path TO "{schema}", public')
            return conn, cur
        conn = psycopg2.connect(self._database_url)
        conn.autocommit = autocommit
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(f'SET search_path TO "{schema}", public')
        return conn, cur

    def _release_connection(self, conn):
        """Release a connection (cached or fresh)."""
        if self._adapter is not None:
            self._adapter.release_cached_connection(conn)
        else:
            conn.close()
```

**Key pattern**: Services accept an optional `adapter` parameter. When provided,
they use `get_cached_connection()` (~300ms) instead of `psycopg2.connect()` (~800ms).

### Service Registry

`src/services/service_registry.py` provides centralized lazy service getters:

```python
from src.services.service_registry import (
    _get_project_service,
    _get_context_service,
    _get_context_search_service,
    _get_conflict_service,
    _get_export_import_service,
    _get_document_processor,
    _get_storage_service,
)

# Usage
service = _get_project_service()
projects = service.list_projects(include_stats=True)
```

Services are lazily initialized with thread-safe double-checked locking:
```python
class ServiceRegistry:
    _project_service = None
    _lock = threading.Lock()

    @classmethod
    def get_project_service(cls):
        if cls._project_service is None:
            with cls._lock:
                if cls._project_service is None:
                    cls._project_service = ProjectService()
        return cls._project_service
```

### Database Access Patterns

#### Connection Helpers (stompy_server.py)

```python
# Project-scoped connection (context manager)
def _get_db_for_project(project: str, skip_validation: bool = False):
    """Returns context manager yielding a connection with search_path set."""

# User-global scope connection (context manager)
def _get_user_global_conn():
    """Returns context manager for user_global schema."""

# Global adapter (for mcp_global tables)
def _get_global_adapter():
    """Returns PostgreSQLAdapter for mcp_global schema."""

# Cached adapter per schema
def _get_cached_adapter(schema_name: str):
    """Returns cached PostgreSQLAdapter for the given schema."""
```

#### PostgreSQLAdapter (postgres_adapter.py)

The adapter provides schema-based multi-tenancy:

```python
class PostgreSQLAdapter:
    def __init__(self, database_url=None, schema=None):
        self.database_url = database_url or os.getenv("DATABASE_URL")
        self.schema = schema  # If None, auto-detected from working directory

    def get_connection(self):
        """Get a connection with search_path set to self.schema."""
        # Creates new TCP connection each time

    def get_cached_connection(self):
        """Get a connection from LRU cache (thread-local)."""
        # Returns cached connection if available, creates new one otherwise
        # LRU eviction: max 10 connections, max 30 min age

    def release_cached_connection(self, conn):
        """Return connection to cache for reuse."""
        conn.rollback()  # Reset state
```

**Important**: The adapter uses an `LRUConnectionCache` per thread:
- Max 10 connections cached per thread
- Connections expire after 30 minutes (1800s)
- Expired or evicted connections are closed automatically

#### Connection Context Manager Pattern

```python
# In stompy_server.py tool handlers:
with _get_db_for_project(project, skip_validation=True) as conn:
    cursor = conn.execute("SELECT * FROM context_locks WHERE label = %s", [topic])
    rows = cursor.fetchall()
    # conn is automatically released/closed on exit
```

### Error Handling Patterns

MCP tools use two standard error response helpers:

```python
# Hard error (unrecoverable)
from claude_mcp_utils import mcp_error
return mcp_error("ERROR_CODE", "Human-readable message", {"extra": "data"})

# Recoverable error (with suggestions)
from claude_mcp_utils import recoverable_error
return recoverable_error(
    "ERROR_CODE",
    "Human-readable message",
    ["Suggestion 1", "Suggestion 2"],
    {"extra": "data"},
)
```

Common error codes:
- `INVALID_INPUT` — Bad parameters
- `PROJECT_NOT_FOUND` — Project doesn't exist
- `CONTEXT_NOT_FOUND` — Context topic not found
- `DATABASE_ERROR` — PostgreSQL error
- `WORKSPACE_ERROR` — Workspace table error
- `VALIDATION_ERROR` — Input validation failed
- `RESERVED_NAME` — Attempted to use a reserved name

### Service Extraction History

stompy_server.py has been refactored in waves:

| Wave | Services Extracted | Status |
|------|-------------------|--------|
| Wave 1 | Database utils, session management, project management | Complete |
| Wave 2 | Database tools, dashboard tools, project tools | Complete |
| Wave 3 | Embedding tools, conflict tools | Complete |
| Wave 4 | Schema tools, bug report tools | Complete |
| Wave 5 | Context lock service, context search service | Complete |

The pattern for extraction:
1. Identify a cluster of helper functions in stompy_server.py
2. Create a new `src/services/*_service.py` file
3. Move the functions into a class or module
4. Import them back into stompy_server.py
5. The `@mcp.tool()` decorated function remains in stompy_server.py as a thin wrapper

### Validation Helpers

```python
# Project validation
def _validate_project_required(project: str) -> Optional[str]:
    """Returns error string if project is invalid, None if OK."""

def _validate_project_exists(project: str) -> Optional[str]:
    """Check if project schema exists in database."""

# Schema resolution
def _project_name_to_schema(project: str) -> str:
    """Convert project display name to schema name."""

def _resolve_project_schema(cur, name: str) -> Optional[str]:
    """Resolve project name to schema via project_metadata + schemata."""
```

---

## 6. Middleware & Auth

### Authentication Flow (server_hosted.py)

The `BearerAuthMiddleware` in `server_hosted.py` handles auth for all protected
paths. It supports two auth methods:

1. **OAuth tokens (Auth0)** — For web UI (stompy.ai) and Claude.ai connectors
   - Validates via `auth0_integration.validate_auth0_token()`
   - Extracts user_id, email, name, tier from token claims
   - Looks up/creates user in `mcp_global.users` table
   - Sets `request.state.user`, `request.state.user_tier`, etc.

2. **Static Bearer token** — For Claude Desktop via npx
   - Compares against `STOMPY_API_KEY` (or legacy `DEMENTIA_API_KEY`)
   - Uses `secrets.compare_digest()` for timing-safe comparison
   - Static users get `admin` tier

**Protected paths**: `/mcp`, `/execute`, `/tools`, `/metrics`, `/api/v1`, `/neon-diagnostic`

**Public paths** (no auth):
- `/api/v1/invites/validate`
- `/api/v1/invites/verify-pending`
- `/api/v1/invites/set-password`
- `/api/v1/auth/register`
- `/api/v1/agent/pricing`

### Auth for REST API Routes (src/api/dependencies.py)

```python
async def get_current_user(request, credentials) -> UserInfo:
    """Extract and validate user from JWT or static token."""
    # 1. Check if BearerAuthMiddleware already authenticated
    # 2. Fallback: validate token ourselves
    # Returns UserInfo(user_id, email, tier, internal_id, ...)

async def get_user_db_url(user: UserInfo) -> str:
    """Resolve database URL for authenticated user."""
    # Routes to user's personal Neon DB if provisioned
    # Falls back to shared DATABASE_URL for admin users

def require_admin(user: UserInfo) -> UserInfo:
    """Dependency that requires admin tier."""
```

### Correlation ID Middleware (src/middleware/auth.py)

```python
class CorrelationIdMiddleware(BaseHTTPMiddleware):
    """Injects X-Correlation-ID for request tracing."""
    # Generates or extracts from request header
    # Stores in contextvars for logging
    # Adds to response headers
```

### User Tier Context Variables

```python
# In server_hosted.py
_current_user_tier: ContextVar[str]        # For MCP tool visibility filtering
_current_user_internal_id: ContextVar[int]  # For per-user DB routing
```

These context variables are set by `BearerAuthMiddleware` and read by MCP tools
to filter tool visibility and route database queries.

---

## 7. Rate Limiting

### MCP Rate Limits (Redis-based)

Defined in `src/middleware/rate_limit.py`:

| Tier | Requests/min | Burst/10s |
|------|-------------|-----------|
| beta | 60 | 20 |
| free | 60 | 20 |
| pro | 180 | 45 |
| enterprise | 300 | 75 |
| admin | 600 | 150 |

Two-level check: per-minute AND per-10-second burst.
Both must pass for request to proceed.

**Redis key pattern**: `stompy:mcp_rl_min:{user_id}:{minute_window}`

**Fallback**: In-memory rate limiter at 50% of normal limits when Redis unavailable.

### OAuth Rate Limits

| Path | Limit/min |
|------|----------|
| `/oauth/token` | 10 (fails closed when Redis unavailable) |
| `/oauth/authorize` | 20 |
| `/oauth/callback` | 20 |

**Security**: `/oauth/token` returns 503 (not 429) when Redis is unavailable,
to prevent brute-force attacks without rate limiting.

### REST API Rate Limits (slowapi)

```python
CONTEXT_CREATE_LIMIT = "60/minute"
CONTEXT_UPDATE_LIMIT = "60/minute"
GENERAL_API_LIMIT = "120/minute"
```

Applied via `@limiter.limit()` decorators on route handlers.

---

## 8. API Routes

### Route Registration Pattern

Routes are defined in `src/api/routes/*.py` using FastAPI `APIRouter`:

```python
# src/api/routes/contexts.py
router = APIRouter(prefix="/projects/{name}/contexts", tags=["Contexts"])

@router.post("", response_model=ContextCreateResponse, status_code=201)
@limiter.limit(CONTEXT_CREATE_LIMIT)
async def create_context(
    request: Request,
    name: str,
    body: ContextCreateRequest,
    background_tasks: BackgroundTasks,
    user: UserInfo = Depends(get_current_user),
    db_url: str = Depends(get_user_db_url),
):
    ...
```

All routers are combined in `src/api/router.py`:
```python
api_router = APIRouter()
api_router.include_router(projects_router)
api_router.include_router(contexts_router)
api_router.include_router(search_router)
# ... etc
```

The combined router is mounted at `/api/v1` in `server_hosted.py`.

### Available Route Modules

| Module | Prefix | Purpose |
|--------|--------|---------|
| projects | `/projects` | Project CRUD, list |
| contexts | `/projects/{name}/contexts` | Context CRUD, move |
| search | `/search` | Global search |
| files | `/projects/{name}/files` | File upload/download |
| bug_reports | `/bug-reports` | Bug report CRUD |
| conflicts | `/projects/{name}/conflicts` | Conflict management |
| admin | `/admin` | Admin operations |
| agent | `/agent` | Agent framework |
| audit | `/audit` | Audit logs |
| auth | `/auth` | Auth endpoints |
| invites | `/invites` | Invite system |
| provisioning | `/provisioning` | Database provisioning |

### Response Patterns

REST API uses Pydantic response models:

```python
# Listing with pagination
class ContextListResponse(BaseModel):
    contexts: List[ContextResponse]
    total: int
    limit: int
    offset: int
    by_priority: Dict[str, int]

# Create response
class ContextCreateResponse(BaseModel):
    id: int
    topic: str
    version: str
    priority: str
    created_at: datetime
    is_update: bool
    delta_info: Optional[DeltaInfo]
```

MCP tools return JSON strings directly via `json.dumps()`.

---

## 9. Redis & Caching Patterns

### Redis Cache Service

`src/services/redis_cache_service.py` provides `RedisCacheService`:

```python
cache = get_cache()  # Module-level singleton

# Context caching
cache.get_context(project, topic, version) -> Optional[dict]
cache.set_context(project, topic, version, data, ttl=3600)
cache.invalidate_context(project, topic)

# Project brief caching
cache.get_brief(project) -> Optional[dict]
cache.set_brief(project, data, ttl=3600)
cache.invalidate_brief(project)

# Search result caching
cache.get_search(project, query_hash) -> Optional[dict]
cache.set_search(project, query_hash, data, ttl=300)
```

### Cache Invalidation

`src/services/cache_invalidator.py` invalidates caches when contexts change:

```python
invalidator = get_cache_invalidator()
invalidator.on_context_change(project, topic)  # Invalidates context + brief + search
```

Called by `lock_context` and `unlock_context` tools after successful operations.

### Project Stats Cache

`src/services/project_stats_cache.py` caches project listing stats:

```python
stats_cache = get_project_stats_cache()
stats_cache.get_many(schema_names) -> dict  # Batch get
stats_cache.set(schema_name, stats_dict)
```

Stats are refreshed by a background scheduler (`project_stats_cache_scheduler.py`).

### Redis Connection

Redis URL comes from `REDIS_URL` environment variable.
Connects to DigitalOcean Managed Valkey (Redis-compatible).
Redis is optional — all features have fallbacks (in-memory or direct DB).

### Redis Key Prefix

All Redis keys use `stompy:` prefix:
- `stompy:ctx:{project}:{topic}:{version}` — Context cache
- `stompy:brief:{project}` — Project brief cache
- `stompy:search:{project}:{hash}` — Search result cache
- `stompy:mcp_rl_min:{user}:{window}` — MCP rate limit
- `stompy:mcp_rl_burst:{user}:{window}` — MCP burst limit
- `stompy:oauth_rl:{path}:{ip}:{window}` — OAuth rate limit
- `stompy:rest_rl:{user}:{window}` — REST rate limit
- `stompy:stats:{schema}` — Project stats cache

---

## 10. Testing Conventions

### Test Framework

```yaml
framework: pytest
runner: python3 -m pytest tests/ -v
config: pyproject.toml (pytest section)
coverage: pytest-cov
fixtures: conftest.py + per-test setup
```

### Running Tests

```bash
# All tests
python3 -m pytest tests/ -v

# Specific test file
python3 -m pytest tests/test_context_service.py -v

# With coverage
python3 -m pytest tests/ --cov=src --cov-report=term-missing

# Integration tests
python3 -m pytest tests/integration/ -v
```

### Test Database Patterns

Tests use fresh database connections or mock adapters:

```python
# Direct database testing (integration)
@pytest.fixture
def test_db():
    adapter = PostgreSQLAdapter(database_url=TEST_DB_URL, schema="test_schema")
    adapter.ensure_schema_exists()
    yield adapter
    # Cleanup: drop test schema

# Mocking database (unit tests)
@pytest.fixture
def mock_conn():
    conn = MagicMock()
    cursor = MagicMock()
    conn.cursor.return_value = cursor
    cursor.fetchall.return_value = [{"label": "test", "version": "1.0"}]
    yield conn
```

### Mocking Patterns

```python
# Mock external services
@patch("src.services.voyage_ai_embedding_service.VoyageAIEmbeddingService.get_embedding")
def test_lock_context_with_embedding(mock_embed):
    mock_embed.return_value = [0.1] * 1024
    ...

# Mock Redis cache
@patch("src.services.redis_cache_service.get_cache")
def test_recall_with_cache(mock_cache):
    mock_cache.return_value.get_context.return_value = {"content": "cached"}
    ...

# Mock config
@patch("src.config.get_config")
def test_config_override(mock_config):
    mock_config.return_value.database_url = "postgresql://test"
    ...
```

### Test File Organization

```
tests/
|-- conftest.py                   # Shared fixtures
|-- test_project_service.py       # ProjectService unit tests
|-- test_context_service.py       # ContextService unit tests
|-- test_context_search.py        # ContextSearchService tests
|-- test_rate_limit.py            # Rate limiting tests
|-- test_auth.py                  # Authentication tests
|-- test_models.py                # Pydantic model tests
|-- integration/
    |-- test_api_contexts.py      # REST API integration tests
    |-- test_api_projects.py      # REST API integration tests
    |-- test_sync_e2e.py          # End-to-end sync tests
```

### Naming Convention

```python
def test_should_[expected_behavior]_when_[condition]():
    # Arrange
    ...
    # Act
    ...
    # Assert
    ...

# Examples:
def test_should_create_context_when_valid_input():
def test_should_reject_duplicate_topic_version():
def test_should_return_404_when_project_not_found():
```

---

## 11. Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string (Neon pooler) |
| `STOMPY_API_KEY` | Yes | Static Bearer token for admin auth |
| `DEMENTIA_API_KEY` | No | Legacy alias for STOMPY_API_KEY |
| `VOYAGEAI_API_KEY` | Yes | Voyage AI embeddings |
| `OPENROUTER_API_KEY` | Yes | OpenRouter LLM API |
| `REDIS_URL` | No | Redis/Valkey cache |
| `AUTH0_DOMAIN` | Yes | Auth0 tenant domain |
| `AUTH0_AUDIENCE` | Yes | Auth0 API audience |
| `AUTH0_CLIENT_ID` | Yes | Auth0 client ID |
| `AUTH0_CLIENT_SECRET` | Yes | Auth0 client secret |
| `AUTH0_M2M_TOKEN` | No | M2M auth for Auth0 Actions |
| `RESEND_API_KEY` | No | Email notifications |
| `ENVIRONMENT` | No | "production" (default) |
| `LOG_LEVEL` | No | "INFO" (default) |
| `BASE_URL` | No | API base URL for internal calls |

### APIConfig Class (`src/_config.py`)

```python
class APIConfig:
    # Content limits
    MAX_CONTENT_SIZE_BYTES = 100_000      # 100 KB per context
    MIN_CONTENT_LENGTH = 1
    MAX_TOPIC_LENGTH = 100
    MAX_PROJECT_STORAGE_BYTES = 10_000_000  # 10 MB default

    # Semantic search thresholds
    SEMANTIC_SEARCH_THRESHOLD = 0.55       # For context_search
    SEMANTIC_CHECK_THRESHOLD = 0.50        # For violation checks

    # Storage quotas per tier (bytes)
    STORAGE_QUOTAS = {
        "beta": 100_000_000,    # 100 MB
        "free": 10_000_000,     # 10 MB
        "pro": 100_000_000,     # 100 MB
        "enterprise": 1_000_000_000,  # 1 GB
        "admin": 10_000_000_000,      # 10 GB
    }

    # Embedding config
    embedding_provider = "voyage_ai"
    embedding_model = "voyage-3.5-lite"
    embedding_dimensions = 1024
    embedding_document_model = "voyage-4-large"
    embedding_query_model = "voyage-4-lite"

    # LLM config
    llm_provider = "openrouter"
    llm_model = "google/gemini-2.5-flash-lite"

    # Feature flags
    enable_semantic_search = True     # Based on VOYAGEAI_API_KEY
    enable_ai_summarization = True    # Based on OPENROUTER_API_KEY
    enable_chunking = True
    enable_hybrid_search = True
    enable_reranking = True
    enable_contextual_enrichment = True

    # Chunking config
    chunk_size_tokens = 400
    chunk_overlap_tokens = 50
    parent_chunk_size_tokens = 2000
    chunking_threshold_tokens = 500
```

### Config Singleton

```python
from src.config import get_config
config = get_config()
print(config.database_url)
print(config.embedding_model)
```

---

## 12. Known Architecture Decisions

### Why stompy_server.py Is Still Large (4895 lines)

Despite extracting 90+ service files, the MCP tool wrapper functions remain in
`stompy_server.py`. This is because:
1. `@mcp.tool()` decorators must be on functions in the module where `mcp` is defined
2. Moving tool registrations would require re-architecting the MCP SDK integration
3. The tools are thin wrappers (10-30 lines each) that delegate to services

### Connection Caching Strategy

The codebase uses **per-thread LRU connection caching** instead of application-side
connection pooling. This is because NeonDB's PgBouncer pooler already handles
connection pooling (up to 10,000 connections). Application-side pooling on top of
Neon's pooler causes connection exhaustion.

### Why Not asyncpg?

MCP tool handlers are technically async but run synchronously because:
1. psycopg2 is simpler and more battle-tested
2. The MCP SDK runs tools sequentially (no concurrent benefit from async)
3. The connection caching pattern works well with psycopg2

asyncpg is only used in `database_initialization.py` for provisioning new user
databases (which benefits from true async I/O).

### Schema Naming History

- Original: `dementia_<hash>` (legacy name, still supported)
- Current: `stompy_<hash>` (new projects)
- API-created: Schema name = MD5 hash of display name
- MCP-created: Schema name = exact user input (validated format)

The `project_metadata` table bridges display names to schema names.

### Plugin Architecture

Plugins follow the pattern in `stompy-ticketing/plugin.py`:

```python
def register_plugin(
    mcp_instance,           # FastMCP server
    api_router,             # FastAPI APIRouter
    get_db_func,            # func(project=None) -> ctx mgr connection
    check_project_func,     # func(project=None) -> error str | None
    get_project_func,       # func(project=None) -> project name str
    resolve_schema_func=None,
) -> dict:
    # Returns {"migrations": [...], "schema_sql_func": callable}
```

Plugins are loaded in `stompy_server.py` at import time:
```python
# In stompy_server.py (near top)
from stompy_ticketing.plugin import register_plugin
register_plugin(mcp, api_router, _get_db_for_project, ...)
```

Plugin migrations extend the core migration system (IDs 27+).

### User Isolation Model

Each authenticated user gets their own NeonDB database, provisioned via
the Neon Management API. The `credential_storage` service stores encrypted
connection strings. `get_user_db_url()` in `src/api/dependencies.py` routes
REST API requests to the correct database.

For MCP connections (Claude Desktop), a shared database is used with
per-project schema isolation.

### Version Management

Version source of truth: `src/__version__.py`
```python
__version__ = "6.0.0"
```

`pyproject.toml` must match. CI enforces sync.

### Deployment Policy

- No direct pushes to main (all changes via PR)
- CI must pass before merge
- Branch protection with `enforce_admins` ON
- Release tags are immutable (never delete/overwrite)
- If CI fails, fix the code (no bypasses)

---

## 13. Common Gotchas & Debugging

### Neon Cold Start

NeonDB serverless can have 1-3 second cold starts after scale-to-zero.
The `LatencyTracker` in `cold_start_helper.py` detects this and adds
a warning to tool output.

### Connection State Issues

When using cached connections, always rollback before changing autocommit:
```python
conn = adapter.get_cached_connection()
conn.rollback()  # MUST do this before setting autocommit
conn.autocommit = True
```

Forgetting `conn.rollback()` before `conn.autocommit = True` causes
`InternalError: SET AUTOCOMMIT cannot run inside a transaction block`.

### Schema Resolution Pitfalls

Project names and schema names are not always the same:
- API-created projects: schema = `stompy_{md5(name)}`
- MCP-created projects: schema = exact name
- Always use `_resolve_project_schema()` or `ProjectService.resolve_schema_name()`

### tsvector Column

The `content_tsvector` column is populated by a trigger (migration 24).
If you update content directly via SQL, the tsvector won't update automatically.
Always go through the normal `lock_context` flow which handles tsvector updates.

### Embedding Dimensions

All embeddings are `vector(1024)` (Voyage AI voyage-3.5-lite).
The newer Voyage 4 models (voyage-4-large, voyage-4-lite) also output 1024 dimensions.
The `embedding_model` column tracks which model generated each embedding.

### Tags Column Format

The `tags` column in `context_locks` stores tags as either:
- JSON array string: `'["tag1", "tag2"]'`
- Comma-separated string: `"tag1, tag2"`

Always handle both formats when reading:
```python
if row.get("tags"):
    try:
        tags = json.loads(row["tags"]) if isinstance(row["tags"], str) else row["tags"]
        if isinstance(tags, str):
            tags = [t.strip() for t in tags.split(",") if t.strip()]
    except (json.JSONDecodeError, TypeError):
        pass
```

### Quoted Identifiers for Cross-Schema Queries

When querying across schemas, always use double-quoted identifiers:
```python
# CORRECT
cur.execute(f'SELECT COUNT(*) FROM "{schema_name}".context_locks')

# WRONG (will fail if schema has special chars)
cur.execute(f"SELECT COUNT(*) FROM {schema_name}.context_locks")
```

### Session ID Management

MCP sessions are tracked via context variables:
```python
from src.session_context import get_session_id
session_id = get_session_id()  # Thread-safe
```

For hosted server, session ID comes from MCP session middleware.
For local server, it's set during `_init_local_session()`.

### Error Response Format

MCP tools must always return valid JSON strings:
```python
# Never raise exceptions from MCP tools
# Always return error JSON
try:
    result = do_work()
    return json.dumps({"success": True, "data": result})
except Exception as e:
    return json.dumps({"error": str(e), "type": type(e).__name__})
```

---

## 14. Performance Notes

### Query Optimization

- `project_list` uses batched UNION ALL queries instead of N sequential queries
  (reduced latency from 15-30s to <1s for 50 projects)
- `pg_stat_user_tables.n_live_tup` for approximate row counts (instant vs COUNT(*))
- Statement timeout of 10s on db_query to prevent runaway queries
- Redis cache-first pattern: context retrieval checks cache before DB

### Embedding Generation

- Synchronous by default (during lock_context)
- `lazy=True` defers embedding until first search
- Failed embeddings tracked via `embedding_status` + `embedding_retry_at`
- Background retry scheduler picks up failed embeddings

### Connection Performance

- Cached connections: ~300ms (LRU cache hit)
- Fresh connections: ~800ms (new TCP to Neon)
- Neon cold start: 1-3s additional on first query after idle

---

## 15. Pydantic Models Reference

### User Models (`src/models/user.py`)

```python
UserTier = Literal["beta", "free", "pro", "enterprise", "admin"]

class UserInfo(BaseModel):
    user_id: str
    email: Optional[str]
    name: Optional[str]
    picture: Optional[str]
    auth_type: str = "oauth"       # "oauth" or "static"
    tier: UserTier = "beta"
    storage_quota_bytes: int
    storage_used_bytes: int = 0
    internal_id: Optional[int]     # DB user ID

class UserResponse(BaseModel):
    user_id: str
    email: Optional[str]
    name: Optional[str]
    tier: UserTier
    storage_quota_bytes: int
    storage_used_bytes: int
    storage_remaining_bytes: int
    created_at: Optional[datetime]
    has_completed_onboarding: bool = False
```

### Project Models (`src/models/project.py`)

```python
class ProjectCreate(BaseModel):
    name: str = Field(min_length=1, max_length=63, pattern=r"^[a-z0-9][a-z0-9_]*$")
    description: Optional[str] = Field(None, max_length=500)

class ProjectStats(BaseModel):
    context_count: int = 0
    session_count: int = 0
    file_count: int = 0
    storage_bytes_db: int = 0
    storage_bytes_s3: int = 0
    last_activity: Optional[datetime]

class ProjectResponse(BaseModel):
    name: str
    schema_name: str
    created_at: datetime
    role: str = "owner"
    is_system: bool = False
    stats: Optional[ProjectStats]
```

### Context Models (`src/models/context.py`)

```python
class ContextCreateRequest(BaseModel):
    topic: str = Field(min_length=1, max_length=255)
    content: str = Field(min_length=1)
    priority: Optional[Literal["always_check", "important", "reference"]]
    tags: Optional[str]
    force_store: bool = False

class ContextResponse(BaseModel):
    id: int
    topic: str
    version: str
    priority: str = "reference"
    tags: List[str]
    preview: Optional[str]
    key_concepts: Optional[List[str]]
    content_hash: Optional[str]
    locked_at: Optional[datetime]
    last_accessed: Optional[datetime]
    access_count: int = 0

class ContextDetailResponse(ContextResponse):
    content: str = ""
    versions: List[VersionSummary]

class ContextUpdateRequest(BaseModel):
    content: str = Field(min_length=1)
    priority: Optional[Literal["always_check", "important", "reference"]]
    tags: Optional[str]

class ContextMoveRequest(BaseModel):
    target_project: str = Field(min_length=1, max_length=255)
```

### Session Models (`src/models/session.py`)

```python
class SessionResponse(BaseModel):
    id: str
    project_name: Optional[str]
    started_at: Optional[datetime]
    last_active: Optional[datetime]
    status: str = "active"
    summary: Optional[Dict[str, Any]]
    summary_text: Optional[str]
    handover_summary: Optional[str]
    handover_generated_at: Optional[datetime]
```

---

## 16. Search System Deep Dive

### Search Architecture

The context search system has three tiers, tried in order:

1. **Hybrid Search** (BM25 + vector with RRF fusion)
   - Combines full-text search (PostgreSQL tsvector) with vector similarity
   - Uses Reciprocal Rank Fusion (RRF) to merge rankings
   - Best quality results, requires both embedding service and tsvector column
   - Service: `HybridSearchService` in `src/services/hybrid_search_service.py`

2. **Semantic Search** (vector-only)
   - Cosine similarity against Voyage AI embeddings
   - Falls back here if hybrid search is unavailable
   - Threshold: 0.55 (general), 0.50 (violation checks)
   - Service: `SemanticSearchService` in `src/services/semantic_search.py`

3. **Keyword Search** (SQL LIKE)
   - Simple string matching with SQL LIKE operator
   - Final fallback when embedding service is unavailable
   - Always works, no external dependencies

### Cross-Schema Search

All search modes automatically search both project and user_global schemas:

```python
# In ContextSearchService.search():
# 1. Search project schema
project_results = self._search_schema(conn, query, ...)

# 2. Search user_global schema
if self._get_user_global_conn:
    with self._get_user_global_conn() as ug_conn:
        global_results = self._search_schema(ug_conn, query, ...)

# 3. Merge results (project takes priority for duplicates)
merged = self._merge_results(project_results, global_results)
```

### SearchResponse Data Model

```python
@dataclass
class SearchResponse:
    search_mode: str          # "semantic", "keyword", "hybrid"
    query: str
    total_results: int
    results: List[Dict]       # Normalized result dicts
    note: str = ""
    fallback_reason: Optional[str] = None
    vector_count: int = 0     # Hybrid: count from vector arm
    bm25_count: int = 0       # Hybrid: count from BM25 arm
    overlap_count: int = 0    # Hybrid: results in both arms
    reranked: bool = False
```

### SearchResult Fields

```python
@dataclass
class SearchResult:
    label: str                # Topic name
    version: Optional[str]
    preview: str              # ~500 char preview
    score: float              # Relevance score (0-1)
    priority: str = "reference"
    tags: List[str]
    source: str = "project"   # "project" or "user_global"
    last_accessed: Optional[float]
    access_count: int = 0
    # Hybrid-specific
    vector_score: Optional[float]
    bm25_score: Optional[float]
    rrf_score: Optional[float]
    rerank_score: Optional[float]
    is_chunk: bool = False
    chunk_id: Optional[str]
    context_id: Optional[str]
```

### Embedding Pipeline

When `lock_context` is called:
1. Content is validated and metadata prepared
2. Content hash is computed (SHA-256)
3. Delta evaluation checks novelty against existing versions
4. If novelty > 10%, context is stored
5. Voyage AI embedding is generated (sync or deferred if `lazy=True`)
6. Embedding stored in `context_locks.embedding` column
7. If content is large (>500 tokens), chunks are created:
   - Content split into ~400 token chunks with 50 token overlap
   - Each chunk gets its own embedding in `mcp_global.chunk_embeddings`
   - `is_chunked` flag set to TRUE on the context_locks row

### Chunking Configuration

```python
# From _config.py
chunk_size_tokens = 400           # Target chunk size
chunk_overlap_tokens = 50         # Overlap between chunks
parent_chunk_size_tokens = 2000   # Parent chunk for context window
chunking_threshold_tokens = 500   # Min content size to trigger chunking
```

### Reranking

When enabled, search results are reranked after initial retrieval:
- Uses Voyage AI reranking model
- Reranking applied to top-N candidates from hybrid/semantic search
- Service: `RerankingService` in `src/services/reranking_service.py`

---

## 17. Session Management Deep Dive

### Session Lifecycle

```
Created → Active → Expired/Finalized
```

1. **Created**: Session inserted into `mcp_global.mcp_sessions` on server start
2. **Active**: Updated via `update_session_activity()` on each tool call
3. **Expired**: Background cleanup marks sessions older than TTL
4. **Finalized**: Explicit finalization with handover summary

### Session Storage

Two session store implementations:
- `mcp_session_store.py` — Synchronous (psycopg2), used by MCP server
- `mcp_session_store_async.py` — Asynchronous (asyncpg), used by hosted server

### Session Summary Structure

```json
{
    "work_done": ["Implemented feature X", "Fixed bug Y"],
    "tools_used": ["lock_context", "context_search"],
    "next_steps": ["Deploy to production", "Add tests"],
    "important_context": {
        "api_changes": "Added /api/v1/contexts endpoint",
        "db_migrations": "Added migration 38"
    }
}
```

### Handover Flow

When a session ends:
1. `session_finalizer.py` generates a handover summary
2. Uses LLM (OpenRouter) to synthesize session activity into narrative
3. Stores in `mcp_sessions.handover_text`
4. Sets `finalized_at` timestamp
5. Next session can retrieve handover via `recall_context("session_handover")`

### Breadcrumb System

`tool_breadcrumbs.py` provides the `@breadcrumb` decorator:

```python
@breadcrumb
@mcp.tool()
async def some_tool(...):
    ...
```

Each decorated tool call records:
- Tool name
- Input summary (first 200 chars of args)
- Output summary (first 200 chars of result)
- Duration in milliseconds
- Error message (if any)

Stored in `mcp_global.breadcrumbs` table, linked to session_id.
Retrieved via `get_breadcrumbs` MCP tool.

---

## 18. Conflict Detection System

### How It Works

When a new context is locked, background conflict detection runs:

1. Extract key claims/rules from the new context
2. Find existing contexts with high semantic similarity
3. Compare rules for contradictions (MUST vs NEVER patterns)
4. Store detected conflicts in a conflicts table

### Conflict Resolution

Conflicts have statuses: `unresolved`, `resolved`, `dismissed`

Resolution strategies:
- `keep_both` — Both contexts are valid (no real conflict)
- `keep_first` — Original context takes precedence
- `keep_second` — New context takes precedence
- `merge` — Manually merged content

### Service Structure

```python
# src/services/conflict_service.py
class ConflictService:
    VALID_RESOLUTIONS = ["keep_both", "keep_first", "keep_second", "merge"]
    VALID_STATUSES = ["unresolved", "resolved", "dismissed"]

    async def detect_conflicts(self, schema, context_id) -> int:
        """Detect conflicts for a newly locked context."""

    async def resolve_conflict(self, schema, conflict_id, resolution, notes) -> dict:
        """Resolve a detected conflict."""

    async def list_conflicts(self, schema, status_filter, limit) -> list:
        """List conflicts for a project."""
```

---

## 19. File Upload & Document Processing

### Upload Flow

1. File uploaded via REST API (`POST /api/v1/projects/{name}/files`)
2. `FileUploadService` validates type and size
3. File stored in DigitalOcean Spaces (S3-compatible)
4. Metadata stored in `uploaded_files` table
5. For PDFs/images: `DocumentProcessor` extracts text content
6. Extracted text can be locked as a context via `lock_context`

### Storage Service

```python
# src/services/storage_service.py
class StorageService:
    """S3-compatible storage for DigitalOcean Spaces."""

    def upload_file(self, file_content, object_key, content_type) -> str:
        """Upload file and return public URL."""

    def download_file(self, object_key) -> bytes:
        """Download file content."""

    def delete_file(self, object_key) -> bool:
        """Delete file from storage."""
```

### Document Processing

```python
# src/services/document_processor.py
class DocumentProcessor:
    """Extract text from PDFs and images."""

    def process_pdf(self, content: bytes) -> str:
        """Extract text from PDF."""

    def process_image(self, content: bytes) -> str:
        """Extract text from image using OCR/vision."""
```

---

## 20. Export/Import System

### Export Format

Projects can be exported as JSON with optional gzip compression:

```python
# src/services/export_import_service.py
class ExportImportService:
    def export_project(
        self,
        project: str,
        output_path: str,
        format: str = "json",       # "json" only for now
        compress: bool = True,       # gzip compression
        include_embeddings: bool = False,  # Exclude 1024-dim vectors by default
    ) -> dict:
        """Export all contexts, memories, and sessions."""

    def import_project(
        self,
        project: str,
        input_path: str,
        merge: bool = False,         # Merge with existing data
    ) -> dict:
        """Import project from export file."""
```

### Export JSON Structure

```json
{
    "version": "1.0",
    "exported_at": "2025-01-01T00:00:00Z",
    "project": "my_project",
    "schema": "stompy_abc123",
    "contexts": [
        {
            "label": "api_spec",
            "version": "1.0",
            "content": "...",
            "priority": "always_check",
            "tags": ["api", "spec"],
            "preview": "...",
            "key_concepts": ["REST", "authentication"]
        }
    ],
    "memories": [...],
    "sessions": [...]
}
```

---

## 21. Database Provisioning System

### Multi-Tenant Architecture

Each authenticated user gets their own NeonDB database:

```
User signs up → Auth0 Action → API call → Provisioning Queue → Neon API → Database Created
```

### Provisioning State Machine

```python
# src/services/provisioning_state_machine.py
States:
  pending → provisioning → ready → active
  pending → failed
  provisioning → failed
```

### Provisioning Worker

```python
# src/services/provisioning_worker.py
class ProvisioningWorker:
    """Async worker that processes provisioning queue."""

    async def provision_database(self, user_id: int) -> dict:
        """Create Neon database for user."""
        # 1. Call Neon Management API to create project
        # 2. Store connection string in credential_storage
        # 3. Run initial migrations on new database
        # 4. Update provisioning status to 'ready'
```

### Neon Management Client

```python
# src/services/neon_management_client.py
class NeonManagementClient:
    """Client for Neon API (database-as-a-service)."""

    async def create_project(self, name: str) -> dict:
    async def delete_project(self, project_id: str) -> bool:
    async def get_connection_string(self, project_id: str) -> str:
```

---

## 22. Invite System

### Flow

1. Admin creates invite via REST API
2. Invite stored in Redis with TTL
3. User receives invite URL via email (Resend API)
4. User validates invite and sets password
5. Auth0 Pre-Registration Action verifies invite in Redis
6. User account created

### Invite Service

```python
# src/services/invite_service.py
class InviteService:
    def create_invite(self, email: str, tier: str) -> dict:
    def validate_invite(self, code: str) -> dict:
    def consume_invite(self, code: str) -> bool:
```

---

## 23. Active Context Engine

### Purpose

`active_context_engine.py` automatically loads relevant contexts when a user
runs a command. For example, if a user asks about "deploying the API", the
engine checks `always_check` contexts for relevant deployment rules.

### How It Works

```python
def get_relevant_contexts_for_text(text: str, session_id: str, db_path: str) -> Optional[str]:
    """Find contexts relevant to the user's input text."""
    # 1. Get all always_check contexts
    # 2. Check semantic similarity with user input
    # 3. Return matching contexts as formatted text

def check_command_context(command: str, session_id: str, db_path: str) -> Optional[str]:
    """Check if a command violates any locked rules."""
    # Used by check_violations mode in context_search
```

---

## 24. Logging & Metrics

### Structured Logging (structlog)

```python
from src.logging_config import get_logger
logger = get_logger(__name__)

# Structured log entries
logger.info("context_created", topic="api_spec", version="1.0", project="myproject")
logger.warning("rate_limit_exceeded", user_id="user123", tier="beta")
logger.error("database_connection_failed", error=str(e), schema="stompy_abc")
```

All logs are JSON-formatted in production:
```json
{"event": "context_created", "topic": "api_spec", "version": "1.0", "timestamp": "2025-01-01T00:00:00Z", "level": "info"}
```

### Prometheus Metrics

```python
from src.metrics import track_tool_execution, tool_invocations

# Decorator for MCP tools
@track_tool_execution("lock_context")
async def lock_context(...):
    ...

# Available metrics:
# tool_invocations_total (counter) — Total MCP tool calls by tool name
# tool_duration_seconds (histogram) — Tool execution time
# active_connections (gauge) — Active database connections
# request_size_bytes (histogram) — HTTP request sizes
# response_size_bytes (histogram) — HTTP response sizes
```

Metrics endpoint: `GET /metrics` (Prometheus-compatible text format).

---

## 25. Utility Functions Reference

### claude_mcp_utils.py

```python
# Preview generation
def generate_preview(content: str, max_length: int = 500) -> str:
    """Extract first paragraph or first max_length chars."""

# Key concept extraction
def extract_key_concepts(content: str) -> List[str]:
    """Extract technical terms from content."""

# Error helpers
def mcp_error(code: str, message: str, data: dict = None) -> str:
    """Return JSON error string for MCP tool response."""

def recoverable_error(code: str, message: str, suggestions: List[str], data: dict = None) -> str:
    """Return JSON error with recovery suggestions."""

# Constants
RECOVERY_CONTEXT_NOT_FOUND = [
    "Use context_explore() to see available contexts",
    "Check the topic name spelling",
]
RECOVERY_DATABASE_CONNECTION = [
    "Check DATABASE_URL environment variable",
    "Verify PostgreSQL is running",
]
RECOVERY_PROJECT_NOT_SELECTED = [
    "Use project_create('name') to create a project",
    "Use project_list() to see available projects",
]

# Reserved schemas (never show in project list)
RESERVED_SCHEMAS = frozenset({
    "pg_catalog", "pg_toast", "information_schema",
    "public", "mcp_global", "user_global",
})
```

### Token Estimation

```python
# In stompy_server.py (imported from services)
def _estimate_tokens(text: str) -> int:
    """Rough token count estimate (chars / 4)."""
    return len(text) // 4
```

### Content Hash

```python
# In context_lock_service.py
def generate_content_hash(content: str) -> str:
    """SHA-256 hash of content for deduplication."""
    return hashlib.sha256(content.encode("utf-8")).hexdigest()
```

### Version Numbering

```python
# In stompy_server.py (imported from services)
def _get_next_version(conn, topic: str) -> str:
    """Get next version number for a topic."""
    # If no existing versions: returns "1.0"
    # If existing: increments minor (1.0 -> 1.1 -> 1.2)
    # If content significantly different: bumps major (1.2 -> 2.0)
```

---

## 26. Background Tasks & Schedulers

### Background Task Pattern

```python
# In route handlers
@router.post("")
async def create_context(
    background_tasks: BackgroundTasks,
    ...
):
    # Main operation
    result = create_the_context()

    # Schedule background work
    background_tasks.add_task(generate_embedding, context_id)
    background_tasks.add_task(detect_conflicts_async, schema, context_id)

    return result
```

### Scheduled Tasks

| Scheduler | Interval | Purpose |
|-----------|----------|---------|
| `project_stats_cache_scheduler` | ~60s | Refresh Redis stats cache |
| `mcp_session_cleanup` | ~5min | Expire old sessions |
| `session_finalizer` | On session end | Generate handover |
| `embedding_retry` | ~10min | Retry failed embeddings |
| `cold_data_service` | ~24hr | Compress old embeddings |

### Circuit Breaker

```python
# src/services/circuit_breaker.py
class CircuitBreaker:
    """Prevents cascade failures for external service calls."""

    def __init__(self, failure_threshold=5, recovery_timeout=60):
        ...

    def call(self, func, *args, **kwargs):
        """Execute func with circuit breaker protection."""
        # States: CLOSED (normal) -> OPEN (failing) -> HALF_OPEN (testing)
```

Used for Voyage AI, OpenRouter, and Neon API calls to prevent cascading
failures when external services are down.

---

## 27. REST API Endpoint Quick Reference

### Projects
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/projects` | List all projects |
| POST | `/api/v1/projects` | Create project |
| GET | `/api/v1/projects/{name}` | Get project details |
| DELETE | `/api/v1/projects/{name}` | Delete project |

### Contexts
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/projects/{name}/contexts` | List contexts |
| POST | `/api/v1/projects/{name}/contexts` | Create/update context |
| GET | `/api/v1/projects/{name}/contexts/{topic}` | Get context detail |
| PUT | `/api/v1/projects/{name}/contexts/{topic}` | Update context |
| DELETE | `/api/v1/projects/{name}/contexts/{topic}` | Delete context |
| POST | `/api/v1/projects/{name}/contexts/{topic}/move` | Move to another project |

### Search
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/search?q=query&project=name` | Global search |

### Files
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/projects/{name}/files` | List files |
| POST | `/api/v1/projects/{name}/files` | Upload file |
| GET | `/api/v1/projects/{name}/files/{id}` | Download file |
| DELETE | `/api/v1/projects/{name}/files/{id}` | Delete file |

### Sessions
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/projects/{name}/sessions` | List sessions |

### Auth
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/auth/me` | Get current user info |

### Admin
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/admin/users` | List users (admin only) |
| GET | `/api/v1/admin/stats` | System stats (admin only) |

### Bug Reports
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/bug-reports` | List bug reports |
| POST | `/api/v1/bug-reports` | Create bug report |

### Invites
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/invites` | Create invite (admin) |
| GET | `/api/v1/invites/validate` | Validate invite code (public) |

---

## 28. Middleware Stack Order

In `server_hosted.py`, middleware is applied in this order (outermost first):

```python
# 1. Metrics collection (outermost - times entire request)
app.add_middleware(MetricsMiddleware)

# 2. CORS headers
app.add_middleware(CORSMiddleware)

# 3. Correlation ID injection
app.add_middleware(CorrelationIdMiddleware)

# 4. Authentication (sets request.state.user, .user_tier, etc.)
app.add_middleware(BearerAuthMiddleware)

# 5. MCP Rate Limiting (checks request.state.user_tier)
app.add_middleware(MCPRateLimitMiddleware)

# 6. OAuth Rate Limiting (IP-based)
app.add_middleware(OAuthRateLimitMiddleware)

# 7. REST API Rate Limit Headers
app.add_middleware(RESTRateLimitHeadersMiddleware)

# 8. Session Persistence (MCP session tracking)
app.add_middleware(MCPSessionPersistenceMiddleware)
```

**Important**: Middleware order matters. Auth must run before rate limiting
(which uses user tier). CORS must run before auth (to allow preflight).

---

## 29. Common Development Workflows

### Adding a New MCP Tool

1. Define the function in `stompy_server.py` with `@mcp.tool()` decorator
2. Use `Annotated[type, "description"]` for all parameters
3. Add `@track_tool_execution("tool_name")` for metrics
4. Add `@breadcrumb` for debug tracing (optional)
5. Return JSON string via `json.dumps()`
6. Handle all errors, never raise from MCP tools

```python
@breadcrumb
@mcp.tool()
@track_tool_execution("my_new_tool")
async def my_new_tool(
    param1: Annotated[str, "Description of param1"],
    project: Annotated[str, "Project name"],
    optional_param: Annotated[Optional[str], "Optional description"] = None,
) -> str:
    """One-line docstring shown in MCP tool listing."""
    project_check = _validate_project_required(project)
    if project_check:
        return project_check

    try:
        with _get_db_for_project(project, skip_validation=True) as conn:
            # Do work
            result = {"success": True, "data": "..."}
            return json.dumps(result)
    except Exception as e:
        return json.dumps({"error": str(e), "type": type(e).__name__})
```

### Adding a New REST API Endpoint

1. Create or update route file in `src/api/routes/`
2. Define Pydantic models in `src/models/`
3. Use FastAPI dependency injection for auth
4. Register router in `src/api/router.py`

```python
# src/api/routes/my_feature.py
from fastapi import APIRouter, Depends
from src.api.dependencies import get_current_user
from src.models.user import UserInfo

router = APIRouter(prefix="/my-feature", tags=["My Feature"])

@router.get("")
async def list_items(
    user: UserInfo = Depends(get_current_user),
    db_url: str = Depends(get_user_db_url),
):
    service = MyService(database_url=db_url)
    return service.list_items()
```

### Adding a New Migration

Append to `src/migrations/definitions.py`:

```python
MIGRATIONS.append({
    "id": NEXT_ID,  # Must be unique and sequential
    "description": "descriptive_name",
    "type": ADD_COLUMN,  # or ADD_INDEX, CUSTOM, etc.
    "table": "context_locks",
    "schema": PROJECT_SCHEMA,  # or GLOBAL_SCHEMA_TYPE
    "spec": {
        "column": "new_column",
        "definition": "TEXT DEFAULT 'value'",
    },
})
```

Migrations run automatically on next adapter initialization.

### Adding a New Service

1. Create `src/services/my_service.py`
2. Follow the service class pattern (init with database_url/adapter)
3. Add to service registry if needed
4. Import in stompy_server.py or route handler

```python
# src/services/my_service.py
class MyService:
    def __init__(self, database_url=None, adapter=None):
        self._database_url = database_url or get_config().database_url
        self._adapter = adapter

    def do_something(self, schema: str, param: str) -> dict:
        conn, cur = self._get_connection(schema)
        try:
            cur.execute("SELECT ...", [param])
            return cur.fetchone()
        finally:
            self._release_connection(conn)
```

---

## 30. Schema Definitions SQL Reference

### Table Creation Order (Foreign Key Dependencies)

```
sessions → context_locks (FK: session_id)
sessions → memory_entries (FK: session_id)
sessions → context_archives (FK: session_id)
sessions → uploaded_files (FK: session_id)
sessions → file_tags (FK: session_id)
```

### Indexes Created by Default

```sql
-- context_locks indexes
idx_{schema}_context_locks_label ON {schema}.context_locks(label)
idx_{schema}_context_locks_session ON {schema}.context_locks(session_id)
idx_{schema}_context_locks_tsvector ON {schema}.context_locks USING gin(content_tsvector)
    WHERE content_tsvector IS NOT NULL
idx_{schema}_context_locks_is_chunked ON {schema}.context_locks(is_chunked)
    WHERE is_chunked = TRUE

-- memory_entries indexes
idx_{schema}_memory_entries_session ON {schema}.memory_entries(session_id)
idx_{schema}_memory_entries_category ON {schema}.memory_entries(category)

-- context_archives indexes
idx_context_archives_label ON {schema}.context_archives(label, deleted_at DESC)
```

### tsvector Trigger

Auto-populates `content_tsvector` on INSERT or UPDATE of content:

```sql
CREATE OR REPLACE FUNCTION {schema}.update_context_locks_tsvector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.content_tsvector := to_tsvector('english', coalesce(NEW.content, ''));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER context_locks_tsvector_update
    BEFORE INSERT OR UPDATE OF content ON {schema}.context_locks
    FOR EACH ROW EXECUTE FUNCTION {schema}.update_context_locks_tsvector();
```

### Query Results Cache

```sql
CREATE TABLE IF NOT EXISTS {schema}.query_results_cache (
    query_id TEXT PRIMARY KEY,
    query_type TEXT,
    params TEXT,
    results TEXT,
    created_at DOUBLE PRECISION,
    expires_at DOUBLE PRECISION
);
```
