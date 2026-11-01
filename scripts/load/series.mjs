// The load test against the real limit of an isolate. For each number of
// players, it starts a new `wrangler dev` (a clean state), runs
// scripts/load/run.mjs, and reads the peak memory of the VM from the log
// lines of beam.com ("beam: memory N MB"). The isolate holds the VM and
// the Worker modules (app.com), so a step fails when the VM peak plus the
// size of app.com is over the limit (128 MB on Cloudflare). `wrangler dev`
// does not apply this limit; this tool does.
//
//   npm run build
//   OUT=/tmp/load-data.json mix run scripts/load/data.exs
//   node scripts/load/series.mjs --players 1,3,5,10,20,50 --seconds 90 \
//     --data /tmp/load-data.json [--limit 128] [--app app.com] [--all]
//
// It prints one JSON line for each step, then the largest number of
// players under the limit. Without --all, it stops after the first step
// that fails. The exit code is 1 when a step fails.
import { spawn, execFileSync } from 'node:child_process';
import { statSync, rmSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const args = Object.fromEntries(
  process.argv.slice(2).reduce((acc, a, i, all) => {
    if (!a.startsWith('--')) return acc;
    const next = all[i + 1];
    return [...acc, [a.slice(2), next === undefined || next.startsWith('--') ? 'true' : next]];
  }, [])
);
const counts = (args.players || '1,3,5,10,20').split(',').map(Number);
const seconds = Number(args.seconds || 90);
const limit = Number(args.limit || 128);
const app = args.app || 'app.com';
const port = Number(args.port || 8787);
const url = `http://localhost:${port}`;
const run = join(dirname(fileURLToPath(import.meta.url)), 'run.mjs');
const appMb = statSync(app).size / 1024 / 1024;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Starts wrangler dev with a clean state. Gives the process and its log.
async function start() {
  rmSync('.wrangler/state', { recursive: true, force: true });
  const log = { text: '' };
  const proc = spawn('npx', ['wrangler', 'dev', '--port', String(port)], { detached: true });
  proc.stdout.on('data', (d) => (log.text += d));
  proc.stderr.on('data', (d) => (log.text += d));
  for (let i = 0; i < 90; i++) {
    try {
      await fetch(`${url}/`);
      break;
    } catch {
      await sleep(2000);
    }
  }
  // The Durable Object starts on the first page.
  await fetch(`${url}/run/new`, { redirect: 'manual' }).catch(() => null);
  return { proc, log };
}

function stop(proc) {
  try {
    process.kill(-proc.pid, 'SIGTERM');
  } catch {}
}

// The workerd process of the Worker: the one with the most memory.
function workerd() {
  const out = execFileSync('ps', ['-eo', 'pid,rss,args'], { encoding: 'utf8' });
  const rows = out
    .split('\n')
    .map((l) => l.trim().split(/\s+/))
    .filter((f) => f[2] && f[2].endsWith('workerd'))
    .sort((a, b) => Number(b[1]) - Number(a[1]));
  return rows[0]?.[0];
}

// The peak memory of the VM, from the log lines of beam.com.
function vmPeak(text) {
  const plain = text.replace(/\x1b\[[0-9;]*m/g, '');
  const all = [...plain.matchAll(/beam: (?:ready.*?, )?memory (\d+) MB/g)].map((m) => Number(m[1]));
  return all.length ? Math.max(...all) : null;
}

function load(players, pid) {
  return new Promise((ok) => {
    const p = spawn('node', [run, '--url', url, '--players', String(players), '--seconds', String(seconds), '--data', args.data, ...(pid ? ['--pid', pid] : [])]);
    let out = '';
    p.stdout.on('data', (d) => (out += d));
    p.on('close', () => {
      try {
        ok(JSON.parse(out.trim().split('\n').pop()));
      } catch {
        ok({ players, errors: { 'no result': 1 } });
      }
    });
  });
}

let best = null;
let failed = false;
for (const n of counts) {
  const { proc, log } = await start();
  const result = await load(n, workerd());
  await sleep(1000);
  stop(proc);
  const vm = vmPeak(log.text);
  const isolate = vm === null ? null : Math.round(vm + appMb);
  const pass = isolate !== null && isolate <= limit;
  const crashed = (log.text.match(/\[error\]/g) || []).length;
  console.log(JSON.stringify({ ...result, vm_peak_mb: vm, app_mb: +appMb.toFixed(1), isolate_mb: isolate, limit_mb: limit, pass, server_errors: crashed }));
  if (pass) best = n;
  else {
    failed = true;
    if (args.all !== 'true') break;
  }
  await sleep(2000);
}

console.log(JSON.stringify({ largest_players_under_limit: best, limit_mb: limit }));
process.exit(failed ? 1 : 0);
