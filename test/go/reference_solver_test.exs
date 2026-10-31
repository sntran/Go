defmodule Go.ReferenceSolverTest do
  @moduledoc """
  Compares the fast solver with the slow reference solver
  (`Go.ReferenceSolver`), which tries all legal moves.
  """

  use ExUnit.Case, async: true

  alias Go.{Board, Puzzle, Puzzles, ReferenceSolver, Solver}

  # Random small positions: a target stone, some attacker and defender
  # stones near it, 1 to 3 attacker moves, and either color to play.
  defp random_positions(seed, count) do
    :rand.seed(:exsss, {seed, 5, 9})

    Stream.repeatedly(fn ->
      target = {Enum.random(0..4), Enum.random(0..4)}
      defender = Enum.random([:blue, :red])
      attacker = Board.other(defender)

      points =
        for(r <- 0..4, c <- 0..4, {r, c} != target, do: {r, c})
        |> Enum.take_random(Enum.random(2..7))

      {att, dfn} = Enum.split(points, div(length(points) + 1, 2))

      stones =
        Map.new(att, &{&1, attacker})
        |> Map.merge(Map.new(dfn, &{&1, defender}))
        |> Map.put(target, defender)

      board = %Board{size: 5, stones: stones}
      {board, target, attacker, Enum.random([attacker, defender]), Enum.random(1..3)}
    end)
    |> Stream.filter(fn {board, _, _, _, _} ->
      Enum.all?(Board.groups(board, :blue) ++ Board.groups(board, :red), &(&1.liberties != []))
    end)
    |> Enum.take(count)
  end

  for seed <- 1..4 do
    @seed seed
    test "random 5x5 positions give the same result (seed #{seed})" do
      for {board, target, attacker, to_move, n} <- random_positions(@seed, 250) do
        assert Solver.attacker_wins?(board, target, attacker, to_move, n) ==
                 ReferenceSolver.attacker_wins?(board, target, attacker, to_move, n),
               "target #{inspect(target)}, attacker #{attacker}, #{to_move} to play, #{n} moves:\n" <>
                 Enum.join(Board.to_rows(board), "\n")
      end
    end
  end

  test "the counter-attack of issue 1: Blue saves the fort by attacking the red stone" do
    # escape-10 of the first bank. After Blue (0,0) and Red (1,2), Blue (1,1)
    # or (2,2) attacks the red stone and holds.
    board = Board.from_rows(["B R . B .", ". . R B R", ". . . R .", ". . . . .", ". . . . ."])
    refute ReferenceSolver.attacker_wins?(board, {0, 3}, :red, :blue, 2)
    refute Solver.attacker_wins?(board, {0, 3}, :red, :blue, 2)
  end

  # The same question for both solvers: the first blue moves that work in
  # the move limit of the puzzle.
  defp fast_good(%Puzzle{goal: goal} = p) do
    board = Puzzle.board(p)

    for move <- Board.legal_moves(board, :blue),
        {:ok, next, _} = Board.play(board, :blue, move),
        good?(goal, next, &Solver.attacker_wins?/5),
        do: move
  end

  defp good?(%{type: :capture} = goal, next, wins?),
    do:
      Board.get(next, goal.target) != :red or
        (goal.moves > 1 and wins?.(next, goal.target, :blue, :red, goal.moves - 1))

  defp good?(%{type: :escape} = goal, next, wins?),
    do:
      Board.get(next, goal.target) == :blue and
        not wins?.(next, goal.target, :red, :red, goal.moves)

  for p <- Puzzles.all() do
    @p p
    @tag timeout: :infinity
    test "#{p.id}: the good first moves are the same as with the reference" do
      assert fast_good(@p) == ReferenceSolver.good_moves(@p.goal, Puzzle.board(@p), @p.goal.moves)
    end
  end
end
