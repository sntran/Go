# The load test: how many players one Durable Object serves

All players use one Durable Object, and one VM (BEAM in WebAssembly) in
it. This test measures how many players it serves. The limit is the
memory: the VM memory never shrinks, and when the isolate goes over its
limit, the object resets and all players lose their connection. An
isolate has 128 MB, for the VM and for the modules of the Worker
(`app.com`). `wrangler dev` does not apply this limit, so the test
applies it there. On Cloudflare, the reset came later (see below).

The newest results use beam.com built from `main` of BEAM.com (commit
6672c01, with the fix of #145). No release has this fix yet.
`docs/beam-memory.md` has all the tables, and the decision of the flags.

## How I measured

- `wrangler dev` (workerd on my computer: 4 cores of an Intel Xeon at 2.1
  GHz), and the Worker `go-staging` on Cloudflare. Both have the
  `app.com` and the `wrangler.jsonc` of this commit (11.8 MiB, `--target
  wasm32`). The Durable Object runs on one thread.
- `scripts/load/run.mjs` starts N players at the same time. Each player
  opens a run over the WebSocket of LiveView, as a browser does, and taps
  a move every 3 to 10 seconds: the moves of the shown answer (60%), or
  a wrong move (40%). Then it taps "Continue the story", "Skip" and "Next
  stage". At the end of a run, the player starts the next run (as a new
  player id). The data (the answers of the runs) comes from
  `scripts/load/data.exs`: only this test tool knows them, never the
  browser.
- `scripts/load/series.mjs` runs a list of N. For each N, it starts a new
  VM, runs the players for 90 s, and waits 30 s after they leave. Each 5
  s, it reads `GET /stats/memory` (only with `MEMORY_STATS=1`):
  `wasm_host:memory/0` (the memory of the VM) and `erlang:memory(total)`
  (only with the allocators of ERTS). It also reads the log lines of
  beam.com (`beam: memory N MB`). `--flags` sets `BEAM_ERL_FLAGS`
  (`default` for none).
- With `wrangler dev`, a step fails when the VM peak plus the size of
  `app.com` is over 128 MB.
- On Cloudflare (`--url` and `--deploy`), a step fails when the object
  resets (a new VM: the memory goes down) or a socket closes. A deploy
  does not restart an object that runs, so the tool deploys, sends no
  request for 150 s (Cloudflare then evicts the object), and checks that
  the VM is new.
- The time from the tap to the blue stone is the time to the reply of the
  tap. The time to Red's reply is the time to the next push of the
  server; Red waits 700 ms on purpose (`:red_delay`), so the tables give
  this time less the 700 ms.

```sh
npm run build
OUT=/tmp/load-data.json mix run scripts/load/data.exs
# wrangler dev:
node scripts/load/series.mjs --players 1,3,5,7,10,15,20 --seconds 90 \
  --data /tmp/load-data.json --flags "-Mea min" --all --samples samples.jsonl
# Cloudflare: a folder "staging" with the same files, and the name
# go-staging in its wrangler.jsonc:
node scripts/load/series.mjs --url https://go-staging.fifo.workers.dev \
  --deploy "cd staging && npx wrangler deploy --var MEMORY_STATS:1 --var MEMORY_LIMIT_MB:off" \
  --players 1,3,5,7,10,15,20 --seconds 90 --data /tmp/load-data.json --all
```

## Results (beam.com of `main`, 6672c01)

The VM peak in MB. "Reset" is a reset of the object on Cloudflare:

| Players | `wrangler dev`, default flags | `wrangler dev`, `-Mea min` | Cloudflare, default flags | Cloudflare, `-Mea min` |
|---:|---:|---:|---|---|
| 1 | 82.8 | 54.4 | 71.6 | 47.6 |
| 3 | 105.8 | 73.4 | 93.3 | 67.4 |
| 5 | **128.8** | 86.2 | 114.1 | 80.4 |
| 7 | **155.1** | 108.4 | 132.6, 142.8 | 89.7, 90.4 (2 sockets closed, no reset) |
| 10 | **165.3** | **134.1** | 167.1, **reset** | 122.7, 126.8, 123.5 |
| 12 | | | | 143.1 |
| 15 | **230.6** | **190.4** | **reset**, **reset** | **reset**, **reset** |
| 20 | **264.3** | **219.9** | **reset** | **reset**, **reset** |
| 1, for 10 minutes | 91.3 | 65.1 | 76.8 | 55.4 |
| At the start | 55.3 | 39.9 | 55.3 | 36.6 |

In bold: over 128 MB with `app.com` (`wrangler dev`), or a reset.

**On Cloudflare, one Durable Object serves 10 players who start at the
same time with no reset, with `-Mea min`** (3 of 3 runs; 12 passed in
its one run). With the default flags, 7 (10 reset in 1 of 2 runs). The
p95 of a tap (to the blue stone) on Cloudflare was 141 to 145 ms with 10
players, 141 to 152 ms in all 90 s runs with no reset, and 130 ms
(default flags) and 200 ms (`-Mea min`) for the 10-minute player. This
includes the network from my computer (about 100 ms). On `wrangler dev`, it was 17 to
38 ms.

The VM memory after the players left was the same as the peak (it never
shrinks). `erlang:memory(total)` went back to about 32 MB (`wrangler
dev`) and 28 MB (Cloudflare).

The app uses `-Mea min` (`wrangler.jsonc`). The reason is in
`docs/beam-memory.md`.

## The guard: "Too many players are here now"

When the VM is above a limit, the server refuses a new player
(`Go.Capacity`, `GoWeb.Capacity`): the page says "Too many players are
here now. Try again in one minute.", with a button to try again (status
503, `retry-after: 60`). A player who had an action in the last 10
minutes is "here", and continues to play. The server checks the page
request and the connect of the live view. The memory comes from
`wasm_host:memory/0`.

The limit is `MEMORY_LIMIT_MB` (`config/runtime.exs`): 100 MB by default
in prod. On Cloudflare, the object reset above about 135 to 170 MB, and
each player who starts at the same time adds about 9 MB. At 100 MB,
about 7 to 8 players are in, and there is space for about 4 more who
come in the same seconds. Players who come one after the other need
less. Test: `test/go_web/capacity_test.exs` (with a limit of 1 MB).

The production Worker `go` still has rc.6 (the npm package of
`package.json`), which has no `wasm_host:memory/0`, so there the guard
is off until a release of beam.com has the fix.

## The results with rc.6

The same series with beam.com 0.1.0-rc.6 (before #145), on `wrangler
dev`, with `-Mea min`:

| Players | Taps | Tap → blue stone, p95 | Red's reply less 700 ms, p95 | Join, p95 | VM peak | Isolate (VM + app.com) | 128 MB | Errors |
|---:|---:|---:|---:|---:|---:|---:|---|---|
| 1 | 6 | 24 ms | 34 ms | 0.14 s | 57 MB | 69 MB | pass | none |
| 3 | 16 | 18 ms | 28 ms | 0.16 s | 90 MB | 102 MB | pass | none |
| 5 | 27 | 17 ms | 21 ms | 0.24 s | 111 MB | 123 MB | pass | none |
| 10 | 54 | 18 ms | 25 ms | 0.43 s | 163 MB | 175 MB | **fail** | none |
| 20 | 107 | 17 ms | 28 ms | 0.95 s | 275 MB | 287 MB | **fail** | none |

And before the changes of the round before (`app.com` of 36 MiB, the
allocators of ERTS):

| Players | VM peak | Isolate | 128 MB |
|---:|---:|---:|---|
| 1 | 94 MB | 130 MB | fail |
| 3 | 119 MB | 155 MB | fail |
| 5 | 155 MB | 191 MB | fail |
| 10 | 203 MB | 239 MB | fail |
| 20 | 329 MB | 365 MB | fail |
| 50 | 653 MB | 689 MB | fail |

The CPU is not the limit: with 20 players, the taps and Red's replies
stay under 40 ms at the 95th percentile on `wrangler dev`, and the
earlier test (below) reached the limit of one thread at about 200
players.

## The missed Red replies

At 100 to 200 players, about 1% of the taps got no reply in 15 s. The
cause was in the test tool, not in the server: when a puzzle had fewer
wrong moves than the number of the run, `scripts/load/data.exs` used the
answer as the "wrong" tap. For 23 of the 360 puzzles of the test, the
answer is one move, so that tap solved the puzzle, and Red does not reply
to a solved puzzle. The tool now takes a real wrong move (or none). A
check of all 360 puzzles of the test runs on the server: each wrong tap
and each step of each answer line gets its reply of Red. In the series
above, no tap waited for Red.

The safety net: if the page shows a busy screen ("Red is thinking…") for
5 s with no change, the hook `Busy` (`assets/js/busy.mjs`) sends "sync",
and again after each 5 s. If the server still waits on the same step,
and its time is over, the server does the step now (Red's move, the
search with no more time, or the next move of a replay), sends the new
state, and logs a warning. Tests: `test/go_web/live/sync_test.exs` (the
server) and `test/go_web/busy_js_test.exs` (the hook). In a browser, with
the timer of Red set to 60 s, Red's stone came after the wait of the
hook.

## The memory at the start

Measured with `wrangler dev`, from the log lines of beam.com:

| When | At the start of this round | Now |
|---|---:|---:|
| The VM is ready (before the data) | 37 MB | 25 MB |
| After the start (the bank and the newest library are loaded) | 79 MB | 40 MB |
| After the home page | 79 MB | 40 MB |
| After the first run page (with the stage animation) | 79 MB | 40 MB |
| `app.com` | 36 MiB | 11.7 MiB |
| The isolate after the start | about 115 MB | about 52 MB |

## What changed in the round before

1. **The data in the Erlang term format.** The library and the bank are
   `term_to_binary` files, not JSON. The moves of a story are packed (one
   byte for each move), and each book stays as bytes until a puzzle needs
   it. The server loads a library version only when a run needs it (at
   the start, only the newest one), and the daily guard reads only the
   head of a file. The start went from 79 MB to 58 MB.
2. **The stage animation plays in the browser.** The server sends the
   moves of the stage one time, and the hook `Anim`
   (`assets/js/anim.mjs`, with `assets/js/board.mjs`) plays them with the
   same SVG as the server. The server state jumps to the end. A test
   compares the SVG of the browser with the SVG of the server for real
   positions, in both looks. The first run page no longer adds memory
   (before: +19 MB).
3. **Small board diffs.** Each list of the board is a keyed comprehension,
   with all values of an item as text. A tap now sends about 2.4 KB in
   place of 29 KB, and the reply of Red about 4.1 KB in place of 30.5 KB
   (`test/go_web/live/board_diff_test.exs`).
4. **`app.com` for WebAssembly only** (`--target wasm32` in
   `scripts/app-com.sh`): 11.7 MiB in place of 36 MiB. The Worker keeps
   this file in its isolate. This file does not run natively; on a
   computer, use `mix phx.server`.
5. **`BEAM_ERL_FLAGS` = `-Mea min`** (in `wrangler.jsonc`): the VM uses
   `malloc` for all its memory, not the allocators of ERTS. With 5 players
   for 60 s, the VM peak was 95 MB with this flag, and 179 MB without it.
   There is no `erlang:memory/0` then (the default poller of
   telemetry_poller is already off in `config/prod.exs`).

Other flags that I tried (5 players, 60 s, VM at the start → peak):

| `BEAM_ERL_FLAGS` | Start | Peak |
|---|---:|---:|
| none (the host gives `-MBsbct 8192 -MHsbct 8192`) | 58 MB | 179 MB |
| `-Mea min` | 41 MB | 95 MB |
| `-MMmcs 0` (no cache of segments) | 75 MB | 204 MB |
| smaller carriers (`-MBlmbcs 1024 -MHlmbcs 1024 -MBsbct 1024 -MHsbct 1024 -MBsmbcs 256 -MHsmbcs 256`) | 56 MB | 182 MB |
| a super carrier of 64 MB (`-MMscs 64 -MMsco true -MMscrpm false`) | 91 MB | 123 MB |

## Where the memory goes

With the allocators of ERTS, one player for 90 s grew the VM from 58 MB
to 94 MB. In the same time, Erlang itself (`erlang:memory()`) went from
31 MB to 37 MB, and the carriers of the allocators from 33 MB to 53 MB
(later 41 MB). Natively, the process of a run page peaks at about 0.5 MB
during a join and a tap. So most of the growth is in the VM, not in the
app: memory that Erlang frees does not come back for later use.
`docs/beam-memory.md` is a report for BEAM.com with a small program that
shows this.

With `-Mea min`, the VM still grows about 14 MB for each player who
starts at the same time (5 players: 41 MB to 111 MB). I could not see
inside it (no `erlang:memory/0` with this flag).

## The earlier test (time of a tap, before this round)

This test ran before the changes above, with up to 500 players, and
measured the time of a tap. The memory columns are old.

| Players | Taps | Tap → blue stone, p50 / p95 | Red's reply less 700 ms, p50 / p95 | Join (all at once), p50 / p95 | CPU (mean of one core) | VM memory (peak) |
|---:|---:|---:|---:|---:|---:|---:|
| 10 | 52 | 18 / 34 ms | 24 / 40 ms | 0.43 / 0.44 s | 5% | 260 MB |
| 50 | 264 | 19 / 39 ms | 24 / 47 ms | 1.5 / 1.8 s | 23% | 632 MB |
| 100 | 527 | 25 / 114 ms | 34 / 114 ms | 3.1 / 5.3 s | 49% | 1,042 MB |
| 150 | 764 | 29 / 173 ms | 43 / 163 ms | 4.3 / 6.5 s | 67% | 1,443 MB |
| 200 | 942 | 108 / 1,335 ms | 123 / 1,457 ms | 6.1 / 10.3 s | 87% | 1,827 MB |
| 500 | 797 | 6.7 / 15.1 s | 8.5 / 14.8 s | 23 / 68 s | 96% | (process: 3.8 GB) |

By the time of a tap, one Durable Object serves about 150 players. By the
memory, it serves 5 who start together.

## On Cloudflare with rc.6 (go-staging)

A separate Worker, `go-staging` (the same `app.com` and `wrangler.jsonc`,
with another name), on the account of the project, with rc.6. Caution:
I thought that a new deploy before each step gave a new VM. Later I saw
that a deploy does not restart an object that runs, so some of these
steps started with the memory of the step before, and some resets came
from it. The results with `main` above have a new VM for each step. `scripts/load/run.mjs` ran from a computer in
the US, with `--url https://go-staging.fifo.workers.dev`, for 90 s:

| Players | Runs | Result | Tap → blue stone, p95 | Red's reply less 700 ms, p95 | Join, p95 |
|---:|---:|---|---:|---:|---:|
| 1 | 1 | pass | 142 ms | 122 ms | 1.4 s |
| 3 | 1 | pass | 144 ms | 132 ms | 1.4 s |
| 5 | 2 | pass, pass | 128 to 149 ms | 149 to 153 ms | 1.5 to 1.7 s |
| 7 | 1 | reset | | | |
| 10 | 4 | reset, pass, pass, reset | 132 to 141 ms (when it passed) | 162 to 180 ms | 1.2 to 1.5 s |
| 20 | 2 | reset, reset | | | |

"Reset": in the middle of the test, the WebSockets of all players closed
at the same time, and the requests of the Worker ended with
`responseStreamDisconnected`. This is what a reset of the Durable Object
looks like. `wrangler tail` did not give the events of the WebSockets of
the Durable Object (only some events of its plain requests, for example
`beam: ready in 25 ms ..., memory 25 MB` and a first peak of 37 MB), so I
have no log line that names the cause. The 128 MB is the likely cause,
because the reset comes with more players, as `wrangler dev` predicts.

So on Cloudflare, one Durable Object serves 5 players who start at the
same time with no reset in these runs; 7 already reset once, and 10
resets about half of the time. The times on Cloudflare include the
network from my computer (about 100 ms).

A browser reconnects after a reset, and the run goes on at the saved
place (the place is in SQLite), but the player sees the page reload.
The load tool does not reconnect.


## Not done

- More Durable Objects (one for each group of players): not done, as you
  asked.
