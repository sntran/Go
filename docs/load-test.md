# The load test: how many players one Durable Object serves

All players use one Durable Object, and one VM (BEAM in WebAssembly) in
it. This test measures how many players it serves, after the books made
each tap a lookup (no search during play).

## How I measured

- `wrangler dev` (workerd on my computer: 4 cores of an Intel Xeon at 2.1
  GHz) with the `app.com` of this commit. The Durable Object runs on one
  thread.
- `scripts/load/run.mjs` starts N players at the same time. Each player
  opens a run over the WebSocket of LiveView, as a browser does, and taps
  a move every 3 to 10 seconds: the moves of the shown answer (60%), or
  a wrong move (40%). Then it taps "Continue the story", "Skip" and "Next
  stage". The data (the answers of the runs) comes from
  `scripts/load/data.exs`: only this test tool knows them, never the
  browser.
- Each N runs 90 seconds, on a new Worker (clean state).
- The time from the tap to the blue stone is the time to the reply of the
  tap. The time to Red's reply is the time to the next push of the
  server; Red waits 700 ms on purpose (`:red_delay`), so the table also
  gives this time less the 700 ms.
- CPU: the CPU time of the workerd process of the Worker, as a percent of
  one core. Memory: the memory of the VM, from the log lines `beam: memory
  N MB (a new peak of this VM)` of beam.com. It never shrinks, so it is the
  peak.

```sh
OUT=/tmp/load-data.json mix run scripts/load/data.exs
npx wrangler dev                       # in another shell
node scripts/load/run.mjs --players 100 --seconds 90 --data /tmp/load-data.json --pid <workerd pid>
```

## Results

| Players | Taps | Tap → blue stone, p50 / p95 | Red's reply less 700 ms, p50 / p95 | Join (all at once), p50 / p95 | Other actions, p95 | CPU (mean of one core) | VM memory (peak) | Errors |
|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 10 | 52 | 18 / 34 ms | 24 / 40 ms | 0.43 / 0.44 s | 59 ms | 5% | 260 MB | none |
| 50 | 264 | 19 / 39 ms | 24 / 47 ms | 1.5 / 1.8 s | 0.8 s | 23% | 632 MB | none |
| 100 | 527 | 25 / 114 ms | 34 / 114 ms | 3.1 / 5.3 s | 1.9 s | 49% | 1,042 MB | 4 missed Red replies |
| 150 | 764 | 29 / 173 ms | 43 / 163 ms | 4.3 / 6.5 s | 2.0 s | 67% | 1,443 MB | 9 missed Red replies |
| 200 | 942 | 108 / 1,335 ms | 123 / 1,457 ms | 6.1 / 10.3 s | 3.5 s | 87% | 1,827 MB | 10 missed Red replies |
| 500 | 797 | 6.7 / 15.1 s | 8.5 / 14.8 s | 23 / 68 s | 10.1 s | 96% | (process: 3.8 GB) | joins crashed, time-outs, 504 |

"Other actions" are "Continue the story", "Skip" and "Next stage". A
"missed Red reply" means that the script saw no push of the server in
15 s after a tap that has a Red reply (about 1% of these taps).

## The answer

**By the time of a tap: 150 players.** With 150 players who all start at
the same time, the 95th percentile of the tap is 173 ms, and of Red's
reply 163 ms after its pause. With 200 players, the single thread of the
Durable Object is nearly full (87% of one core), and the 95th percentile
is 1.3 s.

**But the memory is the real limit, and it is far lower.** On Cloudflare,
an isolate has 128 MB, and `wrangler dev` does not apply this limit. Over
128 MB, Cloudflare resets the Durable Object: all players lose the
connection, and the VM starts again. The VM needs 79 MB after it loads the
bank and the newest library. Small groups that start at the same time:

| Players | VM memory (peak) |
|---:|---:|
| 1 | 79 MB |
| 3 | 125 MB |
| 5 | 138 MB |
| 10 | 260 MB |

So today one Durable Object serves only about 3 players who start
together. The docs of beam.com say that the 128 MB also hold the modules
of the Worker (`app.com`, 37.6 MB), so the real number can be lower. I did
not test on Cloudflare itself. Players who start one after the other need
less: in a test before the last changes, 5 players and then 20 more
stayed at 148 MB.

## Where the memory goes

I looked inside the VM (a debug page in a test build, not in the
repository):

- Erlang itself used only about 34 MB (`erlang:memory()`), also after 50
  run pages. Natively, an open run page needs about 0.14 MB after a
  collection, and 50 open pages need 13 MB.
- The memory of the VM grows in bursts: when many pages render at the
  same time, their heaps grow together, and on WebAssembly the VM keeps
  the peak forever. Later players reuse it only partly: 50 run pages, all
  closed, then 50 more run pages, grew the VM from 403 MB to 646 MB.
- The main cause is the animation at the start of a stage: the server
  renders the whole 9x9 board for each move (every 500 ms). 50 run pages
  needed about 400 MB with the animation, and 149 MB without its steps.
  50 pages of the worlds (5x5 boards, no animation) needed 117 MB.
- The database is not a cause: 600 reads and writes did not change the
  memory.

What I changed, and kept (each one is right on its own, but none solves
the limit):

- A run page keeps only its stage, not the whole run, and the first
  render (before the WebSocket) does not make the run.
- Pages hibernate after 1 s with no message (`hibernate_after`), and each
  process cleans its old heap after 10 collections (`fullsweep_after`).
- The library, the bank and the tiers of the runs are made one time,
  under a lock (`Go.Cache`): before, pages that started together each
  made their own copy.
- One Bandit acceptor (the advice of beam.com: the host has one listener).
- The database pool has 4 connections, and a statement waits up to 2 s:
  before, with 100 players, statements were dropped after 100 ms and pages
  crashed.
- The production log level is `warning` (each log line costs CPU in the
  one VM).

What did not help: the allocator flag `-Mea min` (malloc for all memory),
and a lower log level.

## The memory at the start

The VM is 37 MB when it is ready (before the data). Measured with
`wrangler dev`, from the log lines of beam.com (steps of 8 MB):

| When | Before | Now |
|---|---:|---:|
| After the start (the bank and the newest library are loaded) | 79 MB | 58 MB |
| After the home page | 79 MB | 58 MB |
| After the first run page (with the stage animation) | 79 MB | 58 MB |

What changed:

- The library and the bank are in the Erlang term format
  (`term_to_binary`), not JSON. The moves of a story are packed (one byte
  for each move), and each book stays as bytes until a puzzle needs it.
  The decode makes no big temporary peak. The files are smaller too:
  1.2 MB in place of 1.25 MB for a library version, and 96 KB in place of
  452 KB for the bank.
- The server loads a library version only when a run needs it: at the
  start, only the newest version. A link to a run of an old version loads
  that version.
- The daily guard reads only the head of a library file (its version and
  its daily_from), not the stories.
- The stage animation plays in the browser (see below): the first run
  page does not add memory.

## What could fix the memory (your decision)

1. Play the animation in the browser: the server sends the moves of the
   stage one time, and a small script moves the stones. The look stays
   the same. I expect this to cut the memory of a stage start by more than
   half (see the 149 MB above).
2. Send smaller diffs of the board (stable keys for the points and the
   stones, so that LiveView sends only the changed ones).
3. Keep the library as Erlang terms (`term_to_binary`) in place of JSON,
   so that the start needs less memory.
4. Ask BEAM.com why the memory of the VM grows so far above the memory of
   Erlang under many short renders (perhaps the allocator in
   WebAssembly), and test a fix there.
5. More Durable Objects (one for each group of players). You said you
   will decide this after the numbers.
