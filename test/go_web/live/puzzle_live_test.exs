defmodule GoWeb.PuzzleLiveTest do
  use GoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import GoWeb.PuzzleHelpers

  alias Go.{Play, Progress, Puzzles}
  alias Go.Puzzles.Starter

  setup %{conn: conn} do
    {conn, player} = new_player(conn)
    %{conn: conn, player: player}
  end

  defp open(conn, id) do
    p = Puzzles.get(id)
    {:ok, view, html} = live(conn, ~p"/play/#{p.world}?id=#{id}")
    {view, html}
  end

  describe "home" do
    test "shows the worlds, and the capture world opens", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/")
      assert html =~ "Start a new run"
      assert html =~ "Capture"
      assert html =~ "Escape"
      assert html =~ "Soon"

      {:ok, _view, html} =
        view |> element("#world-capture") |> render_click() |> follow_redirect(conn)

      assert text(html, "#title") == "Close the last road"
    end

    test "an unknown world goes back home", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/play/nothing")
    end
  end

  describe "the correct line" do
    test "edge chase: Red runs, then Blue captures, with 3 stars", %{conn: conn, player: player} do
      {view, html} = open(conn, "capture-08")
      assert text(html, "#moves-left") == "Moves left: 2"

      html = tap_point(view, {0, 2})
      assert stone(html, {0, 2}) == :blue
      assert stone(html, {0, 4}) == :red
      assert text(html, "#message") =~ "Good move!"
      assert text(html, "#moves-left") == "Moves left: 1"
      assert_next_step(html)

      html = tap_point(view, {1, 4})
      assert stone(html, {0, 3}) == nil
      assert stone(html, {0, 4}) == nil
      assert html =~ ~s(class="tower tower-red fall")
      assert text(html, "#fb-title") == "You caught Red!"
      assert text(html, "#message") =~ "3 stars"
      assert html =~ ~s(aria-label="3 stars")
      assert text(html, "#next") == "Next puzzle"

      assert %{"capture-08" => %{status: :solved, stars: 3}} = Progress.results(player)

      assert [%{result: :solved, moves: [blue: {0, 2}, red: {0, 4}, blue: {1, 4}]}] =
               Progress.attempts(player)
    end

    test "net: the answer does not touch Red", %{conn: conn} do
      {view, _html} = open(conn, "capture-12")
      html = tap_point(view, {5, 5})
      assert text(html, "#message") =~ "Good move!"
      red = if stone(html, {5, 4}) == :red, do: {5, 4}, else: {4, 5}
      assert stone(html, red) == :red

      html = if red == {5, 4}, do: tap_point(view, {6, 4}), else: tap_point(view, {4, 6})
      assert text(html, "#message") =~ "Good move!"
      html = if red == {5, 4}, do: tap_point(view, {4, 6}), else: tap_point(view, {6, 4})
      assert text(html, "#fb-title") == "You caught Red!"
    end

    test "escape: Blue runs to open space", %{conn: conn} do
      {view, html} = open(conn, "escape-08")
      assert text(html, "#moves-left") == "Red moves left: 2"
      html = tap_point(view, {2, 1})
      assert text(html, "#fb-title") == "Your fort escaped the attack!"
    end
  end

  describe "a typical wrong move" do
    test "shows Red's punishment and the three parts", %{conn: conn} do
      {view, _html} = open(conn, "capture-08")
      html = tap_point(view, {0, 4})

      assert stone(html, {0, 2}) == :red
      assert text(html, "#fb-title") == "Red is still free"

      assert text(html, "#fb-what") ==
               "What happened: Red ran to the left, toward its friend. Now it has 2 roads."

      assert text(html, "#fb-why") =~ "Why: Your move closed the road toward the corner."
      assert text(html, "#fb-better") =~ "Better move: Build to the left of the red tower."
      assert_next_step(html)
    end

    test "in an escape puzzle, the fort crumbles", %{conn: conn} do
      {view, _html} = open(conn, "escape-08")
      html = tap_point(view, {0, 0})

      assert stone(html, {2, 1}) == :red
      assert stone(html, {1, 0}) == nil
      assert html =~ ~s(class="tower tower-blue fall")
      assert text(html, "#fb-title") == "Your fort fell"
      assert text(html, "#fb-what") =~ "3 of your towers fell"
      assert text(html, "#fb-why") =~ "Your fort ran into the corner."
      assert text(html, "#fb-better") =~ "Run down, out to open space."
    end

    test "Red plays out the whole punishment in a longer escape", %{conn: conn} do
      {view, _html} = open(conn, "escape-10")
      html = tap_point(view, {4, 2})
      assert text(html, "#fb-title") == "Your fort fell"
      assert text(html, "#fb-what") =~ "one by one"
      assert text(html, "#fb-why") =~ "edge"
      assert text(html, "#watch") == "Watch again"
    end

    test "a move far away gets a generated explanation", %{conn: conn} do
      {view, _html} = open(conn, "capture-12")
      html = tap_point(view, {0, 0})
      assert text(html, "#fb-what") =~ "Red ran"
      assert text(html, "#fb-why") =~ "far from the fight"
      assert text(html, "#fb-better") =~ "like a net"
    end
  end

  describe "the help buttons" do
    test "Show the better move marks the point, and Go back one move undoes the wrong move", %{
      conn: conn,
      player: player
    } do
      {view, _html} = open(conn, "capture-08")
      html = tap_point(view, {0, 4})
      refute html =~ "data-glow"

      html = click(view, "show-better")
      assert html =~ ~s(data-glow="0-2")
      refute html =~ ~s(data-glow="0-4")
      refute html =~ ~s(id="show-better")

      html = click(view, "back")
      assert stone(html, {0, 4}) == nil
      assert stone(html, {0, 2}) == nil
      assert text(html, "#feedback") == nil
      assert text(html, "#moves-left") == "Moves left: 2"
      assert text(html, "#message") =~ "went back one move"

      tap_point(view, {0, 2})
      html = tap_point(view, {1, 4})
      assert text(html, "#fb-title") == "You caught Red!"
      # Two helps: the better move and the go back.
      assert html =~ ~s(aria-label="1 stars")
      assert %{"capture-08" => %{status: :solved, stars: 1}} = Progress.results(player)
    end

    test "Go back once gives 2 stars", %{conn: conn} do
      {view, _html} = open(conn, "capture-08")
      tap_point(view, {0, 4})
      click(view, "back")
      tap_point(view, {0, 2})
      html = tap_point(view, {1, 4})
      assert html =~ ~s(aria-label="2 stars")
    end

    test "Watch again plays the last moves again and ends where it was", %{conn: conn} do
      {view, _html} = open(conn, "capture-08")
      before = tap_point(view, {0, 4})
      html = click(view, "watch")
      assert stone(html, {0, 4}) == :blue
      assert stone(html, {0, 2}) == :red
      assert text(html, "#fb-title") == text(before, "#fb-title")
      assert text(html, "#message") == text(before, "#message")
    end

    test "Try again starts the puzzle again, and a solve after it gives 2 stars", %{conn: conn} do
      {view, _html} = open(conn, "capture-08")
      tap_point(view, {0, 4})
      html = click(view, "retry")
      assert stone(html, {0, 4}) == nil
      assert stone(html, {0, 2}) == nil
      assert text(html, "#feedback") == nil
      assert text(html, "#moves-left") == "Moves left: 2"

      tap_point(view, {0, 2})
      html = tap_point(view, {1, 4})
      assert html =~ ~s(aria-label="2 stars")
    end

    test "a hint makes some spots glow, and costs one star", %{conn: conn} do
      {view, html} = open(conn, "capture-08")
      refute html =~ "data-glow"
      html = click(view, "hint")
      assert html =~ ~s(data-glow="0-2")
      assert text(html, "#message") == "Which road leads away from the corner?"

      tap_point(view, {0, 2})
      html = tap_point(view, {1, 4})
      assert html =~ ~s(aria-label="2 stars")
    end

    test "two hints and a try again give 1 star", %{conn: conn} do
      {view, _html} = open(conn, "capture-08")
      click(view, "hint")
      tap_point(view, {0, 4})
      click(view, "retry")
      click(view, "hint")
      tap_point(view, {0, 2})
      html = tap_point(view, {1, 4})
      assert html =~ ~s(aria-label="1 stars")
    end

    test "Show the answer gives \"learned\", not \"solved\"", %{conn: conn, player: player} do
      {view, _html} = open(conn, "capture-08")
      html = click(view, "show-answer")
      assert stone(html, {0, 2}) == :blue
      assert stone(html, {0, 3}) == nil
      assert text(html, "#fb-title") == "Now you know it"
      assert text(html, "#fb-why") =~ "comes back in a few days"
      refute html =~ "stars-big"
      assert text(html, "#next") == "Next puzzle"

      assert %{"capture-08" => %{status: :learned, due: due}} = Progress.results(player)
      assert Date.compare(due, Date.utc_today()) == :gt

      # A solve after the answer does not count as solved.
      click(view, "retry")
      tap_point(view, {0, 2})
      tap_point(view, {1, 4})
      assert %{"capture-08" => %{status: :learned}} = Progress.results(player)
    end

    test "a learned puzzle comes back when it is due" do
      results = %{"capture-01" => %{status: :learned, due: Date.add(Date.utc_today(), 3)}}
      refute Puzzles.next(:capture, nil, results, Date.utc_today()).id == "capture-01"

      assert Puzzles.next(:capture, nil, results, Date.add(Date.utc_today(), 3)).id ==
               "capture-01"
    end
  end

  describe "Next puzzle" do
    test "goes to the next puzzle of the path", %{conn: conn, player: player} do
      {view, _html} = open(conn, "capture-01")
      tap_point(view, {2, 3})
      click(view, "next")
      {next, :new} = Go.Path.next(:capture, Progress.results(player), 0, Date.utc_today())
      assert_patch(view, ~p"/play/capture?id=#{next.id}")
      assert text(render(view), "#title") == next.title
    end

    test "the first open puzzle skips solved ones", %{conn: conn} do
      {view, _html} = open(conn, "capture-01")
      tap_point(view, {2, 3})
      {:ok, _view, html} = live(conn, ~p"/play/capture")
      refute text(html, "#title") == "Close the last road"
    end

    test "after the last puzzle of the world, it shows the end", %{conn: conn, player: player} do
      for p <- Puzzles.world(:escape) do
        blue = for {:blue, m} <- Play.answer_line(p), do: m
        {:ok, play} = Play.replay(p, blue)
        {:ok, _} = Progress.record(player, play)
      end

      {:ok, _view, html} = live(conn, ~p"/play/escape")
      assert html =~ "You finished the path of this world!"
      assert text(html, "#home") == "Choose a world"
    end
  end

  describe "taps" do
    test "a tap on an occupied point changes nothing and tells why", %{conn: conn} do
      {view, _html} = open(conn, "capture-08")
      html = tap_point(view, {0, 3})
      assert text(html, "#message") =~ "There is a tower on that spot already"
      assert text(html, "#feedback") == nil
      assert text(html, "#moves-left") == "Moves left: 2"
      html = tap_point(view, {1, 3})
      assert text(html, "#message") =~ "There is a tower on that spot already"
    end

    test "a tap on an illegal point changes nothing and tells why", %{conn: conn} do
      {puzzle, point} =
        Enum.find_value(Puzzles.all(), fn p ->
          board = Go.Puzzle.board(p)

          s =
            Enum.find(
              Go.Board.points(board),
              &(Go.Board.play(board, :blue, &1) == {:error, :suicide})
            )

          s && {p, s}
        end)

      {view, _html} = open(conn, puzzle.id)
      html = tap_point(view, point)
      assert text(html, "#message") =~ "You cannot build there"
      assert stone(html, point) == nil
      assert text(html, "#feedback") == nil
    end

    test "a tap after the end changes nothing", %{conn: conn} do
      {view, _html} = open(conn, "capture-01")
      tap_point(view, {2, 3})
      html = tap_point(view, {0, 0})
      assert stone(html, {0, 0}) == nil
      assert text(html, "#message") =~ "You solved this puzzle"
      assert_next_step(html)
    end
  end

  test "the look changes to a real Go board and stays", %{conn: conn} do
    {view, html} = open(conn, "capture-01")
    assert html =~ ~s(class="tower tower-red danger")
    html = click(view, "look-board")
    assert html =~ ~s(class="stone stone-red)
    refute html |> LazyHTML.from_document() |> LazyHTML.query("#board .tower") |> Enum.any?()
    assert html =~ "black stones"

    {_view, html} = open(conn, "capture-01")
    assert html =~ ~s(class="stone stone-red)
  end

  test "the hard puzzles hide the road counts", %{conn: conn} do
    hard = Enum.find(Puzzles.all(), & &1.hide_roads)
    easy = Puzzles.get("capture-01")
    {_view, html} = open(conn, hard.id)
    refute html =~ "data-road"
    assert html =~ "Count the roads yourself!"
    {_view, html} = open(conn, easy.id)
    assert html =~ "data-road"
  end

  test "the page never has the answer before the player asks for help", %{conn: conn} do
    for p <- Starter.all() do
      {_view, html} = open(conn, p.id)
      refute html =~ "data-glow"
      refute html =~ (p.better || "no better text")
    end
  end

  describe "each starter puzzle, with real clicks" do
    for p <- Starter.all() do
      @p p

      test "#{p.id}: the answer line solves it, and each typical wrong move teaches", %{
        conn: conn
      } do
        {view, _html} = open(conn, @p.id)

        html =
          @p
          |> Play.answer_line()
          |> Enum.filter(&match?({:blue, _}, &1))
          |> Enum.reduce(nil, fn {:blue, point}, _ ->
            html = tap_point(view, point)
            assert_next_step(html)
            html
          end)

        assert text(html, "#fb-title") in [
                 "You caught Red!",
                 "Your fort is safe!",
                 "Your fort escaped the attack!"
               ]

        assert_next_step(html)

        for {point, _text} <- @p.wrong do
          click(view, "retry")
          html = tap_point(view, point)
          assert text(html, "#fb-what") =~ "What happened:"
          assert text(html, "#fb-why") =~ "Why:"
          assert text(html, "#fb-better") =~ "Better move:"
          assert_next_step(html)
          html = click(view, "show-better")
          assert html =~ ~s(data-glow="#{elem(@p.answer, 0)}-#{elem(@p.answer, 1)}")
        end
      end
    end
  end
end
