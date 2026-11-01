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
    def policy({:follow, game}, moves), do: %{elem(Enum.at(game, length(moves)), 1) => 1.0}
    def policy({:board, policy}, _moves), do: policy
    def policy(_state, _moves), do: %{pass: 1.0}

    @impl true
    def score({:flat, _game}, _moves, _visits), do: 0.0

    def score({:line, game}, moves, _visits),
      do: if(List.starts_with?(game, moves), do: 10.0, else: 0.0)

    # The moves of the game are 6 points better with a small search, but
    # only 4 points better with a big search.
    def score({:near, game}, moves, visits) do
      cond do
        not List.starts_with?(game, moves) -> 0.0
        visits >= 200 -> 4.0
        true -> 6.0
      end
    end

    def score({:board, _policy}, [{:blue, {r, c}}], _visits), do: -0.3 * (abs(r - 4) + abs(c - 4))
    def score(_state, _moves, _visits), do: 0.0
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

    assert {:drop, reason} = Maker.story(game, flat, margin: -200..200, books: false)
    assert reason =~ "fewer than #{Maker.min_moments()} moments that matter"
    assert reason =~ "0 after the checks"
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

    assert {:drop, "not a close game by the area score" <> _} =
             Maker.story(game, line, margin: (margin + 1)..(margin + 10), books: false)
  end

  test "a game that does not end with two passes is dropped", %{game: game} do
    line = {LineEvaluator, {:line, game.moves}}
    game = %{game | moves: Enum.drop(game.moves, -2)}
    assert Maker.story(game, line, margin: -200..200) == {:drop, "the game did not end"}
  end

  @tag timeout: :infinity
  test "a difference under 8 points is checked again with 200 visits", %{game: game} do
    near = {LineEvaluator, {:near, game.moves}}

    # With 16 visits each moment is 6 points better, but with 200 visits
    # only 4: all moments drop.
    assert {:drop, reason} = Maker.story(game, near, margin: -200..200, books: false)
    assert reason =~ "0 after the checks"

    # Without the second check, the moments stay.
    assert {:ok, _} =
             Maker.story(game, near, margin: -200..200, books: false, recheck_visits: 16)

    assert Maker.recheck_diffs([{{0, 0}, 6.0}, {{1, 1}, 9.0}], {2, 2}, [], near, 200) == nil
  end

  test "the opening: different moves, not the copies of one move" do
    # On the empty board, the 4 corners of 3-3 are one move.
    policy = %{
      {4, 4} => 0.4,
      {2, 2} => 0.1,
      {2, 6} => 0.1,
      {6, 2} => 0.1,
      {6, 6} => 0.1,
      {3, 4} => 0.05,
      {0, 0} => 0.005
    }

    ev = {LineEvaluator, {:board, policy}}
    moves = Maker.opening_moves(ev, [], policy, Go.Board.new(9), :blue)
    assert {4, 4} in moves and {3, 4} in moves
    assert length(Enum.filter(moves, &(&1 in [{2, 2}, {2, 6}, {6, 2}, {6, 6}]))) == 1
    refute {0, 0} in moves
  end

  test "a game stops at move 10 when 2 stories have its opening", %{game: game} do
    ev = {LineEvaluator, {:follow, game.moves}}
    played = Maker.game(1, ev, opening_full?: fn _key -> true end)
    assert played.gave_up == "an opening that 2 stories have"
    assert length(played.moves) == 10
    assert Maker.story(played, ev) == {:drop, "an opening that 2 stories have"}
  end

  test "the keys of an opening and of a game are the same in each rotation", %{game: game} do
    turned =
      Enum.map(game.moves, fn
        {c, :pass} -> {c, :pass}
        {c, p} -> {c, Go.Puzzles.Symmetry.map_point(5, 9, p)}
      end)

    assert Maker.opening_key(turned) == Maker.opening_key(game.moves)
    assert Maker.game_key(turned) == Maker.game_key(game.moves)
    refute Maker.game_key(Enum.drop(turned, -2)) == Maker.game_key(game.moves)
  end

  test "a game with too few moments is dropped" do
    game = %{seed: 1, moves: [{:blue, :pass}, {:red, :pass}], moments: [], gave_up: false}
    assert {:drop, "fewer than 4 moments that matter" <> _} = Maker.story(game, nil)
    assert {:drop, _} = Maker.story(%{game | gave_up: true}, nil)
  end
end
