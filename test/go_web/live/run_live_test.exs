defmodule GoWeb.RunLiveTest do
  use GoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import GoWeb.PuzzleHelpers

  alias Go.{Play, Progress, Runs}

  @seed Runs.code(Go.Library.newest(), "8F3K")

  setup %{conn: conn} do
    {conn, player} = new_player(conn)
    %{conn: conn, player: player}
  end

  defp puzzle_of(html), do: Regex.run(~r/Puzzle (\d+) of (\d+)/, text(html, "#kicker"))

  # The puzzle that the page shows now, from the run of the player.
  defp current_puzzle(player, seed) do
    place = Progress.run_place(player, seed)
    stage = Enum.at(Runs.run(seed, place.level).stages, place.stage - 1)
    Runs.puzzle(stage, Enum.at(stage.puzzles, place.moment - 1))
  end

  # Plays the current puzzle with the answer line, or with a wrong first
  # move.
  defp play_puzzle(view, puzzle, wrong?) do
    if wrong? do
      wrong =
        Enum.find_value(Enum.sort(puzzle.book.first), fn {p, e} -> if e.kind == :wrong, do: p end)

      if wrong do
        html = tap_point(view, wrong)
        assert text(html, "#fb-what") =~ "What happened:"
        assert text(html, "#fb-why") =~ "Why:"
        html
      else
        click(view, "show-answer")
      end
    else
      html =
        for {:blue, p} <- Play.answer_line(puzzle), reduce: nil do
          _ -> tap_point(view, p)
        end

      assert text(html, "#fb-title") in [
               "You caught Red!",
               "Your fort is safe!",
               "Your fort escaped the attack!"
             ]

      html
    end
  end

  # Plays one stage from its first puzzle to its end page.
  defp play_stage(view, player, seed, wrong?) do
    html = render(view)
    [_, _, total] = puzzle_of(html)

    for k <- 1..String.to_integer(total), reduce: html do
      html ->
        assert puzzle_of(html) |> Enum.at(1) == "#{k}"
        html = play_puzzle(view, current_puzzle(player, seed), wrong?)
        assert_next_step(html)
        assert text(html, "#continue") == "Continue the story"
        click(view, "continue")
    end
  end

  test "Start a new run goes to a run with a new seed, and the page shows the seed", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/run/" <> seed}}} = live(conn, ~p"/run/new")
    assert Runs.parse(seed) == seed
    assert Runs.split(seed) |> elem(0) == Go.Library.newest()

    {:ok, _view, html} = live(conn, ~p"/run/#{seed}")
    assert text(html, "#seed") == seed
    assert text(html, "#kicker") =~ "Stage 1 of 5"
  end

  test "the daily run is the run of the date of the player", %{conn: conn, player: player} do
    date = Runs.today(nil)
    tomorrow = Date.add(date, 1)

    # No date from the browser: the UTC date.
    assert {:error, {:live_redirect, %{to: to}}} = live(conn, ~p"/run/daily")
    assert to == "/run/#{Runs.daily_code(date)}?day=#{date}"

    # The date of the browser, when it is today somewhere.
    for day <- [date, tomorrow] do
      conn = put_connect_params(conn, %{"date" => Date.to_iso8601(day)})
      expected = if Runs.today_somewhere?(day), do: day, else: date
      assert {:error, {:live_redirect, %{to: to}}} = live(conn, ~p"/run/daily")
      assert to == "/run/#{Runs.daily_code(expected)}?day=#{expected}"
    end

    # A date that is not today anywhere opens the UTC date.
    conn2 = put_connect_params(conn, %{"date" => Date.to_iso8601(Date.add(date, 3))})
    assert {:error, {:live_redirect, %{to: to}}} = live(conn2, ~p"/run/daily")
    assert to == "/run/#{Runs.daily_code(date)}?day=#{date}"

    # The run keeps its date, and the results of a stage have it.
    code = Runs.daily_code(date)
    {:ok, view, html} = live(conn, "/run/#{code}?day=#{date}")
    assert text(html, "#daily") =~ "Daily run of"
    assert Progress.run_place(player, code).daily == date
    play_stage(view, player, code, false)
    assert [%{daily: ^date, stage: 1}] = Progress.stage_results(player)
  end

  test "a day that does not match the code is not a daily run", %{conn: conn, player: player} do
    date = Runs.today(nil)
    {:ok, _view, _html} = live(conn, "/run/#{@seed}?day=#{date}")
    assert Progress.run_place(player, @seed).daily == (if Runs.daily_code(date) == @seed, do: date)
  end

  test "an old link with no version opens the run of version 1", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/run/1-8F3K"}}} = live(conn, ~p"/run/8F3K")
    {:ok, _view, html} = live(conn, ~p"/run/1-8F3K")
    assert text(html, "#seed") == "1-8F3K"
  end

  test "a code that is not a seed goes home", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/run/hello")
  end

  test "a run plays from stage 1 to the end with the correct moves", %{conn: conn, player: player} do
    {:ok, view, _html} = live(conn, ~p"/run/#{@seed}")

    for stage <- 1..5 do
      html = play_stage(view, player, @seed, false)
      assert text(html, "#kicker") =~ "Stage #{stage} of 5"

      if stage == 5 do
        assert text(html, "#title") == "The end of the game"
        assert text(html, "#score-blue") =~ "Blue:"
        assert html =~ "data-field="
        assert text(html, "#next-stage") == "See the result of the run"
      else
        assert text(html, "#title") == "Stage #{stage} is over"
        assert text(html, "#next-stage") == "Next stage"
      end

      assert text(html, "#stage-result") =~ "★★★"
      click(view, "next-stage")
    end

    html = render(view)
    assert text(html, "#title") == "You finished the run!"
    assert text(html, "#seed") == @seed
    assert text(html, "#share") =~ "/run/#{@seed}"

    # Each stage result stays for a later leaderboard: 3 stars, no help.
    results = Progress.stage_results(player) |> Enum.filter(&(&1.seed == @seed))
    assert length(results) == 5
    assert Enum.all?(results, fn st -> Enum.all?(st.results, &(&1.stars == 3 and &1.help == 0)) end)
    assert [%{seed: @seed}] = Progress.finished_runs(player)
  end

  test "a stage goes on after a wrong move at each puzzle", %{conn: conn, player: player} do
    {:ok, view, _html} = live(conn, ~p"/run/#{@seed}")
    html = play_stage(view, player, @seed, true)
    assert text(html, "#title") == "Stage 1 is over"
  end

  test "the board dims the part outside the fight, and a tap there still plays", %{
    conn: conn,
    player: player
  } do
    {:ok, _view, _html} = live(conn, ~p"/run/#{@seed}")
    place = Progress.run_place(player, @seed)
    run = Runs.run(@seed, place.level)

    # A puzzle of the run with a window smaller than the board.
    {stage, k, moment} =
      Enum.find_value(run.stages, fn stage ->
        stage.puzzles
        |> Enum.with_index(1)
        |> Enum.find_value(fn {m, k} -> if elem(m.window, 2) < 9, do: {stage, k, m} end)
      end)

    Progress.put_run_place(player, %{place | stage: stage.number, moment: k})
    {:ok, view, html} = live(conn, ~p"/run/#{@seed}")
    assert html =~ "dim-outside"

    board = Go.Library.board_at(stage.story, moment.index)

    outside =
      Enum.find(Go.Board.legal_moves(board, :blue), &(not Go.Library.in_window?(moment.window, &1)))

    if outside do
      html = tap_point(view, outside)
      assert stone(html, outside) == :blue
    end
  end

  test "the run goes on after a reload, and the home page continues it", %{
    conn: conn,
    player: player
  } do
    {:ok, view, _html} = live(conn, ~p"/run/#{@seed}")
    play_puzzle(view, current_puzzle(player, @seed), false)
    click(view, "continue")
    place = Progress.run_place(player, @seed)

    {:ok, _view, html} = live(conn, ~p"/run/#{@seed}")
    assert Progress.run_place(player, @seed) == place

    if is_integer(place.moment) do
      assert puzzle_of(html) |> Enum.at(1) == "#{place.moment}"
    end

    {:ok, _view, html} = live(conn, ~p"/")
    assert text(html, "#continue-run") == "Continue the run"
    assert text(html, ".story-where") =~ "Run #{@seed}"
  end

  test "a saved place that the run does not have starts the stage again", %{
    conn: conn,
    player: player
  } do
    {:ok, _view, _html} = live(conn, ~p"/run/#{@seed}")
    place = Progress.run_place(player, @seed)
    Progress.put_run_place(player, %{place | moment: 99})

    {:ok, _view, html} = live(conn, ~p"/run/#{@seed}")
    assert puzzle_of(html) |> Enum.at(1) == "1"
    assert Progress.run_place(player, @seed).moment == 1
  end

  test "a shared link gives a new player the same games", %{conn: conn, player: player} do
    {:ok, _view, html} = live(conn, ~p"/run/#{@seed}")

    {conn2, friend} = new_player(conn)
    {:ok, _view, html2} = live(conn2, ~p"/run/#{@seed}")
    assert text(html2, "#seed") == @seed

    # Both players start at level 1: the same story, rotation and puzzle.
    assert Progress.run_place(friend, @seed).level == Progress.run_place(player, @seed).level
    assert current_puzzle(friend, @seed) == current_puzzle(player, @seed)
    assert board_part(html) == board_part(html2)
  end

  defp board_part(html), do: html |> LazyHTML.from_document() |> LazyHTML.query("#board") |> LazyHTML.to_html()

  test "the home page starts a new run and the daily run", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert text(html, "#new-run") == "Start a new run"
    assert text(html, "#daily-run") == "Play the daily run"
    assert text(html, "#continue-run") == nil

    date = Runs.today(nil)
    conn = put_connect_params(conn, %{"date" => Date.to_iso8601(date)})
    {:ok, _view, html} = live(conn, ~p"/")
    assert text(html, "#daily-code") == "Today: #{Runs.daily_code(date)}"
  end
end
