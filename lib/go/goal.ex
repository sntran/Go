defmodule Go.Goal do
  @moduledoc """
  The goal of a puzzle, and how the server checks it.

  A goal is a map with a `:type`, a `:target` point and a number of
  `:moves`. Blue always plays first.

    * `:capture`: Blue attacks. Blue must capture the target group in
      `moves` Blue moves. The "moves left" count Blue moves.
    * `:escape`: Red attacks. The target is a blue group, and it must live
      for `moves` Red moves. The "moves left" count Red moves.

  The worlds that come later (connect and cut, eyes, ko, fields) add more
  types. Each type must give the functions of this module.
  """

  alias Go.{Board, Solver}

  @type type :: :capture | :escape
  @type t :: %{type: type(), target: Board.point(), moves: pos_integer()}

  @types [:capture, :escape]

  @doc "The goal types that the server can check now."
  def types, do: @types

  @doc "The color that attacks the target."
  @spec attacker(t()) :: Board.color()
  def attacker(%{type: :capture}), do: :blue
  def attacker(%{type: :escape}), do: :red

  @doc "The color of the target."
  @spec defender(t()) :: Board.color()
  def defender(goal), do: Board.other(attacker(goal))

  @doc """
  Gives the "moves left" after a blue move (for `:capture`) or after a red
  move (for `:escape`).
  """
  @spec after_blue(t(), non_neg_integer()) :: non_neg_integer()
  def after_blue(%{type: :capture}, left), do: left - 1
  def after_blue(%{type: :escape}, left), do: left

  @spec after_red(t(), non_neg_integer()) :: non_neg_integer()
  def after_red(%{type: :capture}, left), do: left
  def after_red(%{type: :escape}, left), do: left - 1

  @doc """
  Tells if the goal is reached. Call it after each move.

  An escape goal is reached when Red has no moves left, or when Red cannot
  capture the target in its moves even if Blue does nothing more.
  """
  @spec reached?(t(), Board.t(), non_neg_integer()) :: boolean()
  def reached?(%{type: :capture} = goal, board, _left),
    do: Solver.captured?(board, goal.target, :red)

  def reached?(%{type: :escape} = goal, board, left) do
    not Solver.captured?(board, goal.target, :blue) and
      (left == 0 or not Solver.attacker_wins?(board, goal.target, :red, :red, left, passes_only: true))
  end

  @doc """
  Tells if Blue can still reach the goal with its best play, when Blue is
  to play and `left` moves are left.
  """
  @spec reachable?(t(), Board.t(), non_neg_integer()) :: boolean()
  def reachable?(%{type: :capture} = goal, board, left),
    do: left > 0 and Solver.attacker_wins?(board, goal.target, :blue, :blue, left)

  def reachable?(%{type: :escape} = goal, board, left),
    do: not Solver.attacker_wins?(board, goal.target, :red, :blue, left)

  @doc """
  Tells if a blue move keeps the goal reachable. The move must be legal.
  `left` is the count before the move.
  """
  @spec good_move?(t(), Board.t(), non_neg_integer(), Board.point()) :: boolean()
  def good_move?(goal, board, left, point) do
    case Board.play(board, :blue, point) do
      {:ok, next, _} -> good_after?(goal, next, after_blue(goal, left))
      {:error, _} -> false
    end
  end

  defp good_after?(%{type: :capture} = goal, next, left) do
    reached?(goal, next, left) or
      (left > 0 and Solver.attacker_wins?(next, goal.target, :blue, :red, left))
  end

  defp good_after?(%{type: :escape} = goal, next, left) do
    not Solver.captured?(next, goal.target, :blue) and
      not Solver.attacker_wins?(next, goal.target, :red, :red, left)
  end

  @doc "Gives all good blue moves on the whole board."
  @spec good_moves(t(), Board.t(), non_neg_integer()) :: [Board.point()]
  def good_moves(goal, board, left) do
    board
    |> Board.legal_moves(:blue)
    |> Enum.filter(&good_move?(goal, board, left, &1))
  end

  @doc """
  Gives the best red move. `left` is the count before the move.

  In a capture puzzle, Red defends: it escapes if it can, and else it
  makes the capture as long as possible. In an escape puzzle, Red attacks:
  it captures as fast as it can, and else it takes away the most roads.
  `prefer` is a move to play if it is as good as the best one.
  """
  @spec red_move(t(), Board.t(), non_neg_integer(), Board.point() | nil) :: Board.point() | :pass
  def red_move(goal, board, left, prefer \\ nil)

  def red_move(%{type: :capture} = goal, board, left, prefer) do
    moves = Solver.candidates(board, goal.target) ++ [:pass]

    scored =
      for move <- moves, {:ok, next, captured} <- [Board.play(board, :red, move)] do
        need = Solver.moves_to_capture(next, goal.target, :blue, :blue, left)
        libs = Board.liberty_count(next, goal.target)
        # Escape first, then the longest capture, then the most roads.
        {move, {if(need, do: need, else: 100), libs, length(captured), move != :pass}}
      end

    pick_best(scored, prefer)
  end

  def red_move(%{type: :escape} = goal, board, left, prefer) do
    moves = Solver.candidates(board, goal.target)

    scored =
      for move <- moves, {:ok, next, _} <- [Board.play(board, :red, move)] do
        need =
          if Solver.captured?(next, goal.target, :blue),
            do: 0,
            else: Solver.moves_to_capture(next, goal.target, :red, :blue, left - 1)

        libs = Board.liberty_count(next, goal.target)
        safe = length(Board.group(next, move).liberties)
        # The fastest capture first, then the fewest roads for Blue.
        {move, {-(need || 100), -libs, min(safe, 3)}}
      end

    case scored do
      [] -> :pass
      _ -> pick_best(scored, prefer)
    end
  end

  defp pick_best([], _prefer), do: :pass

  defp pick_best(scored, prefer) do
    {best, score} = Enum.max_by(scored, &elem(&1, 1))

    case List.keyfind(scored, prefer, 0) do
      {^prefer, ^score} -> prefer
      _ -> best
    end
  end

  @doc """
  Gives the best blue move for the answer. `prefer` is a move to play if
  it is good.
  """
  @spec blue_move(t(), Board.t(), non_neg_integer(), Board.point() | nil) :: Board.point() | nil
  def blue_move(goal, board, left, prefer \\ nil) do
    if prefer && good_move?(goal, board, left, prefer) do
      prefer
    else
      goal
      |> good_moves(board, left)
      |> Enum.map(&{&1, blue_score(goal, board, left, &1)})
      |> Enum.max_by(&elem(&1, 1), fn -> {nil, 0} end)
      |> elem(0)
    end
  end

  defp blue_score(%{type: :capture} = goal, board, left, move) do
    {:ok, next, _} = Board.play(board, :blue, move)
    need = Solver.moves_to_capture(next, goal.target, :blue, :red, left - 1) || 0
    {-need, -Board.liberty_count(next, goal.target)}
  end

  defp blue_score(%{type: :escape} = goal, board, _left, move) do
    {:ok, next, captured} = Board.play(board, :blue, move)
    {Board.liberty_count(next, goal.target), length(captured)}
  end

  @doc """
  Gives a blue move that resists for the longest time in a lost escape
  puzzle. It is for the replay of Red's punishment.
  """
  @spec blue_resist(t(), Board.t(), non_neg_integer()) :: Board.point() | :pass
  def blue_resist(%{type: :escape} = goal, board, left) do
    scored =
      for move <- Solver.candidates(board, goal.target),
          {:ok, next, _} <- [Board.play(board, :blue, move)],
          not Solver.captured?(next, goal.target, :blue) do
        need = Solver.moves_to_capture(next, goal.target, :red, :red, left) || 100
        {move, {need, Board.liberty_count(next, goal.target)}}
      end

    pick_best(scored, nil)
  end
end
