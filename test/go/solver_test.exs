defmodule Go.SolverTest do
  use ExUnit.Case, async: true

  alias Go.{Board, Fixtures, Goal, Puzzle, Solver}

  describe "edge chase fixture" do
    setup do
      p = Fixtures.edge_chase()
      %{p: p, board: Puzzle.board(p)}
    end

    test "Blue captures in 2 moves, but not in 1", %{board: board} do
      assert Solver.attacker_wins?(board, {0, 3}, :blue, :blue, 2)
      refute Solver.attacker_wins?(board, {0, 3}, :blue, :blue, 1)
      assert Solver.moves_to_capture(board, {0, 3}, :blue, :blue, 5) == 2
    end

    test "(0,2) is the only answer", %{p: p, board: board} do
      assert Goal.good_moves(p.goal, board, 2) == [{0, 2}]
    end

    test "the line: Blue (0,2), Red (0,4), Blue (1,4) captures both red stones", %{board: board} do
      {:ok, board, []} = Board.play(board, :blue, {0, 2})
      {:ok, board, []} = Board.play(board, :red, {0, 4})
      assert {:ok, _board, [{0, 3}, {0, 4}]} = Board.play(board, :blue, {1, 4})
    end

    test "after the wrong move (0,4), Red runs to (0,2) and has 2 liberties", %{board: board} do
      {:ok, board, []} = Board.play(board, :blue, {0, 4})
      {:ok, board, []} = Board.play(board, :red, {0, 2})
      assert Board.liberty_count(board, {0, 3}) == 2
      refute Solver.attacker_wins?(board, {0, 3}, :blue, :blue, 1)
    end
  end

  describe "net fixture" do
    setup do
      p = Fixtures.net()
      %{p: p, board: Puzzle.board(p)}
    end

    test "there are 74 legal first moves, and only (5,5) works", %{p: p, board: board} do
      assert length(Board.legal_moves(board, :blue)) == 74
      assert Goal.good_moves(p.goal, board, 3) == [{5, 5}]
    end

    test "the answer does not touch the target", %{board: board} do
      refute {5, 5} in Board.neighbors(board, {4, 4})
    end

    test "the line captures 3 stones", %{board: board} do
      moves = [blue: {5, 5}, red: {5, 4}, blue: {6, 4}, red: {4, 5}]

      board =
        Enum.reduce(moves, board, fn {color, m}, b ->
          {:ok, b, []} = Board.play(b, color, m)
          b
        end)

      assert {:ok, _board, captured} = Board.play(board, :blue, {4, 6})
      assert length(captured) == 3
    end

    test "if Red goes to (4,5) first, Blue still captures", %{board: board} do
      moves = [blue: {5, 5}, red: {4, 5}, blue: {4, 6}, red: {5, 4}]

      board =
        Enum.reduce(moves, board, fn {color, m}, b ->
          {:ok, b, []} = Board.play(b, color, m)
          b
        end)

      assert {:ok, _board, captured} = Board.play(board, :blue, {6, 4})
      assert length(captured) == 3
    end

    @tag timeout: 120_000
    test "after each tempting move, Red survives also at a depth of 8 moves", %{board: board} do
      for trap <- [{4, 5}, {5, 4}] do
        {:ok, next, []} = Board.play(board, :blue, trap)
        refute Solver.attacker_wins?(next, {4, 4}, :blue, :red, 8), "trap #{inspect(trap)}"
      end
    end
  end

  describe "escape" do
    test "a tower in atari that runs out has 3 liberties" do
      board = Board.new(5, [{2, 2}], [{1, 2}, {2, 1}, {3, 2}])
      assert Solver.attacker_wins?(board, {2, 2}, :red, :red, 1)
      refute Solver.attacker_wins?(board, {2, 2}, :red, :blue, 1)
    end

    test "the sound cut: L liberties need L attacker moves" do
      board = Board.new(9, [], [{4, 4}])
      refute Solver.attacker_wins?(board, {4, 4}, :blue, :blue, 3)
    end

    test "a defender that only passes is captured when its liberties run out" do
      board = Board.new(5, [{2, 2}], [{1, 2}, {2, 1}])
      assert Solver.attacker_wins?(board, {2, 2}, :red, :red, 2, passes_only: true)
      refute Solver.attacker_wins?(board, {2, 2}, :red, :red, 1, passes_only: true)
    end
  end

  test "the candidates are near the fight" do
    board = Board.new(9, [{3, 4}, {3, 5}, {4, 3}, {5, 3}], [{4, 4}, {4, 7}, {7, 4}])
    candidates = Solver.candidates(board, {4, 4})
    assert {4, 5} in candidates
    assert {5, 5} in candidates
    refute {0, 0} in candidates
  end
end
