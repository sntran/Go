defmodule Go.StoriesTest do
  use ExUnit.Case, async: true

  alias Go.{Board, Play, Puzzle, Stories}
  alias Go.Puzzles.Check

  test "there are 3 stories, each with 5 moments or more, at least 4 moves apart" do
    stories = Stories.all()
    assert length(stories) == 3

    for s <- stories do
      assert length(s.moments) >= 5
      indexes = Enum.map(s.moments, & &1.index)
      assert indexes == Enum.sort(indexes)
      assert Enum.all?(Enum.zip(indexes, tl(indexes)), fn {a, b} -> b - a >= 4 end)
      # The game ends with two passes.
      assert [{_, :pass}, {_, :pass}] = Enum.take(s.moves, -2)
    end
  end

  test "the views grow and never become smaller, and each view holds its board" do
    for s <- Stories.all() do
      views = Enum.map(s.moments, & &1.view)
      assert views == Enum.sort(views)

      for m <- s.moments do
        board = Stories.board_at(s, m.index)
        assert Stories.view(board, 5, [m.puzzle.answer]) <= m.view
      end
    end
  end

  test "the board of a moment is the full 9x9 board of the game" do
    for s <- Stories.all(), m <- s.moments do
      board = Stories.board_at(s, m.index)
      assert m.puzzle.size == 9
      assert Puzzle.board(m.puzzle).stones == board.stones
    end
  end

  for s <- Stories.all(), m <- s.moments do
    @m m
    @s s
    @tag timeout: :infinity
    test "#{m.puzzle.id}: passes the puzzle checks, and its answer is the move of the game" do
      assert Enum.at(@s.moves, @m.index) == {:blue, @m.puzzle.answer}
      report = Check.run(@m.puzzle)
      assert report.ok, Enum.join(report.errors, "; ")
      assert report.good == [@m.puzzle.answer]

      # The book has the answer as the only first move that is not wrong.
      not_wrong = for {p, %{kind: kind}} <- @m.puzzle.book.first, kind != :wrong, do: p
      assert not_wrong == [@m.puzzle.answer]

      assert Map.keys(@m.puzzle.book.first) |> Enum.sort() ==
               Board.legal_moves(Puzzle.board(@m.puzzle), :blue)

      assert [{:blue, a} | _] = Play.answer_line(@m.puzzle)
      assert a == @m.puzzle.answer
    end
  end

  test "the score counts stones, fields and the komi" do
    board = Board.from_rows(["B B . . .", "B . B . .", "B B R R R", ". . R . .", ". . R . ."])
    score = Go.Score.count(%{board | size: 5})
    assert score.blue.fields == 1
    assert score.blue.stones == 6
    assert score.blue.total == 6 + 1
    assert score.red.total == 5 + Go.Score.komi() + score.red.fields
  end
end
