defmodule Go.Puzzles.Symmetry do
  @moduledoc """
  The 8 symmetries of a square board (4 turns, each with and without a
  mirror), and a key that is the same for all copies of a puzzle under
  them.
  """

  alias Go.Puzzle

  @doc "The 8 symmetries, as numbers from 0 to 7."
  def all, do: Enum.to_list(0..7)

  @doc "Applies a symmetry to a point on a board of `size`."
  @spec map_point(0..7, pos_integer(), Go.Board.point()) :: Go.Board.point()
  def map_point(sym, size, {r, c}) do
    m = size - 1

    case sym do
      0 -> {r, c}
      1 -> {c, m - r}
      2 -> {m - r, m - c}
      3 -> {m - c, r}
      4 -> {r, m - c}
      5 -> {m - c, m - r}
      6 -> {m - r, c}
      7 -> {c, r}
    end
  end

  @doc "Applies a symmetry to all points of a puzzle."
  @spec transform(Puzzle.t(), 0..7) :: Puzzle.t()
  def transform(%Puzzle{size: size} = p, sym) do
    f = &map_point(sym, size, &1)

    %{
      p
      | blue: Enum.sort(Enum.map(p.blue, f)),
        red: Enum.sort(Enum.map(p.red, f)),
        answer: p.answer && f.(p.answer),
        goal: %{p.goal | target: f.(p.goal.target)},
        wrong: Map.new(p.wrong, fn {pt, t} -> {f.(pt), map_reply(t, f)} end),
        book: map_book(p.book, f)
    }
  end

  @doc "Applies a point function to all points of a book (see `Go.Puzzle`)."
  def map_book(nil, _f), do: nil

  def map_book(book, f) do
    line = fn l -> Enum.map(l, fn {c, m} -> {c, if(m == :pass, do: :pass, else: f.(m))} end) end

    %{
      first: Map.new(book.first, fn {p, e} -> {f.(p), %{e | line: line.(e.line)}} end),
      answer: line.(book.answer)
    }
  end

  defp map_reply(%{reply: reply} = t, f) when reply != nil, do: %{t | reply: f.(reply)}
  defp map_reply(t, _f), do: t

  @doc """
  The key of a puzzle: the same for all 8 copies of it. Two puzzles with
  the same key are copies. The key uses the target group, not the target
  point, because any stone of the group is the same target.
  """
  @spec key(Puzzle.t()) :: term()
  def key(%Puzzle{} = p) do
    board = Puzzle.board(p)
    target_group = Go.Board.group(board, p.goal.target).stones

    all()
    |> Enum.map(fn sym ->
      f = &map_point(sym, p.size, &1)

      {p.size, p.goal.type, p.goal.moves, Enum.sort(Enum.map(p.blue, f)),
       Enum.sort(Enum.map(p.red, f)), Enum.sort(Enum.map(target_group, f))}
    end)
    |> Enum.min()
  end
end
