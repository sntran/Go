# The memory of the VM in WebAssembly grows far above erlang:memory()

A report for [BEAM.com](https://github.com/sntran/BEAM.com), to file as an
issue there.

## Summary

On Cloudflare Workers (`workerd`, with `wrangler dev`), with the default
allocators of ERTS, the memory of the VM grows each time that a process
makes a big heap and ends, but `erlang:memory(total)` stays the same. The
memory of the VM never shrinks, so after enough work the VM goes over the
128 MB of an isolate. A small program shows it: 300 renders of 2.2 MB of
terms, one at a time, take the VM from 34 MB to 94 MB, while
`erlang:memory(total)` stays at 16 MB. Natively, the same program grows
from 61 MB to 76 MB (RSS) and then stays there. With `BEAM_ERL_FLAGS` =
`-Mea min`, the VM in WebAssembly stays at 25 MB.

## Versions

- beam.com 0.1.0-rc.6 (the npm package and the native file of the
  release `v0.1.0-rc.6`).
- Elixir 1.20.4, Erlang/OTP 29.1.1 (from beam.com).
- wrangler 4.142.0 (workerd), Node.js 22.23.4, Linux x86_64.

## The program

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

## Steps

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

## Results

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

## The same in a real app

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

## What I think happens (not checked in the C code)

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

## Questions and ideas

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
