defmodule Go.SelfPlay do
  @moduledoc """
  The computer plays a 9x9 game against itself. The story games come from
  these games (see `Go.Stories`).

  The moves of a side, in order of priority:

    1. Capture stones.
    2. Save an own group in atari, when the save gives it 3 roads or more.
    3. A tactic that the solver finds: capture a group with 2 roads in 3
       moves or fewer.
    4. Save an own group with 2 roads that the other side can capture.
    5. Atari, with some chance.
    6. A move near the last moves, else a move anywhere.

  A side does not fill its own eyes, it does not play in a closed field (an
  empty region of 20 points or fewer that only one color touches, and after
  the opening each own field), and it does not put its own group in atari. The first 16 moves stay in the top-left
  5x5 corner, the next moves until move 30 in the 7x7 corner, and then the
  game spreads. When no useful move is left, the side passes. Two passes
  end the game.
  """

  alias Go.{Board, Solver}

  @size 9
  @max_moves 200

  @doc "The corner window of the move number `n` (from 0)."
  def window(n) when n < 16, do: 5
  def window(n) when n < 30, do: 7
  def window(_n), do: @size

  @doc """
  Plays one game. The same seed gives the same game. Gives the moves, as
  `{color, point | :pass}`. Blue plays first.
  """
  @spec game(integer()) :: [{Board.color(), Board.point() | :pass}]
  def game(seed) do
    :rand.seed(:exsss, {seed, 101, 103})
    loop(Board.new(@size), :blue, [], 0)
  end

  defp loop(_board, _color, moves, _passes) when length(moves) >= @max_moves,
    do: Enum.reverse(moves)

  defp loop(_board, _color, moves, 2), do: Enum.reverse(moves)

  defp loop(board, color, moves, passes) do
    move = choose(board, color, length(moves), moves)
    {:ok, next, _} = Board.play(board, color, move)
    passes = if move == :pass, do: passes + 1, else: 0
    loop(next, Board.other(color), [{color, move} | moves], passes)
  end

  @doc "The move of `color` on `board` at move number `n`."
  def choose(board, color, n, history) do
    w = window(n)
    enemy = Board.other(color)
    useful = useful_moves(board, color, w, n)

    captures(board, color, useful) ||
      saves(board, color) ||
      tactic(board, color, enemy, w) ||
      defense(board, color, enemy, useful) ||
      chance(0.5, fn -> atari(board, color, enemy, useful) end) ||
      near(useful, history) ||
      random(useful) ||
      :pass
  end

  # The legal moves in the window that do not fill an eye or a closed field
  # (see closed_fields/3), and that do not put the own group in atari.
  defp useful_moves(board, color, w, n) do
    fields = closed_fields(board, color, n)

    for r <- 0..(w - 1),
        c <- 0..(w - 1),
        p = {r, c},
        Board.get(board, p) == nil,
        not eye?(board, p, color),
        Map.get(fields, p) == nil,
        {:ok, next, captured} <- [Board.play(board, color, p)],
        captured != [] or Board.liberty_count(next, p) >= 2,
        do: p
  end

  defp eye?(board, p, color),
    do: Enum.all?(Board.neighbors(board, p), &(Board.get(board, &1) == color))

  # The fields of 20 points or fewer, and after the opening all own fields.
  # A bigger region of the other side is still open land (at the start,
  # the whole empty board touches only the first stone).
  defp closed_fields(board, color, n) do
    owners = Go.Score.fields(board)
    points = Map.keys(owners) |> MapSet.new()

    {closed, _} =
      Enum.reduce(points, {%{}, MapSet.new()}, fn p, {acc, seen} ->
        if MapSet.member?(seen, p) do
          {acc, seen}
        else
          region = grow(board, points, [p], MapSet.new([p]))
          own = owners[p] == color and n >= 30

          acc =
            if own or MapSet.size(region) <= 20,
              do: Enum.reduce(region, acc, &Map.put(&2, &1, true)),
              else: acc

          {acc, MapSet.union(seen, region)}
        end
      end)

    closed
  end

  defp grow(_board, _set, [], region), do: region

  defp grow(board, set, [p | rest], region) do
    next =
      Enum.filter(
        Board.neighbors(board, p),
        &(MapSet.member?(set, &1) and not MapSet.member?(region, &1))
      )

    grow(board, set, next ++ rest, Enum.reduce(next, region, &MapSet.put(&2, &1)))
  end

  defp captures(board, color, useful) do
    useful
    |> Enum.map(fn p ->
      {:ok, _, captured} = Board.play(board, color, p)
      {p, length(captured)}
    end)
    |> Enum.filter(fn {_p, n} -> n > 0 end)
    |> Enum.max_by(&elem(&1, 1), fn -> nil end)
    |> then(&(&1 && elem(&1, 0)))
  end

  defp saves(board, color) do
    board
    |> Board.groups(color)
    |> Enum.filter(&match?([_], &1.liberties))
    |> Enum.find_value(fn %{liberties: [lib]} ->
      case Board.play(board, color, lib) do
        {:ok, next, _} -> if Board.liberty_count(next, lib) >= 3, do: lib
        _ -> nil
      end
    end)
  end

  # Capture a group with 2 roads in 3 moves or fewer.
  defp tactic(board, color, enemy, w) do
    board
    |> Board.groups(enemy)
    |> Enum.filter(
      &(length(&1.liberties) == 2 and Enum.all?(&1.stones, fn {r, c} -> r < w and c < w end))
    )
    |> Enum.find_value(fn g ->
      target = hd(g.stones)

      Enum.find(Solver.candidates(board, target), fn m ->
        case Board.play(board, color, m) do
          {:ok, next, _} ->
            Board.liberty_count(next, m) >= 2 and
              Solver.attacker_wins?(next, target, color, enemy, 2)

          _ ->
            false
        end
      end)
    end)
  end

  # Save an own group with 2 roads that the other side can capture.
  defp defense(board, color, enemy, useful) do
    board
    |> Board.groups(color)
    |> Enum.filter(&(length(&1.liberties) == 2))
    |> Enum.find_value(fn g ->
      target = hd(g.stones)

      if Solver.attacker_wins?(board, target, enemy, enemy, 3) do
        board
        |> Solver.candidates(target)
        |> Enum.filter(&(&1 in useful))
        |> Enum.find(fn m ->
          {:ok, next, _} = Board.play(board, color, m)
          not Solver.attacker_wins?(next, target, enemy, enemy, 3)
        end)
      end
    end)
  end

  defp atari(board, _color, enemy, useful) do
    targets =
      for g <- Board.groups(board, enemy), length(g.liberties) == 2, lib <- g.liberties, do: lib

    useful |> Enum.filter(&(&1 in targets)) |> random()
  end

  defp near(useful, history) do
    last = for {_c, {_, _} = p} <- Enum.take(history, 2), do: p

    useful
    |> Enum.filter(fn {r, c} ->
      Enum.any?(last, fn {a, b} -> abs(a - r) <= 2 and abs(b - c) <= 2 end)
    end)
    |> random()
  end

  defp chance(p, fun), do: if(:rand.uniform() < p, do: fun.(), else: nil)

  defp random([]), do: nil
  defp random(list), do: Enum.random(list)
end
