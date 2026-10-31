defmodule Go.Progress do
  @moduledoc """
  The progress of each player: the attempts, the result of each puzzle,
  and the look (castles or the real board).

  The data stays in memory (an ETS table). There is no database yet. The
  leaderboard comes later, and it will use the attempts:

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

  alias Go.{Play, Puzzle}

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

  @doc "The results of a player: a map from a puzzle id to its result."
  @spec results(String.t()) :: map()
  def results(player), do: get(player, :results, %{})

  @doc "The attempts of a player, the newest first."
  def attempts(player), do: get(player, :attempts, [])

  @doc """
  The number of puzzles of `world` since the last review (see `Go.Path`).
  """
  def since_review(player, world), do: get(player, {:since_review, world}, 0)

  @doc "Counts a finished puzzle of the path: a new one, or a review."
  def count_path(player, world, :review), do: put(player, {:since_review, world}, 0)

  def count_path(player, world, :new),
    do: put(player, {:since_review, world}, since_review(player, world) + 1)

  @doc """
  The place of a player in the stories: `%{story: id, moment: n}` (the
  moment from 1), or nil before the first story.
  """
  def story(player), do: get(player, :story, nil)

  def put_story(player, place), do: put(player, :story, place)

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

      put(player, :attempts, [attempt | attempts(player)])
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
    case :ets.lookup(@table, {player, key}) do
      [{_, value}] -> value
      [] -> default
    end
  end

  defp put(player, key, value) do
    :ets.insert(@table, {{player, key}, value})
    :ok
  end
end
