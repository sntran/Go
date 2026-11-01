defmodule Go.Progress do
  @moduledoc """
  The progress of each player: the attempts, the result of each puzzle,
  the runs, the results of the stages, and the look (castles or the real
  board).

  The data stays in SQLite (`Go.Repo`), so it stays after a restart or a
  deploy. An ETS table keeps a copy in memory: the first read of a player
  loads all data of the player from the database, and each write goes to
  both. The table `progress` has one value for each player and key, and
  the table `attempts` has the attempts.

  The leaderboard comes later, and it will use the attempts:

    * Each attempt has the puzzle id, the list of moves, the result and
      the stars.
    * Before the server counts a result, it plays the moves again with the
      rules engine (see `Go.Play.verify/3`).

  A warning for the leaderboard: `Go.Play.verify/3` checks only that the
  moves are legal and that the result is true. It does not check that the
  red moves are the moves of the solver. This is correct now, because the
  server makes all red moves. But never accept a move list from the
  browser: the browser could send red moves that help Blue.
  """

  use GenServer

  import Ecto.Query

  alias Go.{Play, Puzzle, Repo}

  @table __MODULE__
  @learned_days 3

  defmodule Attempt do
    @moduledoc "One attempt at a puzzle."
    defstruct [:player, :puzzle_id, :moves, :result, :stars, :at]
  end

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
    {:ok, nil}
  end

  # One process loads the data of a player, so that two loads do not mix.
  @impl true
  def handle_call({:load, player}, _from, state) do
    unless :ets.member(@table, {player, :__loaded__}) do
      rows =
        Repo.all(from p in "progress", where: p.player == ^player, select: {p.key, p.value})

      for {key, value} <- rows do
        :ets.insert(@table, {{player, decode(key)}, decode(value)})
      end

      :ets.insert(@table, {{player, :__loaded__}, true})
    end

    {:reply, :ok, state}
  end

  @doc "The results of a player: a map from a puzzle id to its result."
  @spec results(String.t()) :: map()
  def results(player), do: get(player, :results, %{})

  @doc "The attempts of a player, the newest first."
  def attempts(player) do
    Repo.all(
      from a in "attempts", where: a.player == ^player, order_by: [desc: a.id], select: a.value
    )
    |> Enum.map(&decode/1)
  end

  @doc """
  The number of puzzles of `world` since the last review (see `Go.Path`).
  """
  def since_review(player, world), do: get(player, {:since_review, world}, 0)

  @doc "Counts a finished puzzle of the path: a new one, or a review."
  def count_path(player, world, :review), do: put(player, {:since_review, world}, 0)

  def count_path(player, world, :new),
    do: put(player, {:since_review, world}, since_review(player, world) + 1)

  ## Runs (see Go.Runs)

  @doc "The seed of the run that the player plays now, or nil."
  def current_run(player), do: get(player, :current_run, nil)

  @doc """
  The place of a player in the run of a seed, or nil before the start:
  `%{seed, level, stage, moment, results}`. `moment` is `:start` (the
  moves before the first puzzle play first), the number of the puzzle in
  the stage (from 1), or `:end`. `results` has the result of each puzzle of
  the stage, in order.
  """
  def run_place(player, seed), do: get(player, {:run, seed}, nil)

  @doc "Saves the place of a player in a run, and makes it the current run."
  def put_run_place(player, %{seed: seed} = place) do
    put(player, {:run, seed}, place)
    put(player, :current_run, seed)
  end

  @doc """
  Saves the result of a stage, for a later leaderboard: the stars and the
  help of each puzzle. The results come from the plays on the server,
  never from the browser.
  """
  def record_stage(player, %{seed: seed, level: level, stage: stage, results: results} = place) do
    # The results of a daily run have the date of the run (not the time of
    # play), so that all players of one date can compare.
    entry = %{
      seed: seed,
      level: level,
      stage: stage,
      results: results,
      daily: Map.get(place, :daily),
      at: DateTime.utc_now()
    }

    others = Enum.reject(stage_results(player), &(&1.seed == seed and &1.stage == stage))
    put(player, :stage_results, [entry | others])
  end

  @doc "The saved results of the stages, the newest first."
  def stage_results(player), do: get(player, :stage_results, [])

  @doc """
  The runs that the player finished (all stages), with the mean stars of
  the puzzles: `[%{seed, level, stars_per_puzzle}]`.
  """
  def finished_runs(player) do
    player
    |> stage_results()
    |> Enum.group_by(& &1.seed)
    |> Enum.filter(fn {_seed, stages} -> length(stages) == Go.Runs.stages() end)
    |> Enum.map(fn {seed, stages} ->
      results = Enum.flat_map(stages, & &1.results)
      stars = Enum.sum(Enum.map(results, & &1.stars))

      %{
        seed: seed,
        level: hd(stages).level,
        stars_per_puzzle: if(results == [], do: 0, else: stars / length(results))
      }
    end)
  end

  @doc "The look of a player: `:castle` or `:board`."
  def look(player), do: get(player, :look, :castle)

  def put_look(player, look) when look in [:castle, :board], do: put(player, :look, look)

  @doc """
  Records the end of a play. It plays the moves again first, and records
  nothing if the result is not the same.
  """
  @spec record(String.t(), Play.t(), Date.t()) :: {:ok, Attempt.t()} | {:error, atom()}
  def record(player, %Play{puzzle: %Puzzle{} = puzzle} = play, today \\ Date.utc_today()) do
    result = Play.result(play)

    with :ok <- verify(puzzle, play, result) do
      attempt = %Attempt{
        player: player,
        puzzle_id: puzzle.id,
        moves: play.moves,
        result: result,
        stars: if(result == :solved, do: Play.stars(play), else: 0),
        at: DateTime.utc_now()
      }

      Repo.insert_all("attempts", [
        %{player: player, puzzle_id: puzzle.id, value: :erlang.term_to_binary(attempt)}
      ])

      put(player, :results, update(results(player), puzzle.id, result, attempt.stars, today))
      {:ok, attempt}
    end
  end

  defp verify(_puzzle, _play, :open), do: {:error, :open}
  defp verify(_puzzle, _play, :learned), do: :ok

  # The rules engine plays the moves again: each move must be legal, and a
  # solved result must reach the goal in the move limit.
  defp verify(puzzle, play, result), do: Play.verify(puzzle, play.moves, result)

  defp update(results, id, :solved, stars, _today) do
    best =
      case results[id] do
        %{status: :solved, stars: old} -> max(old, stars)
        _ -> stars
      end

    Map.put(results, id, %{status: :solved, stars: best})
  end

  defp update(results, id, :learned, _stars, today) do
    case results[id] do
      %{status: :solved} -> results
      _ -> Map.put(results, id, %{status: :learned, due: Date.add(today, @learned_days)})
    end
  end

  # A failure leaves a mark, so that the path goes to the next puzzle.
  defp update(results, id, :failed, _stars, _today),
    do: Map.put_new(results, id, %{status: :tried})

  defp get(player, key, default) do
    load(player)

    case :ets.lookup(@table, {player, key}) do
      [{_, value}] -> value
      [] -> default
    end
  end

  defp put(player, key, value) do
    load(player)

    Repo.insert_all(
      "progress",
      [%{player: player, key: :erlang.term_to_binary(key), value: :erlang.term_to_binary(value)}],
      on_conflict: {:replace, [:value]},
      conflict_target: [:player, :key]
    )

    :ets.insert(@table, {{player, key}, value})
    :ok
  end

  defp load(player) do
    unless :ets.member(@table, {player, :__loaded__}), do: GenServer.call(__MODULE__, {:load, player})
  end

  # The data is from this app only. The atoms of the data are atoms of the
  # code, so `:safe` is enough.
  defp decode(binary), do: :erlang.binary_to_term(binary, [:safe])
end
