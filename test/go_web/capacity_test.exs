defmodule GoWeb.CapacityTest do
  # The limit is a global setting, so these tests do not run at the same
  # time as others.
  use GoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Go.Capacity

  setup do
    Capacity.reset()
    old = Application.get_env(:go, :memory_limit_mb)
    on_exit(fn -> Application.put_env(:go, :memory_limit_mb, old) end)
    :ok
  end

  # 1 MB: the VM always uses more, so the server is full.
  defp full, do: Application.put_env(:go, :memory_limit_mb, 1)
  defp open, do: Application.put_env(:go, :memory_limit_mb, nil)

  defp player(conn, id), do: init_test_session(conn, %{"player_id" => id})

  test "the memory of the VM is known natively" do
    assert Capacity.memory() > 1024 * 1024
  end

  test "under the limit, a new player comes in", %{conn: conn} do
    Application.put_env(:go, :memory_limit_mb, 100_000)
    refute Capacity.full?()
    assert {:ok, _view, _html} = live(player(conn, "new-player"), ~p"/")
  end

  test "above the limit, a new player gets the page with a button to try again", %{conn: conn} do
    full()
    assert Capacity.full?()

    conn = get(player(conn, "new-player"), "/worlds/escape?x=1")
    html = html_response(conn, 503)
    assert html =~ "Too many players are here now."
    assert html =~ "Try again in one minute."
    assert html =~ ~s(id="retry")
    assert html =~ ~s(href="/worlds/escape?x=1")
    assert get_resp_header(conn, "retry-after") == ["60"]
  end

  test "a player without a cookie is also refused", %{conn: conn} do
    full()
    assert get(conn, "/") |> html_response(503) =~ "Too many players"
  end

  test "above the limit, a player who is already here continues to play", %{conn: conn} do
    open()
    {:ok, view, _html} = live(player(conn, "here"), ~p"/")
    assert Capacity.here?("here")

    full()
    # The live view that is open works.
    assert render(view) =~ "Tower Go"
    # A new page of the same player also opens.
    assert {:ok, _view, _html} = live(player(build_conn(), "here"), ~p"/")
    # Another player gets the page "Too many players".
    assert get(player(build_conn(), "other"), "/") |> html_response(503) =~ "Too many players"
  end

  test "an event of a live view keeps the player here", %{conn: conn} do
    open()
    {:ok, view, _html} = live(player(conn, "tapper"), ~p"/move")
    Capacity.reset()
    refute Capacity.here?("tapper")
    render_click(view, "make_code", %{})
    assert Capacity.here?("tapper")
  end

  test "a new live view connection above the limit loads the page again", %{conn: conn} do
    open()
    # The page loads under the limit...
    conn = get(player(conn, "late"), "/worlds/escape")
    assert html_response(conn, 200)

    # ...but the server is full when the live view connects.
    full()
    conn = put_connect_params(conn, %{"_here" => "/worlds/escape"})
    assert {:error, {:redirect, %{to: "/worlds/escape"}}} = live(conn)
  end

  test "the path to try again is only a path of this site" do
    assert GoWeb.Capacity.safe_path("/run/abc?x=1") == "/run/abc?x=1"
    assert GoWeb.Capacity.safe_path("//evil.example") == "/"
    assert GoWeb.Capacity.safe_path("/\\evil.example") == "/"
    assert GoWeb.Capacity.safe_path("https://evil.example") == "/"
    assert GoWeb.Capacity.safe_path(nil) == "/"
  end

  test "the guard is off with no limit" do
    open()
    refute Capacity.full?()
    assert Capacity.admit?(nil)
  end

  describe "GET /stats/memory" do
    setup do
      old = Application.get_env(:go, :memory_stats)
      on_exit(fn -> Application.put_env(:go, :memory_stats, old) end)
    end

    test "is off by default", %{conn: conn} do
      Application.put_env(:go, :memory_stats, false)
      assert get(conn, "/stats/memory").status == 404
    end

    test "gives the memory when it is on", %{conn: conn} do
      Application.put_env(:go, :memory_stats, true)
      full()
      body = get(conn, "/stats/memory") |> json_response(200)
      # Natively, there is no memory of WebAssembly.
      assert body["vm"] == nil
      assert body["erlang_total"] > 1024 * 1024
      assert body["limit"] == 1024 * 1024
      assert body["full"] == true
    end
  end
end
