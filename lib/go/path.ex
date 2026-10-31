defmodule Go.Path do
  @moduledoc """
  The path through the puzzles of a world (see
  `docs/plans/puzzle-path.md`).

    * An idea is the template of a puzzle. The ideas of a world come in the
      order of their first puzzle in the world.
    * A puzzle is solved clean when the player solves it on the first try
      with no help (3 stars). Then its idea is known, and the path skips
      the other puzzles of the idea.
    * After help or a failure, the path gives the next puzzle of the same
      idea. When no puzzle of an idea is left, the idea is practised.
    * When 2 ideas or more are finished (known or practised), each 4th
      puzzle is a review: a skipped puzzle of an earlier, finished idea.

  The results come from `Go.Progress`: a map from a puzzle id to
  `%{status: :solved, stars: n}`, `%{status: :learned, due: date}` or
  `%{status: :tried}`.
  """

  alias Go.{Puzzle, Puzzles}

  @review_every 4

  @doc """
  The ideas of a world, in order: `[%{idea: name, puzzles: puzzles}]`.
  """
  @spec ideas(atom()) :: [%{idea: String.t(), puzzles: [Puzzle.t()]}]
  def ideas(world) do
    world
    |> Puzzles.world()
    |> Enum.with_index()
    |> Enum.group_by(fn {p, _i} -> p.template end)
    |> Enum.map(fn {idea, list} -> {elem(hd(list), 1), idea, Enum.map(list, &elem(&1, 0))} end)
    |> Enum.sort()
    |> Enum.map(fn {_first, idea, puzzles} -> %{idea: idea, puzzles: puzzles} end)
  end

  @doc "True when the player solved a puzzle of the idea clean."
  def known?(%{puzzles: puzzles}, results),
    do: Enum.any?(puzzles, &match?(%{status: :solved, stars: 3}, results[&1.id]))

  @doc "The puzzles of the idea that the player can play now on the path."
  def open(%{puzzles: puzzles}, results, today),
    do: Enum.filter(puzzles, &open?(results[&1.id], today))

  defp open?(nil, _today), do: true
  defp open?(%{status: :learned, due: due}, today), do: Date.compare(today, due) != :lt
  defp open?(_result, _today), do: false

  @doc "True when the idea is known, or when no puzzle of it is left."
  def finished?(idea, results, today),
    do: known?(idea, results) or open(idea, results, today) == []

  @doc """
  The status of a puzzle for the world page: `:solved`, `:learned`,
  `:tried`, `:skipped` (its idea is known, and the player did not play
  it) or `:open`.
  """
  def status(puzzle, idea, results) do
    case results[puzzle.id] do
      %{status: status} -> status
      nil -> if known?(idea, results), do: :skipped, else: :open
    end
  end

  @doc """
  The next puzzle of the path, as `{puzzle, :new}` or `{puzzle, :review}`,
  or nil when the world is done. `since_review` is the number of puzzles
  since the last review (see `Go.Progress.path/2`).
  """
  @spec next(atom(), map(), non_neg_integer(), Date.t()) :: {Puzzle.t(), :new | :review} | nil
  def next(world, results, since_review, today) do
    ideas = ideas(world)
    {finished, rest} = Enum.split_with(ideas, &finished?(&1, results, today))
    current = List.first(rest)

    review =
      if length(finished) >= 2 and since_review >= @review_every - 1,
        do: review(finished, current, results)

    cond do
      review -> {review, :review}
      current -> {hd(open(current, results, today)), :new}
      true -> nil
    end
  end

  # The first skipped puzzle of the earliest finished idea.
  defp review(finished, current, results) do
    finished
    |> Enum.reject(&(current && &1.idea == current.idea))
    |> Enum.find_value(fn idea -> Enum.find(idea.puzzles, &(results[&1.id] == nil)) end)
  end

  @doc "The title of a review puzzle: only its goal, not its idea."
  def review_title(puzzle), do: Go.Puzzles.Generator.title(puzzle)

  @doc "The text of a review puzzle."
  def review_say, do: "A puzzle from before. Read the board first."

  @doc "The name of an idea for the world page."
  def name(idea) do
    Map.get(
      %{
        "capture_in_1" => "Close the last road",
        "edge_chase" => "Chase on the edge",
        "ladder" => "The ladder",
        "net" => "The net",
        "escape_extend" => "Run out",
        "escape_capture" => "Take to escape",
        "escape_connect" => "Join a friend",
        "edge_chase_swapped" => "Escape on the edge",
        "ladder_swapped" => "Escape the ladder"
      },
      idea,
      idea
    )
  end
end
