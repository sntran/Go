defmodule Go.LifeTest do
  use ExUnit.Case, async: true

  alias Go.{Board, Life}

  test "a group with two eyes is alive" do
    board =
      Board.from_rows([
        ". B . B R",
        "B B B B R",
        "R R R R R",
        ". . . . .",
        ". . . . ."
      ])

    assert Life.alive?(board, {1, 1})
    refute Life.alive?(board, {2, 2})
  end

  test "a group with one eye is not alive" do
    board =
      Board.from_rows([
        ". B R . .",
        "B B R . .",
        "R R R . .",
        ". . . . .",
        ". . . . ."
      ])

    refute Life.alive?(board, {1, 1})
  end

  test "a group with many liberties but no eyes is not alive" do
    board = Board.new(5, [{2, 1}, {2, 2}, {2, 3}])
    refute Life.alive?(board, {2, 2})
  end

  test "a group that runs out on an empty board is not alive" do
    board = Board.new(5, [{1, 3}, {0, 4}], [{0, 3}, {0, 2}])
    refute Life.alive?(board, {0, 3})
  end
end
