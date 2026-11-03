// The load test: N players play runs at the same time, over the WebSocket
// of LiveView, as browsers do. Each player opens a run, and taps a move
// every 3 to 10 seconds: the moves of the shown answer, or a wrong move.
//
//   node scripts/load/run.mjs --url http://localhost:8787 --players 50 \
//     --seconds 90 --data /tmp/load-data.json [--pid <workerd pid>]
//
// It prints one JSON line with the results. The package `ws` comes with
// wrangler (npm install).
import WebSocket from 'ws';
import { readFileSync } from 'node:fs';

const args = Object.fromEntries(
  process.argv.slice(2).reduce((acc, a, i, all) => (a.startsWith('--') ? [...acc, [a.slice(2), all[i + 1]]] : acc), [])
);
const url = args.url || 'http://localhost:8787';
const players = Number(args.players || 10);
const seconds = Number(args.seconds || 90);
const data = JSON.parse(readFileSync(args.data, 'utf8'));
const pid = args.pid;
const RED_DELAY = 700;

const stats = { blue: [], red: [], action: [], join: [], errors: {}, taps: 0, wrong: 0, refused: 0 };
// A player who got the page "Too many players are here now".
class Refused extends Error {}
const error = (what) => (stats.errors[what] = (stats.errors[what] || 0) + 1);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const pause = () => sleep(3000 + Math.random() * 7000);
let stop = false;

// The CPU time and the memory of the workerd process.
function sample() {
  if (!pid) return null;
  try {
    const stat = readFileSync(`/proc/${pid}/stat`, 'utf8').split(') ')[1].split(' ');
    const cpu = (Number(stat[11]) + Number(stat[12])) / 100;
    const rss = Number(/VmRSS:\s+(\d+)/.exec(readFileSync(`/proc/${pid}/status`, 'utf8'))[1]) / 1024;
    return { cpu, rss };
  } catch {
    return null;
  }
}

class Player {
  constructor(run) {
    this.run = run;
    this.ref = 0;
    this.waiting = new Map();
    this.onDiff = null;
  }

  async open() {
    const t0 = Date.now();
    // No cookie: each run has a new player id. A finished run can change
    // the level of a player, and then the run has other puzzles than the
    // data of this tool.
    const res = await fetch(`${url}/run/${this.run.code}`, { redirect: 'manual' });
    const html = await res.text();
    // The guard of the server: "Too many players are here now".
    if (res.status === 503 && html.includes('Too many players')) throw new Refused();
    const cookie = (res.headers.get('set-cookie') || '').split(';')[0];
    const csrf = /<meta[^>]*name="csrf-token" content="([^"]+)"/.exec(html)[1];
    const tag = (/<div[^>]*data-phx-main[^>]*>/.exec(html) || [])[0];
    if (!tag) throw new Error('no live view');
    const attr = (name) => new RegExp(`${name}="([^"]+)"`).exec(tag)[1];
    const main = [null, attr('id'), attr('data-phx-session'), attr('data-phx-static')];
    this.topic = `lv:${main[1]}`;
    const wsUrl = `${url.replace('http', 'ws')}/live/websocket?_csrf_token=${encodeURIComponent(csrf)}&vsn=2.0.0`;
    this.ws = new WebSocket(wsUrl, { headers: { cookie } });
    this.ws.on('message', (raw) => this.message(JSON.parse(raw)));
    this.ws.on('error', () => error('websocket'));
    const ws = this.ws;
    // The close code tells who closed the socket (1006: no close frame).
    this.ws.on('close', (code) => { if (!stop && !ws.done) error(`closed ${code}`); });
    await new Promise((ok, fail) => { this.ws.once('open', ok); this.ws.once('error', fail); });
    this.heartbeat = setInterval(() => this.ws.send(JSON.stringify([null, String(++this.ref), 'phoenix', 'heartbeat', {}])), 30000);
    const reply = await this.push('phx_join', {
      url: `${url}/run/${this.run.code}`,
      params: { _csrf_token: csrf, _mounts: 0, date: new Date().toISOString().slice(0, 10) },
      session: main[2],
      static: main[3],
    });
    // At the limit, the join gives a redirect to the same page, and the page
    // then says "Too many players".
    const to = reply.response?.redirect?.to;
    if (reply.status !== 'ok' && to) {
      this.close();
      const again = await fetch(new URL(to, url), { redirect: 'manual' });
      if (again.status === 503 && (await again.text()).includes('Too many players')) throw new Refused();
    }
    if (reply.status !== 'ok') throw new Error('join ' + JSON.stringify(reply.response).slice(0, 200));
    stats.join.push(Date.now() - t0);
  }

  message([, ref, , event, payload]) {
    if (event === 'phx_reply' && this.waiting.has(ref)) {
      this.waiting.get(ref)(payload);
      this.waiting.delete(ref);
    } else if (event === 'diff' && this.onDiff) {
      this.onDiff();
      this.onDiff = null;
    } else if (event === 'phx_error') {
      error('phx_error');
    }
  }

  push(event, payload, topic = this.topic) {
    const ref = String(++this.ref);
    this.ws.send(JSON.stringify(['1', ref, topic, event, payload]));
    return new Promise((ok) => {
      const timer = setTimeout(() => { error('timeout ' + event); this.waiting.delete(ref); ok({ status: 'timeout' }); }, 20000);
      this.waiting.set(ref, (p) => { clearTimeout(timer); ok(p); });
    });
  }

  async click(name, value = {}) {
    const t0 = Date.now();
    const reply = await this.push('event', { type: 'click', event: name, value });
    if (reply.status !== 'ok') error('reply ' + name);
    return Date.now() - t0;
  }

  // A tap: the time to the blue stone (the reply), and to the next push of
  // the server (Red's reply, after its planned pause).
  async tap([r, c], expectRed) {
    const t0 = Date.now();
    const red = expectRed ? new Promise((ok) => (this.onDiff = () => ok(Date.now() - t0))) : null;
    const blue = await this.click('tap', { r: String(r), c: String(c) });
    stats.blue.push(blue);
    stats.taps++;
    if (red) {
      const t = await Promise.race([red, sleep(15000).then(() => null)]);
      if (t === null) error('no red reply');
      else stats.red.push(t);
    }
  }

  async play() {
    stats.action.push(await this.click('skip'));
    for (const [s, stage] of this.run.stages.entries()) {
      for (const puzzle of stage) {
        if (stop) return;
        await pause();
        if (puzzle.wrong && Math.random() < 0.4) {
          stats.wrong++;
          await this.tap(puzzle.wrong, true);
        } else {
          for (const [k, p] of puzzle.answer.entries()) {
            if (stop) return;
            if (k > 0) await pause();
            await this.tap(p, k < puzzle.answer.length - 1);
          }
        }
        await pause();
        stats.action.push(await this.click('continue'));
        stats.action.push(await this.click('skip'));
      }
      if (s < this.run.stages.length - 1) {
        await pause();
        stats.action.push(await this.click('next_stage'));
        stats.action.push(await this.click('skip'));
      }
    }
  }

  close() {
    clearInterval(this.heartbeat);
    if (this.ws) this.ws.done = true;
    this.ws?.close();
  }
}

const pct = (list, p) => {
  if (list.length === 0) return null;
  const s = [...list].sort((a, b) => a - b);
  return s[Math.min(s.length - 1, Math.floor((p / 100) * s.length))];
};

const all = Array.from({ length: players }, (_, i) => new Player(data[i % data.length]));
all.forEach((p, i) => (p.index = i));
const before = sample();
let peakRss = before?.rss || 0;
let peakCpu = 0;
let last = before;
const sampler = setInterval(() => {
  const s = sample();
  if (!s) return;
  peakRss = Math.max(peakRss, s.rss);
  if (last) peakCpu = Math.max(peakCpu, (s.cpu - last.cpu) * 100);
  last = s;
}, 1000);

const start = Date.now();
await Promise.all(
  all.map(async (p) => {
    try {
      // A player who ends a run starts the next run (as a new player id),
      // until the time ends.
      for (let k = 1; !stop; k++) {
        await p.open();
        await p.play();
        if (stop) break;
        p.close();
        p.run = data[(p.index + k * players) % data.length];
        p.waiting.clear();
        stats.runs = (stats.runs || 0) + 1;
      }
    } catch (e) {
      if (e instanceof Refused) stats.refused++;
      else error('open: ' + String(e.message).slice(0, 60));
    }
  }).map((run) => Promise.race([run, sleep(seconds * 1000)]))
);
stop = true;
const after = sample();
clearInterval(sampler);
const wall = (Date.now() - start) / 1000;
all.forEach((p) => p.close());

console.log(JSON.stringify({
  players,
  seconds: Math.round(wall),
  taps: stats.taps,
  wrong_taps: stats.wrong,
  join_ms: { p50: pct(stats.join, 50), p95: pct(stats.join, 95), n: stats.join.length },
  blue_ms: { p50: pct(stats.blue, 50), p95: pct(stats.blue, 95), max: pct(stats.blue, 100) },
  red_ms: { p50: pct(stats.red, 50), p95: pct(stats.red, 95), n: stats.red.length },
  red_minus_pause_ms: { p50: pct(stats.red, 50) - RED_DELAY, p95: pct(stats.red, 95) - RED_DELAY },
  action_ms: { p50: pct(stats.action, 50), p95: pct(stats.action, 95) },
  cpu: before && after ? { seconds: +(after.cpu - before.cpu).toFixed(1), mean_percent: +((after.cpu - before.cpu) / wall * 100).toFixed(1), peak_percent: +peakCpu.toFixed(0) } : null,
  rss_mb: before ? { start: +before.rss.toFixed(0), peak: +peakRss.toFixed(0) } : null,
  runs_done: stats.runs || 0,
  // The players who got the page "Too many players are here now".
  refused: stats.refused,
  errors: stats.errors,
}));
process.exit(0);
