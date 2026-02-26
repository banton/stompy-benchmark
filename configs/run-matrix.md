# Benchmark Run Matrix

## Claude Code Native (Phase 1)

| # | Model | Condition | Session | Status | Score | Time (s) | Pts/min | Notes |
|---|-------|-----------|---------|--------|-------|----------|---------|-------|
| 1 | claude-opus-4-6 | stompy | 1 | pending | - | - | - | |
| 2 | claude-opus-4-6 | stompy | 2 | pending | - | - | - | |
| 3 | claude-opus-4-6 | stompy | 3 | pending | - | - | - | |
| 4 | claude-opus-4-6 | file | 1 | pending | - | - | - | |
| 5 | claude-opus-4-6 | file | 2 | pending | - | - | - | |
| 6 | claude-opus-4-6 | file | 3 | pending | - | - | - | |
| 7 | claude-opus-4-6 | nomemory | 1 | pending | - | - | - | |
| 8 | claude-opus-4-6 | nomemory | 2 | pending | - | - | - | |
| 9 | claude-opus-4-6 | nomemory | 3 | pending | - | - | - | |

## Deferred — Requires Proxy Layer (Phase 2)

| # | Model | Condition | Session | Status | Notes |
|---|-------|-----------|---------|--------|-------|
| 10 | gpt-5.1-codex | stompy | 1 | deferred | Needs OpenAI proxy for Claude Code |
| 11 | gpt-5.1-codex | stompy | 2 | deferred | |
| 12 | gpt-5.1-codex | stompy | 3 | deferred | |
| 13 | gpt-5.1-codex | file | 1 | deferred | |
| 14 | gpt-5.1-codex | file | 2 | deferred | |
| 15 | gpt-5.1-codex | file | 3 | deferred | |
| 16 | gpt-5.1-codex | nomemory | 1 | deferred | |
| 17 | gpt-5.1-codex | nomemory | 2 | deferred | |
| 18 | gpt-5.1-codex | nomemory | 3 | deferred | |
| 19 | gemini-2.5-pro | stompy | 1 | deferred | Needs Google proxy for Claude Code |
| 20 | gemini-2.5-pro | stompy | 2 | deferred | |
| 21 | gemini-2.5-pro | stompy | 3 | deferred | |
| 22 | gemini-2.5-pro | file | 1 | deferred | |
| 23 | gemini-2.5-pro | file | 2 | deferred | |
| 24 | gemini-2.5-pro | file | 3 | deferred | |
| 25 | gemini-2.5-pro | nomemory | 1 | deferred | |
| 26 | gemini-2.5-pro | nomemory | 2 | deferred | |
| 27 | gemini-2.5-pro | nomemory | 3 | deferred | |

## Metrics Tracked Per Session

| Metric | Source | Description |
|--------|--------|-------------|
| input_tokens | Claude Code JSON | Total input tokens consumed |
| output_tokens | Claude Code JSON | Total output tokens generated |
| cost_usd | Claude Code JSON | Actual cost reported by Claude Code |
| duration_ms | Claude Code JSON | Total session duration |
| num_turns | Claude Code JSON | Number of agentic turns |
| wall_clock_seconds | run-session.sh timer | End-to-end time including overhead |
| score / max | scoring scripts | Functional correctness (25+6+6=37 pts) |
| points_per_minute | derived | score / (wall_clock / 60) — time effectiveness |
| tokens_per_second | derived | total_tokens / wall_clock — throughput |
| ramp_up_ratio | analyze-tokens | Fraction of tokens before first productive action |
| time_to_first_productive | analyze-tokens | Seconds before first write/edit |

## Stompy Condition — Memory Features Measured

The stompy condition leverages both **context storage** and **ticketing**:
- Session 1 → stores 3 contexts (architecture, schema, API patterns) + creates 3 tickets
- Session 2 → recalls contexts, stores updates + closes tickets, creates new ones
- Session 3 → recalls all contexts + reviews ticket board for task context
- Ticketing gives the agent a structured backlog, not just prose memory
