// The load test against the real limit of an isolate. For each number of
// players, it starts a clean VM, runs scripts/load/run.mjs, and records the
// memory of the VM:
//
// - each 5 s, from GET /stats/memory (MEMORY_STATS=1): wasm_host:memory/0
//   (the memory of WebAssembly, in bytes) and erlang:memory(total) (only
//   with the allocators of ERTS);
// - the log lines of beam.com ("beam: memory N MB"), with `wrangler dev`.
//
// After the players leave, it waits --after seconds and samples again.
// The isolate holds the VM and the Worker modules (app.com), so a step
// fails when the VM peak plus the size of app.com is over the limit (128 MB
// on Cloudflare). `wrangler dev` does not apply this limit; this tool does.
// On Cloudflare (--url), a step fails when the Durable Object resets: the
// WebSockets close before the end.
//
//   npm run build
//   OUT=/tmp/load-data.json mix run scripts/load/data.exs
//   node scripts/load/series.mjs --players 1,3,5,7,10,15,20 --seconds 90 \
//     --data /tmp/load-data.json [--flags default|"-Mea min"] [--limit 128] \
//     [--app app.com] [--after 30] [--all] [--samples FILE]
//
// On Cloudflare: --url https://NAME.workers.dev --deploy "COMMAND". The
// tool runs COMMAND before each step (a new deploy, so a new VM), and
// waits until the new version answers.
//
// It prints one JSON line for each step, then the largest number of
// players that passed. Without --all, it stops after the first step that
// fails. The exit code is 1 when a step fails. --samples writes all
// samples (one JSON line for each) to FILE.
import { spawn, execFileSync, execSync } from 'node:child_process';
import { statSync, rmSync, appendFileSync } from 'node:fs';
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
const after = Number(args.after || 30);
const limit = Number(args.limit || 128);
const app = args.app || 'app.com';
const port = Number(args.port || 8787);
const remote = args.url && args.url !== 'true' ? args.url.replace(/\/$/, '') : null;
const url = remote || `http://localhost:${port}`;
// "default": no BEAM_ERL_FLAGS (the allocators of ERTS).
const flags = args.flags === undefined || args.flags === 'default' ? '' : args.flags;
const run = join(dirname(fileURLToPath(import.meta.url)), 'run.mjs');
const appMb = statSync(app).size / 1024 / 1024;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const MB = 1024 * 1024;

// Starts wrangler dev with a clean state. Gives the process and its log.
async function startLocal() {
  rmSync('.wrangler/state', { recursive: true, force: true });
  const log = { text: '' };
  const vars = [`BEAM_ERL_FLAGS:${flags}`, 'MEMORY_STATS:1', 'MEMORY_LIMIT_MB:off'];
  const proc = spawn('npx', ['wrangler', 'dev', '--port', String(port), ...vars.flatMap((v) => ['--var', v])], { detached: true });
  proc.stdout.on('data', (d) => (log.text += d));
  proc.stderr.on('data', (d) => (log.text += d));
  await ready();
  return { proc, log };
}

// A new deploy on Cloudflare: a new version, so a new Durable Object VM.
async function startRemote() {
  if (args.deploy) execSync(args.deploy, { stdio: ['ignore', 'ignore', 'inherit'] });
  await sleep(5000);
  await ready();
  return { proc: null, log: { text: '' } };
}

async function ready() {
  for (let i = 0; i < 90; i++) {
    try {
      const res = await fetch(`${url}/stats/memory`);
      if (res.ok) break;
    } catch {}
    await sleep(2000);
  }
  // The Durable Object starts on the first page.
  await fetch(`${url}/run/new`, { redirect: 'manual' }).catch(() => null);
}

function stop(proc) {
  if (!proc) return;
  try {
    process.kill(-proc.pid, 'SIGTERM');
  } catch {}
}

// The workerd process of the Worker: the one with the most memory.
function workerd() {
  if (remote) return null;
  const out = execFileSync('ps', ['-eo', 'pid,rss,args'], { encoding: 'utf8' });
  const rows = out
    .split('\n')
    .map((l) => l.trim().split(/\s+/))
    .filter((f) => f[2] && f[2].endsWith('workerd'))
    .sort((a, b) => Number(b[1]) - Number(a[1]));
  return rows[0]?.[0];
}

// The peak memory of the VM, from the log lines of beam.com.
function logPeak(text) {
  const plain = text.replace(/\x1b\[[0-9;]*m/g, '');
  const all = [...plain.matchAll(/beam: (?:ready.*?, )?memory (\d+) MB/g)].map((m) => Number(m[1]));
  return all.length ? Math.max(...all) : null;
}

// One sample of GET /stats/memory, in MB.
async function sample(t0, phase) {
  try {
    const res = await fetch(`${url}/stats/memory`, { signal: AbortSignal.timeout(4000) });
    const m = await res.json();
    const mb = (v) => (v == null ? null : +(v / MB).toFixed(1));
    return { t: Math.round((Date.now() - t0) / 1000), phase, vm_mb: mb(m.vm), erlang_mb: mb(m.erlang_total) };
  } catch {
    return { t: Math.round((Date.now() - t0) / 1000), phase, error: true };
  }
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

const max = (list) => (list.length ? Math.max(...list) : null);

let best = null;
let failed = false;
for (const n of counts) {
  const { proc, log } = remote ? await startRemote() : await startLocal();
  const t0 = Date.now();
  const samples = [await sample(t0, 'start')];
  let phase = 'play';
  const timer = setInterval(async () => samples.push(await sample(t0, phase)), 5000);
  const result = await load(n, workerd());
  phase = 'after';
  await sleep(after * 1000);
  clearInterval(timer);
  samples.push(await sample(t0, 'after'));
  stop(proc);
  if (args.samples) for (const s of samples) appendFileSync(args.samples, JSON.stringify({ players: n, flags: flags || 'default', ...s }) + '\n');

  const vm = samples.filter((s) => s.vm_mb != null).map((s) => s.vm_mb);
  const erl = samples.filter((s) => s.erlang_mb != null).map((s) => s.erlang_mb);
  const fromLog = logPeak(log.text);
  const peak = max([...vm, ...(fromLog == null ? [] : [fromLog])]);
  const last = samples[samples.length - 1];
  const isolate = peak === null ? null : Math.round(peak + appMb);
  // A reset closes the WebSockets, or a sample fails.
  const reset = Boolean(result.errors?.closed) || samples.some((s) => s.error);
  const pass = remote ? !reset && !result.errors?.['no result'] : isolate !== null && isolate <= limit;
  const crashed = (log.text.match(/\[error\]/g) || []).length;
  console.log(JSON.stringify({
    ...result,
    flags: flags || 'default',
    vm_mb: { start: samples[0].vm_mb ?? null, peak: max(vm), after: last.vm_mb ?? null, log_peak: fromLog },
    erlang_mb: erl.length ? { start: samples[0].erlang_mb, peak: max(erl), after: last.erlang_mb } : null,
    app_mb: +appMb.toFixed(1),
    isolate_mb: isolate,
    limit_mb: limit,
    reset,
    pass,
    server_errors: crashed,
  }));
  if (pass) best = n;
  else {
    failed = true;
    if (args.all !== 'true') break;
  }
  await sleep(2000);
}

console.log(JSON.stringify({ largest_players_passed: best, flags: flags || 'default', limit_mb: limit, remote: Boolean(remote) }));
process.exit(failed ? 1 : 0);
