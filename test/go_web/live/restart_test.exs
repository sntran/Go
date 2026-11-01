defmodule GoWeb.RestartTest do
  @moduledoc """
  The progress stays in SQLite: after a restart of the app (a new deploy),
  a run in progress goes on from its place.

  Not async: the test stops and starts the app.
  """

  use GoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import GoWeb.PuzzleHelpers

  alias Go.{Play, Progress, Runs}

  defp restart_app do
    :ok = Application.stop(:go)
    {:ok, _} = Application.ensure_all_started(:go)
  end

  test "a run in progress goes on after a restart of the app", %{conn: conn} do
    {conn, player} = new_player(conn)
    seed = Runs.code(Go.Library.newest(), "8F3K")
    {:ok, view, _html} = live(conn, ~p"/run/#{seed}")

    # Solve the first puzzle, and go on to the next one.
    place = Progress.run_place(player, seed)
    stage = Enum.at(Runs.run(seed, place.level).stages, 0)
    puzzle = Runs.puzzle(stage, hd(stage.puzzles))
    for {:blue, p} <- Play.answer_line(puzzle), do: tap_point(view, p)
    click(view, "continue")

    place = Progress.run_place(player, seed)
    results = Progress.results(player)
    assert [%{stars: 3}] = place.results
    assert results[puzzle.id] == %{status: :solved, stars: 3}

    restart_app()

    # The memory is new, and the data comes from SQLite.
    assert Progress.run_place(player, seed) == place
    assert Progress.results(player) == results
    assert Progress.current_run(player) == seed
    assert [%{puzzle_id: id, stars: 3}] = Progress.attempts(player)
    assert id == puzzle.id

    {:ok, _view, html} = live(conn, ~p"/run/#{seed}")
    assert text(html, "#kicker") =~ "Puzzle #{place.moment} of"

    {:ok, _view, html} = live(conn, ~p"/")
    assert text(html, "#continue-run") == "Continue the run"
  end
end
