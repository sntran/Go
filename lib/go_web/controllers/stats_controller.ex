defmodule GoWeb.StatsController do
  @moduledoc """
  The memory of the VM, for the load test (`scripts/load/series.mjs`):
  `wasm_host:memory/0` (in WebAssembly), `erlang:memory(:total)` (when the
  allocators of ERTS are on), and the limit of `Go.Capacity`. In bytes.

  Only with `MEMORY_STATS=1` (see `config/runtime.exs`). Else 404.
  """

  use GoWeb, :controller

  def memory(conn, _params) do
    if Application.get_env(:go, :memory_stats, false) do
      json(conn, %{
        vm: wasm_memory(),
        erlang_total: erlang_total(),
        limit: Go.Capacity.limit(),
        full: Go.Capacity.full?()
      })
    else
      send_resp(conn, 404, "")
    end
  end

  defp wasm_memory do
    if Code.ensure_loaded?(:wasm_host) and function_exported?(:wasm_host, :memory, 0),
      do: apply(:wasm_host, :memory, [])
  end

  defp erlang_total do
    :erlang.memory(:total)
  rescue
    _ -> nil
  end
end
