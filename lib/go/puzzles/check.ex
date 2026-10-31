defmodule Go.Puzzles.Check do
  @moduledoc """
  The checks that each puzzle of the bank must pass.

    * It has exactly one correct first move.
    * It cannot be solved in fewer moves.
    * Each tempting wrong move really fails, also deeper than the move
      limit. A tempting move touches the target group or takes stones.
    * In an escape puzzle, the fort lives also deeper than the move limit
      after the correct first move.

  The duplicate check is in `Go.Puzzles.Symmetry`.
  """

  alias Go.{Board, Goal, Puzzle, Solver}

  @type report :: %{
          ok: boolean(),
          errors: [String.t()],
          good: [Board.point()],
          traps: [Board.point()],
          touches_target: boolean()
        }

  @doc """
  Checks a puzzle. `deep` is the number of extra moves for the deeper
  checks (2 by default).
  """
  @spec run(Puzzle.t(), keyword()) :: report()
  def run(%Puzzle{} = puzzle, opts \\ []) do
    deep = Keyword.get(opts, :deep, 2)
    goal = puzzle.goal
    board = Puzzle.board(puzzle)
    n = goal.moves
    good = Goal.good_moves(goal, board, n)
    answer = puzzle.answer || List.first(good)
    traps = traps(goal, board, good)

    errors =
      []
      |> add(
        Board.get(board, goal.target) != Goal.defender(goal),
        "the target is not a #{Goal.defender(goal)} stone"
      )
      |> add(
        good != [answer],
        "the correct first moves are #{inspect(good)}, not exactly [#{inspect(answer)}]"
      )
      |> add(not needs_all_moves?(goal, board, n, answer), "it can be solved in fewer moves")
      |> add(Enum.reject(traps, &trap_fails?(goal, board, n + deep, &1)), fn bad ->
        "the tempting moves #{inspect(bad)} do not fail at a depth of #{n + deep}"
      end)
      |> add(
        not answer_holds?(goal, board, n + deep, answer),
        "the answer does not hold at a depth of #{n + deep}"
      )
      |> Enum.reverse()

    %{
      ok: errors == [],
      errors: errors,
      good: good,
      traps: traps,
      touches_target: answer != nil and touches?(board, goal.target, answer)
    }
  end

  defp add(errors, true, text), do: [text | errors]
  defp add(errors, false, _text), do: errors
  defp add(errors, [], _fun), do: errors
  defp add(errors, bad, fun) when is_list(bad), do: [fun.(bad) | errors]

  @doc """
  The tempting wrong first moves: legal moves that touch the target group,
  or that take stones.
  """
  @spec traps(Goal.t(), Board.t(), [Board.point()]) :: [Board.point()]
  def traps(goal, board, good) do
    board
    |> Board.legal_moves(:blue)
    |> Enum.reject(&(&1 in good))
    |> Enum.filter(fn p ->
      {:ok, _, captured} = Board.play(board, :blue, p)
      touches?(board, goal.target, p) or captured != []
    end)
  end

  @doc "Tells if a point is next to the group on `target`."
  def touches?(board, target, point) do
    case Board.group(board, target) do
      nil -> false
      g -> Enum.any?(Board.neighbors(board, point), &(&1 in g.stones))
    end
  end

  defp needs_all_moves?(_goal, _board, 1, _answer), do: true

  defp needs_all_moves?(%{type: :capture} = goal, board, n, _answer),
    do: not Goal.reachable?(goal, board, n - 1)

  # An escape puzzle needs all its moves when a shorter horizon lets other
  # first moves work too.
  defp needs_all_moves?(%{type: :escape} = goal, board, n, answer),
    do: Goal.good_moves(goal, board, n - 1) != [answer]

  defp trap_fails?(%{type: :capture} = goal, board, depth, trap) do
    {:ok, next, _} = Board.play(board, :blue, trap)

    not Solver.captured?(next, goal.target, :red) and
      not Solver.attacker_wins?(next, goal.target, :blue, :red, depth - 1)
  end

  defp trap_fails?(%{type: :escape} = goal, board, _depth, trap) do
    not Goal.good_move?(goal, board, goal.moves, trap)
  end

  defp answer_holds?(_goal, _board, _depth, nil), do: false
  defp answer_holds?(%{type: :capture}, _board, _depth, _answer), do: true

  defp answer_holds?(%{type: :escape} = goal, board, depth, answer) do
    {:ok, next, _} = Board.play(board, :blue, answer)
    not Solver.attacker_wins?(next, goal.target, :red, :red, depth)
  end
end
