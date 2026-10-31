defmodule Go.ReferenceSolver do
  @moduledoc """
  A slow solver that is simple and clearly correct. The tests compare
  `Go.Solver` with it.

  It has the same rules and the same sound cut as `Go.Solver` (a target
  with L liberties survives if L is more than the attacker moves that are
  left). But it does not look only near the fight: the defender tries all
  legal moves and a pass, and the attacker tries all legal moves. It keeps
  a cache of the positions that it checked, and it tries the moves near
  the target first. The cache and the order do not change the result.
  """

  alias Go.Board

  @doc "Tells if the attacker can capture the target group in `n` attacker moves."
  def attacker_wins?(board, target, attacker, to_move, n) do
    {result, _cache} = search(board, target, attacker, to_move, n, %{})
    result
  end

  @doc "The good first blue moves of a puzzle goal (see `Go.Goal.good_moves/3`)."
  def good_moves(goal, board, left) do
    for move <- Board.legal_moves(board, :blue), good?(goal, board, left, move), do: move
  end

  defp good?(%{type: :capture} = goal, board, left, move) do
    {:ok, next, _} = Board.play(board, :blue, move)

    Board.get(next, goal.target) != :red or
      (left > 1 and attacker_wins?(next, goal.target, :blue, :red, left - 1))
  end

  defp good?(%{type: :escape} = goal, board, left, move) do
    {:ok, next, _} = Board.play(board, :blue, move)

    Board.get(next, goal.target) == :blue and
      not attacker_wins?(next, goal.target, :red, :red, left)
  end

  # All legal moves, the moves near the target group first.
  defp ordered(board, target, color) do
    stones = Board.group(board, target).stones

    board
    |> Board.legal_moves(color)
    |> Enum.sort_by(fn {r, c} -> Enum.min(Enum.map(stones, fn {a, b} -> abs(a - r) + abs(b - c) end)) end)
  end

  defp search(board, target, attacker, to_move, n, cache) do
    key = {board.stones, board.ko, to_move, n}

    case cache do
      %{^key => result} ->
        {result, cache}

      _ ->
        {result, cache} = compute(board, target, attacker, to_move, n, cache)
        {result, Map.put(cache, key, result)}
    end
  end

  defp compute(board, target, attacker, to_move, n, cache) do
    defender = Board.other(attacker)

    case Board.group(board, target) do
      %{color: ^defender, liberties: libs} ->
        cond do
          n == 0 or length(libs) > n ->
            {false, cache}

          to_move == attacker ->
            Enum.reduce_while(ordered(board, target, attacker), {false, cache}, fn move, {false, cache} ->
              {:ok, next, _} = Board.play(board, attacker, move)

              cond do
                Board.get(next, target) != defender ->
                  {:halt, {true, cache}}

                n > 1 ->
                  case search(next, target, attacker, defender, n - 1, cache) do
                    {true, cache} -> {:halt, {true, cache}}
                    {false, cache} -> {:cont, {false, cache}}
                  end

                true ->
                  {:cont, {false, cache}}
              end
            end)

          true ->
            moves = ordered(board, target, defender) ++ [:pass]

            Enum.reduce_while(moves, {true, cache}, fn move, {true, cache} ->
              {:ok, next, _} = Board.play(board, defender, move)

              case search(next, target, attacker, attacker, n, cache) do
                {false, cache} -> {:halt, {false, cache}}
                {true, cache} -> {:cont, {true, cache}}
              end
            end)
        end

      _captured ->
        {true, cache}
    end
  end
end
