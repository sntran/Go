# The memory of the VM in WebAssembly grows far above erlang:memory()

A report for [BEAM.com](https://github.com/sntran/BEAM.com). The first
part is the report as I filed it (issue 141). BEAM.com #145 (merge
8d700bd) fixed the main cause. The part "After BEAM.com #145" has the new
measurements.

## After BEAM.com #145

### The build

No release has 8d700bd yet: the newest release is v0.1.0-rc.6 (also on
npm), and it is older than the fix. So I built beam.com from `main` as
`docs/BUILDING.md` of BEAM.com tells (`make toolchain`, then
`build/cosmocc/bin/make`), and made the npm package with
`scripts/npm.sh` and `npm pack`:

| | |
|---|---|
| BEAM.com commit | `6672c01c6d03524623c25003690c03c57af7fdf5` (`main`, 2 November 2026; it has the merge 8d700bd of #145) |
| `beam.com --version` | 0.1.0-rc.6 (`main` did not change the version) |
| SHA-256 of `build/beam.com` | `919706f042618ccb864b29238b77a332569af89753907b6977baa7929548557e` |
| Runtime id (`runtime/runtime-id.js`) | `11f6eac7ed1a179741090e8029cfba01cb9e29f5699aace2fc4a0d98a79c5eda` |
| `app.com` of Tower Go (`--target wasm32`) | 11.8 MiB |

The `make` of the build ran its own step `test`, and it passed.

### The small program again

The program of the report (below), with the same steps. Renders of
`kb=1000`, one at a time, then 5 renders of each bigger size. The VM
memory comes from the log lines of the host:

| Step | rc.6, default | `main`, default | rc.6, `-Mea min` | `main`, `-Mea min` |
|---|---:|---:|---:|---:|
| Start | 34 MB | 34 MB | 25 MB | 24 MB |
| 50 renders | 55 MB | 53 MB | 25 MB | 24 MB |
| 100 renders | 55 MB | 53 MB | 25 MB | 24 MB |
| 200 renders | 81 MB | 53 MB | | 24 MB |
| 300 renders | 94 MB | 53 MB | 25 MB | 24 MB |
| `kb=2000` | 102 MB | 53 MB | 36 MB | 34 MB |
| `kb=4000` | 115 MB | 80 MB | 36 MB | 44 MB |
| `kb=6000` | 138 MB | 99 MB | 60 MB | 56 MB |

`erlang:memory(total)` was 16 MB after each step. So the leak is fixed:
with the default allocators, the VM no longer grows with each render of
the same size. A bigger render still makes the VM grow (53 → 80 → 99
MB), more than with `-Mea min` (34 → 44 → 56 MB).

### Tower Go on `wrangler dev`

`scripts/load/series.mjs` (see `docs/load-test.md`): for each step, a
new `wrangler dev` (a new VM), N players who start at the same time for
90 s, then 30 s with no players. Each 5 s, the tool reads
`/stats/memory`: `wasm_host:memory/0` and, with the default flags,
`erlang:memory(total)`. "After" is the last sample, 30 s after the
players left. The isolate is the VM peak plus `app.com` (11.8 MB). The
10-minute player starts a new run when a run ends (3 runs in 10
minutes).

Default flags (no `BEAM_ERL_FLAGS`; the host gives `-MBsbct 8192 -MHsbct
8192`):

| Players | VM start | VM peak | VM after | `erlang:memory(total)` start / peak / after | Isolate | Under 128 MB |
|---:|---:|---:|---:|---|---:|---|
| 1 | 56.6 MB | 82.8 MB | 82.8 MB | 30.4 / 38.8 / 31.7 MB | 95 MB | yes |
| 3 | 55.3 MB | 105.8 MB | 105.8 MB | 30.4 / 50.2 / 31.8 MB | 118 MB | yes |
| 5 | 55.3 MB | 128.8 MB | 128.8 MB | 30.4 / 61.4 / 31.9 MB | 141 MB | no |
| 7 | 55.3 MB | 155.1 MB | 155.1 MB | 30.4 / 72.9 / 32.0 MB | 167 MB | no |
| 10 | 55.3 MB | 165.3 MB | 165.3 MB | 30.4 / 89.2 / 32.1 MB | 177 MB | no |
| 15 | 55.3 MB | 230.6 MB | 230.6 MB | 30.4 / 120.5 / 32.4 MB | 242 MB | no |
| 20 | 55.3 MB | 264.3 MB | 264.3 MB | 30.4 / 151.4 / 32.7 MB | 276 MB | no |
| 1, for 10 minutes | 55.3 MB | 91.3 MB | 91.3 MB | 30.4 / 39.8 / 32.0 MB | 103 MB | yes |

`-Mea min`:

| Players | VM start | VM peak | VM after | Isolate | Under 128 MB |
|---:|---:|---:|---:|---:|---|
| 1 | 39.9 MB | 54.4 MB | 54.4 MB | 66 MB | yes |
| 3 | 39.9 MB | 73.4 MB | 73.4 MB | 85 MB | yes |
| 5 | 39.9 MB | 86.2 MB | 86.2 MB | 98 MB | yes |
| 7 | 39.9 MB | 108.4 MB | 108.4 MB | 120 MB | yes |
| 10 | 39.9 MB | 134.1 MB | 134.1 MB | 146 MB | no |
| 15 | 39.8 MB | 190.4 MB | 190.4 MB | 202 MB | no |
| 20 | 39.9 MB | 219.9 MB | 219.9 MB | 232 MB | no |
| 1, for 10 minutes | 39.8 MB | 65.1 MB | 65.1 MB | 77 MB | yes |

With rc.6 (the report below), `-Mea min` gave 57, 90, 111, 163 and 275
MB for 1, 3, 5, 10 and 20 players. So `main` also lowered `-Mea min`
(for example 5 players: 111 → 86 MB).

What the tables show:

- The VM memory never shrinks, so "after" is the peak. Erlang gives its
  memory back: `erlang:memory(total)` goes back to about 32 MB when the
  players leave.
- With the default flags, the VM grows 1.7 to 2.4 times as much as
  `erlang:memory(total)`. For example, 20 players: Erlang grew by 121 MB,
  and the VM by 209 MB.
- Erlang itself grows about 6 MB for each player who joins at the same
  time (20 players: 30 → 151 MB). This is the join of a run page: Tower
  Go can make it smaller.
- One player for 10 minutes: the VM grew in the first minute, and then
  slowly (default: 82.8 MB at 50 s, 91.3 MB at 10 minutes; `-Mea min`:
  53.6 MB at 50 s, 65.1 MB at 10 minutes).

### Tower Go on Cloudflare

The Worker `go-staging` (the same `app.com` and runtime). Caution: a
deploy did **not** restart the Durable Object that was running (November
2026): the VM kept its memory after a deploy, also with other variables
or other code. `docs/WORKERS.md` says that a deploy resets the Durable
Objects. The VM was new only after about 150 s with no requests. So
before each step, the tool deploys, sends no request for 150 s, and
checks that the VM is new (its memory is under 65 MB).

A reset is a new VM: the memory of a VM never shrinks, so a sample under
an earlier sample is a new VM. Then all WebSockets close (code 1006).

Each step ran 90 s, from this container (in the US), with a new VM. For
a reset, the peak is the last sample before the reset (the samples come
each 5 s, so the real peak was higher). The times are the p95 of the
runs with no reset, and include the network (about 100 ms):

Default flags:

| Players | Runs | VM start | VM peak | VM after | `erlang:memory(total)` start / peak / after | Tap → blue stone, p95 | Red's reply less 700 ms, p95 | Join, p95 |
|---:|---|---:|---:|---:|---|---:|---:|---:|
| 1 | pass | 56.6 MB | 71.6 MB | 71.6 MB | 26.9 / 33.9 / 28.2 MB | 146 ms | 152 ms | 1.4 s |
| 3 | pass | 55.3 MB | 93.3 MB | 93.3 MB | 26.8 / 47.3 / 28.3 MB | 143 ms | 145 ms | 0.9 s |
| 5 | pass | 55.3 MB | 114.1 MB | 114.1 MB | 26.8 / 58.1 / 28.4 MB | 146 ms | 174 ms | 1.4 s |
| 7 | pass, pass | 55.3 MB | 132.6, 142.8 MB | the same | 26.8 / 71.3 / 28.5 MB | 147 to 152 ms | 165 to 187 ms | 1.3 to 1.5 s |
| 10 | pass, **reset** | 55.3 MB | 167.1 MB; reset after 155.1 MB | 167.1 MB; a new VM | 26.8 / 88.7 / 28.6 MB | 141 ms | 244 ms | 1.3 s |
| 15 | **reset**, **reset** | 55.3 MB | reset after 157.3 and 133.4 MB | a new VM | | | | |
| 20 | **reset** | 55.3 MB | reset after 165.7 MB | a new VM | | | | |
| 1, for 10 minutes | pass | 55.3 MB | 76.8 MB | 76.8 MB | 26.8 / 37.6 / 28.5 MB | 130 ms | 137 ms | 1.4 s |

`-Mea min`:

| Players | Runs | VM start | VM peak | VM after | Tap → blue stone, p95 | Red's reply less 700 ms, p95 | Join, p95 |
|---:|---|---:|---:|---:|---:|---:|---:|
| 1 | pass | 36.6 MB | 47.6 MB | 47.6 MB | 144 ms | 151 ms | 1.1 s |
| 3 | pass | 36.6 MB | 67.4 MB | 67.4 MB | 144 ms | 177 ms | 1.4 s |
| 5 | pass | 37.1 MB | 80.4 MB | 80.4 MB | 148 ms | 181 ms | 1.4 s |
| 7 | no reset, but 2 of 7 sockets closed (2 times) | 36.6 MB | 89.7, 90.4 MB | the same | | | 1.2 s |
| 10 | pass, pass, pass | 36.6 MB | 122.7, 126.8, 123.5 MB | the same | 141 to 145 ms | 179 to 219 ms | 1.3 to 1.4 s |
| 12 | pass (1 run) | 36.6 MB | 143.1 MB | 143.1 MB | 142 ms | 368 ms | 1.5 s |
| 15 | **reset**, **reset** | 36.6 MB | reset after 166.6 and 167.0 MB | a new VM | | | |
| 20 | **reset**, **reset** | 36.5 MB | reset after 159.8 and 159.6 MB | a new VM | | | |
| 1, for 10 minutes | pass | 36.5 MB | 55.4 MB | 55.4 MB | 200 ms | 230 ms | 1.6 s |

What the tables show:

- On Cloudflare, the object reset when the VM went above about 135 to 170
  MB, with both settings. This is more than 128 MB less `app.com`: the
  check of `wrangler dev` (VM + `app.com` under 128 MB) is stricter than
  Cloudflare was in these runs. 10 players with the default flags passed
  one time at 167.1 MB.
- With the default flags, the VM grows about 11 MB for each player who
  starts at the same time; with `-Mea min`, about 9 MB. So the default
  flags reach the reset with 10 players (1 of 2 runs), and `-Mea min`
  only with 15 (12 passed in its one run).
- In the two runs of 7 players with `-Mea min`, 2 sockets closed with
  the code 1006 during the run, but the VM did not reset (its memory
  stayed at 90 MB). The proxy of my computer had no failure. 10 players
  with the same flag had no closed socket in 3 runs, and no other step
  with no reset had one. I do not know the cause. A browser reconnects
  and continues the run.
- The earlier runs on Cloudflare (with rc.6, in `docs/load-test.md`) did
  not always have a new VM, because a deploy did not restart the object.
  Some of their resets came from the memory of earlier steps.

### The decision: `-Mea min`

`-Mea min` serves more players with no reset: on Cloudflare, 10 players
who start at the same time passed in 3 of 3 runs with it (VM 123 to 127
MB), and in 1 of 2 runs with the default flags (VM 155 to 167 MB). On
`wrangler dev`, the largest N under 128 MB is 7 with `-Mea min` and 3
with the default flags. With one player for 10 minutes, the VM is 55 MB
with it and 77 MB without it (Cloudflare). The results are not near the
same, so the app keeps `-Mea min` (`wrangler.jsonc`).

The cost: `erlang:memory/0` does not work, so the telemetry poller stays
off. The app reads the memory of the VM with `wasm_host:memory/0`
(`/stats/memory` for the load test, and the log line of a refused
player).

Caution: the production Worker `go` is still on rc.6. Workers Builds
installs the npm package `beam.com` of `package.json` (0.1.0-rc.6), and
`npx beam.com` downloads the `beam.com` of that release. These do not
have the fix, and they do not have `wasm_host:memory/0`. The guard of
`Go.Capacity` counts pages, so it also works there. When BEAM.com makes a
release with 8d700bd, set that version in `package.json`. The results above come from the
build of `main` on `go-staging`.

### The guard: why not the memory

The first guard of Tower Go refused new players when
`wasm_host:memory/0` was above 100 MB. This is not a correct signal: the
memory of WebAssembly never shrinks, but the VM uses its free memory
again (the small program stays at 53 MB for 300 renders). After one
peak above the limit, the guard refused all new players until Cloudflare
evicted the object, also when only one player played. Now the guard
counts the connected pages (at most 8, `PLAYER_LIMIT`), and the memory
is only for the measurements and the log.

Rounds on one VM (8 players play for 90 s and leave, then 8 new players
come; no eviction between the rounds), `-Mea min`, on Cloudflare:

| Round | Run A (5 rounds): VM peak | closed sockets | tap p95 | Run B (8 rounds): VM peak | refused | closed sockets | tap p95 |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 97.6 MB | 0 | 892 ms | 106.9 MB | 0 | 0 | 149 ms |
| 2 | 97.6 MB | 2 | 741 ms | 108.7 MB | 0 | 0 | 158 ms |
| 3 | 115.4 MB | 0 | 363 ms | 108.7 MB | **2** | 2 | 533 ms |
| 4 | 115.6 MB | 0 | 174 ms | 108.7 MB | 0 | 1 | 394 ms |
| 5 | 115.6 MB | 0 | 174 ms | 118.1 MB | 0 | 0 | 410 ms |
| 6 | | | | 118.4 MB | 0 | 0 | 403 ms |
| 7 | | | | 118.4 MB | 0 | 0 | 396 ms |
| 8 | | | | 118.4 MB | 0 | 0 | 384 ms |

The VM started at 36.5 MB (A) and 37.1 MB (B). No reset. **The peak did
not stop growing after the first round:** it grew one more step later
(A: +17.8 MB in round 3; B: +9.4 MB in round 5), and then it stayed flat
(A: 2 rounds; B: 3 rounds). The peak stays far under the resets (135 to
170 MB). The test of the rounds stopped there.

Two more findings of these rounds:

- **Stale pages.** Sometimes the close of a WebSocket does not reach the
  VM. In round 2 of B, only 6 of the 8 WebSocket requests of the Durable
  Object ended when the players left (Workers Logs). The other 2 stayed
  open, so their live views stayed in the VM and in the count of the
  guard. In round 3, the count was 2 + 6 = 8, and 2 new players got "Too
  many players" (the log line of the guard: `refused 1 new page(s); 8 of
  8 pages are connected; VM memory 108.7 MB`). In A, the 2 stale
  requests stayed open for 789 s, until Cloudflare evicted that object.
  Phoenix closes a WebSocket with no data for 60 s, but these stayed. So
  a stale page can take a place of the guard for many minutes.
- **Slower taps.** In B, from round 3, the tap p95 was about 400 ms (115
  to 160 ms before). In A, rounds 1 and 2 were slow, and rounds 4 and 5
  were not. I do not know the cause.

### The sockets that closed with the code 1006

In some runs on Cloudflare, 2 sockets closed with the code 1006 and the
VM did not reset (7 players with `-Mea min`, 2 runs; round 2 of the
rounds above). With Workers Logs on (`"observability": { "enabled":
true }` in `wrangler.jsonc`), round 2 of the rounds showed this:

- The front Worker passes each WebSocket to the Durable Object. Its part
  of the request ends about 0.1 s after the start. For 6 sockets, it
  ended with the outcome `canceled`, as in all other runs. For 2 sockets,
  it ended with `responseStreamDisconnected`.
- The Durable Object has an event (outcome `canceled`, about 89 s) for
  the 6 sockets, and **no event** for the 2 sockets.
- The VM wrote no error, and the host wrote no line about them.
- In round 5, one request of the front Worker also ended with
  `responseStreamDisconnected`, but no socket closed, and the object had
  8 events.
- Two new runs of 7 players with `-Mea min` (with `wrangler tail` open)
  had no `responseStreamDisconnected` and no closed socket.

So the closes come on the path of the WebSocket between the front Worker
and the Durable Object, not in the app. The logs do not say why the
stream disconnected. A browser reconnects and continues the run.

The 2 requests of the Durable Object for these sockets did end, but
only at 19:45:58, after 789 s and with the outcome
`responseStreamDisconnected`, when Cloudflare evicted that object. So
for 13 minutes after the client lost the socket, the VM still had it
open, with its live view. The same came without a 1006 close: in round 2
of run B, 2 of 8 requests had no end when the players closed their
sockets, and they took 2 places of the guard in round 3. Phoenix closes
a WebSocket with no data for 60 s (`timeout` of the socket), so either
data still came from the host, or the timeout does not work through the
socket of the host (`wasm_tcp`).

### Open points for BEAM.com

1. A deploy does not restart a Durable Object that is running. The VM
   keeps its memory until Cloudflare evicts the object (after about 150
   s with no requests). `docs/WORKERS.md` says that a deploy resets the
   objects.
2. With the default flags, the VM still grows 1.7 to 2.4 times as much
   as `erlang:memory(total)`, and a bigger render still adds memory
   (the small program: 53 → 99 MB). With `-Mea min`, about 30% less.
3. On Cloudflare, the reset came at a VM of about 135 to 170 MB, not at
   128 MB. Is the 128 MB counted in another way (for example, only the
   pages of the memory of WebAssembly that are used)?
4. Sometimes the request of the front Worker for a WebSocket ends with
   `responseStreamDisconnected`, the Durable Object has no event for
   that socket, and the socket can close later with the code 1006 (see
   above). Can the front Worker log the reason, or retry the connect to
   the object?
5. Then the VM keeps that socket open for many minutes (789 s in one
   case), past the timeout of Phoenix (60 s with no data). Does the
   socket of the host (`wasm_tcp`) give the VM the close of the client
   and the timeout of a read?


## The report (before #145)

### Summary

On Cloudflare Workers (`workerd`, with `wrangler dev`), with the default
allocators of ERTS, the memory of the VM grows each time that a process
makes a big heap and ends, but `erlang:memory(total)` stays the same. The
memory of the VM never shrinks, so after enough work the VM goes over the
128 MB of an isolate. A small program shows it: 300 renders of 2.2 MB of
terms, one at a time, take the VM from 34 MB to 94 MB, while
`erlang:memory(total)` stays at 16 MB. Natively, the same program grows
from 61 MB to 76 MB (RSS) and then stays there. With `BEAM_ERL_FLAGS` =
`-Mea min`, the VM in WebAssembly stays at 25 MB.

### Versions

- beam.com 0.1.0-rc.6 (the npm package and the native file of the
  release `v0.1.0-rc.6`).
- Elixir 1.20.4, Erlang/OTP 29.1.1 (from beam.com).
- wrangler 4.142.0 (workerd), Node.js 22.23.4, Linux x86_64.

### The program

A Mix project with no dependencies. An HTTP server on `gen_tcp`; each
request to `/render?kb=K` starts a process that builds `K * 8` rows of
small tuples and strings, makes iodata of them, then one binary, and
ends. The answer is `erlang:memory()` after the work. With `kb=1000`, the
rows are 2.2 MB of terms, and the binary is 433 KB. This is like the
render of a big LiveView page.

`mix.exs`:

```elixir
defmodule MemRepro.MixProject do
  use Mix.Project

  def project do
    [app: :mem_repro, version: "0.1.0", elixir: "~> 1.18", deps: [], releases: [mem_repro: [include_erts: false]]]
  end

  def application, do: [mod: {MemRepro, []}, extra_applications: [:logger]]
end
```

`config/config.exs`: `import Config`.

`lib/mem_repro.ex`:

```elixir
defmodule MemRepro do
  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT", "4000"))
    pid = spawn_link(fn -> listen(port) end)
    {:ok, pid}
  end

  defp listen(port) do
    {:ok, l} = :gen_tcp.listen(port, [:binary, packet: :http_bin, active: false, reuseaddr: true])
    accept(l)
  end

  defp accept(l) do
    {:ok, s} = :gen_tcp.accept(l)
    pid = spawn(fn -> serve(s) end)
    :gen_tcp.controlling_process(s, pid)
    send(pid, :go)
    accept(l)
  end

  defp serve(s) do
    receive do
      :go -> :ok
    end

    {:ok, {:http_request, _, {:abs_path, path}, _}} = :gen_tcp.recv(s, 0)
    headers(s)
    body = handle(URI.parse(path))
    :ok = :inet.setopts(s, packet: :raw)

    :gen_tcp.send(s, [
      "HTTP/1.1 200 OK\r\ncontent-type: text/plain\r\nconnection: close\r\ncontent-length: ",
      Integer.to_string(byte_size(body)),
      "\r\n\r\n",
      body
    ])

    :gen_tcp.close(s)
  end

  defp headers(s) do
    case :gen_tcp.recv(s, 0) do
      {:ok, :http_eoh} -> :ok
      {:ok, _} -> headers(s)
    end
  end

  # One render in a new process, which then ends.
  defp handle(%URI{path: "/render", query: q}) do
    kb = String.to_integer(URI.decode_query(q || "")["kb"] || "1000")
    {pid, ref} = spawn_monitor(fn -> exit({:size, byte_size(render(kb))}) end)
    size = receive do: ({:DOWN, ^ref, :process, ^pid, {:size, n}} -> n)
    "rendered #{div(size, 1024)} KB\n" <> memory()
  end

  defp handle(_), do: memory()

  defp render(kb) do
    rows =
      for i <- 1..(kb * 8) do
        {:row, i, "item-#{i}", [~s( x="#{i * 1.5}"), ~s( y="#{i / 3}")]}
      end

    rows
    |> Enum.map(fn {:row, i, id, attrs} -> ["<g id=\"", id, "\"", attrs, ">", Integer.to_string(i), "</g>"] end)
    |> IO.iodata_to_binary()
  end

  defp memory do
    m =
      try do
        :erlang.memory()
      rescue
        # With -Mea min, erlang:memory/0 is not supported.
        _ -> [total: 0, processes: 0, binary: 0, code: 0, ets: 0, system: 0]
      end

    Enum.map_join([:total, :processes, :binary, :code, :ets, :system], "\n", &"#{&1} #{div(m[&1], 1024)} KB") <> "\n"
  end
end
```

`worker.js`:

```js
import app from './app.com' with { type: 'bytes' };
import { serve } from 'beam.com';

const beam = serve(app);

export default {
  fetch(request, env, ctx) {
    return beam.fetch(request, env, ctx);
  },
};
```

`wrangler.jsonc`:

```jsonc
{
  "name": "mem-repro",
  "main": "worker.js",
  "compatibility_date": "2026-09-01",
  "compatibility_flags": ["no_handle_cross_request_promise_resolution"],
  "rules": [{ "type": "Data", "globs": ["**/*.com"], "fallthrough": true }]
}
```

`package.json`: the dev dependencies `"beam.com": "0.1.0-rc.6"` and
`"wrangler": "4.142.0"`.

### Steps

```sh
npm install
MIX_ENV=prod npx beam.com mix compile
MIX_ENV=prod RELEASE_ERTS=false npx beam.com mix release --overwrite
npx beam.com _build/prod/rel/mem_repro -o app.com
npx wrangler dev --port 8788 > log.txt 2>&1 &

vm() { sed 's/\x1b\[[0-9;]*m//g' log.txt | grep -o "memory [0-9]* MB" | grep -o "[0-9]*" | sort -n | tail -1; }
for round in 1 2 3 4 5 6; do
  for i in $(seq 1 50); do curl -s -o /dev/null "localhost:8788/render?kb=1000"; done
  echo "after $((round * 50)) renders: VM $(vm) MB"
  curl -s localhost:8788/memory | grep total
done
```

The VM memory comes from the log lines of the host (`beam: ready ...
memory N MB` and `beam: memory N MB (a new peak of this VM)`, in steps of
8 MB). For `-Mea min`, start wrangler with `--var "BEAM_ERL_FLAGS:-Mea
min"`. For the native run: `PORT=4002 ./app.com`, and the RSS of the
process.

### Results

Renders of `kb=1000`, one at a time:

| Renders | VM, default allocators | `erlang:memory(total)` | VM, `-Mea min` | Native RSS | Native `erlang:memory(total)` |
|---:|---:|---:|---:|---:|---:|
| 0 | 34 MB | 16 MB | 25 MB | 61 MB | 32 MB |
| 20 | | | 25 MB | 72 MB | 32 MB |
| 50 | 55 MB | 16 MB | 25 MB | | |
| 100 | 55 MB | 16 MB | 25 MB | 76 MB | 32 MB |
| 150 | 68 MB | 16 MB | | | |
| 200 | 81 MB | 16 MB | | | |
| 300 | 94 MB | 16 MB | 25 MB | | |

Then 5 renders of each bigger size (after the 300 renders):

| Size | VM, default allocators | VM, `-Mea min` |
|---|---:|---:|
| `kb=2000` (4.5 MB of terms) | 102 MB | 36 MB |
| `kb=4000` (9.0 MB of terms) | 115 MB | 36 MB |
| `kb=6000` (13.4 MB of terms) | 138 MB | 60 MB |

`erlang:memory(total)` was 16 MB after each step. The VM with the default
allocators grows in steps of about 11 to 13 MB, and it does not stop
growing. Renders at the same time (10 at a time, 5 times) took it from 34
MB to 55 MB; with `-Mea min` it stayed at 25 MB.

### The same in a real app

[Tower Go](https://github.com/sntran/Go) is a Phoenix LiveView app on a
Durable Object. With the default allocators (the host flags `-MBsbct 8192
-MHsbct 8192`), one player who played for 90 s took the VM from 58 MB to
94 MB. In the same time:

| | At the start | Peak | After 90 s |
|---|---:|---:|---:|
| `erlang:memory(total)` | 31 MB | 37 MB | 32 MB |
| The carriers of the ERTS allocators (`mbcs` and `sbcs` of `erlang:system_info({allocator, A})`) | 33 MB | 53 MB | 41 MB |
| The VM | 58 MB | 94 MB | 94 MB |

Natively, the process of a page of this app peaks at about 0.5 MB during
a join and a tap.

`BEAM_ERL_FLAGS` that I tried (5 players for 60 s, VM at the start →
peak):

| `BEAM_ERL_FLAGS` | Start | Peak |
|---|---:|---:|
| none | 58 MB | 179 MB |
| `-Mea min` | 41 MB | 95 MB |
| `-MMmcs 0` | 75 MB | 204 MB |
| `-MBlmbcs 1024 -MHlmbcs 1024 -MBsbct 1024 -MHsbct 1024 -MBsmbcs 256 -MHsmbcs 256` | 56 MB | 182 MB |
| `-MMscs 64 -MMsco true -MMscrpm false` | 91 MB | 123 MB |

The app now uses `-Mea min`. With it, the VM still grows about 14 MB for
each player who starts at the same time (5 players: 41 MB to 111 MB), and
I cannot see inside it, because `erlang:memory/0` is not supported.

### What I think happens (not checked in the C code)

- The carriers of ERTS come from `mmap()`, and in Emscripten `mmap()` is
  `malloc()` (`erl_mmap.h` in `wasm/erts/otp.patch`). A carrier that ERTS
  gives back (the carriers went from 53 MB to 41 MB above) goes back to
  `malloc`, but the VM did not use that space again for later carriers:
  the VM kept growing.
- The growth comes in steps of 11 to 13 MB. This looks like new carriers
  (or new segments of `malloc`) at the end of the memory, not in the free
  space.
- With `-Mea min`, the blocks go to `malloc` directly, and `malloc` uses
  its free space again: the program stays flat.

### Questions and ideas

1. Can the host use `-Mea min` by default on Workers, or allocator
   settings that give the same result, while `erlang:memory/0` still
   works?
2. Can freed carriers be used again (for example, `munmap()` that keeps
   the space in a list that the next `mmap()` of the same size or smaller
   takes)?
3. Can Erlang read the size of the memory of the VM (for example, in
   `erlang:system_info/1`, or a function of `wasm_host`)? Then an app can
   measure itself, also with `-Mea min`.
4. With `-Mea min`, what makes the VM of the Phoenix app grow about 14 MB
   for each player who starts at the same time, when a page process
   natively peaks at 0.5 MB?
