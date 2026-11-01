defmodule GoWeb.MoveLiveTest do
  use GoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import GoWeb.PuzzleHelpers

  alias Go.{Progress, Transfer}

  test "a code moves the progress to another device", %{conn: conn} do
    # The first device has progress.
    {conn1, owner} = new_player(conn)
    Progress.put_run_place(owner, %{seed: "1-8F3K", level: 1, stage: 2, moment: 1, results: []})

    {:ok, view, html} = live(conn1, ~p"/move")
    assert text(html, "#title") == "Move my progress to another device"
    html = click(view, "make-code")
    shown = text(html, "#code")
    assert shown =~ ~r/^[2-9A-Z]{5}-[2-9A-Z]{5}$/

    # The other device types the code.
    {conn2, other} = new_player(conn)
    conn2 = post(conn2, ~p"/move", %{"code" => shown})
    assert redirected_to(conn2) == "/"
    assert get_session(conn2, "player_id") == owner
    assert other != owner

    # The other device now has the progress.
    {:ok, _view, html} = conn2 |> recycle() |> live(~p"/")
    assert text(html, "#continue-run") == "Continue the run"
    assert text(html, ".story-where") =~ "Run 1-8F3K · Stage 2 of 5"
  end

  test "a used, an old or a wrong code changes nothing", %{conn: conn} do
    {_conn1, owner} = new_player(conn)
    {code, _} = Transfer.create(owner)
    {:ok, ^owner} = Transfer.redeem(code, "someone")

    {conn2, other} = new_player(conn)

    for typed <- [code, "AAAAAAAAAA"] do
      conn3 = post(conn2, ~p"/move", %{"code" => typed})
      assert redirected_to(conn3) == "/move"
      assert get_session(conn3, "player_id") == other
      assert Phoenix.Flash.get(conn3.assigns.flash, :error) =~ "This code does not work"
    end
  end

  test "after 5 wrong codes, the page tells to wait one hour", %{conn: conn} do
    {conn2, _other} = new_player(conn)
    for _ <- 1..5, do: post(conn2, ~p"/move", %{"code" => "AAAAAAAAAA"})
    conn3 = post(conn2, ~p"/move", %{"code" => "AAAAAAAAAA"})
    assert Phoenix.Flash.get(conn3.assigns.flash, :error) =~ "Try again in one hour"
  end

  test "the home page has a link to the page", %{conn: conn} do
    {conn, _} = new_player(conn)
    {:ok, _view, html} = live(conn, ~p"/")
    assert text(html, "#move-link") == "Move my progress to another device"
  end
end
