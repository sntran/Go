defmodule Go.Fixtures do
  @moduledoc """
  The two verified puzzles of the plan, for the tests.
  Coordinates are (row, column), from 0, row 0 at the top.
  """

  alias Go.Puzzle

  @doc """
  Edge chase, 5x5, capture in 2 moves. The red helper at (1,1) gives Red a
  real escape after the wrong move (0,4). Without it, Blue catches Red at
  the other corner some moves later.
  """
  def edge_chase do
    %Puzzle{
      id: "fixture-edge-chase",
      world: :capture,
      goal: %{type: :capture, target: {0, 3}, moves: 2},
      size: 5,
      blue: [{1, 3}],
      red: [{0, 3}, {1, 1}],
      answer: {0, 2},
      template: "edge_chase",
      wrong: %{{0, 4} => %{what: nil, why: nil, reply: {0, 2}}}
    }
  end

  @doc "Net, 9x9, capture in 3 moves."
  def net do
    %Puzzle{
      id: "fixture-net",
      world: :capture,
      goal: %{type: :capture, target: {4, 4}, moves: 3},
      size: 9,
      blue: [{3, 4}, {3, 5}, {4, 3}, {5, 3}],
      red: [{4, 4}, {4, 7}, {7, 4}],
      answer: {5, 5},
      template: "net"
    }
  end
end
