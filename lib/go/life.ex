defmodule Go.Life do
  @moduledoc """
  Benson's algorithm: finds the groups that are alive whatever the other
  color plays, also if their own color never plays again.

  The game says "Red got away" or "Your fort is safe!" only when this test
  proves it. A search to a fixed depth cannot prove it.

  The steps, for one color:

    1. The chains are the groups of the color. The regions are the
       connected sets of points that do not have a stone of the color.
    2. A region is vital to a chain when all the empty points of the
       region are liberties of the chain.
    3. Remove each chain that has fewer than 2 vital regions. Remove each
       region that touches a removed chain. Do this again until nothing
       changes.
    4. The chains that stay are alive.
  """

  alias Go.Board

  @doc "Gives the points of the stones of `color` that are alive."
  @spec alive(Board.t(), Board.color()) :: MapSet.t(Board.point())
  def alive(board, color) do
    chains =
      board
      |> Board.groups(color)
      |> Enum.with_index()
      |> Map.new(fn {g, i} ->
        {i, %{stones: MapSet.new(g.stones), libs: MapSet.new(g.liberties)}}
      end)

    chain_of = for {i, c} <- chains, p <- c.stones, into: %{}, do: {p, i}

    regions =
      board
      |> regions(color)
      |> Enum.map(fn points ->
        empty = Enum.filter(points, &(Board.get(board, &1) == nil))

        borders =
          points
          |> Enum.flat_map(&Board.neighbors(board, &1))
          |> Enum.flat_map(&List.wrap(Map.get(chain_of, &1)))
          |> MapSet.new()

        vital_to =
          for {i, c} <- chains,
              MapSet.member?(borders, i),
              Enum.all?(empty, &MapSet.member?(c.libs, &1)),
              into: MapSet.new(),
              do: i

        %{borders: borders, vital_to: vital_to}
      end)

    alive_ids = reduce(MapSet.new(Map.keys(chains)), regions)

    for i <- alive_ids, p <- chains[i].stones, into: MapSet.new(), do: p
  end

  @doc "Tells if all stones of the group on `point` are alive."
  @spec alive?(Board.t(), Board.point()) :: boolean()
  def alive?(board, point) do
    case Board.group(board, point) do
      nil -> false
      g -> MapSet.subset?(MapSet.new(g.stones), alive(board, g.color))
    end
  end

  defp reduce(chains, regions) do
    # A region stays while all the chains around it stay.
    regions = Enum.filter(regions, &MapSet.subset?(&1.borders, chains))

    keep =
      MapSet.filter(chains, fn i ->
        Enum.count(regions, &MapSet.member?(&1.vital_to, i)) >= 2
      end)

    if keep == chains, do: chains, else: reduce(keep, regions)
  end

  # The connected sets of points with no stone of `color`.
  defp regions(board, color) do
    open = for p <- Board.points(board), Board.get(board, p) != color, do: p

    {regions, _seen} =
      Enum.reduce(open, {[], MapSet.new()}, fn p, {acc, seen} ->
        if MapSet.member?(seen, p) do
          {acc, seen}
        else
          region = flood(board, color, [p], MapSet.new([p]))
          {[MapSet.to_list(region) | acc], MapSet.union(seen, region)}
        end
      end)

    regions
  end

  defp flood(_board, _color, [], seen), do: seen

  defp flood(board, color, [p | rest], seen) do
    next =
      board
      |> Board.neighbors(p)
      |> Enum.reject(&(Board.get(board, &1) == color or MapSet.member?(seen, &1)))

    flood(board, color, next ++ rest, Enum.reduce(next, seen, &MapSet.put(&2, &1)))
  end
end
