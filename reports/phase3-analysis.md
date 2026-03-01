# Phase 3 Analysis Report: Multi-Agent Swarm with Persistent Memory

**Date**: 2026-03-01
**Benchmark version**: v3 (third iteration after fixing instrumentation issues in v1 and v2)
**Model**: claude-opus-4-6
**Task**: Implement a complete Duffel flight booking feature across backend, frontend, and tests

---

## Executive Summary

Phase 3 tests whether **persistent project memory** (via Stompy MCP) improves multi-agent swarm performance on a complex, real-world feature implementation. A 6-agent team (1 lead + 5 specialists) was given the same task under two conditions: one with access to pre-loaded codebase knowledge, one without.

**Key finding**: Stompy memory reduced API cost by **29.1%** ($0.96 savings per run) while achieving an identical perfect score. The memory-augmented team spent less time on codebase exploration and more time on implementation, resulting in a **33% reduction in API processing time**.

---

## Experimental Design

### Task

Build a complete Duffel flight booking flow for an existing Python/FastAPI + React/Vite codebase (~100 files, ~50K lines). The task requires:

- Duffel Orders API client (`POST /air/orders`)
- REST endpoints (`POST /api/v1/book`, `GET /api/v1/booking/{id}`)
- Passenger data schemas (Pydantic v2)
- Booking idempotency layer (Redis-backed)
- Frontend booking flow (React components: form, confirmation, error handling)
- Test suite (unit + integration, mocked Duffel API)

### Conditions

| Condition | Description |
|-----------|-------------|
| **stompy** | Lead agent has access to 5 pre-loaded Stompy MCP contexts covering architecture, Duffel integration, payment patterns, frontend patterns, and testing conventions. Lead can also lock new contexts (e.g., architecture decisions) for teammates to recall. |
| **nomemory** | Lead agent must explore the codebase from scratch by reading files. Architecture decisions are shared only via ephemeral messages to teammates. No persistent memory layer. |

### Controls

Both conditions share identical:
- Model (claude-opus-4-6)
- Fresh codebase snapshot (no `.git`, no `.env`, no prior state)
- Budget ($35 max), turns (400 max), timeout (60m soft / 65m hard)
- Scoring rubric (24 checks, 40 points)
- Team structure (1 lead + 5 specialists: duffel-engineer, api-engineer, payment-engineer, frontend-engineer, test-engineer)
- `--no-session-persistence` to prevent cross-condition bleed
- `--permission-mode bypassPermissions` for unattended execution

### Scoring Rubric (40 points)

| Category | Points | Checks |
|----------|--------|--------|
| File existence | 8 | Booking service, routes, schemas, frontend components, tests, syntax valid, no secrets, naming conventions |
| Duffel integration | 8 | Orders API call, offer validation, passenger formatting, PNR extraction |
| API + idempotency | 8 | POST /book, GET /booking/{id}, idempotency, error handling |
| Frontend | 8 | Passenger form, confirmation page, field validation, error states |
| Tests | 8 | Service tests, endpoint tests, error case coverage, 8+ test functions |

---

## Results

### Headline Metrics

| Metric | Stompy | Nomemory | Delta |
|--------|--------|----------|-------|
| **Score** | 40/40 (100%) | 40/40 (100%) | Tied |
| **Total cost** | **$2.34** | **$3.30** | Stompy 29.1% cheaper |
| **API processing time** | 6.2 min | 8.2 min | Stompy 33.2% faster |
| **Lead turns** | 25 | 22 | Nomemory fewer lead turns |
| **Wall clock** | 60m (timeout) | 60m (timeout) | Both capped |
| **Teammates spawned** | 5 | 5 | Identical |
| **NDJSON events** | 72 | 61 | Stompy more events |

### Cost Efficiency

| Metric | Stompy | Nomemory |
|--------|--------|----------|
| Cost per point | $0.058 | $0.082 |
| Cost per turn | $0.093 | $0.150 |
| Cost per new line | $0.0011 | $0.0012 |
| Lines per dollar | 900 | 825 |

### Code Output

| Category | Stompy (lines) | Nomemory (lines) |
|----------|---------------|-----------------|
| Backend (4 files) | 681 | 797 |
| Tests (3 files) | 926 | 788 |
| Frontend (3 files) | 496 | 1,133 |
| **Total new code** | **2,103** | **2,718** |

Nomemory produced 29% more lines of code for the same score. This suggests the nomemory lead communicated more verbose specifications to teammates (especially the frontend engineer, who produced 2.3x more lines), while Stompy's recalled contexts enabled more concise, convention-aligned output.

### Existing File Modifications

| File | Original | Stompy | Nomemory |
|------|----------|--------|----------|
| `api_server.py` | 1,978 | 1,980 (+2) | 1,997 (+19) |
| `api_schemas.py` | 278 | 278 (unchanged) | 278 (unchanged) |

Both conditions made minimal modifications to existing files, preferring to create new modules — consistent with the codebase's modular architecture.

---

## Analysis

### Where Stompy Memory Helped

**1. Eliminated codebase exploration overhead**

The nomemory lead must read 9+ files to understand patterns before designing the architecture. The stompy lead calls 5 `recall_context()` functions and immediately has:
- File naming conventions (snake_case, no prefixes)
- Import patterns (relative imports, aiohttp not requests)
- API structure (FastAPI async handlers, Pydantic v2)
- Duffel API specifics (headers, endpoints, offer store TTL)
- Payment patterns (idempotency key generation, Redis TTL)
- Frontend conventions (JSX not TSX, TailwindCSS, fetch not axios)
- Testing patterns (pytest-asyncio, mock all external calls)

This is reflected in the 33% reduction in API processing time (6.2 min vs 8.2 min).

**2. Reduced cost through smaller context windows**

Stompy's recalled contexts are ~500 tokens each (2,500 total). The nomemory lead must read full files to extract the same information — `api_server.py` alone is 1,978 lines (~8,000 tokens). This larger context window across multiple turns explains the $0.96 cost difference.

**3. Enabled architecture sharing via persistent context**

The stompy lead locked a `booking_api_contract` context that all 5 teammates could recall. The nomemory lead must embed the full architecture spec in each teammate's spawn prompt or send it via `SendMessage`, duplicating the same information 5 times.

### Where Stompy Memory Didn't Help

**1. Score ceiling already reached**

Both conditions scored 40/40. The scoring rubric checks for feature completeness (files exist, correct patterns, error handling) rather than code quality depth. A harder rubric — checking import consistency, test coverage percentage, or runtime correctness — might reveal more differentiation.

**2. Wall clock time was capped**

Both runs hit the 60-minute timeout. This means we can't compare actual completion times. The API processing times (6.2 vs 8.2 min) are more revealing, but the real wall clock includes teammate execution which ran concurrently.

**3. Nomemory still succeeded fully**

Claude Opus 4.6 is capable enough to explore a codebase, extract patterns, and coordinate a team without memory. Memory is an efficiency optimization, not a capability enabler — at this model quality level.

### Behavioral Differences

| Behavior | Stompy | Nomemory |
|----------|--------|----------|
| First action | `recall_context()` x5 | `Read` files x9+ |
| Architecture phase | Design from recalled patterns | Design after reading code |
| Teammate prompts | "Recall booking_api_contract" | Full spec embedded in prompt |
| Frontend verbosity | 496 lines (concise) | 1,133 lines (verbose) |
| Test emphasis | 926 lines (more tests) | 788 lines (fewer tests) |

The stompy condition wrote 87% more test code, suggesting the lead had more budget/turns remaining for the test engineer after the cheaper exploration phase.

---

## Iteration History

Phase 3 required three benchmark iterations to get clean results:

| Version | Issue | Fix |
|---------|-------|-----|
| **v1** | Scoring regex too strict, timeout killed before JSON output | Fixed regex, added SIGINT-then-SIGKILL timeout |
| **v2** | Stompy scored 0/40 — teammates wrote to real repo, not run dir. result.json = 0 bytes. | Root cause: recalled contexts + lead prompts didn't enforce relative paths. `--output-format json` buffers and loses data on kill. |
| **v3** | Clean run | Added CRITICAL FILE PATH RULE to prompts. Switched to `--output-format stream-json --verbose` with NDJSON post-processing. Cleaned contaminated files from real repo. |

### Key Instrumentation Lessons

1. **`--output-format json` is unsafe with timeouts** — it buffers the entire response and flushes on completion. If the process is killed, you get 0 bytes. Use `stream-json --verbose` and extract the last `type=result` NDJSON line.

2. **Multi-agent path isolation is critical** — when teammates are spawned with `general-purpose` subagent_type, they inherit the lead's CWD. If any context (recalled or prompt-based) contains absolute paths, teammates will write there. Explicit relative-path instructions in the lead prompt are essential.

3. **Recalled contexts with absolute paths contaminate the real repo** — even though the Stompy contexts themselves used relative paths, the lead's CWD resolution could produce absolute paths in teammate prompts. The fix was a blanket instruction, not context re-locking.

---

## Conclusions

### 1. Persistent memory is a cost optimizer, not a capability enabler

At claude-opus-4-6 quality, both conditions achieve perfect scores. The value of Stompy memory is **economic**: 29% cost reduction, 33% less API time, more efficient context utilization.

### 2. The savings compound with team size

The $0.96 savings came from a single 6-agent run. In production workflows with frequent swarm invocations, the per-session savings add up. The exploration phase eliminated by memory is O(files) in token cost — for larger codebases, the savings would be proportionally greater.

### 3. Memory changes team coordination patterns

With Stompy, the lead uses `lock_context()` + `recall_context()` as a shared knowledge base. Without it, the lead must duplicate architecture specs across teammate prompts. This affects not just cost but also consistency — a single locked context is authoritative, while 5 copy-pasted message blocks can drift.

### 4. Harder rubrics needed for deeper signal

A 40-point rubric with binary pass/fail checks saturates at 100% for capable models. Future phases should include:
- Runtime test execution (do the tests actually pass?)
- Import resolution (do modules correctly reference each other?)
- Code consistency scoring (does new code match existing style quantitatively?)
- Partial credit for complex checks

---

## Raw Data

### File Inventory — New Files Created

| File | Stompy (lines) | Nomemory (lines) |
|------|----------------|------------------|
| `duffel_booking_service.py` | 349 | 310 |
| `booking_routes.py` | 165 | 163 |
| `booking_schemas.py` | 42 | 161 |
| `booking_idempotency.py` | 125 | 163 |
| `tests/test_booking_service.py` | 374 | 385 |
| `tests/test_booking_routes.py` | 318 | 223 |
| `tests/test_booking_idempotency.py` | 234 | 180 |
| `frontend/src/pages/BookingPage.jsx` | 210 | 521 |
| `frontend/src/components/PassengerForm.jsx` | 180 | 308 |
| `frontend/src/components/BookingConfirmation.jsx` | 106 | 304 |
| **Total** | **2,103** | **2,718** |

### NDJSON Event Distribution

| Event Type | Stompy | Nomemory |
|------------|--------|----------|
| `assistant` | 40 | 32 |
| `user` | 24 | 21 |
| `system/task_started` | 5 | 5 |
| `system/init` | 1 | 1 |
| `rate_limit_event` | 1 | 1 |
| `result/success` | 1 | 1 |

### Scoring — All 24 Checks (both passed all)

| # | Check | Points |
|---|-------|--------|
| 1 | Booking service file exists | 1 |
| 2 | Booking route/endpoint file exists | 1 |
| 3 | Passenger schema models exist | 1 |
| 4 | Frontend booking components exist | 1 |
| 5 | Test files for booking exist | 1 |
| 6 | Python syntax valid (all new files) | 1 |
| 7 | No hardcoded API keys or secrets | 1 |
| 8 | Follows existing file naming conventions | 1 |
| 9 | Duffel Orders API call (POST /air/orders) | 2 |
| 10 | Offer validation before booking | 2 |
| 11 | Passenger data formatted for Duffel API | 2 |
| 12 | Booking confirmation/PNR extraction | 2 |
| 13 | POST /api/v1/book endpoint | 2 |
| 14 | GET /api/v1/booking/{id} endpoint | 2 |
| 15 | Booking idempotency (prevent double-booking) | 2 |
| 16 | Error handling (expired offer, payment failure, Duffel error) | 2 |
| 17 | Passenger input form component | 2 |
| 18 | Booking confirmation page | 2 |
| 19 | Form validates required fields | 2 |
| 20 | Error state handling (booking failure, timeout) | 2 |
| 21 | Unit tests for booking service (mock Duffel API) | 2 |
| 22 | Unit tests for booking endpoint (mock service) | 2 |
| 23 | Tests cover error cases | 2 |
| 24 | More than 8 test functions total | 2 |

### Run Configuration

```
Model:     claude-opus-4-6
Turns:     400 max
Budget:    $35 max
Timeout:   60m soft (SIGINT) / 65m hard (SIGKILL)
Output:    stream-json --verbose (NDJSON)
Session:   --no-session-persistence
Perms:     bypassPermissions
Snapshot:  Fresh copy of dollar-flights-snapshot/ per condition
```

### Artifacts

```
runs/p3-claude-opus-4-6-stompy/
  result.json              — Extracted result with cost/turns
  result-stream.ndjson     — Full NDJSON stream (72 lines)
  scores.json              — Scoring breakdown
  stderr.log               — Runtime stderr

runs/p3-claude-opus-4-6-nomemory/
  result.json              — Extracted result with cost/turns
  result-stream.ndjson     — Full NDJSON stream (61 lines)
  scores.json              — Scoring breakdown
  stderr.log               — Runtime stderr
```
