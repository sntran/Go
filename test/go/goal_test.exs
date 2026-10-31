defmodule Go.GoalTest do
  use ExUnit.Case, async: true

  alias Go.{Board, Goal, Play}
  alias Go.Puzzles.{Diagram, Starter}

  defp starter(id), do: Enum.find(Starter.all(), &(&1.id == id))

  describe "escape: the fort is safe only when it really lives" do
    setup do
      # The first version of escape-05 (issue 2). Blue takes the red stone
      # at (0,2) and has 2 roads. Red cannot catch the fort in its 1 move,
      # but it catches the fort 5 moves later.
      d = Diagram.parse([". B R b .", ". . . R .", ". R R . .", ". . . . .", ". . . . ."])
      goal = %{type: :escape, target: d.target, moves: 1}
      %{goal: goal, board: Board.new(5, d.blue, d.red)}
    end

    test "the move is not good, and the goal is not reached", %{goal: goal, board: board} do
      refute Goal.good_move?(goal, board, 1, {1, 2})
      {:ok, next, [{0, 2}]} = Board.play(board, :blue, {1, 2})
      refute Goal.reached?(goal, next, 1)
    end

    test "with a friend, the same move is good, and the fort is safe", %{goal: goal, board: board} do
      board = %{board | stones: Map.put(board.stones, {2, 3}, :blue)}
      assert Goal.good_move?(goal, board, 1, {1, 2})
      {:ok, next, _} = Board.play(board, :blue, {1, 2})
      assert Goal.reached?(goal, next, 1)
    end
  end

  test "capture: a wrong move that is only too slow does not say that Red got away" do
    # capture-01: after a move corner to corner, Red runs and has 3 roads.
    # Blue has no moves left, but on this small board Blue can catch Red
    # later.
    {:ok, play} = Play.replay(starter("capture-01"), [{1, 1}])
    assert play.status == :failed
    assert play.feedback.title == "Not fast enough"
    assert play.feedback.why =~ "You could catch Red later, but not in time."
  end

  test "capture: a tempting wrong move that really fails says that Red got away" do
    {:ok, play} = Play.replay(starter("capture-08"), [{0, 4}])
    assert play.feedback.title == "Red got away"
  end
end
