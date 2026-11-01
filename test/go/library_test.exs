defmodule Go.LibraryTest do
  @moduledoc """
  Each story of the newest version of the library passes the checks of
  the library maker (`Go.Library.Maker`), from the data in the file. A
  sample of the moments runs the full puzzle checks again. The old
  versions stay as they are, for the old links (see `Go.Library`).
  """

  use ExUnit.Case, async: true

  alias Go.{Board, Library, Play, Puzzle, Score}
  alias Go.Library.Maker
  alias Go.Puzzles.{Check, Symmetry}

  @stories Library.all()

  test "the library has stories" do
    refute Enum.empty?(@stories)
    assert length(Enum.uniq_by(@stories, & &1.id)) == length(@stories)
  end

  test "no two stories are the same game (with the rotations)" do
    keys = Enum.map(@stories, &Maker.game_key(&1.moves))
    assert length(Enum.uniq(keys)) == length(keys)
  end

  # In each version: a stone that touches the fight is never dimmed.
  for version <- Library.versions() do
    @version version
    test "version #{version}: no stone next to a road of the target, the answer or a trap is dimmed" do
      for s <- Library.all(@version), m <- s.moments do
        board = Library.board_at(s, m.index)
        roads = Board.group(board, m.goal.target).liberties
        traps = Enum.map(m.diffs, &elem(&1, 0))

        for p <- roads ++ [m.answer | traps],
            q <- Board.neighbors(board, p),
            Board.get(board, q) != nil do
          assert Library.in_window?(m.window, q),
                 "#{s.id}, move #{m.index}: the stone #{inspect(q)} is outside #{inspect(m.window)}"
        end
      end
    end
  end

  for s <- @stories do
    @s s
    test "#{s.id}: passes the checks of a story" do
      s = @s
      assert length(s.moments) >= Maker.min_moments()

      c1 = Enum.count(s.moments, &Library.capture_in_1?/1)
      assert c1 * 2 <= length(s.moments), "more than half of the moments are capture in 1"

      # A close game: by the area score at the end, and by the estimate.
      final = Library.final_board(s)
      area = Score.count(final)
      assert %{blue: area.blue.total, red: area.red.total} == s.score
      assert (area.blue.total - area.red.total) in Maker.margin()
      assert s.estimate >= Maker.margin().first and s.estimate <= Maker.margin().last

      # The game ends with two passes, and the colors take turns.
      assert [{_, :pass}, {_, :pass}] = Enum.take(s.moves, -2)

      assert Enum.map(s.moves, &elem(&1, 0)) ==
               Enum.take(Stream.cycle([:blue, :red]), length(s.moves))

      answers = Enum.map(s.moments, & &1.answer)
      assert answers == Enum.uniq(answers), "two moments have the same answer"

      indexes = Enum.map(s.moments, & &1.index)
      assert indexes == Enum.sort(indexes)
      assert s.grade == round(Enum.sum(Enum.map(s.moments, & &1.grade.score)) / length(s.moments))
      assert s.rank == Maker.rank(s)
    end

    test "#{s.id}: each moment matters, and its window holds the fight" do
      for m <- @s.moments do
        # The answer is the move of the game.
        assert Enum.at(@s.moves, m.index) == {:blue, m.answer}

        # The answer is better than each tempting wrong move by 5 points.
        assert m.diffs != []
        assert Enum.all?(m.diffs, fn {_t, d} -> d >= Maker.min_diff() end)

        puzzle = Library.puzzle(@s, m)
        board = Puzzle.board(puzzle)
        assert Board.get(board, m.goal.target) == if(m.goal.type == :capture, do: :red, else: :blue)

        {r, c, size} = m.window
        assert size in [5, 7, 9] and r >= 0 and c >= 0 and r + size <= 9 and c + size <= 9
        traps = Enum.map(m.diffs, &elem(&1, 0))
        fight = Maker.fight(board, puzzle, %{traps: traps})
        assert Enum.all?(fight, &Library.in_window?(m.window, &1))

        # The book: only the answer is not wrong, and the answer line
        # starts with the answer.
        %{nodes: %{[] => %{taps: first}}} = puzzle.book
        not_wrong = for {p, %{kind: kind}} <- first, kind != :wrong, do: p
        assert not_wrong == [m.answer]
        assert Map.keys(first) |> Enum.sort() == Board.legal_moves(board, :blue)
        assert [{:blue, a} | _] = Play.answer_line(puzzle)
        assert a == m.answer
      end
    end
  end

  # The full puzzle checks are slow on a 9x9 board: they run on a sample.
  for s <- Enum.take_every(@stories, max(div(length(@stories), 12), 1)) do
    @s s
    @tag timeout: :infinity
    test "#{s.id}: the first moment passes the puzzle checks" do
      m = hd(@s.moments)
      puzzle = Library.puzzle(@s, m)
      report = Check.run(puzzle)
      assert report.ok, Enum.join(report.errors, "; ")
      assert report.good == [m.answer]
      assert Enum.sort(report.traps) == Enum.sort(Enum.map(m.diffs, &elem(&1, 0)))
    end
  end

  test "a rotated moment has the rotated answer, and passes the puzzle checks" do
    s = hd(@stories)
    m = hd(s.moments)

    for sym <- [1, 6] do
      rotated = Library.rotate(s, sym)
      rm = hd(rotated.moments)
      f = &Symmetry.map_point(sym, 9, &1)
      puzzle = Library.puzzle(rotated, rm)

      assert rm.answer == f.(m.answer)
      assert Library.board_at(rotated, rm.index).stones ==
               Map.new(Library.board_at(s, m.index).stones, fn {p, c} -> {f.(p), c} end)

      fight = Maker.fight(Puzzle.board(puzzle), puzzle, %{traps: []})
      assert Enum.all?(fight, &Library.in_window?(rm.window, &1))

      report = Check.run(puzzle)
      assert report.ok, Enum.join(report.errors, "; ")
      assert report.good == [rm.answer]
    end
  end

  test "the rotation of a story is the same as the rotation of its puzzles" do
    s = hd(@stories)

    for sym <- 0..7, m <- s.moments do
      rotated = Library.rotate(s, sym)
      rm = Enum.find(rotated.moments, &(&1.index == m.index))
      expected = Symmetry.transform(Library.puzzle(s, m), sym)
      got = Library.puzzle(rotated, rm)

      assert Enum.sort(got.blue) == Enum.sort(expected.blue)
      assert Enum.sort(got.red) == Enum.sort(expected.red)
      assert got.answer == expected.answer
      assert got.goal == expected.goal
      # The book stays unturned; the puzzle keeps the symmetry.
      assert got.book == expected.book
      assert got.sym == sym and expected.sym == sym
    end
  end

  test "the compact format keeps each story" do
    for s <- @stories do
      assert s |> Library.encode() |> JSON.encode!() |> JSON.decode!() |> Library.decode() == s
    end
  end

  test "the window is the smallest square that holds the points, on the board" do
    assert Library.window([{0, 0}, {2, 3}]) == {0, 0, 5}
    assert Library.window([{4, 4}]) == {2, 2, 5}
    assert Library.window([{8, 8}, {6, 7}]) == {4, 4, 5}
    assert Library.window([{1, 1}, {6, 2}]) == {1, 0, 7}
    assert Library.window([{0, 0}, {8, 1}]) == {0, 0, 9}
  end
end
