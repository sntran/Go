defmodule Go.Stories do
  @moduledoc """
  The story games. A story is one 9x9 game of `Go.SelfPlay`. Each puzzle of
  the story is a moment of the game: the position before a key move of
  Blue. Between the moments, the game goes on with its own moves (the main
  line). At the end, the page shows the score (`Go.Score`).

  The mix task `mix go.gen.stories` makes the stories, and writes
  `priv/puzzles/stories.json`. The app reads the file one time.

  A moment passes the normal puzzle checks (`Go.Puzzles.Check`), and its
  answer is the move of the game. A check that takes more than 20 s does
  not give a moment. Two moments are at least 4 moves apart.
  A game makes a story only if both sides still have 10 stones or more at
  the end, Blue wins, and it gives at least 5 moments. The first moment
  must fit in the 5x5 view, and the last one must need the full board.
  """

  alias Go.{Board, Goal, Puzzle, Puzzles, Score, SelfPlay, Solver}
  alias Go.Puzzles.{Check, Generator, Grade}

  @key {__MODULE__, :stories}
  @min_moments 5
  @gap 4
  @check_ms 20_000
  @views [5, 7, 9]

  ## Reading

  @doc "All stories, in order."
  def all do
    case :persistent_term.get(@key, nil) do
      nil ->
        stories = load(path())
        :persistent_term.put(@key, stories)
        stories

      stories ->
        stories
    end
  end

  @doc "The story with this id, or nil."
  def get(id), do: Enum.find(all(), &(&1.id == id))

  @doc "The path of the stories file."
  def path, do: Application.app_dir(:go, "priv/puzzles/stories.json")

  @doc "Reads a stories file."
  def load(path) do
    path |> File.read!() |> JSON.decode!() |> Map.fetch!("stories") |> Enum.map(&from_map/1)
  end

  @doc "The board after the first `n` moves of the main line."
  @spec board_at(map(), non_neg_integer()) :: Board.t()
  def board_at(story, n) do
    story.moves
    |> Enum.take(n)
    |> Enum.reduce(Board.new(9), fn {color, move}, b ->
      {:ok, b, _} = Board.play(b, color, move)
      b
    end)
  end

  @doc """
  The view: the smallest top-left window (5, 7 or 9 points) that holds all
  the stones of the board and the extra points, and at least `min`.
  """
  @spec view(Board.t(), pos_integer(), [Board.point()]) :: pos_integer()
  def view(board, min \\ 5, extra \\ []) do
    points = Map.keys(board.stones) ++ extra
    far = Enum.reduce(points, 0, fn {r, c}, acc -> max(acc, max(r, c)) end)
    Enum.find(@views, 9, &(&1 > far and &1 >= min))
  end

  ## Making

  @doc """
  Makes `count` stories from self-play games, from the seed `from` on.
  The option `report` is a function that gets the seed and the moments of
  each game. Gives `%{stories: stories, games: tried}`.
  """
  def build(count, opts \\ []) do
    from = Keyword.get(opts, :from, 1)
    report = Keyword.get(opts, :report, fn _seed, _moments -> :ok end)

    found =
      Stream.iterate(from, &(&1 + 1))
      |> Stream.chunk_every(System.schedulers_online())
      |> Stream.flat_map(fn seeds ->
        seeds
        |> Task.async_stream(&{&1, scan_good_game(&1)}, ordered: true, timeout: :infinity)
        |> Enum.map(fn {:ok, {seed, moments} = result} ->
          report.(seed, moments)
          result
        end)
      end)
      |> Stream.with_index(1)
      |> Stream.filter(fn {{seed, moments}, _tried} -> good_story?(seed, moments) end)
      |> Enum.take(count)

    tried = found |> List.last() |> elem(1)

    stories =
      found
      |> Enum.with_index(1)
      |> Enum.map(fn {{{seed, moments}, _}, k} -> story(k, seed, moments) end)

    %{stories: stories, games: tried}
  end

  # At least 5 moments. The first moment fits in the 5x5 view, and the
  # last one needs the full board: the view grows from a corner.
  defp good_story?(_seed, moments) when length(moments) < @min_moments, do: false

  defp good_story?(seed, moments) do
    moves = SelfPlay.game(seed)
    {first, _} = hd(moments)
    {last, _} = List.last(moments)
    view(board_from(moves, first)) == 5 and view(board_from(moves, last)) == 9
  end

  # A game makes a good story when both sides still have 10 stones or more
  # at the end, and Blue wins. Else it gives no moments (no scan needed).
  defp scan_good_game(seed) do
    moves = SelfPlay.game(seed)
    final = board_from(moves, length(moves))
    score = Score.count(final)

    if score.blue.stones >= 10 and score.red.stones >= 10 and score.winner == :blue,
      do: scan(moves),
      else: []
  end

  defp story(k, seed, moments) do
    moves = SelfPlay.game(seed)
    id = "story-#{k}"

    {moments, _view} =
      moments
      |> Enum.with_index(1)
      |> Enum.map_reduce(5, fn {{index, puzzle}, m}, min ->
        board = board_from(moves, index)
        view = view(board, min, [puzzle.answer])
        puzzle = %{puzzle | id: "#{id}-#{m}"}
        {%{index: index, view: view, puzzle: %{puzzle | book: Puzzles.book(puzzle)}}, view}
      end)

    final = board_from(moves, length(moves))
    score = Score.count(final)

    %{
      id: id,
      title: "Story #{k}",
      seed: seed,
      moves: moves,
      moments: moments,
      score: %{blue: score.blue.total, red: score.red.total, winner: score.winner}
    }
  end

  defp board_from(moves, n), do: board_at(%{moves: moves}, n)

  @doc """
  Finds the moments of a game: the positions before a blue move where a
  capture or an escape puzzle passes the checks, and the move of the game
  is its answer. Gives `[{index, puzzle}]`, at least 4 moves apart.
  """
  def scan(moves) do
    {found, _board} =
      moves
      |> Enum.with_index()
      |> Enum.reduce({[], Board.new(9)}, fn {{color, move}, i}, {acc, board} ->
        acc =
          with :blue <- color,
               {_, _} <- move,
               nil <- board.ko,
               true <- far_enough?(acc, i),
               %Puzzle{} = puzzle <- moment(board, move) do
            [{i, puzzle} | acc]
          else
            _ -> acc
          end

        {:ok, board, _} = Board.play(board, color, move)
        {acc, board}
      end)

    Enum.reverse(found)
  end

  defp far_enough?([], _i), do: true
  defp far_enough?([{j, _} | _], i), do: i - j >= @gap

  # A capture puzzle (a red group that Blue catches in 3 moves or fewer),
  # else an escape puzzle (a blue group that Red catches in 3 moves or
  # fewer if Blue does nothing). The move of the game must be the answer.
  defp moment(board, move) do
    captures =
      for g <- Board.groups(board, :red), length(g.liberties) <= 3 do
        target = Enum.min(g.stones)
        n = Solver.moves_to_capture(board, target, :blue, :blue, 3)
        n && %{type: :capture, target: target, moves: n}
      end

    escapes =
      for g <- Board.groups(board, :blue), length(g.liberties) <= 3 do
        target = Enum.min(g.stones)

        n =
          Enum.find(
            1..3,
            &Solver.attacker_wins?(board, target, :red, :red, &1, passes_only: true)
          )

        n && %{type: :escape, target: target, moves: n}
      end

    (captures ++ escapes)
    |> Enum.reject(&is_nil/1)
    |> Enum.find_value(fn goal ->
      # A check that takes too long does not give a moment.
      case Go.Think.within(@check_ms, fn ->
             if Goal.good_move?(goal, board, goal.moves, move), do: checked(board, goal, move)
           end) do
        {:ok, puzzle} -> puzzle
        :timeout -> nil
      end
    end)
  end

  defp checked(board, goal, move) do
    blue = for {p, :blue} <- board.stones, do: p
    red = for {p, :red} <- board.stones, do: p

    puzzle = %Puzzle{
      world: goal.type,
      goal: goal,
      size: 9,
      blue: Enum.sort(blue),
      red: Enum.sort(red),
      answer: move,
      template: "story",
      source: :generated
    }

    report = Check.run(puzzle)

    if report.ok and report.good == [move] do
      grade = Grade.of(puzzle, report)

      %{
        puzzle
        | title: Generator.title(puzzle),
          say: say(goal),
          grade: grade,
          hide_roads: false
      }
    end
  end

  defp say(%{type: :capture}),
    do: "This is a moment of the game. Look at the board, and find the weak red fort. Catch it!"

  defp say(%{type: :escape}),
    do: "This is a moment of the game. Red attacks one of your forts. Find it, and save it!"

  ## The file

  @doc "Writes the stories to a file."
  def write(stories, path) do
    body = """
    {
      "version": 1,
      "stories": [
    #{Enum.map_join(stories, ",\n", &("    " <> JSON.encode!(to_map(&1))))}
      ]
    }
    """

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, body)
  end

  defp to_map(s) do
    %{
      "id" => s.id,
      "title" => s.title,
      "seed" => s.seed,
      "moves" => Enum.map(s.moves, fn {c, m} -> [Atom.to_string(c), move_to(m)] end),
      "moments" =>
        Enum.map(s.moments, fn m ->
          %{"index" => m.index, "view" => m.view, "puzzle" => Puzzle.to_map(m.puzzle)}
        end),
      "score" => %{
        "blue" => s.score.blue,
        "red" => s.score.red,
        "winner" => Atom.to_string(s.score.winner)
      }
    }
  end

  defp from_map(m) do
    %{
      id: m["id"],
      title: m["title"],
      seed: m["seed"],
      moves: Enum.map(m["moves"], fn [c, mv] -> {color(c), move_from(mv)} end),
      moments:
        Enum.map(m["moments"], fn x ->
          %{index: x["index"], view: x["view"], puzzle: Puzzle.from_map(x["puzzle"])}
        end),
      score: %{
        blue: m["score"]["blue"],
        red: m["score"]["red"],
        winner: color(m["score"]["winner"])
      }
    }
  end

  defp move_to(:pass), do: "pass"
  defp move_to({r, c}), do: [r, c]
  defp move_from("pass"), do: :pass
  defp move_from([r, c]), do: {r, c}
  defp color("blue"), do: :blue
  defp color("red"), do: :red

  @doc "Removes the stories from memory, so that the next call reads the file again."
  def reload, do: :persistent_term.erase(@key)
end
