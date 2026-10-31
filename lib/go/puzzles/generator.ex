defmodule Go.Puzzles.Generator do
  @moduledoc """
  Makes puzzles from the templates in `Go.Puzzles.Templates`.

  For each base position of a template, it makes variations: shifts on the
  board, an added helper stone, a moved helper stone, and swapped sides
  (Blue and Red change places, so a capture becomes an escape). The 8
  symmetries are not checked one by one: all 8 copies of a position have
  the same answer, so the generator checks one copy and shows a random
  copy.

  The solver checks each variation (see `Go.Puzzles.Check`), and the
  duplicate check removes copies of puzzles that it already has.

  It also counts the yield: the number of good, different puzzles from
  each template.
  """

  alias Go.{Board, Puzzle, Solver}
  alias Go.Puzzles.{Check, Grade, Symmetry, Templates}

  @doc """
  Makes the puzzles. Options:

    * `:seed`: the seed of the random choices (the default is 1).
    * `:known`: puzzles that are in the bank already, for the duplicate
      check.
    * `:templates`: the templates to use (all by default).

  Gives `%{puzzles: puzzles, stats: stats}`.
  """
  @spec run(keyword()) :: %{puzzles: [Puzzle.t()], stats: [map()]}
  def run(opts \\ []) do
    :rand.seed(:exsss, {Keyword.get(opts, :seed, 1), 7, 11})
    seen = MapSet.new(Keyword.get(opts, :known, []), &position_key/1)
    templates = Keyword.get(opts, :templates, Templates.all())

    {results, _seen} =
      Enum.map_reduce(templates, seen, fn template, seen ->
        {straight, seen} = generate(template, template.type, false, seen)

        if template.swap do
          {swapped, seen} = generate(template, :escape, true, seen)
          {[straight, swapped], seen}
        else
          {[straight], seen}
        end
      end)

    results = List.flatten(results)

    %{
      puzzles: Enum.flat_map(results, & &1.puzzles),
      stats: Enum.map(results, &Map.delete(&1, :puzzles))
    }
  end

  defp generate(template, type, swapped?, seen) do
    name = if swapped?, do: template.name <> "_swapped", else: template.name

    variations =
      template.bases.()
      |> Enum.flat_map(&variations(&1, template.helpers))
      |> Enum.map(&if(swapped?, do: swap(&1), else: &1))

    acc = %{
      template: name,
      variations: length(variations),
      valid: 0,
      different: 0,
      good: 0,
      good_list: []
    }

    {acc, seen} =
      Enum.reduce(variations, {acc, seen}, fn base, {acc, seen} ->
        puzzle = to_puzzle(base, template, name, type, base.max)

        cond do
          not valid?(base, type) ->
            {acc, seen}

          MapSet.member?(seen, position_key(puzzle)) ->
            {%{acc | valid: acc.valid + 1}, seen}

          true ->
            seen = MapSet.put(seen, position_key(puzzle))
            acc = %{acc | valid: acc.valid + 1, different: acc.different + 1}

            case solve(puzzle, min_moves(template, swapped?), base.max) do
              nil -> {acc, seen}
              good -> {%{acc | good: acc.good + 1, good_list: [good | acc.good_list]}, seen}
            end
        end
      end)

    kept = keep(Enum.reverse(acc.good_list), template.limit)

    puzzles =
      kept
      |> Enum.map(&Symmetry.transform(&1, Enum.random(Symmetry.all())))
      |> Enum.with_index(1)
      |> Enum.map(fn {p, i} ->
        %{p | id: "#{name}-#{String.pad_leading(Integer.to_string(i), 2, "0")}"}
      end)

    {%{
       template: name,
       variations: acc.variations,
       valid: acc.valid,
       different: acc.different,
       good: acc.good,
       kept: length(puzzles),
       puzzles: puzzles
     }, seen}
  end

  # Keep `limit` puzzles, spread over all the grades.
  defp keep(puzzles, limit) do
    sorted = Enum.sort_by(puzzles, &{&1.grade.score, Symmetry.key(&1)})
    n = length(sorted)

    if n <= limit do
      sorted
    else
      Enum.map(0..(limit - 1), fn i -> Enum.at(sorted, div(i * (n - 1), limit - 1)) end)
      |> Enum.uniq()
    end
  end

  @doc "The variations of a base: the base, its shifts, and its helper stones."
  def variations(base, helpers?) do
    shifted = [base | shifts(base)]

    if helpers? do
      shifted ++ Enum.flat_map([base], &(add_helper(&1) ++ move_helper(&1)))
    else
      shifted
    end
  end

  defp shifts(base) do
    for dr <- -2..2,
        dc <- -2..2,
        {dr, dc} != {0, 0},
        moved = shift(base, dr, dc),
        moved != nil,
        do: moved
  end

  defp shift(base, dr, dc) do
    f = fn {r, c} -> {r + dr, c + dc} end
    points = Enum.map(base.blue ++ base.red, f)

    if Enum.all?(points, fn {r, c} -> r >= 0 and r < base.size and c >= 0 and c < base.size end) do
      %{base | blue: Enum.map(base.blue, f), red: Enum.map(base.red, f), target: f.(base.target)}
    end
  end

  defp add_helper(base) do
    board = Board.new(base.size, base.blue, base.red)

    for p <- near(board, base.target, 3), color <- [:blue, :red] do
      if color == :blue, do: %{base | blue: [p | base.blue]}, else: %{base | red: [p | base.red]}
    end
  end

  defp move_helper(base) do
    board = Board.new(base.size, base.blue, base.red)
    target_group = Board.group(board, base.target).stones

    for {p, color} <- board.stones,
        p not in target_group,
        q <- Board.neighbors(board, p) ++ Board.diagonals(board, p),
        Board.get(board, q) == nil do
      move = fn list -> [q | List.delete(list, p)] end

      if color == :blue,
        do: %{base | blue: move.(base.blue)},
        else: %{base | red: move.(base.red)}
    end
  end

  defp near(board, target, dist) do
    {tr, tc} = target

    for {r, c} <- Board.points(board),
        abs(r - tr) <= dist and abs(c - tc) <= dist,
        Board.get(board, {r, c}) == nil,
        do: {r, c}
  end

  defp swap(base), do: %{base | blue: base.red, red: base.blue}

  defp valid?(base, type) do
    board = Board.new(base.size, base.blue, base.red)
    defender = if type == :capture, do: :red, else: :blue

    length(Enum.uniq(base.blue ++ base.red)) == length(base.blue ++ base.red) and
      Board.get(board, base.target) == defender and
      Enum.all?(Board.groups(board, :blue) ++ Board.groups(board, :red), &(&1.liberties != []))
  end

  # The key of the position only (not the move count), for duplicates.
  defp position_key(puzzle), do: Symmetry.key(%{puzzle | goal: %{puzzle.goal | moves: 0}})

  defp to_puzzle(base, template, name, type, moves) do
    %Puzzle{
      world: type,
      goal: %{type: type, target: base.target, moves: moves},
      size: base.size,
      blue: Enum.sort(base.blue),
      red: Enum.sort(base.red),
      template: name,
      source: :generated,
      say: say(template, type),
      hint: hint(template, type),
      better: if(type == template.type, do: template.better),
      win: nil
    }
  end

  defp say(%{type: type} = t, type), do: t.say
  defp say(_t, :escape), do: "Red wants to catch your tower. Save it!"

  defp hint(%{type: type} = t, type), do: t.hint
  defp hint(_t, :escape), do: "Count the roads of your tower. Which move gives it the most roads?"

  # A swapped puzzle needs 2 moves or more to show its idea.
  defp min_moves(template, false), do: template.min
  defp min_moves(_template, true), do: 2

  # Finds the move count for a puzzle, checks it, and adds the texts.
  defp solve(%Puzzle{goal: %{type: :capture}} = p, min, max) do
    board = Puzzle.board(p)

    case Solver.moves_to_capture(board, p.goal.target, :blue, :blue, max) do
      n when is_integer(n) and n >= min -> checked(%{p | goal: %{p.goal | moves: n}})
      _ -> nil
    end
  end

  defp solve(%Puzzle{goal: %{type: :escape}} = p, min, max) do
    board = Puzzle.board(p)
    # The fort must be in danger: Red catches it if Blue does nothing.
    max
    |> Range.new(min, -1)
    |> Enum.find_value(fn n ->
      if Solver.attacker_wins?(board, p.goal.target, :red, :red, n, passes_only: true),
        do: checked(%{p | goal: %{p.goal | moves: n}})
    end)
  end

  defp checked(puzzle) do
    report = Check.run(puzzle)

    if report.ok do
      grade = Grade.of(puzzle, report)
      title = title(puzzle)
      trap_why = template_trap_why(puzzle)

      wrong =
        if trap_why,
          do: Map.new(report.traps, &{&1, %{what: nil, why: trap_why}}),
          else: %{}

      %{
        puzzle
        | answer: hd(report.good),
          grade: grade,
          hide_roads: Grade.hide_roads?(grade),
          title: title,
          wrong: wrong
      }
    end
  end

  defp template_trap_why(%Puzzle{template: name, goal: %{type: type}}) do
    Enum.find_value(Templates.all(), fn t ->
      if t.name == name and t.type == type, do: t.trap_why
    end)
  end

  @doc "The title of a puzzle, from its goal."
  def title(%Puzzle{goal: goal} = p) do
    board = Puzzle.board(p)
    many = length(Board.group(board, goal.target).stones) > 1
    moves = Go.Explain.moves(goal.moves)

    case goal.type do
      :capture -> "Catch the red #{if many, do: "fort", else: "tower"} in #{moves}"
      :escape -> "Save your #{if many, do: "fort", else: "tower"} for #{moves}"
    end
  end
end
