defmodule Go.Puzzles.Check do
  @moduledoc """
  The checks that each puzzle of the bank must pass. They are true in real
  Go, not only in the move limit:

    * It has exactly one correct first move.
    * It cannot be solved in fewer moves. For an escape puzzle: if Blue
      does nothing, Red needs all its moves to capture the fort.
    * Each tempting wrong move of a capture puzzle really fails: Blue
      cannot capture Red in the move limit plus `Go.Goal.deep/0` moves.
      A tempting move touches the target group or takes stones.
    * In an escape puzzle, the fort lives also after the move limit: a
      blue move is correct only if Red cannot capture the fort in the move
      limit plus `Go.Goal.deep/0` moves (see `Go.Goal`).

  The fast checks run first. The deep checks run only when the fast
  checks pass. The duplicate check is in `Go.Puzzles.Symmetry`.
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
  Checks a puzzle. `deep` is the number of extra moves for the deep checks
  (`Go.Goal.deep/0` by default).
  """
  @spec run(Puzzle.t(), keyword()) :: report()
  def run(%Puzzle{} = puzzle, opts \\ []) do
    deep = Keyword.get(opts, :deep, Goal.deep())
    goal = puzzle.goal
    board = Puzzle.board(puzzle)
    n = goal.moves

    errors =
      add(
        [],
        Board.get(board, goal.target) != Goal.defender(goal),
        "the target is not a #{Goal.defender(goal)} stone"
      )

    good = if errors == [], do: Goal.good_moves(goal, board, n), else: []
    answer = puzzle.answer || List.first(good)
    traps = if errors == [], do: traps(goal, board, good), else: []

    errors =
      errors
      |> add(
        good != [answer],
        "the correct first moves are #{inspect(good)}, not exactly [#{inspect(answer)}]"
      )
      |> add(not needs_all_moves?(goal, board, n), "it can be solved in fewer moves")

    # The deep checks are slow. They run only when the fast checks pass.
    errors =
      if errors == [] do
        errors
        |> add(Enum.reject(traps, &trap_fails?(goal, board, n + deep, &1)), fn bad ->
          "the tempting moves #{inspect(bad)} do not fail at a depth of #{n + deep}"
        end)
        |> add(
          not answer_holds?(goal, board, n + deep, deep, answer),
          "the answer does not hold at a depth of #{n + deep}"
        )
      else
        errors
      end
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

  defp needs_all_moves?(_goal, _board, 1), do: true

  defp needs_all_moves?(%{type: :capture} = goal, board, n),
    do: not Goal.reachable?(goal, board, n - 1)

  # If Blue does nothing, Red needs all its moves to capture the fort.
  defp needs_all_moves?(%{type: :escape} = goal, board, n) do
    Solver.attacker_wins?(board, goal.target, :red, :red, n, passes_only: true) and
      not Solver.attacker_wins?(board, goal.target, :red, :red, n - 1, passes_only: true)
  end

  defp trap_fails?(%{type: :capture} = goal, board, depth, trap) do
    {:ok, next, _} = Board.play(board, :blue, trap)

    not Solver.captured?(next, goal.target, :red) and
      not Solver.attacker_wins?(next, goal.target, :blue, :red, depth - 1)
  end

  # A wrong escape move is wrong in real Go already (see Go.Goal).
  defp trap_fails?(%{type: :escape}, _board, _depth, _trap), do: true

  defp answer_holds?(_goal, _board, _depth, _deep, nil), do: false
  defp answer_holds?(%{type: :capture}, _board, _depth, _deep, _answer), do: true

  defp answer_holds?(%{type: :escape} = goal, board, depth, deep, answer) do
    # With the default depth, the good-move check of Go.Goal did this already.
    deep == Goal.deep() or
      (
        {:ok, next, _} = Board.play(board, :blue, answer)
        not Solver.attacker_wins?(next, goal.target, :red, :red, depth)
      )
  end
end
