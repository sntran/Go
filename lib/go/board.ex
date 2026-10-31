defmodule Go.Board do
  @moduledoc """
  The rules of Go on a small square board.

  A point is `{row, column}`, from 0. Row 0 is at the top. The colors are
  `:blue` (the player, black stones on a real board) and `:red` (the
  computer, white stones).

  The rules:

    * A stone with no liberty is captured.
    * A move with no liberty is illegal (suicide), unless it captures.
    * Simple ko: a player cannot take back one stone at once on the point
      where a single stone was just captured.
  """

  defstruct size: 5, stones: %{}, ko: nil

  @type color :: :blue | :red
  @type point :: {non_neg_integer(), non_neg_integer()}
  @type t :: %__MODULE__{size: pos_integer(), stones: %{point() => color()}, ko: point() | nil}
  @type group :: %{color: color(), stones: [point()], liberties: [point()]}

  @doc "Makes a board with the given stones."
  @spec new(pos_integer(), [point()], [point()]) :: t()
  def new(size, blue \\ [], red \\ []) do
    stones =
      Map.new(blue, &{&1, :blue})
      |> Map.merge(Map.new(red, &{&1, :red}))

    %__MODULE__{size: size, stones: stones}
  end

  @doc "Gives the other color."
  @spec other(color()) :: color()
  def other(:blue), do: :red
  def other(:red), do: :blue

  @doc "Gives the color on a point, or nil if the point is empty."
  @spec get(t(), point()) :: color() | nil
  def get(%__MODULE__{stones: stones}, point), do: Map.get(stones, point)

  @spec on_board?(t(), point()) :: boolean()
  def on_board?(%__MODULE__{size: n}, {r, c}), do: r >= 0 and r < n and c >= 0 and c < n

  @doc "Gives all points of the board, row by row."
  @spec points(t()) :: [point()]
  def points(%__MODULE__{size: n}), do: for(r <- 0..(n - 1), c <- 0..(n - 1), do: {r, c})

  @doc "Gives the points up, down, left and right of a point."
  @spec neighbors(t(), point()) :: [point()]
  def neighbors(%__MODULE__{size: n}, {r, c}) do
    [{r - 1, c}, {r + 1, c}, {r, c - 1}, {r, c + 1}]
    |> Enum.filter(fn {a, b} -> a >= 0 and a < n and b >= 0 and b < n end)
  end

  @doc "Gives the points corner to corner from a point."
  @spec diagonals(t(), point()) :: [point()]
  def diagonals(%__MODULE__{size: n}, {r, c}) do
    [{r - 1, c - 1}, {r - 1, c + 1}, {r + 1, c - 1}, {r + 1, c + 1}]
    |> Enum.filter(fn {a, b} -> a >= 0 and a < n and b >= 0 and b < n end)
  end

  @doc """
  Gives the group on a point: its color, its stones and its liberties.
  Gives nil if the point is empty.
  """
  @spec group(t(), point()) :: group() | nil
  def group(board, point) do
    case get(board, point) do
      nil ->
        nil

      color ->
        {stones, libs} = flood(board, color, [point], %{point => true}, %{})
        %{color: color, stones: Map.keys(stones), liberties: Map.keys(libs)}
    end
  end

  defp flood(_board, _color, [], stones, libs), do: {stones, libs}

  defp flood(board, color, [p | rest], stones, libs) do
    {todo, stones, libs} =
      Enum.reduce(neighbors(board, p), {rest, stones, libs}, fn q, {todo, st, li} ->
        case Map.get(board.stones, q) do
          nil -> {todo, st, Map.put(li, q, true)}
          ^color when not is_map_key(st, q) -> {[q | todo], Map.put(st, q, true), li}
          _ -> {todo, st, li}
        end
      end)

    flood(board, color, todo, stones, libs)
  end

  @doc "Gives the number of liberties of the group on a point (0 if empty)."
  @spec liberty_count(t(), point()) :: non_neg_integer()
  def liberty_count(board, point) do
    case group(board, point) do
      nil -> 0
      g -> length(g.liberties)
    end
  end

  @doc "Gives all groups of a color."
  @spec groups(t(), color()) :: [group()]
  def groups(board, color) do
    board.stones
    |> Enum.filter(fn {_p, c} -> c == color end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
    |> Enum.reduce({[], %{}}, fn p, {acc, seen} ->
      if Map.has_key?(seen, p) do
        {acc, seen}
      else
        g = group(board, p)
        {[g | acc], Enum.reduce(g.stones, seen, &Map.put(&2, &1, true))}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  @doc """
  Plays a stone of `color` on `point`, or passes with `:pass`.

  Gives `{:ok, board, captured}`, with the captured points, or
  `{:error, reason}`. The reasons are `:off_board`, `:occupied`, `:ko`
  and `:suicide`.
  """
  @spec play(t(), color(), point() | :pass) ::
          {:ok, t(), [point()]} | {:error, :off_board | :occupied | :ko | :suicide}
  def play(board, _color, :pass), do: {:ok, %{board | ko: nil}, []}

  def play(board, color, point) do
    cond do
      not on_board?(board, point) -> {:error, :off_board}
      Map.has_key?(board.stones, point) -> {:error, :occupied}
      point == board.ko -> {:error, :ko}
      true -> place(board, color, point)
    end
  end

  defp place(board, color, point) do
    enemy = other(color)
    board = %{board | stones: Map.put(board.stones, point, color)}

    {board, captured} =
      board
      |> neighbors(point)
      |> Enum.reduce({board, []}, fn q, {b, caps} ->
        with ^enemy <- Map.get(b.stones, q),
             %{liberties: []} = g <- group(b, q) do
          {%{b | stones: Map.drop(b.stones, g.stones)}, g.stones ++ caps}
        else
          _ -> {b, caps}
        end
      end)

    me = group(board, point)

    cond do
      me.liberties == [] ->
        {:error, :suicide}

      match?([_], captured) and match?([_], me.stones) and match?([_], me.liberties) ->
        {:ok, %{board | ko: hd(captured)}, captured}

      true ->
        {:ok, %{board | ko: nil}, Enum.sort(captured)}
    end
  end

  @doc "Tells if a move is legal."
  @spec legal?(t(), color(), point()) :: boolean()
  def legal?(board, color, point), do: match?({:ok, _, _}, play(board, color, point))

  @doc "Gives all legal moves of a color, row by row."
  @spec legal_moves(t(), color()) :: [point()]
  def legal_moves(board, color), do: Enum.filter(points(board), &legal?(board, color, &1))

  @doc """
  Makes a board from rows of text. `B` is a blue stone, `R` is a red
  stone, and `.` is an empty point. Spaces are ignored.
  """
  @spec from_rows([String.t()]) :: t()
  def from_rows(rows) do
    cells = Enum.map(rows, &String.graphemes(String.replace(&1, " ", "")))
    size = length(cells)

    stones =
      for {row, r} <- Enum.with_index(cells),
          {ch, c} <- Enum.with_index(row),
          ch in ["B", "R"],
          into: %{},
          do: {{r, c}, if(ch == "B", do: :blue, else: :red)}

    %__MODULE__{size: size, stones: stones}
  end

  @doc "Writes a board as rows of text (see `from_rows/1`)."
  @spec to_rows(t()) :: [String.t()]
  def to_rows(board) do
    for r <- 0..(board.size - 1) do
      Enum.map_join(0..(board.size - 1), " ", fn c ->
        case get(board, {r, c}) do
          :blue -> "B"
          :red -> "R"
          nil -> "."
        end
      end)
    end
  end
end
