defmodule Go.Capacity do
  @moduledoc """
  The guard of the memory of the VM.

  On Cloudflare, an isolate has 128 MB for the VM and for `app.com`. The
  memory of the VM in WebAssembly never shrinks, and when the isolate goes
  over its limit, the Durable Object resets and all players lose their
  connection. So when the VM is above a limit, the server refuses new
  players: their page says "Too many players are here now", with a button
  to try again (see `GoWeb.Capacity`).

  A player who is already here continues to play. The server keeps the
  time of the last action of each player (a mount or an event of a live
  view). A player with an action in the last `@grace` ms is "here".

  The memory comes from `wasm_host:memory/0` of beam.com (the size of the
  memory of WebAssembly, also with `-Mea min`). Natively, and in an older
  beam.com, it is `erlang:memory(:total)`. When no value is available,
  the guard is off.

  The limit is `config :go, :memory_limit_mb` (see `config/runtime.exs`,
  `MEMORY_LIMIT_MB`). `nil` turns the guard off.
  """

  use GenServer

  @table __MODULE__
  # A player with an action in this time (ms) is still here.
  @grace 10 * 60_000

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @impl true
  def init(nil) do
    :ets.new(@table, [:named_table, :public, :set, write_concurrency: true])
    # Remove the players who left, one time in each grace time.
    :timer.send_interval(@grace, :sweep)
    {:ok, nil}
  end

  @impl true
  def handle_info(:sweep, state) do
    old = now() - @grace
    :ets.select_delete(@table, [{{:_, :"$1"}, [{:<, :"$1", old}], [true]}])
    {:noreply, state}
  end

  @doc "The memory of the VM in bytes, or nil when it is not available."
  @spec memory() :: non_neg_integer() | nil
  def memory do
    if Code.ensure_loaded?(:wasm_host) and function_exported?(:wasm_host, :memory, 0) do
      # apply/3: the module is only in the WebAssembly runtime.
      apply(:wasm_host, :memory, [])
    else
      :erlang.memory(:total)
    end
  rescue
    # With -Mea min, erlang:memory/0 is not supported.
    _ -> nil
  end

  @doc "The limit in bytes, or nil when the guard is off."
  @spec limit() :: non_neg_integer() | nil
  def limit do
    case Application.get_env(:go, :memory_limit_mb) do
      mb when is_number(mb) and mb > 0 -> round(mb * 1024 * 1024)
      _ -> nil
    end
  end

  @doc "True when the memory of the VM is above the limit."
  @spec full?() :: boolean()
  def full? do
    with limit when limit != nil <- limit(),
         memory when memory != nil <- memory() do
      memory > limit
    else
      _ -> false
    end
  end

  @doc """
  True when the player can come in: the VM is under the limit, or the
  player is already here.
  """
  @spec admit?(String.t() | nil) :: boolean()
  def admit?(player), do: here?(player) or not full?()

  @doc "Records an action of the player."
  @spec seen(String.t() | nil) :: :ok
  def seen(nil), do: :ok

  def seen(player) do
    :ets.insert(@table, {player, now()})
    :ok
  end

  @doc "True when the player had an action in the last grace time."
  @spec here?(String.t() | nil) :: boolean()
  def here?(nil), do: false

  def here?(player) do
    case :ets.lookup(@table, player) do
      [{^player, time}] -> now() - time < @grace
      [] -> false
    end
  end

  @doc "Forgets all players (for the tests)."
  def reset, do: :ets.delete_all_objects(@table)

  defp now, do: System.monotonic_time(:millisecond)
end
