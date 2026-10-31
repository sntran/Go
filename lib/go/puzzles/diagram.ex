defmodule Go.Puzzles.Diagram do
  @moduledoc """
  Reads a position from rows of text, so that puzzles are easy to write
  and to read.

    * `B`: a blue stone. `b`: a blue stone that is the target.
    * `R`: a red stone. `r`: a red stone that is the target.
    * `.`: an empty point.

  Spaces are ignored.
  """

  @doc "Gives `%{size: n, blue: points, red: points, target: point | nil}`."
  @spec parse([String.t()]) :: map()
  def parse(rows) do
    cells = Enum.map(rows, &String.graphemes(String.replace(&1, " ", "")))
    size = length(cells)

    unless Enum.all?(cells, &(length(&1) == size)),
      do: raise(ArgumentError, "a diagram must be square: #{inspect(rows)}")

    marks =
      for {row, r} <- Enum.with_index(cells), {ch, c} <- Enum.with_index(row), ch != ".", do: {ch, {r, c}}

    %{
      size: size,
      blue: for({ch, p} <- marks, ch in ["B", "b"], do: p),
      red: for({ch, p} <- marks, ch in ["R", "r"], do: p),
      target: Enum.find_value(marks, fn {ch, p} -> if ch in ["b", "r"], do: p end)
    }
  end
end
