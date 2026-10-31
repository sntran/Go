defmodule Go.Puzzles.Grade do
  @moduledoc """
  The difficulty grade of a puzzle. The levers:

    * more moves to read,
    * more tempting wrong moves (traps),
    * an answer that does not touch the target (a net),
    * a bigger board.

  On the hardest levels, the road counts are hidden.
  """

  @hide_roads_from 40

  @doc "Gives the grade from the check report of `Go.Puzzles.Check`."
  @spec of(Go.Puzzle.t(), map()) :: map()
  def of(puzzle, report) do
    moves = puzzle.goal.moves
    traps = length(report.traps)
    touches = report.touches_target
    score = moves * 10 + traps * 4 + if(touches, do: 0, else: 10) + (puzzle.size - 5) * 2
    %{moves: moves, traps: traps, touches_target: touches, size: puzzle.size, score: score}
  end

  @doc "True when the road counts must be hidden for this grade."
  def hide_roads?(%{score: score}), do: score >= @hide_roads_from
end
