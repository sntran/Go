defmodule GoWeb.RunMemoryTest do
  @moduledoc """
  One Durable Object serves all players, and on WebAssembly the memory of
  its VM never shrinks (see docs/load-test.md). A run page keeps only its
  stage, and its process stays small after a collection.

  Not async: the test measures memory.
  """

  use GoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import GoWeb.PuzzleHelpers

  alias Go.{Library, Runs}

  @tag timeout: :infinity
  test "a run page keeps only its stage, and needs little memory" do
    code = Runs.code(Library.newest(), "CK6H")
    {conn, _} = new_player(build_conn())
    {:ok, view, _html} = live(conn, ~p"/run/#{code}")

    state = :sys.get_state(view.pid)
    assigns = state.socket.assigns
    assert %{seed: ^code, level: 1} = assigns.run
    refute Map.has_key?(assigns.run, :stages)
    assert assigns.stage.number == 1

    :erlang.garbage_collect(view.pid)
    {:memory, bytes} = Process.info(view.pid, :memory)
    assert bytes < 400_000, "a run page needs #{bytes} bytes"
  end

  test "the processes hibernate after 1 s with no message" do
    assert GoWeb.Endpoint.config(:live_view)[:hibernate_after] == 1_000
  end
end
