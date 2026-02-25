export interface ToolCall {
  tool: string;
  timestamp: number;
  input_tokens: number;
  output_tokens: number;
  args?: Record<string, unknown>;
}

export interface SessionMetrics {
  model: string;
  condition: 'stompy' | 'file' | 'nomemory';
  session: 1 | 2 | 3;
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
}

export interface ConditionComparison {
  model: string;
  session: number;
  conditions: Record<string, SessionMetrics>;
  ramp_up_savings: {
    stompy_vs_nomemory: number;
    file_vs_nomemory: number;
    stompy_vs_file: number;
  };
}

export interface AggregateReport {
  generated_at: number;
  models: string[];
  sessions_analyzed: number;
  comparisons: ConditionComparison[];
  summary: {
    avg_ramp_up_ratio_by_condition: Record<string, number>;
    avg_cost_by_condition: Record<string, number>;
    avg_productive_ratio_by_condition: Record<string, number>;
  };
}
