defmodule GoWeb.PlayerTest do
  use GoWeb.ConnCase, async: true

  @year 365 * 24 * 60 * 60

  test "the session cookie lives for one year, and each visit sends it again", %{conn: conn} do
    conn = get(conn, ~p"/")
    cookie = conn.resp_cookies["_go_key"]
    assert cookie.max_age == @year
    player = get_session(conn, "player_id")
    assert is_binary(player)

    # The next visit sends the cookie again (a new year), with the same player.
    conn = conn |> recycle() |> get(~p"/")
    assert conn.resp_cookies["_go_key"].max_age == @year
    assert get_session(conn, "player_id") == player
  end
end
