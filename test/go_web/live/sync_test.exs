defmodule GoWeb.SyncTest do
  @moduledoc """
  The safety net of a busy screen: if the page waits on "Red is
  thinking…" for `:sync_after` ms, the hook Busy sends "sync", and the
  server does the step that it waits on. Here Red waits 60 s, as if its
  timer were lost, so only the safety net can bring Red's reply.
  """

  # Not async: the tests change the delays of the app.
  use GoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import GoWeb.PuzzleHelpers

  @wait 200

  setup %{conn: conn} do
    Application.put_env(:go, :red_delay, 60_000)
    Application.put_env(:go, :watch_delay, 60_000)
    Application.put_env(:go, :sync_after, @wait)

    on_exit(fn ->
      Application.put_env(:go, :red_delay, 0)
      Application.put_env(:go, :watch_delay, 0)
      Application.delete_env(:go, :sync_after)
    end)

    {conn, _player} = new_player(conn)
    %{conn: conn}
  end

  defp step(html) do
    [_, step] = Regex.run(~r/id="message"[^>]*data-step="(\d+)"/, html)
    step
  end

  defp busy(html), do: Regex.run(~r/id="message"[^>]*data-busy="(\w+)"/, html) |> List.last()

  test "the page tells the hook the wait, the step and the busy state", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/play/capture?id=capture-08")
    assert html =~ ~r/id="message"[^>]*phx-hook="Busy"/
    assert html =~ ~r/id="message"[^>]*data-wait="#{@wait}"/
    assert busy(html) == "false"

    html = tap_point(view, {0, 2})
    assert text(html, "#message") == "Red is thinking…"
    assert busy(html) == "true"
  end

  test "after the wait, a sync brings the reply of Red", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/play/capture?id=capture-08")
    html = tap_point(view, {0, 2})
    assert stone(html, {0, 4}) == nil
    s = step(html)

    Process.sleep(@wait + 50)
    html = render_hook(view, "sync", %{"step" => s})
    assert stone(html, {0, 4}) == :red
    assert text(html, "#message") =~ "Good move!"
    assert busy(html) == "false"
  end

  test "a sync before the wait, or for an old step, changes nothing", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/play/capture?id=capture-08")
    html = tap_point(view, {0, 2})
    s = step(html)

    # Too early: Red still has time.
    html = render_hook(view, "sync", %{"step" => s})
    assert stone(html, {0, 4}) == nil
    assert text(html, "#message") == "Red is thinking…"

    # An old step: the page did not see the last change yet.
    Process.sleep(@wait + 50)
    html = render_hook(view, "sync", %{"step" => "0"})
    assert stone(html, {0, 4}) == nil

    # A sync on a screen that is not busy does nothing.
    {:ok, view2, html2} = live(conn, ~p"/play/capture?id=capture-08")
    after_sync = render_hook(view2, "sync", %{"step" => step(html2)})
    assert step(after_sync) == step(html2)
    assert busy(after_sync) == "false"
  end

  test "a long punishment of Red goes on with one sync for each move", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/play/escape?id=escape-10")
    html = tap_point(view, {4, 2})

    html =
      Enum.reduce_while(1..30, html, fn _, html ->
        if busy(html) == "true" do
          Process.sleep(@wait + 20)
          {:cont, render_hook(view, "sync", %{"step" => step(html)})}
        else
          {:halt, html}
        end
      end)

    assert text(html, "#fb-title") == "Your fort fell"
  end

  test "Watch again goes on with a sync", %{conn: conn} do
    Application.put_env(:go, :red_delay, 0)
    {:ok, view, _html} = live(conn, ~p"/play/capture?id=capture-08")
    tap_point(view, {0, 4})
    html = click(view, "watch")
    assert text(html, "#message") == "Watch…"
    Process.sleep(@wait + 50)
    html = render_hook(view, "sync", %{"step" => step(html)})
    assert text(html, "#message") == "Your move…"
  end
end
