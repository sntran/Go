defmodule GoWeb.RunSpeedTest do
  @moduledoc """
  Each server action of a run page takes less than 1 s: the start of a
  run, the taps, "Continue the story", and "Next stage".

  Not async: other tests on the same cores would change the times.
  """

  use GoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import GoWeb.PuzzleHelpers

  alias Go.{Play, Progress, Runs}

  @limit_ms 1000

  defp ms(fun) do
    {us, result} = :timer.tc(fun)
    {div(us, 1000), result}
  end

  @tag timeout: :infinity
  test "each action of a run takes less than 1 s", %{conn: conn} do
    {conn, player} = new_player(conn)
    seed = "Q7RM"

    {t, {:ok, view, _html}} = ms(fn -> live(conn, ~p"/run/#{seed}") end)
    times = [{"start", t}]

    times =
      Enum.reduce(1..Runs.stages(), times, fn _stage, times ->
        times = play_stage(view, player, seed, times)
        {t, _} = ms(fn -> click(view, "next-stage") end)
        [{"next stage", t} | times]
      end)

    {what, slowest} = Enum.max_by(times, &elem(&1, 1))
    assert slowest < @limit_ms, "#{what} took #{slowest} ms"
  end

  # Taps the answer line of each puzzle of the stage, then "Continue".
  defp play_stage(view, player, seed, times) do
    place = Progress.run_place(player, seed)

    if is_integer(place.moment) do
      stage = Enum.at(Runs.run(seed, place.level).stages, place.stage - 1)
      puzzle = Runs.puzzle(stage, Enum.at(stage.puzzles, place.moment - 1))

      times =
        for {:blue, p} <- Play.answer_line(puzzle), reduce: times do
          times ->
            {t, _} = ms(fn -> tap_point(view, p) end)
            [{"tap #{inspect(p)}", t} | times]
        end

      {t, _} = ms(fn -> click(view, "continue") end)
      play_stage(view, player, seed, [{"continue", t} | times])
    else
      times
    end
  end
end
