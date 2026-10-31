defmodule Go.SpeedTest do
  @moduledoc """
  A tap must be fast: no server action may take more than 1 s, for the
  puzzles of the bank and for the moments of the stories. The first taps
  use the book of the puzzle. A later tap searches with the time limit
  of the game (`:think_ms`, 700 ms).

  Not async: other tests on the same cores would change the times.
  """

  use ExUnit.Case, async: false

  alias Go.{Board, Play, Puzzles}

  @limit_ms 1000
  @budget 700

  defp ms(fun) do
    {us, result} = :timer.tc(fun)
    {div(us, 1000), result}
  end

  # The puzzles of the bank and the moments of the stories.
  for p <- Puzzles.all() ++ for(s <- Go.Stories.all(), m <- s.moments, do: m.puzzle) do
    @p p
    @tag timeout: :infinity
    test "#{p.id}: each server action takes less than 1 s" do
      start = Play.new(@p)

      # Each first tap, the hint and "Show the answer".
      first =
        for point <- Board.legal_moves(start.board, :blue) do
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
