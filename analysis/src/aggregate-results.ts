import { readFile, readdir } from 'fs/promises';
import { join } from 'path';
import type { SessionMetrics, ConditionComparison, AggregateReport } from './types.js';

function parseArgs(argv: string[]): { resultsDir: string } {
  const idx = argv.indexOf('--results-dir');
  if (idx === -1 || idx + 1 >= argv.length) {
    console.error('Usage: aggregate-results --results-dir <path>');
    console.error('  --results-dir  Path to directory containing SessionMetrics JSON files');
    process.exit(1);
  }
  return { resultsDir: argv[idx + 1] };
}

async function loadAllMetrics(resultsDir: string): Promise<SessionMetrics[]> {
  let files: string[];
  try {
    files = await readdir(resultsDir);
  } catch (err) {
    console.error(`Error: Could not read directory ${resultsDir}`);
    console.error((err as Error).message);
    process.exit(1);
  }

  const jsonFiles = files.filter(f => f.endsWith('.json'));
  if (jsonFiles.length === 0) {
    console.error(`Error: No JSON files found in ${resultsDir}`);
    process.exit(1);
  }

  const allMetrics: SessionMetrics[] = [];

  for (const file of jsonFiles) {
    try {
      const content = await readFile(join(resultsDir, file), 'utf-8');
      const metrics = JSON.parse(content) as SessionMetrics;
      // Basic validation: check required fields exist
      if (metrics.model && metrics.condition && metrics.session) {
        allMetrics.push(metrics);
      } else {
        console.error(`Warning: Skipping ${file} - missing required fields`);
      }
    } catch {
      console.error(`Warning: Could not parse ${file}, skipping`);
    }
  }

  return allMetrics;
}

function groupBy<T>(items: T[], keyFn: (item: T) => string): Record<string, T[]> {
  const groups: Record<string, T[]> = {};
  for (const item of items) {
    const key = keyFn(item);
    if (!groups[key]) groups[key] = [];
    groups[key].push(item);
  }
  return groups;
}

function average(values: number[]): number {
  if (values.length === 0) return 0;
  return Math.round((values.reduce((a, b) => a + b, 0) / values.length) * 10000) / 10000;
}

function calcSavingsPercent(baseline: number, improved: number): number {
  if (baseline === 0) return 0;
  return Math.round(((baseline - improved) / baseline) * 10000) / 10000 * 100;
}

function buildComparisons(allMetrics: SessionMetrics[]): ConditionComparison[] {
  const comparisons: ConditionComparison[] = [];

  // Group by model + session
  const grouped = groupBy(allMetrics, m => `${m.model}|${m.session}`);

  for (const [key, metrics] of Object.entries(grouped)) {
    const [model, sessionStr] = key.split('|');
    const session = parseInt(sessionStr);

    const conditionMap: Record<string, SessionMetrics> = {};
    for (const m of metrics) {
      conditionMap[m.condition] = m;
    }

    const nomemoryRampUp = conditionMap['nomemory']?.ramp_up_tokens ?? 0;
    const stompyRampUp = conditionMap['stompy']?.ramp_up_tokens ?? 0;
    const fileRampUp = conditionMap['file']?.ramp_up_tokens ?? 0;

    comparisons.push({
      model,
      session,
      conditions: conditionMap,
      ramp_up_savings: {
        stompy_vs_nomemory: calcSavingsPercent(nomemoryRampUp, stompyRampUp),
        file_vs_nomemory: calcSavingsPercent(nomemoryRampUp, fileRampUp),
        stompy_vs_file: calcSavingsPercent(fileRampUp, stompyRampUp),
      },
    });
  }

  return comparisons;
}

function padRight(str: string, len: number): string {
  return str + ' '.repeat(Math.max(0, len - str.length));
}

function padLeft(str: string, len: number): string {
  return ' '.repeat(Math.max(0, len - str.length)) + str;
}

function printSummaryTable(report: AggregateReport): void {
  console.log('\n' + '='.repeat(72));
  console.log('  STOMPY BENCHMARK - AGGREGATE RESULTS');
  console.log('='.repeat(72));
  console.log(`  Generated: ${new Date(report.generated_at).toISOString()}`);
  console.log(`  Models: ${report.models.join(', ')}`);
  console.log(`  Sessions analyzed: ${report.sessions_analyzed}`);
  console.log('');

  // Summary table
  const conditions = Object.keys(report.summary.avg_ramp_up_ratio_by_condition);
  const header = `  ${padRight('Condition', 12)} | ${padLeft('Avg Ramp-Up Ratio', 18)} | ${padLeft('Avg Cost ($)', 12)} | ${padLeft('Avg Productive %', 16)}`;
  const separator = '  ' + '-'.repeat(header.length - 2);

  console.log(header);
  console.log(separator);

  for (const condition of conditions) {
    const rampUp = report.summary.avg_ramp_up_ratio_by_condition[condition] ?? 0;
    const cost = report.summary.avg_cost_by_condition[condition] ?? 0;
    const productive = report.summary.avg_productive_ratio_by_condition[condition] ?? 0;

    console.log(
      `  ${padRight(condition, 12)} | ${padLeft((rampUp * 100).toFixed(2) + '%', 18)} | ${padLeft('$' + cost.toFixed(4), 12)} | ${padLeft((productive * 100).toFixed(2) + '%', 16)}`
    );
  }

  console.log('');

  // Ramp-up savings summary
  if (report.comparisons.length > 0) {
    console.log('  Ramp-Up Token Savings (avg across all model-session pairs):');
    const allStompyVsNomemory: number[] = [];
    const allFileVsNomemory: number[] = [];
    const allStompyVsFile: number[] = [];

    for (const c of report.comparisons) {
      if (c.ramp_up_savings.stompy_vs_nomemory !== 0) allStompyVsNomemory.push(c.ramp_up_savings.stompy_vs_nomemory);
      if (c.ramp_up_savings.file_vs_nomemory !== 0) allFileVsNomemory.push(c.ramp_up_savings.file_vs_nomemory);
      if (c.ramp_up_savings.stompy_vs_file !== 0) allStompyVsFile.push(c.ramp_up_savings.stompy_vs_file);
    }

    if (allStompyVsNomemory.length > 0) {
      console.log(`    Stompy vs No-Memory: ${average(allStompyVsNomemory).toFixed(2)}% fewer ramp-up tokens`);
    }
    if (allFileVsNomemory.length > 0) {
      console.log(`    File vs No-Memory:   ${average(allFileVsNomemory).toFixed(2)}% fewer ramp-up tokens`);
    }
    if (allStompyVsFile.length > 0) {
      console.log(`    Stompy vs File:      ${average(allStompyVsFile).toFixed(2)}% fewer ramp-up tokens`);
    }
  }

  console.log('\n' + '='.repeat(72));
}

async function main(): Promise<void> {
  const { resultsDir } = parseArgs(process.argv);

  const allMetrics = await loadAllMetrics(resultsDir);
  if (allMetrics.length === 0) {
    console.error('Error: No valid metrics files found');
    process.exit(1);
  }

  const models = [...new Set(allMetrics.map(m => m.model))].sort();
  const comparisons = buildComparisons(allMetrics);

  // Compute averages by condition
  const byCondition = groupBy(allMetrics, m => m.condition);
  const avgRampUpRatio: Record<string, number> = {};
  const avgCost: Record<string, number> = {};
  const avgProductiveRatio: Record<string, number> = {};

  for (const [condition, metrics] of Object.entries(byCondition)) {
    avgRampUpRatio[condition] = average(metrics.map(m => m.ramp_up_ratio));
    avgCost[condition] = average(metrics.map(m => m.estimated_cost));

    const productiveRatios = metrics.map(m => {
      const total = m.total_input_tokens + m.total_output_tokens;
      return total > 0 ? m.productive_tokens / total : 0;
    });
    avgProductiveRatio[condition] = average(productiveRatios);
  }

  const report: AggregateReport = {
    generated_at: Date.now(),
    models,
    sessions_analyzed: allMetrics.length,
    comparisons,
    summary: {
      avg_ramp_up_ratio_by_condition: avgRampUpRatio,
      avg_cost_by_condition: avgCost,
      avg_productive_ratio_by_condition: avgProductiveRatio,
    },
  };

  // Output JSON to stdout
  console.log(JSON.stringify(report, null, 2));

  // Print human-readable summary to stderr so JSON output remains clean
  const originalLog = console.log;
  console.log = (...args) => process.stderr.write(args.join(' ') + '\n');
  printSummaryTable(report);
  console.log = originalLog;
}

main();
