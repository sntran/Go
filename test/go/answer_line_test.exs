defmodule Go.AnswerLineTest do
  @moduledoc """
  For each moment of each version of the library, and for each of the 8
  rotations of its story: the stored answer line (the line of "Show the
  answer") solves the puzzle with real taps. Red must answer as the shown
  line, also when the board is turned and Red has more than one best move.
  """

  use ExUnit.Case, async: true

  alias Go.{Library, Play}

  # Taps the blue moves of the answer line. Each red reply must be the red
  # move of the line.
  defp play_line(puzzle) do
    Enum.reduce_while(Play.answer_line(puzzle), Play.new(puzzle), fn
      {:blue, p}, play ->
        {:ok, play} = Play.tap(play, p, budget: :infinity)
        {:cont, if(play.status == :red_turn, do: Play.run_red(play), else: play)}

      {:red, r}, play ->
        case List.last(play.moves) do
          {:red, ^r} -> {:cont, play}
          other -> {:halt, %{play | status: {:red_played, other, :line_has, r}}}
        end
    end)
  end

  for version <- Library.versions(), story <- Library.all(version) do
    @story story
    @tag timeout: :infinity
    test "version #{version}, #{story.id}: the answer lines solve the puzzles in all rotations" do
      for sym <- 0..7, rotated = Library.rotate(@story, sym), m <- rotated.moments do
        play = play_line(Library.puzzle(rotated, m))
        assert play.status == :solved, "rotation #{sym}, move #{m.index}: #{inspect(play.status)}"
      end
    end
  end
end
