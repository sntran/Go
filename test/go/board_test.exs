defmodule Go.BoardTest do
  use ExUnit.Case, async: true

  alias Go.Board

  describe "capture" do
    test "a stone with no liberty is captured" do
      board = Board.new(5, [{1, 2}, {2, 1}, {3, 2}], [{2, 2}])
      assert {:ok, board, [{2, 2}]} = Board.play(board, :blue, {2, 3})
      assert Board.get(board, {2, 2}) == nil
    end

    test "a group of stones is captured together" do
      board = Board.from_rows([". . . . .", ". B B . .", "B R R . .", ". B B . .", ". . . . ."])
      assert {:ok, board, captured} = Board.play(board, :blue, {2, 3})
      assert captured == [{2, 1}, {2, 2}]
      assert Board.groups(board, :red) == []
    end

    test "a stone in the corner has 2 liberties, and on the edge 3" do
      board = Board.new(5, [], [{0, 0}, {0, 2}, {2, 2}])
      assert Board.liberty_count(board, {0, 0}) == 2
      assert Board.liberty_count(board, {0, 2}) == 3
      assert Board.liberty_count(board, {2, 2}) == 4
    end

    test "stones that touch only corner to corner are not connected" do
      board = Board.new(5, [{1, 1}, {2, 2}])
      assert length(Board.groups(board, :blue)) == 2
      assert Board.group(board, {1, 1}).stones == [{1, 1}]
    end
  end

  describe "illegal moves" do
    test "a move on an occupied point is illegal" do
      board = Board.new(5, [{2, 2}])
      assert Board.play(board, :red, {2, 2}) == {:error, :occupied}
    end

    test "a move off the board is illegal" do
      assert Board.play(Board.new(5), :blue, {5, 0}) == {:error, :off_board}
    end

    test "suicide is illegal" do
      board = Board.new(5, [{0, 1}, {1, 0}])
      assert Board.play(board, :red, {0, 0}) == {:error, :suicide}
    end

    test "a move with no liberty is legal when it captures" do
      # The red stones have one liberty: (0,0). A blue stone there has no
      # liberty of its own, but it captures.
      board = Board.from_rows([". R B . .", "R B . . .", "B . . . .", ". . . . .", ". . . . ."])
      assert {:ok, _board, captured} = Board.play(board, :blue, {0, 0})
      assert captured == [{0, 1}, {1, 0}]
    end
  end

  describe "ko" do
    setup do
      # Blue at (1,2) takes the red stone at (1,1). Then the blue stone has
      # only 1 liberty: the point of the red stone that it took.
      board =
        Board.from_rows([
          ". B R . .",
          "B R . R .",
          ". B R . .",
          ". . . . .",
          ". . . . ."
        ])

      {:ok, board, [{1, 1}]} = Board.play(board, :blue, {1, 2})
      %{board: board}
    end

    test "a player cannot take back at once", %{board: board} do
      assert board.ko == {1, 1}
      assert Board.play(board, :red, {1, 1}) == {:error, :ko}
    end

    test "after a move elsewhere, the take-back is legal", %{board: board} do
      {:ok, board, _} = Board.play(board, :red, {4, 4})
      {:ok, board, _} = Board.play(board, :blue, {4, 0})
      assert {:ok, _board, [{1, 2}]} = Board.play(board, :red, {1, 1})
    end

    test "a pass also ends the ko", %{board: board} do
      {:ok, board, []} = Board.play(board, :red, :pass)
      assert board.ko == nil
    end
  end

  test "rows of text give the same board back" do
    rows = [". B . . .", ". R B . .", ". . . . .", ". . . . .", "R . . . ."]
    assert rows |> Board.from_rows() |> Board.to_rows() == rows
  end
end
