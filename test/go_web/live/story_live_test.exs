defmodule GoWeb.StoryLiveTest do
  use GoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import GoWeb.PuzzleHelpers

  alias Go.{Play, Progress, Stories}

  setup %{conn: conn} do
    {conn, player} = new_player(conn)
    %{conn: conn, player: player}
  end

  # The size of the view, from the label of the board.
  defp view_size(html) do
    case Regex.run(~r/the corner (\d) by \d of 9 by 9/, html) do
      [_, n] -> String.to_integer(n)
      nil -> 9
    end
  end

  defp moment_of(html), do: Regex.run(~r/Moment (\d+) of (\d+)/, text(html, "#kicker"))

  # Plays one story from the start to the score. `wrong?` taps a wrong first
  # move at each moment, else the answer line.
  defp play_story(view, story, wrong?) do
    html = render(view)

    Enum.reduce(Enum.with_index(story.moments, 1), {html, []}, fn {m, k}, {html, views} ->
      assert moment_of(html) == [
               "Moment #{k} of #{length(story.moments)}",
               "#{k}",
               "#{length(story.moments)}"
             ]

      views = [view_size(html) | views]

      html =
        if wrong? do
          wrong =
            Enum.find_value(Enum.sort(m.puzzle.book.first), fn {p, e} ->
              if e.kind == :wrong, do: p
            end)

          html = tap_point(view, wrong)
          assert text(html, "#fb-what") =~ "What happened:"
          assert text(html, "#fb-why") =~ "Why:"
          assert text(html, "#fb-better") =~ "Better move:"
          html
        else
          for {:blue, p} <- Play.answer_line(m.puzzle), reduce: html do
            _ -> tap_point(view, p)
          end
          |> tap(
            &assert(
              text(&1, "#fb-title") in [
                "You caught Red!",
                "Your fort is safe!",
                "Your fort escaped the attack!"
              ]
            )
          )
        end

      assert_next_step(html)
      assert text(html, "#continue") == "Continue the story"
      {click(view, "continue"), views}
    end)
  end

  for {mode, wrong?} <- [{"the correct moves", false}, {"a wrong move at each moment", true}] do
    @wrong wrong?
    test "a story goes on from start to end with #{mode}, and the view grows", %{conn: conn} do
      story = hd(Stories.all())
      {:ok, view, html} = live(conn, ~p"/story")
      assert text(html, "#kicker") =~ story.title

      {html, views} = play_story(view, story, @wrong)
      views = Enum.reverse(views)
      assert views == Enum.sort(views)
      assert List.last(views) > hd(views) or view_size(html) > hd(views)

      # The end of the game: the score, with the fields.
      assert text(html, "#title") == "The end of the game"
      assert text(html, "#score-blue") =~ "Blue:"
      assert text(html, "#score-red") =~ "Red:"
      assert html =~ "data-field="
      assert text(html, "#next-story") == "Next story"
    end
  end

  test "each story plays from start to end", %{conn: conn, player: player} do
    for story <- Stories.all() do
      Progress.put_story(player, %{story: story.id, moment: 1})
      {:ok, view, _html} = live(conn, ~p"/story")
      {html, _views} = play_story(view, story, false)
      assert text(html, "#title") == "The end of the game"
    end
  end

  test "Next story goes to the next story, and the home page continues the story", %{
    conn: conn,
    player: player
  } do
    [first, second | _] = Stories.all()
    Progress.put_story(player, %{story: first.id, moment: :end})
    {:ok, view, html} = live(conn, ~p"/story")
    assert text(html, "#title") == "The end of the game"

    html = click(view, "next-story")
    assert text(html, "#kicker") =~ second.title
    assert moment_of(html) |> hd() == "Moment 1 of #{length(second.moments)}"

    {:ok, _view, html} = live(conn, ~p"/")
    assert text(html, "#story") == "Continue the story"
    assert text(html, ".story-where") =~ second.title
  end

  test "the home page starts with the story", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert text(html, "#story") == "Start the story"
  end
end
