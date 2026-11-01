defmodule GoWeb.BoardDiffTest do
  @moduledoc """
  A move sends only the points of the board that changed (see
  `GoWeb.BoardComponents.board/1`): not the whole board again. The test
  reads the diffs that the LiveView process sends, and measures them as
  JSON, as on the WebSocket.
  """

  # Not async: the test changes the delay of Red.
  use GoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import GoWeb.PuzzleHelpers

  setup %{conn: conn} do
    Application.put_env(:go, :red_delay, 100)
    on_exit(fn -> Application.put_env(:go, :red_delay, 0) end)
    {conn, _player} = new_player(conn)
    %{conn: conn}
  end

  # The diffs that the LiveView process sent while fun ran, as JSON.
  defp diffs(view, fun) do
    :erlang.trace(view.pid, true, [:send])
    fun.()
    Process.sleep(300)
    :erlang.trace(view.pid, false, [:send])
    collect([])
  end

  defp collect(acc) do
    receive do
      {:trace, _, :send, %Phoenix.Socket.Reply{payload: %{diff: d}}, _} ->
        collect([json(d) | acc])

      {:trace, _, :send, %Phoenix.Socket.Message{event: "diff", payload: d}, _} ->
        collect([json(d) | acc])

      {:trace, _, :send, _, _} ->
        collect(acc)
    after
      100 -> Enum.reverse(acc)
    end
  end

  defp json(diff), do: Phoenix.json_library().encode!(diff)

  test "a tap and the reply of Red send small diffs, with only the changed points", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/play/capture?id=capture-08")
    full = byte_size(html)

    [tap, red] = diffs(view, fn -> tap_point(view, {0, 2}) end)

    # The full page is about 30 KB; a move is a small part of it.
    assert byte_size(tap) < 3_000, "the tap sent #{byte_size(tap)} bytes"
    assert byte_size(red) < 5_000, "the reply of Red sent #{byte_size(red)} bytes"
    assert byte_size(tap) * 8 < full

    # Of the 81 spots for the taps, only the spot of the new stone
    # changes (its label for screen readers).
    assert length(Regex.scan(~r/aria-label=\\"Row /, tap)) == 1
    assert tap =~ ~s(Row 1, column 3: blue tower)
    assert length(Regex.scan(~r/aria-label=\\"Row /, red)) == 1
  end
end
