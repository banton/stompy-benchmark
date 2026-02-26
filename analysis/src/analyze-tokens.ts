import { readFile, readdir } from 'fs/promises';
import { join, basename } from 'path';
import type { ClaudeCodeResult, ToolCall, SessionMetrics } from './types.js';

// Cost rates per 1M tokens (fallback — prefer cost_usd from Claude Code output)
const COST_RATES: Record<string, { input: number; output: number }> = {
  'claude-opus': { input: 15, output: 75 },
  'claude-sonnet': { input: 3, output: 15 },
  'claude-haiku': { input: 0.25, output: 1.25 },
  'gpt-5.1-codex': { input: 10, output: 30 },
  'gemini-2.5-pro': { input: 1.25, output: 10 },
};

function parseArgs(argv: string[]): { runDir: string; session?: number; scoreFile?: string } {
  let runDir = '';
  let session: number | undefined;
  let scoreFile: string | undefined;

  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--run-dir' && i + 1 < argv.length) {
      runDir = argv[i + 1];
      i++;
    } else if (argv[i] === '--session' && i + 1 < argv.length) {
      session = parseInt(argv[i + 1]);
      i++;
    } else if (argv[i] === '--score-file' && i + 1 < argv.length) {
      scoreFile = argv[i + 1];
      i++;
    }
  }

  if (!runDir) {
    console.error('Usage: analyze-tokens --run-dir <path> [--session <1|2|3>] [--score-file <path>]');
    console.error('');
    console.error('  --run-dir     Path to a run directory (e.g., runs/claude-opus-4-6-stompy)');
    console.error('  --session     Session number to analyze (default: auto-detect from files)');
    console.error('  --score-file  Path to session scores JSON (for points_per_minute calc)');
    console.error('');
    console.error('Reads session-{n}-result.json (Claude Code JSON output) as primary token source.');
    console.error('Falls back to token-log.jsonl for per-tool-call granularity if available.');
    process.exit(1);
  }

  return { runDir, session, scoreFile };
}

const INVESTIGATION_PATTERNS = /^(read|grep|glob|list|ls|find|cat|head|tail|search)$/i;
const WEB_SEARCH_PATTERNS = /^(webfetch|web_search|web_fetch|fetch)$/i;
const PRODUCTIVE_PATTERNS = /^(write|edit|patch|create|insert)$/i;
const TEST_ARG_PATTERNS = /(npm test|vitest|npx vitest|npx test)/i;
const MEMORY_TOOL_PATTERNS = /(stompy|mcp_stompy)/i;
const MEMORY_ARG_PATTERNS = /(MEMORY\.md|TASKS\.md)/i;

function categorizeToolCall(call: ToolCall): string {
  const toolName = call.tool;
  const argsStr = call.args ? JSON.stringify(call.args) : '';

  if (/^bash$/i.test(toolName) && TEST_ARG_PATTERNS.test(argsStr)) return 'test';
  if (MEMORY_TOOL_PATTERNS.test(toolName) || MEMORY_ARG_PATTERNS.test(argsStr)) return 'memory';
  if (INVESTIGATION_PATTERNS.test(toolName)) return 'investigation';
  if (WEB_SEARCH_PATTERNS.test(toolName)) return 'web_search';
  if (PRODUCTIVE_PATTERNS.test(toolName)) return 'productive';

  return 'other';
}

function detectModelFromPath(runDir: string): string {
  const lower = runDir.toLowerCase();
  if (lower.includes('opus')) return 'claude-opus';
  if (lower.includes('sonnet')) return 'claude-sonnet';
  if (lower.includes('haiku')) return 'claude-haiku';
  if (lower.includes('gpt') || lower.includes('codex')) return 'gpt-5.1-codex';
  if (lower.includes('gemini')) return 'gemini-2.5-pro';
  return 'claude-opus';
}

function detectConditionFromPath(runDir: string): 'stompy' | 'file' | 'nomemory' {
  const lower = runDir.toLowerCase();
  if (lower.includes('nomemory') || lower.includes('no-memory') || lower.includes('no_memory')) return 'nomemory';
  if (lower.includes('file')) return 'file';
  return 'stompy';
}

function detectSessionFromFiles(runDir: string, files: string[]): 1 | 2 | 3 {
  // Find highest session number with a result file
  for (let s = 3; s >= 1; s--) {
    if (files.includes(`session-${s}-result.json`)) return s as 1 | 2 | 3;
  }
  return 1;
}

function estimateCost(model: string, inputTokens: number, outputTokens: number): number {
  const rates = COST_RATES[model] ?? COST_RATES['claude-opus'];
  return (inputTokens / 1_000_000) * rates.input + (outputTokens / 1_000_000) * rates.output;
}

async function loadClaudeCodeResult(filePath: string): Promise<ClaudeCodeResult | null> {
  try {
    const content = await readFile(filePath, 'utf-8');
    return JSON.parse(content) as ClaudeCodeResult;
  } catch {
    return null;
  }
}

async function loadToolCallLog(filePath: string): Promise<ToolCall[]> {
  try {
    const content = await readFile(filePath, 'utf-8');
    const lines = content.trim().split('\n').filter(line => line.trim());
    return lines.map(line => JSON.parse(line) as ToolCall).filter(Boolean);
  } catch {
    return [];
  }
}

async function main(): Promise<void> {
  const { runDir, session: requestedSession, scoreFile } = parseArgs(process.argv);

  let files: string[];
  try {
    files = await readdir(runDir);
  } catch {
    console.error(`Error: Could not read directory ${runDir}`);
    process.exit(1);
  }

  const model = detectModelFromPath(runDir);
  const condition = detectConditionFromPath(runDir);
  const session = (requestedSession ?? detectSessionFromFiles(runDir, files)) as 1 | 2 | 3;

  // ─── Primary source: Claude Code JSON output ─────────────────────

  const resultFile = join(runDir, `session-${session}-result.json`);
  const ccResult = await loadClaudeCodeResult(resultFile);

  if (!ccResult) {
    console.error(`Error: Could not load ${resultFile}`);
    console.error('Expected Claude Code --output-format json result file.');
    process.exit(1);
  }

  const totalInput = ccResult.input_tokens ?? 0;
  const totalOutput = ccResult.output_tokens ?? 0;
  const totalTokens = totalInput + totalOutput;
  const durationMs = ccResult.duration_ms ?? 0;
  const wallClockSeconds = ccResult.benchmark_wall_clock_seconds ?? (durationMs / 1000);

  // Prefer Claude Code's cost_usd; fall back to rate estimation
  const costUsd = ccResult.cost_usd ?? estimateCost(model, totalInput, totalOutput);

  // ─── Secondary source: token-log.jsonl for per-tool granularity ──

  const logPath = join(runDir, 'token-log.jsonl');
  const toolCalls = await loadToolCallLog(logPath);

  let rampUpTokens = 0;
  let investigationTokens = 0;
  let productiveTokens = 0;
  let testTokens = 0;
  let memoryTokens = 0;
  let otherTokens = 0;
  let firstProductiveTimestamp = 0;
  const toolCallCounts: Record<string, number> = {};

  if (toolCalls.length > 0) {
    // We have per-tool-call granularity
    const categorized = toolCalls.map(call => ({
      call,
      category: categorizeToolCall(call),
    }));

    const firstProductive = categorized.find(c => c.category === 'productive');
    firstProductiveTimestamp = firstProductive?.call.timestamp ?? toolCalls[toolCalls.length - 1].timestamp;

    for (const { call, category } of categorized) {
      const callTokens = call.input_tokens + call.output_tokens;

      if (call.timestamp < firstProductiveTimestamp) {
        rampUpTokens += callTokens;
      }

      switch (category) {
        case 'investigation': investigationTokens += callTokens; break;
        case 'productive': productiveTokens += callTokens; break;
        case 'test': testTokens += callTokens; break;
        case 'memory': memoryTokens += callTokens; break;
        default: otherTokens += callTokens; break;
      }

      toolCallCounts[call.tool] = (toolCallCounts[call.tool] ?? 0) + 1;
    }
  } else {
    // No per-tool log — estimate from totals
    // Without tool-level data, we can only report totals
    otherTokens = totalTokens;
  }

  const rampUpRatio = totalTokens > 0 ? rampUpTokens / totalTokens : 0;

  // ─── Time/effectiveness metrics ──────────────────────────────────

  const tokensPerSecond = wallClockSeconds > 0
    ? Math.round((totalTokens / wallClockSeconds) * 100) / 100
    : 0;

  const timeToFirstProductive = toolCalls.length > 0 && firstProductiveTimestamp > 0
    ? (firstProductiveTimestamp - toolCalls[0].timestamp) / 1000
    : 0;

  // Load score file for points_per_minute if available
  let pointsPerMinute = 0;
  if (scoreFile) {
    try {
      const scoreContent = await readFile(scoreFile, 'utf-8');
      const scoreData = JSON.parse(scoreContent);
      pointsPerMinute = scoreData.points_per_minute ?? 0;
    } catch {
      // Score file not available — leave as 0
    }
  } else if (wallClockSeconds > 0) {
    // Try to auto-detect score file
    const autoScoreFile = join(runDir, `session-${session}-scores.json`);
    try {
      const scoreContent = await readFile(autoScoreFile, 'utf-8');
      const scoreData = JSON.parse(scoreContent);
      pointsPerMinute = scoreData.points_per_minute ?? 0;
    } catch {
      // No score file — leave as 0
    }
  }

  // ─── Build metrics ───────────────────────────────────────────────

  const metrics: SessionMetrics = {
    model,
    condition,
    session,
    total_input_tokens: totalInput,
    total_output_tokens: totalOutput,
    ramp_up_tokens: rampUpTokens,
    investigation_tokens: investigationTokens,
    productive_tokens: productiveTokens,
    test_tokens: testTokens,
    memory_tokens: memoryTokens,
    other_tokens: otherTokens,
    ramp_up_ratio: Math.round(rampUpRatio * 10000) / 10000,
    wall_clock_seconds: Math.round(wallClockSeconds * 100) / 100,
    estimated_cost: Math.round(estimateCost(model, totalInput, totalOutput) * 10000) / 10000,
    api_call_count: toolCalls.length || ccResult.num_turns || 0,
    first_productive_timestamp: firstProductiveTimestamp,
    tool_call_counts: toolCallCounts,
    // Claude Code native metrics
    duration_ms: durationMs,
    duration_api_ms: ccResult.duration_api_ms ?? 0,
    num_turns: ccResult.num_turns ?? 0,
    cost_usd: Math.round(costUsd * 10000) / 10000,
    is_error: ccResult.is_error ?? false,
    session_id: ccResult.session_id ?? '',
    // Effectiveness metrics
    tokens_per_second: tokensPerSecond,
    time_to_first_productive_seconds: Math.round(timeToFirstProductive * 100) / 100,
    points_per_minute: Math.round(pointsPerMinute * 10000) / 10000,
  };

  console.log(JSON.stringify(metrics, null, 2));
}

main();
