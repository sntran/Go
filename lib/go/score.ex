defmodule Go.Score do
  @moduledoc """
  Area scoring: the stones of a side, plus the empty regions that only
  its stones touch (its fields). Red gets the komi, because Blue plays
  first.
  """

  alias Go.Board

  @komi 7

  @doc "The komi of Red."
  def komi, do: @komi

  @doc """
  Counts a board. Gives the stones, the fields and the total of each side,
  the owner of each empty point in a field, and the winner.
  """
  @spec count(Board.t()) :: map()
  def count(board) do
    owners = fields(board)
    stones = Enum.frequencies(Map.values(board.stones))
    fields = Enum.frequencies(Map.values(owners))

    blue = Map.get(stones, :blue, 0) + Map.get(fields, :blue, 0)
    red = Map.get(stones, :red, 0) + Map.get(fields, :red, 0) + @komi

    %{
      blue: %{stones: Map.get(stones, :blue, 0), fields: Map.get(fields, :blue, 0), total: blue},
      red: %{
        stones: Map.get(stones, :red, 0),
        fields: Map.get(fields, :red, 0),
        komi: @komi,
        total: red
      },
      owners: owners,
      winner: if(blue > red, do: :blue, else: :red)
    }
  end

  @doc "The owner of each empty point that only one color touches."
  @spec fields(Board.t()) :: %{Board.point() => Board.color()}
  def fields(board) do
    empty = for p <- Board.points(board), Board.get(board, p) == nil, do: p

    {owners, _seen} =
      Enum.reduce(empty, {%{}, MapSet.new()}, fn p, {owners, seen} ->
        if MapSet.member?(seen, p) do
          {owners, seen}
        else
          {region, colors} = region(board, [p], MapSet.new([p]), MapSet.new())
          seen = MapSet.union(seen, region)

          case MapSet.to_list(colors) do
            [color] -> {Enum.reduce(region, owners, &Map.put(&2, &1, color)), seen}
            _ -> {owners, seen}
          end
        end
      end)

    owners
  end

  defp region(_board, [], region, colors), do: {region, colors}

  defp region(board, [p | rest], region, colors) do
    {todo, region, colors} =
      Enum.reduce(Board.neighbors(board, p), {rest, region, colors}, fn q, {todo, reg, cols} ->
        case Board.get(board, q) do
          nil ->
            if MapSet.member?(reg, q),
              do: {todo, reg, cols},
              else: {[q | todo], MapSet.put(reg, q), cols}

          color ->
            {todo, reg, MapSet.put(cols, color)}
        end
      end)

    region(board, todo, region, colors)
  end
end
