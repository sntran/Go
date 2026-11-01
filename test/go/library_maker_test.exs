defmodule Go.Library.MakerTest do
  @moduledoc """
  The checks of the library maker, with simple evaluators in place of
  KataGo. The games come from `Go.SelfPlay`.
  """

  use ExUnit.Case, async: true

  alias Go.{Board, Library, SelfPlay}
  alias Go.Library.Maker

  defmodule LineEvaluator do
    @moduledoc """
    Knows one game. `:line`: the moves of the game are 10 points better
    than all other moves. `:flat`: all moves are the same (no move changes
    the score).
    """
    @behaviour Go.Library.Evaluator

    @impl true
    def policy(_state, _moves), do: %{pass: 1.0}

    @impl true
    def score({:flat, _game}, _moves, _visits), do: 0.0

    def score({:line, game}, moves, _visits),
      do: if(List.starts_with?(game, moves), do: 10.0, else: 0.0)
  end

  # The moments of a game: the positions where the move of the game is a
  # puzzle answer that matters.
  defp scan(moves) do
    ev = {LineEvaluator, {:line, moves}}

    {found, _board} =
      moves
      |> Enum.with_index()
      |> Enum.reduce({[], Board.new(9)}, fn {{color, move}, i}, {acc, board} ->
        acc =
          with :blue <- color,
               {_, _} <- move,
               true <- acc == [] or i - hd(acc).index >= 4,
               %{} = m <- Maker.find_moment(board, Enum.take(moves, i), ev),
               true <- m.puzzle.answer == move do
            [Map.put(m, :index, i) | acc]
          else
            _ -> acc
          end

        {:ok, board, _} = Board.play(board, color, move)
        {acc, board}
      end)

    Enum.reverse(found)
  end

  setup_all do
    moves = SelfPlay.game(9)
    %{game: %{seed: 9, moves: moves, moments: scan(moves), gave_up: false}}
  end

  @tag timeout: :infinity
  test "a story whose moments do not change the score is dropped", %{game: game} do
    assert length(game.moments) >= Maker.min_moments()
    flat = {LineEvaluator, {:flat, game.moves}}

    assert Maker.story(game, flat, margin: -200..200, books: false) ==
             {:drop, "fewer than #{Maker.min_moments()} moments that matter"}
  end

  @tag timeout: :infinity
  test "a story whose moments matter is kept", %{game: game} do
    line = {LineEvaluator, {:line, game.moves}}
    assert {:ok, story} = Maker.story(game, line, margin: -200..200, books: false)
    assert length(story.moments) >= Maker.min_moments()
    assert Enum.all?(story.moments, fn m -> Enum.all?(m.diffs, &(elem(&1, 1) >= 5)) end)

    c1 = Enum.count(story.moments, &Library.capture_in_1?/1)
    assert c1 * 2 <= length(story.moments)
  end

  test "a game that is not close is dropped", %{game: game} do
    line = {LineEvaluator, {:line, game.moves}}
    margin = Go.Score.count(Library.final_board(game))
    margin = margin.blue.total - margin.red.total

    assert {:drop, "not a close game by the area score"} =
             Maker.story(game, line, margin: (margin + 1)..(margin + 10), books: false)
  end

  test "a game with too few moments is dropped" do
    game = %{seed: 1, moves: [{:blue, :pass}, {:red, :pass}], moments: [], gave_up: false}
    assert Maker.story(game, nil) == {:drop, "fewer than 4 moments that matter"}
    assert {:drop, _} = Maker.story(%{game | gave_up: true}, nil)
  end
end
