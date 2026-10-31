defmodule Go.GoalTest do
  use ExUnit.Case, async: true

  alias Go.{Board, Goal, Life, Play, Puzzle}
  alias Go.Puzzles.{Diagram, Starter}

  defp starter(id), do: Enum.find(Starter.all(), &(&1.id == id))

  describe "escape: a move is good only when the fort lives deeper" do
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

    test "with a friend, the same move is good", %{goal: goal, board: board} do
      board = %{board | stones: Map.put(board.stones, {2, 3}, :blue)}
      assert Goal.good_move?(goal, board, 1, {1, 2})
      {:ok, next, _} = Board.play(board, :blue, {1, 2})
      assert Goal.reached?(goal, next, 1)
    end
  end

  # The cases of issue 13: Blue still catches Red some moves later, so the
  # texts must not say "got away".
  @late [
    {"capture-01", [{0, 0}, {0, 1}, {0, 4}]},
    {"capture-04", [{0, 0}, {0, 2}, {0, 4}]},
    {"capture-05", [{0, 0}, {0, 1}, {0, 2}]},
    {"capture-07", [{2, 3}]}
  ]

  for {id, moves} <- @late, move <- moves do
    @id id
    @move move
    test "#{id}: after the wrong move #{inspect(move)}, the texts do not say \"got away\"" do
      {:ok, play} = Play.replay(starter(@id), [@move])
      assert play.status == :failed
      assert play.feedback.title == "Red is still free"
      texts = [play.feedback.title, play.feedback.what, play.feedback.why, play.message]
      refute Enum.any?(texts, &(&1 && &1 =~ "got away"))
      assert play.feedback.why =~ ~r/catch Red|not enough/
    end
  end

  test "the first escape puzzle of the issue: the texts do not say \"safe\"" do
    # The first version of escape-01 (issue 13): Red catches the fort 8 red
    # moves after the answer.
    d = Diagram.parse([". . . . .", ". . R . .", ". R b . .", ". . R . .", ". . . . ."])

    p = %Puzzle{
      id: "old-escape-01",
      world: :escape,
      goal: %{type: :escape, target: d.target, moves: 1},
      size: 5,
      blue: d.blue,
      red: d.red,
      answer: {2, 3}
    }

    {:ok, play} = Play.replay(p, [{2, 3}])
    assert play.status == :solved
    assert play.feedback.title == "Your fort escaped the attack!"
    refute play.feedback.why =~ "safe"
  end

  test "escape-01 says \"safe\", because Benson's algorithm proves it" do
    {:ok, play} = Play.replay(starter("escape-01"), [{2, 1}])
    assert play.feedback.title == "Your fort is safe!"
    assert Life.alive?(play.board, {3, 1})
  end
end
