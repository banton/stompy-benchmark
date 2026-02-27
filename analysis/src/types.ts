export interface ToolCall {
  tool: string;
  timestamp: number;
  input_tokens: number;
  output_tokens: number;
  args?: Record<string, unknown>;
}

/**
 * Claude Code JSON output fields (from --output-format json).
 * These are the primary token/cost source for the benchmark.
 */
export interface ClaudeCodeResult {
  type: string;
  subtype: string;
  result: string;
  duration_ms: number;
  duration_api_ms: number;
  is_error: boolean;
  num_turns: number;
  stop_reason: string | null;
  session_id: string;
  total_cost_usd: number;
  usage: {
    input_tokens: number;
    cache_creation_input_tokens: number;
    cache_read_input_tokens: number;
    output_tokens: number;
  };
  modelUsage: Record<string, {
    inputTokens: number;
    outputTokens: number;
    cacheReadInputTokens: number;
    cacheCreationInputTokens: number;
    costUSD: number;
  }>;
  // Injected by run-session.sh
  benchmark_wall_clock_seconds?: number;
}

export interface SessionMetrics {
  model: string;
  condition: 'stompy' | 'file' | 'nomemory';
  session: 1 | 2 | 3;
  // Phase 2 fields
  phase?: 1 | 2;
  task_level?: 1 | 2 | 3;
  task_name?: string;
  total_input_tokens: number;
  total_output_tokens: number;
  ramp_up_tokens: number;
  investigation_tokens: number;
  productive_tokens: number;
  test_tokens: number;
  memory_tokens: number;
  other_tokens: number;
  ramp_up_ratio: number;
  wall_clock_seconds: number;
  estimated_cost: number;
  api_call_count: number;
  first_productive_timestamp: number;
  tool_call_counts: Record<string, number>;
  // Time/effectiveness metrics (from Claude Code JSON output)
  duration_ms: number;
  duration_api_ms: number;
  num_turns: number;
  cost_usd: number;
  is_error: boolean;
  session_id: string;
  // Derived effectiveness metrics
  tokens_per_second: number;
  time_to_first_productive_seconds: number;
  points_per_minute: number;
}

export interface ConditionComparison {
  model: string;
  session: number;
  phase?: 1 | 2;
  task_level?: number;
  task_name?: string;
  conditions: Record<string, SessionMetrics>;
  ramp_up_savings: {
    stompy_vs_nomemory: number;
    file_vs_nomemory: number;
    stompy_vs_file: number;
  };
  time_savings: {
    stompy_vs_nomemory: number;
    file_vs_nomemory: number;
    stompy_vs_file: number;
  };
}

export interface AggregateReport {
  generated_at: number;
  phase: 1 | 2;
  models: string[];
  sessions_analyzed: number;
  comparisons: ConditionComparison[];
  summary: {
    avg_ramp_up_ratio_by_condition: Record<string, number>;
    avg_cost_by_condition: Record<string, number>;
    avg_productive_ratio_by_condition: Record<string, number>;
    avg_wall_clock_by_condition: Record<string, number>;
    avg_tokens_per_second_by_condition: Record<string, number>;
    avg_points_per_minute_by_condition: Record<string, number>;
  };
}
