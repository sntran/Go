defmodule Go.Katago do
  @moduledoc """
  The KataGo analysis engine, for the offline library maker
  (`mix go.gen.library`). It never runs on the server.

  KataGo runs as a port (`katago analysis`). The queries and the answers
  are lines of JSON on stdin and stdout. More callers can ask at the same
  time: KataGo does the queries in parallel.

  The rules: area scoring, simple ko, no suicide, komi 7, as `Go.Score`
  and `Go.Board`. Blue is Black, and plays first. Red is White. The
  players must capture the dead stones before they pass (no friendly
  pass), thus the area score at the end is the real score.

  All scores are from the side of Blue: a positive score means that Blue
  wins by that many points.

  The program and the network do not come with the repository. See the
  README for the download and the licenses.
  """

  use GenServer

  alias Go.Board

  @size 9
  @cols ~c"ABCDEFGHJ"
  @rules %{
    "ko" => "SIMPLE",
    "scoring" => "AREA",
    "tax" => "NONE",
    "suicide" => false,
    "hasButton" => false,
    "whiteHandicapBonus" => "0",
    "friendlyPassOk" => false
  }

  @type move :: {Board.color(), Board.point() | :pass}

  ## Start

  @doc """
  Starts KataGo. Options:

    * `:katago`: the path of the program (else `$KATAGO`, else `katago`).
    * `:model`: the path of the network (else `$KATAGO_MODEL`).
    * `:threads`: the number of analyses in parallel (the default is the
      number of CPU cores).
  """
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts)

  @doc "Stops KataGo."
  def stop(server), do: GenServer.stop(server)

  @doc """
  The policy of the network for the side to move after `moves`: a map
  from each legal point (and `:pass`) to its chance. One evaluation.
  """
  @spec policy(GenServer.server(), [move()]) :: %{(Board.point() | :pass) => float()}
  def policy(server, moves) do
    result = query(server, moves, %{"maxVisits" => 1, "includePolicy" => true})

    result["policy"]
    |> Enum.with_index()
    |> Enum.reject(fn {p, _} -> p < 0 end)
    |> Map.new(fn {p, i} -> {index_point(i), p} end)
  end

  @doc """
  The score estimate after `moves`, from the side of Blue, with a search
  of `visits` visits.
  """
  @spec score(GenServer.server(), [move()], pos_integer()) :: float()
  def score(server, moves, visits) do
    query(server, moves, %{"maxVisits" => visits})["rootInfo"]["scoreLead"]
  end

  @doc "Sends one query, and waits for its answer (a decoded JSON map)."
  def query(server, moves, extra) do
    case GenServer.call(server, {:query, moves, extra}, :infinity) do
      %{"error" => error} -> raise "KataGo error: #{error}"
      result -> result
    end
  end

  ## Coordinates

  @doc "A point as KataGo writes it: `{0, 0}` (top left) is \"A9\"."
  def gtp(:pass), do: "pass"
  def gtp({r, c}), do: <<Enum.at(@cols, c), Integer.to_string(@size - r)::binary>>

  @doc "The point of a KataGo coordinate."
  def from_gtp("pass"), do: :pass

  def from_gtp(<<col, row::binary>>),
    do: {@size - String.to_integer(row), Enum.find_index(@cols, &(&1 == col))}

  # The policy is in row order from the top row, and the last value is the pass.
  defp index_point(i) when i == @size * @size, do: :pass
  defp index_point(i), do: {div(i, @size), rem(i, @size)}

  ## The server

  @impl true
  def init(opts) do
    katago = opts[:katago] || System.get_env("KATAGO") || System.find_executable("katago")
    model = opts[:model] || System.get_env("KATAGO_MODEL")

    unless katago && File.exists?(katago), do: raise("KataGo not found. Set --katago or $KATAGO.")
    unless model && File.exists?(model), do: raise("No network. Set --model or $KATAGO_MODEL.")

    threads = opts[:threads] || System.schedulers_online()
    dir = Path.join(System.tmp_dir!(), "go-katago-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    config = Path.join(dir, "analysis.cfg")

    File.write!(config, """
    logDir = #{dir}
    logToStderr = false
    reportAnalysisWinratesAs = BLACK
    numAnalysisThreads = #{threads}
    numSearchThreadsPerAnalysisThread = 1
    nnMaxBatchSize = #{threads}
    nnCacheSizePowerOfTwo = 20
    nnMutexPoolSizePowerOfTwo = 14
    nnRandomize = true
    numNNServerThreadsPerModel = #{opts[:nn_threads] || 1}
    #{opts[:extra_config]}
    """)

    # The messages of KataGo on stderr go to a file.
    port =
      Port.open({:spawn_executable, "/bin/sh"}, [
        :binary,
        :exit_status,
        {:line, 1_000_000},
        args: [
          "-c",
          ~s(exec "$0" analysis -model "$1" -config "$2" 2>>"$3"),
          katago,
          model,
          config,
          Path.join(dir, "stderr.txt")
        ]
      ])

    {:ok, %{port: port, next: 1, waiting: %{}, buffer: ""}}
  end

  @impl true
  def handle_call({:query, moves, extra}, from, state) do
    id = Integer.to_string(state.next)

    body =
      Map.merge(
        %{
          "id" => id,
          "moves" => Enum.map(moves, fn {color, move} -> [player(color), gtp(move)] end),
          "rules" => @rules,
          "komi" => 7,
          "boardXSize" => @size,
          "boardYSize" => @size
        },
        extra
      )

    Port.command(state.port, [JSON.encode!(body), "\n"])
    {:noreply, %{state | next: state.next + 1, waiting: Map.put(state.waiting, id, from)}}
  end

  @impl true
  def handle_info({port, {:data, {:noeol, part}}}, %{port: port} = state),
    do: {:noreply, %{state | buffer: state.buffer <> part}}

  def handle_info({port, {:data, {:eol, part}}}, %{port: port} = state) do
    line = state.buffer <> part
    state = %{state | buffer: ""}

    case line do
      "{" <> _ -> {:noreply, answer(JSON.decode!(line), state)}
      # Some builds write a message that is not JSON on stdout first.
      _ -> {:noreply, state}
    end
  end

  def handle_info({port, {:exit_status, status}}, %{port: port} = state),
    do: {:stop, {:katago_exit, status}, state}

  @impl true
  def terminate(_reason, %{port: port}) do
    if Port.info(port), do: Port.close(port)
    :ok
  catch
    _, _ -> :ok
  end

  # A warning is not the answer. The answer comes later.
  defp answer(%{"warning" => _} = message, state) when not is_map_key(message, "error"),
    do: state

  defp answer(message, state) do
    {from, waiting} = Map.pop(state.waiting, message["id"])
    if from, do: GenServer.reply(from, message)
    %{state | waiting: waiting}
  end

  defp player(:blue), do: "B"
  defp player(:red), do: "W"
end
