defmodule GoWeb.PathLiveTest do
  use GoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import GoWeb.PuzzleHelpers

  alias Go.{Path, Play, Progress, Puzzles}

  setup %{conn: conn} do
    {conn, player} = new_player(conn)
    %{conn: conn, player: player}
  end

  defp template_of(html) do
    title = text(html, "#title")
    Enum.find(Puzzles.world(:capture), &(&1.title == title)).template
  end

  # Solves a puzzle with real taps: the blue moves of its answer line.
  defp solve(view, puzzle) do
    for {:blue, point} <- Play.answer_line(puzzle), reduce: nil do
      _ -> tap_point(view, point)
    end
  end

  test "a clean solve of the first puzzle of an idea goes to a new idea", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/play/capture")
    first = Enum.find(Puzzles.world(:capture), &(&1.title == text(html, "#title")))
    assert first.template == "capture_in_1"

    html = solve(view, first)
    assert html =~ ~s(aria-label="3 stars")
    click(view, "next")
    refute template_of(render(view)) == "capture_in_1"
  end

  test "a solve with a hint gives the same idea again", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/play/capture")
    first = Enum.find(Puzzles.world(:capture), &(&1.title == text(html, "#title")))

    click(view, "hint")
    solve(view, first)
    click(view, "next")
    html = render(view)
    assert template_of(html) == "capture_in_1"
    refute text(html, "#title") == first.title
  end

  test "after 2 finished ideas, an earlier idea comes back with a neutral title", %{
    conn: conn,
    player: player
  } do
    [a, b | _] = Path.ideas(:capture)

    for idea <- [a, b] do
      p = hd(idea.puzzles)
      {:ok, play} = Play.replay(p, for({:blue, m} <- Play.answer_line(p), do: m))
      {:ok, _} = Progress.record(player, play)
    end

    for _ <- 1..3, do: Progress.count_path(player, :capture, :new)

    {:ok, _view, html} = live(conn, ~p"/play/capture")
    assert text(html, "#say") == "A puzzle from before. Read the board first."
    review = Enum.find(a.puzzles ++ b.puzzles, &(Path.review_title(&1) == text(html, "#title")))
    assert review
    refute text(html, "#title") == review.title
  end

  test "the world page shows a skipped puzzle as skipped", %{conn: conn, player: player} do
    [first | _] = Path.ideas(:capture)
    p = hd(first.puzzles)
    {:ok, play} = Play.replay(p, for({:blue, m} <- Play.answer_line(p), do: m))
    {:ok, _} = Progress.record(player, play)

    {:ok, view, html} = live(conn, ~p"/worlds/capture")
    assert text(html, "#puzzle-#{p.id} .puzzle-status-text") == "★★★"
    skipped = Enum.at(first.puzzles, 1)

    assert text(html, "#puzzle-#{skipped.id} .puzzle-status-text") ==
             "Skipped. You know this one."

    # A skipped puzzle stays available.
    {:ok, _view, html} =
      view |> element("#puzzle-#{skipped.id} a") |> render_click() |> follow_redirect(conn)

    assert text(html, "#title") == skipped.title
  end
end
