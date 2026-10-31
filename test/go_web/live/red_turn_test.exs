defmodule GoWeb.RedTurnTest do
  # Not async: these tests change the delays of the app.
  use GoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import GoWeb.PuzzleHelpers

  @delay 150

  setup %{conn: conn} do
    Application.put_env(:go, :red_delay, @delay)
    Application.put_env(:go, :watch_delay, @delay)

    on_exit(fn ->
      Application.put_env(:go, :red_delay, 0)
      Application.put_env(:go, :watch_delay, 0)
    end)

    {conn, _player} = new_player(conn)
    %{conn: conn}
  end

  # Waits until a condition is true for the screen, or fails.
  defp eventually(view, fun, tries \\ 40) do
    html = render(view)

    cond do
      fun.(html) -> html
      tries == 0 -> flunk("the screen did not change: " <> (text(html, "#message") || ""))
      true -> Process.sleep(25) && eventually(view, fun, tries - 1)
    end
  end

  test "taps during Red's turn only say \"Wait\"", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/play/capture?id=capture-08")
    html = tap_point(view, {0, 2})
    assert text(html, "#message") == "Red is thinking…"
    assert stone(html, {0, 4}) == nil
    assert html =~ ~r/id="retry"[^>]*disabled/

    html = tap_point(view, {1, 4})
    assert text(html, "#message") == "Wait. Red is thinking."
    assert stone(html, {1, 4}) == nil

    refute html =~ ~s(id="hint")

    html = eventually(view, &(stone(&1, {0, 4}) == :red))
    assert text(html, "#message") =~ "Good move!"
    html = tap_point(view, {1, 4})
    assert text(html, "#fb-title") == "You caught Red!"
  end

  test "Red plays out a long punishment one move at a time", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/play/escape?id=escape-10")
    html = tap_point(view, {4, 2})
    assert text(html, "#feedback") == nil
    html = eventually(view, &(text(&1, "#fb-title") == "Your fort fell"), 80)
    assert_next_step(html)
  end

  test "Watch again shows the moves one by one, then the end again", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/play/capture?id=capture-08")
    tap_point(view, {0, 4})
    final = eventually(view, &(text(&1, "#fb-title") == "Red got away"))

    html = click(view, "watch")
    assert text(html, "#message") == "Watch…"
    assert text(html, "#feedback") == nil
    assert stone(html, {0, 4}) == nil

    html = eventually(view, &(text(&1, "#message") == "Your move…"))
    assert stone(html, {0, 4}) == :blue
    assert stone(html, {0, 2}) == nil

    html = eventually(view, &(text(&1, "#message") == "…then Red's move."))
    assert stone(html, {0, 2}) == :red

    html = eventually(view, &(text(&1, "#fb-title") == "Red got away"))
    assert text(html, "#message") == text(final, "#message")
  end

  test "Show the answer plays the moves one by one", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/play/capture?id=capture-08")
    html = click(view, "show-answer")
    assert text(html, "#message") == "Watch the answer."
    html = eventually(view, &(text(&1, "#fb-title") == "Now you know it"), 80)
    assert stone(html, {0, 3}) == nil
  end
end
