import { readFile } from 'fs/promises';
import { join } from 'path';
import type { ToolCall, SessionMetrics } from './types.js';

// Cost rates per 1M tokens
const COST_RATES: Record<string, { input: number; output: number }> = {
  'claude-opus': { input: 15, output: 75 },
  'gpt-5.1-codex': { input: 10, output: 30 },
  'gemini-2.5-pro': { input: 1.25, output: 10 },
};

function parseArgs(argv: string[]): { runDir: string } {
  const idx = argv.indexOf('--run-dir');
  if (idx === -1 || idx + 1 >= argv.length) {
    console.error('Usage: analyze-tokens --run-dir <path>');
    console.error('  --run-dir  Path to a run directory containing token-log.jsonl');
    process.exit(1);
  }
  return { runDir: argv[idx + 1] };
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

  // Test: bash/Bash with test-related args
  if (/^bash$/i.test(toolName) && TEST_ARG_PATTERNS.test(argsStr)) {
    return 'test';
  }

  // Memory: tool name contains stompy patterns or args reference memory files
  if (MEMORY_TOOL_PATTERNS.test(toolName) || MEMORY_ARG_PATTERNS.test(argsStr)) {
    return 'memory';
  }

  if (INVESTIGATION_PATTERNS.test(toolName)) return 'investigation';
  if (WEB_SEARCH_PATTERNS.test(toolName)) return 'web_search';
  if (PRODUCTIVE_PATTERNS.test(toolName)) return 'productive';

  return 'other';
}

function detectModelFromPath(runDir: string): string {
  const lower = runDir.toLowerCase();
  if (lower.includes('claude') || lower.includes('opus')) return 'claude-opus';
  if (lower.includes('gpt') || lower.includes('codex')) return 'gpt-5.1-codex';
  if (lower.includes('gemini')) return 'gemini-2.5-pro';
  return 'claude-opus'; // default
}

function detectConditionFromPath(runDir: string): 'stompy' | 'file' | 'nomemory' {
  const lower = runDir.toLowerCase();
  if (lower.includes('nomemory') || lower.includes('no-memory') || lower.includes('no_memory')) return 'nomemory';
  if (lower.includes('file')) return 'file';
  return 'stompy'; // default
}

function detectSessionFromPath(runDir: string): 1 | 2 | 3 {
  const match = runDir.match(/s([123])/);
  if (match) return parseInt(match[1]) as 1 | 2 | 3;
  return 1; // default
}

function estimateCost(model: string, inputTokens: number, outputTokens: number): number {
  const rates = COST_RATES[model] ?? COST_RATES['claude-opus'];
  return (inputTokens / 1_000_000) * rates.input + (outputTokens / 1_000_000) * rates.output;
}

async function main(): Promise<void> {
  const { runDir } = parseArgs(process.argv);

  const logPath = join(runDir, 'token-log.jsonl');
  let content: string;
  try {
    content = await readFile(logPath, 'utf-8');
  } catch (err) {
    console.error(`Error: Could not read ${logPath}`);
    console.error((err as Error).message);
    process.exit(1);
  }

  const lines = content.trim().split('\n').filter(line => line.trim());
  if (lines.length === 0) {
    console.error(`Error: ${logPath} is empty`);
    process.exit(1);
  }

  const toolCalls: ToolCall[] = lines.map((line, i) => {
    try {
      return JSON.parse(line) as ToolCall;
    } catch {
      console.error(`Warning: Could not parse line ${i + 1}, skipping`);
      return null;
    }
  }).filter((call): call is ToolCall => call !== null);

  if (toolCalls.length === 0) {
    console.error('Error: No valid tool calls found in log');
    process.exit(1);
  }

  // Categorize all tool calls
  const categorized = toolCalls.map(call => ({
    call,
    category: categorizeToolCall(call),
  }));

  // Find first productive timestamp (ramp-up boundary)
  const firstProductive = categorized.find(c => c.category === 'productive');
  const firstProductiveTimestamp = firstProductive?.call.timestamp ?? toolCalls[toolCalls.length - 1].timestamp;

  // Compute token totals by category
  let totalInput = 0;
  let totalOutput = 0;
  let rampUpTokens = 0;
  let investigationTokens = 0;
  let productiveTokens = 0;
  let testTokens = 0;
  let memoryTokens = 0;
  let otherTokens = 0;
  const toolCallCounts: Record<string, number> = {};

  for (const { call, category } of categorized) {
    const callTokens = call.input_tokens + call.output_tokens;
    totalInput += call.input_tokens;
    totalOutput += call.output_tokens;

    // Count tokens before first productive call as ramp-up
    if (call.timestamp < firstProductiveTimestamp) {
      rampUpTokens += callTokens;
    }

    // Categorized token buckets
    switch (category) {
      case 'investigation':
        investigationTokens += callTokens;
        break;
      case 'productive':
        productiveTokens += callTokens;
        break;
      case 'test':
        testTokens += callTokens;
        break;
      case 'memory':
        memoryTokens += callTokens;
        break;
      case 'web_search':
        otherTokens += callTokens;
        break;
      default:
        otherTokens += callTokens;
        break;
    }

    // Tool call counts
    toolCallCounts[call.tool] = (toolCallCounts[call.tool] ?? 0) + 1;
  }

  const totalTokens = totalInput + totalOutput;
  const rampUpRatio = totalTokens > 0 ? rampUpTokens / totalTokens : 0;

  // Wall clock from first to last timestamp
  const timestamps = toolCalls.map(c => c.timestamp);
  const wallClockSeconds = (Math.max(...timestamps) - Math.min(...timestamps)) / 1000;

  // Detect metadata from path
  const model = detectModelFromPath(runDir);
  const condition = detectConditionFromPath(runDir);
  const session = detectSessionFromPath(runDir);

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
    api_call_count: toolCalls.length,
    first_productive_timestamp: firstProductiveTimestamp,
    tool_call_counts: toolCallCounts,
  };

  console.log(JSON.stringify(metrics, null, 2));
}

main();
