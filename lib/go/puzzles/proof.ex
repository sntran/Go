defmodule Go.Puzzles.Proof do
  @moduledoc """
  The final check of a kept puzzle. It looks to the move limit plus 12
  moves, with no 5-road rule. Only a capture or Benson's algorithm (see
  `Go.Life`) ends the search early, so a result is a proof.

  The claims:

    * Escape: the fort lives after the answer line. The bank drops (or the
      starter set must fix) a puzzle when the check proves that the fort
      dies.
    * Capture: each tempting wrong first move fails. When the check proves
      that the wrong move still catches Red later, the puzzle stays: the
      text says only that Blue cannot catch Red in the moves that are
      left, as "mate in N" in chess. The bank counts these late catches.

  Each claim has a time limit. A claim that does not finish in time is
  "unproven", and the puzzle stays.
  """

  alias Go.{Board, Puzzle, Solver, Think}
  alias Go.Puzzles.Check

  @extra 12

  @type claim :: %{
          kind: :fort_lives | :trap_fails,
          at: Board.point() | nil,
          result: :holds | false | :unproven
        }

  @doc "The extra moves of the final check."
  def extra, do: @extra

  @doc """
  Checks the claims of a puzzle. `ms` is the time limit of each claim.
  Gives the list of claims and their results.
  """
  @spec run(Puzzle.t(), timeout()) :: [claim()]
  def run(%Puzzle{goal: %{type: :escape} = goal} = puzzle, ms) do
    line = Go.Play.answer_line(puzzle)

    board =
      Enum.reduce(line, Puzzle.board(puzzle), fn {color, move}, b ->
        {:ok, b, _} = Board.play(b, color, move)
        b
      end)

    reds = Enum.count(line, &match?({:red, _}, &1))

    to_move =
      if match?([_ | _], line) and elem(List.last(line), 0) == :blue, do: :red, else: :blue

    left = max(goal.moves - reds, 0) + @extra

    result =
      prove(ms, fn ->
        Solver.attacker_wins?(board, goal.target, :red, to_move, left, life: true)
      end)

    [%{kind: :fort_lives, at: nil, result: result}]
  end

  def run(%Puzzle{goal: %{type: :capture} = goal} = puzzle, ms) do
    board = Puzzle.board(puzzle)

    for trap <- Check.traps(goal, board, [puzzle.answer]) do
      {:ok, next, _} = Board.play(board, :blue, trap)

      result =
        prove(ms, fn ->
          Solver.attacker_wins?(next, goal.target, :blue, :red, goal.moves - 1 + @extra,
            life: true
          )
        end)

      %{kind: :trap_fails, at: trap, result: result}
    end
  end

  # The claim holds when the attacker cannot capture.
  defp prove(ms, fun) do
    case Think.within(ms, fun) do
      {:ok, false} -> :holds
      {:ok, true} -> false
      :timeout -> :unproven
    end
  end

  @doc "True when a claim proves that the fort of an escape puzzle dies."
  def fort_dies?(claims), do: Enum.any?(claims, &(&1.kind == :fort_lives and &1.result == false))
end
