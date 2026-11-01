defmodule Go.SpeedTest do
  @moduledoc """
  A tap must be fast: no server action may take more than 1 s, for the
  puzzles of the bank and for the puzzles of a run. The first taps use the
  book of the puzzle. A later tap, or a first tap outside the book of a
  run puzzle, searches with the time limit of the game (`:think_ms`, 700
  ms).

  Not async: other tests on the same cores would change the times.
  """

  use ExUnit.Case, async: false

  alias Go.{Board, Play, Puzzles, Runs}

  @limit_ms 1000
  @budget 700

  defp ms(fun) do
    {us, result} = :timer.tc(fun)
    {div(us, 1000), result}
  end

  # A run puzzle has a book only for the points of the fight. The test taps
  # all of them, and 3 other points.
  defp first_points(%{book: %{first: first}, id: "story-" <> _}, board) do
    others = Board.legal_moves(board, :blue) |> Enum.reject(&Map.has_key?(first, &1))
    Map.keys(first) ++ Enum.take_every(others, max(div(length(others), 3), 1))
  end

  defp first_points(_puzzle, board), do: Board.legal_moves(board, :blue)

  # The puzzles of the bank, and the puzzles of a run at the highest level
  # (the stage in the name: a story can come back in another stage).
  run_puzzles =
    for st <- Runs.run("8F3K", 3).stages, m <- st.puzzles do
      {"stage #{st.number}, ", Runs.puzzle(st, m)}
    end

  for {where, p} <- Enum.map(Puzzles.all(), &{"", &1}) ++ run_puzzles do
    @p p
    @tag timeout: :infinity
    test "#{where}#{p.id}: each server action takes less than 1 s" do
      start = Play.new(@p)

      # Each first tap, the hint and "Show the answer".
      first =
        for point <- first_points(@p, start.board) do
          {t, {:ok, _}} = ms(fn -> Play.tap(start, point, budget: @budget) end)
          {"tap #{inspect(point)}", t}
        end

      {t_hint, _} = ms(fn -> Play.hint(start, budget: @budget) end)
      {t_answer, _} = ms(fn -> Play.show_answer(start) end)

      # A later tap, after the answer and the red reply: the next move of
      # the answer line, and one other move. They are not in the book.
      later =
        case Play.answer_line(@p) do
          [{:blue, a}, {:red, _}, {:blue, b} | _] ->
            {:ok, play} = Play.tap(start, a, budget: @budget)
            play = Play.run_red(play)
            other = Enum.find(Board.legal_moves(play.board, :blue), &(&1 != b))
            {t_hint2, _} = ms(fn -> Play.hint(play, budget: @budget) end)

            [{"hint after the first move", t_hint2}] ++
              for point <- [b, other], point != nil do
                {t, {:ok, _}} = ms(fn -> Play.tap(play, point, budget: @budget) end)
                {"later tap #{inspect(point)}", t}
              end

          _ ->
            []
        end

      times = first ++ [{"hint", t_hint}, {"show the answer", t_answer}] ++ later
      {what, slowest} = Enum.max_by(times, &elem(&1, 1))
      assert slowest < @limit_ms, "#{what} took #{slowest} ms"
    end
  end
end
