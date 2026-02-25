import { readFile } from 'fs/promises';
import { join } from 'path';
import type { SessionMetrics, ConditionComparison } from './types.js';

function parseArgs(argv: string[]): { model: string; session: number; resultsDir: string } {
  let model = '';
  let session = 0;
  let resultsDir = '';

  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--model' && i + 1 < argv.length) {
      model = argv[i + 1];
      i++;
    } else if (argv[i] === '--session' && i + 1 < argv.length) {
      session = parseInt(argv[i + 1]);
      i++;
    } else if (argv[i] === '--results-dir' && i + 1 < argv.length) {
      resultsDir = argv[i + 1];
      i++;
    }
  }

  if (!model || !session || !resultsDir) {
    console.error('Usage: compare-conditions --model <model> --session <1|2|3> --results-dir <path>');
    console.error('  --model        Model name (e.g., claude-opus, gpt-5.1-codex, gemini-2.5-pro)');
    console.error('  --session      Session number (1, 2, or 3)');
    console.error('  --results-dir  Path to directory containing SessionMetrics JSON files');
    process.exit(1);
  }

  if (session < 1 || session > 3) {
    console.error('Error: --session must be 1, 2, or 3');
    process.exit(1);
  }

  return { model, session, resultsDir };
}

async function loadMetrics(filePath: string): Promise<SessionMetrics | null> {
  try {
    const content = await readFile(filePath, 'utf-8');
    return JSON.parse(content) as SessionMetrics;
  } catch {
    return null;
  }
}

function calcSavingsPercent(baseline: number, improved: number): number {
  if (baseline === 0) return 0;
  const savings = ((baseline - improved) / baseline) * 100;
  return Math.round(savings * 100) / 100;
}

async function main(): Promise<void> {
  const { model, session, resultsDir } = parseArgs(process.argv);

  const conditions = ['stompy', 'file', 'nomemory'] as const;
  const metricsMap: Record<string, SessionMetrics> = {};
  const missing: string[] = [];

  for (const condition of conditions) {
    const fileName = `${model}-${condition}-s${session}.json`;
    const filePath = join(resultsDir, fileName);
    const metrics = await loadMetrics(filePath);

    if (metrics) {
      metricsMap[condition] = metrics;
    } else {
      missing.push(fileName);
    }
  }

  if (missing.length > 0) {
    console.error(`Warning: Missing metrics files: ${missing.join(', ')}`);
  }

  if (Object.keys(metricsMap).length < 2) {
    console.error('Error: Need at least 2 condition results to compare');
    process.exit(1);
  }

  const nomemoryRampUp = metricsMap['nomemory']?.ramp_up_tokens ?? 0;
  const stompyRampUp = metricsMap['stompy']?.ramp_up_tokens ?? 0;
  const fileRampUp = metricsMap['file']?.ramp_up_tokens ?? 0;

  const comparison: ConditionComparison = {
    model,
    session,
    conditions: metricsMap,
    ramp_up_savings: {
      stompy_vs_nomemory: calcSavingsPercent(nomemoryRampUp, stompyRampUp),
      file_vs_nomemory: calcSavingsPercent(nomemoryRampUp, fileRampUp),
      stompy_vs_file: calcSavingsPercent(fileRampUp, stompyRampUp),
    },
  };

  console.log(JSON.stringify(comparison, null, 2));
}

main();
