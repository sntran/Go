defmodule Go.Capacity do
  @moduledoc """
  The guard of the number of players.

  All players share one VM in one Durable Object. Each player who starts
  at the same time takes memory, and when the isolate goes over its
  limit, the object resets and all players lose their connection (see
  `docs/load-test.md`). So the server lets in at most `limit/0` connected
  pages. A new player at the limit gets the page "Too many players are
  here now", with a button to try again (see `GoWeb.Capacity`).

  The count is the number of connected pages: the WebSocket connections
  (transports) that have a connected live view. This process monitors
  each live view, so the count goes down when a page closes. A player who
  is already connected continues to play: a new live view on the same
  connection (a live navigation), or a new page of a player who has a
  connected live view (a reload), always comes in.

  This process does the check and the count in one step, so players who
  join at the same time cannot all pass the check.

  The memory of the VM (`memory/0`) does not decide: in WebAssembly it
  never shrinks, but the VM uses its free memory again. `/stats/memory`
  and the log give it.

  The limit is `config :go, :player_limit` (see `config/runtime.exs`,
  `PLAYER_LIMIT`). `nil` turns the guard off.
  """

  use GenServer

  require Logger

  # At most one log line of refused players in this time (ms).
  @log_every 10_000

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc "The most connected pages, or nil when the guard is off."
  @spec limit() :: pos_integer() | nil
  def limit do
    case Application.get_env(:go, :player_limit) do
      n when is_integer(n) and n > 0 -> n
      _ -> nil
    end
  end

  @doc """
  The live view that calls this joins, on its connection `transport`, for
  `player`. Gives `:ok` (the count now has it, until the live view ends),
  or `:full`.
  """
  @spec join(String.t() | nil, pid()) :: :ok | :full
  def join(player, transport), do: GenServer.call(__MODULE__, {:join, self(), player, transport})

  @doc """
  True when a page of the player can come in: under the limit, or the
  player has a connected live view.
  """
  @spec admit?(String.t() | nil) :: boolean()
  def admit?(player), do: GenServer.call(__MODULE__, {:admit?, player})

  @doc "The number of connected pages."
  @spec count() :: non_neg_integer()
  def count, do: GenServer.call(__MODULE__, :count)

  @doc "Forgets all live views (for the tests)."
  def reset, do: GenServer.call(__MODULE__, :reset)

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

  # The state: the live views (pid => {player, transport, monitor}), and
  # the refused players that are not in the log yet.
  @impl true
  def init(nil), do: {:ok, %{views: %{}, refused: 0, logged: nil}}

  @impl true
  def handle_call({:join, pid, player, transport}, _from, state) do
    if Map.has_key?(state.views, pid) or room?(state, player, transport) do
      views =
        Map.put_new_lazy(state.views, pid, fn -> {player, transport, Process.monitor(pid)} end)

      {:reply, :ok, %{state | views: views}}
    else
      {:reply, :full, refused(state)}
    end
  end

  def handle_call({:admit?, player}, _from, state) do
    if room?(state, player, nil), do: {:reply, true, state}, else: {:reply, false, refused(state)}
  end

  def handle_call(:count, _from, state), do: {:reply, transports(state), state}

  def handle_call(:reset, _from, state) do
    for {_, {_, _, ref}} <- state.views, do: Process.demonitor(ref, [:flush])
    {:reply, :ok, %{state | views: %{}, refused: 0}}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _}, state) do
    {:noreply, %{state | views: Map.delete(state.views, pid)}}
  end

  defp room?(state, player, transport) do
    limit = limit()

    limit == nil or
      Enum.any?(state.views, fn {_, {p, t, _}} ->
        t == transport or (player != nil and p == player)
      end) or
      transports(state) < limit
  end

  defp transports(state),
    do: state.views |> Enum.map(fn {_, {_, t, _}} -> t end) |> Enum.uniq() |> length()

  # Counts a refused player, and writes the log at most one time in
  # @log_every ms, with the memory of the VM.
  defp refused(state) do
    now = System.monotonic_time(:millisecond)
    state = %{state | refused: state.refused + 1}

    if state.logged == nil or now - state.logged >= @log_every do
      mb = if m = memory(), do: Float.round(m / 1_048_576, 1)

      Logger.warning(
        "Too many players: refused #{state.refused} new page(s); #{transports(state)} of #{limit()} pages are connected; VM memory #{mb} MB"
      )

      %{state | refused: 0, logged: now}
    else
      state
    end
  end
end
