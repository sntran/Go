defmodule GoWeb.CapacityTest do
  # The limit is a global setting, so these tests do not run at the same
  # time as others.
  use GoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Go.Capacity

  setup do
    Capacity.reset()
    old = Application.get_env(:go, :player_limit)

    on_exit(fn ->
      Application.put_env(:go, :player_limit, old)
      Capacity.reset()
    end)

    :ok
  end

  defp limit(n), do: Application.put_env(:go, :player_limit, n)

  defp player(conn, id), do: init_test_session(conn, %{"player_id" => id})

  # A connected page of the player.
  defp page(id) do
    {:ok, view, _html} = live(player(build_conn(), id), ~p"/")
    view
  end

  # Closes a page, and waits until the count has it.
  defp leave(view) do
    ref = Process.monitor(view.pid)
    Process.unlink(view.pid)
    Process.exit(view.pid, :kill)
    assert_receive {:DOWN, ^ref, :process, _, _}
    # The DOWN of Go.Capacity comes after the DOWN of this test process,
    # or at the same time: a call to it is in the queue after its DOWN.
    _ = Capacity.count()
  end

  defp refused?(id, path \\ "/") do
    conn = get(player(build_conn(), id), path)
    conn.status == 503 and conn.resp_body =~ "Too many players are here now."
  end

  test "at the limit, a new player is refused; when players leave, a new player comes in" do
    limit(2)
    a = page("a")
    b = page("b")
    assert Capacity.count() == 2

    assert refused?("c")

    leave(a)
    leave(b)
    assert Capacity.count() == 0

    refute refused?("c")
    assert {:ok, _view, _html} = live(player(build_conn(), "c"), ~p"/")
    assert Capacity.count() == 1
  end

  test "the memory of the VM does not decide" do
    # The peak of the VM never shrinks. Only the count of pages decides.
    limit(1)
    assert Capacity.memory() > 1024 * 1024
    view = page("first")
    assert refused?("second")
    leave(view)
    refute refused?("second")
  end

  test "the page of a refused player has a button to try again", %{conn: conn} do
    limit(1)
    _ = page("here")

    conn = get(player(conn, "new-player"), "/worlds/escape?x=1")
    html = html_response(conn, 503)
    assert html =~ "Too many players are here now."
    assert html =~ "Try again in one minute."
    assert html =~ ~s(id="retry")
    assert html =~ ~s(href="/worlds/escape?x=1")
    assert get_resp_header(conn, "retry-after") == ["60"]
  end

  test "a player without a cookie is also refused", %{conn: conn} do
    limit(1)
    _ = page("here")
    assert get(conn, "/") |> html_response(503) =~ "Too many players"
  end

  test "at the limit, a player who is connected continues to play" do
    limit(1)
    view = page("here")
    # The live view that is open works.
    assert render(view) =~ "Tower Go"
    # A new page of the same player (a reload) also opens.
    assert {:ok, _view, _html} = live(player(build_conn(), "here"), ~p"/")
    assert Capacity.count() == 2
    # Another player gets the page "Too many players".
    assert refused?("other")
  end

  test "a new live view on the same connection comes in (a live navigation)" do
    limit(1)
    transport = spawn(fn -> Process.sleep(:infinity) end)
    test = self()

    views =
      for player <- ["a", "a", "b"] do
        spawn(fn ->
          send(test, {:joined, self(), Capacity.join(player, transport)})
          Process.sleep(:infinity)
        end)
      end

    for v <- views, do: assert_receive({:joined, ^v, :ok})
    assert Capacity.count() == 1
    assert Capacity.join("c", spawn(fn -> Process.sleep(:infinity) end)) == :full
  end

  test "players who join at the same time do not pass the limit" do
    limit(8)
    test = self()

    for i <- 1..20 do
      spawn(fn ->
        transport = spawn(fn -> Process.sleep(:infinity) end)
        send(test, {:joined, Capacity.join("p#{i}", transport)})
        Process.sleep(:infinity)
      end)
    end

    results =
      for _ <- 1..20 do
        assert_receive {:joined, result}
        result
      end

    assert Enum.count(results, &(&1 == :ok)) == 8
    assert Enum.count(results, &(&1 == :full)) == 12
    assert Capacity.count() == 8
  end

  test "a new live view connection at the limit loads the page again", %{conn: conn} do
    limit(1)
    # The page loads under the limit...
    conn = get(player(conn, "late"), "/worlds/escape")
    assert html_response(conn, 200)

    # ...but another player connects first.
    _ = page("first")
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
    limit(nil)
    for i <- 1..3, do: page("p#{i}")
    refute refused?("new")
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

    test "gives the memory and the count when it is on", %{conn: conn} do
      Application.put_env(:go, :memory_stats, true)
      limit(8)
      _ = page("a")
      body = get(conn, "/stats/memory") |> json_response(200)
      # Natively, there is no memory of WebAssembly.
      assert body["vm"] == nil
      assert body["erlang_total"] > 1024 * 1024
      assert body["pages"] == 1
      assert body["player_limit"] == 8
    end
  end
end
