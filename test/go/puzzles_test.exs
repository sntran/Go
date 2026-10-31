defmodule Go.PuzzlesTest do
  use ExUnit.Case, async: true

  alias Go.{Fixtures, Play, Puzzle, Puzzles}
  alias Go.Puzzles.{Check, Diagram, Generator, Starter, Symmetry, Templates}

  describe "checks" do
    test "the two fixtures pass all checks" do
      assert %{ok: true, good: [{0, 2}], traps: [{0, 4}]} = Check.run(Fixtures.edge_chase())

      assert %{ok: true, good: [{5, 5}], touches_target: false} =
               report = Check.run(Fixtures.net(), deep: 5)

      assert Enum.sort(report.traps) == [{4, 5}, {5, 4}]
    end

    test "a puzzle with two answers fails" do
      p = %{
        Fixtures.edge_chase()
        | red: [{0, 2}],
          goal: %{type: :capture, target: {0, 2}, moves: 1},
          blue: [{0, 1}, {0, 3}]
      }

      assert %{ok: false, errors: [error | _]} = Check.run(p)
      assert error =~ "correct first moves"
    end

    test "a puzzle that is solved in fewer moves fails" do
      p = %{Fixtures.edge_chase() | goal: %{type: :capture, target: {0, 3}, moves: 3}}
      assert %{ok: false, errors: errors} = Check.run(p)
      assert Enum.any?(errors, &(&1 =~ "fewer moves"))
    end

    test "a trap that captures Red some moves later fails the deep check" do
      # On a small board with no red friend, the "wrong" move also captures
      # Red later, because Red runs into the edge.
      d = Diagram.parse([". . . . .", ". . B . .", ". B r . .", ". B . B .", ". . . . ."])

      p = %Puzzle{
        id: "t",
        world: :capture,
        goal: %{type: :capture, target: d.target, moves: 2},
        size: 5,
        blue: d.blue,
        red: d.red
      }

      assert %{ok: false, errors: errors} = Check.run(p)
      assert Enum.any?(errors, &(&1 =~ "do not fail"))
    end

    test "an escape whose answer dies some moves later fails" do
      # Running along the edge gives 2 roads, but Red then chases the tower to the corner.
      d = Diagram.parse([". R b . .", ". . R . .", ". . . . .", ". . . . .", ". . . . ."])

      p = %Puzzle{
        id: "t",
        world: :escape,
        goal: %{type: :escape, target: d.target, moves: 1},
        size: 5,
        blue: d.blue,
        red: d.red
      }

      assert %{ok: false, errors: errors} = Check.run(p)
      assert Enum.any?(errors, &(&1 =~ "correct first moves are []"))
    end
  end

  describe "symmetry" do
    test "the 8 copies of a puzzle have the same key and the same answer" do
      p = Fixtures.net()
      key = Symmetry.key(p)

      for sym <- Symmetry.all() do
        copy = Symmetry.transform(p, sym)
        assert Symmetry.key(copy) == key
        assert %{ok: true, good: [answer]} = Check.run(copy)
        assert answer == copy.answer
      end
    end

    test "different puzzles have different keys" do
      refute Symmetry.key(Fixtures.net()) == Symmetry.key(Fixtures.edge_chase())
    end
  end

  describe "starter set" do
    test "it has no copies, also after rotation or mirroring" do
      keys = Enum.map(Starter.all(), &Symmetry.key/1)
      assert length(Enum.uniq(keys)) == length(keys)
    end

    test "it has 10 to 15 puzzles in each world" do
      counts = Enum.frequencies_by(Starter.all(), & &1.world)
      assert counts.capture in 10..15
      assert counts.escape in 10..15
    end

    for p <- Starter.all() do
      @p p
      test "#{p.id} passes all checks, and its answer is the only good move" do
        report = Check.run(@p)
        assert report.ok, Enum.join(report.errors, "; ")
        assert report.good == [@p.answer]
        for field <- [:title, :say, :hint, :better], do: assert(is_binary(Map.fetch!(@p, field)))
      end

      test "#{p.id}: the hand-written replies punish, and the answer line solves it" do
        board = Puzzle.board(@p)

        for {point, text} <- @p.wrong do
          assert is_binary(text.why)
          {:ok, next, _} = Go.Board.play(board, :blue, point)
          left = Go.Goal.after_blue(@p.goal, @p.goal.moves)

          if reply = text[:reply] do
            assert Play.punishes?(@p.goal, next, left, reply),
                   "reply #{inspect(reply)} to #{inspect(point)}"
          end

          {:ok, play} = Play.replay(@p, [point])
          assert play.status == :failed
          if reply = text[:reply], do: assert(Enum.at(play.moves, 1) == {:red, reply})
          assert play.feedback.why == text.why
          if text.what, do: assert(play.feedback.what == text.what)
        end

        blue = for {:blue, m} <- Play.answer_line(@p), do: m
        assert {:ok, %{status: :solved}} = Play.replay(@p, blue)
      end
    end
  end

  describe "generator" do
    # Small templates with few bases, so that the tests are fast.
    defp small_edge_chase do
      base = %{size: 5, red: [{0, 3}], blue: [{1, 3}], target: {0, 3}, max: 3}

      %{
        Templates.edge_chase()
        | helpers: false,
          bases: fn -> [base, Map.put(%{base | red: [{1, 1} | base.red]}, :fixed, true)] end
      }
    end

    defp small_escape_extend do
      t = Templates.escape_extend()
      %{t | helpers: false, bases: fn -> Enum.take(t.bases.(), 2) end}
    end

    test "each template gives good, different puzzles that pass the checks" do
      %{puzzles: puzzles, stats: stats} =
        Generator.run(templates: [small_edge_chase(), small_escape_extend()])

      assert Enum.map(stats, & &1.template) == [
               "edge_chase",
               "edge_chase_swapped",
               "escape_extend"
             ]

      for s <- stats do
        assert s.good <= s.different and s.different <= s.variations
      end

      assert Enum.find(stats, &(&1.template == "edge_chase")).good > 0
      assert Enum.find(stats, &(&1.template == "escape_extend")).good > 0

      keys = Enum.map(puzzles, &Symmetry.key/1)
      assert length(Enum.uniq(keys)) == length(keys)

      for p <- puzzles do
        assert %{ok: true, good: [answer]} = Check.run(p)
        assert answer == p.answer
        assert p.grade.moves == p.goal.moves
      end
    end

    test "the edge chase in 2 moves with no red helper fails the deep check" do
      %{puzzles: puzzles} = Generator.run(templates: [small_edge_chase()])
      plain = Symmetry.key(%{Fixtures.edge_chase() | red: [{0, 3}]})
      assert Enum.any?(puzzles, &(&1.goal.type == :capture))
      refute Enum.any?(puzzles, &(Symmetry.key(&1) == plain))
      assert Enum.all?(puzzles, &(&1.goal.type == :escape or &1.goal.moves >= 2))
    end

    test "it skips copies of known puzzles" do
      key = Symmetry.key(Fixtures.edge_chase())
      %{puzzles: before} = Generator.run(templates: [small_edge_chase()])
      assert Enum.any?(before, &(Symmetry.key(&1) == key))

      %{puzzles: puzzles} =
        Generator.run(templates: [small_edge_chase()], known: [Fixtures.edge_chase()])

      refute Enum.any?(puzzles, &(Symmetry.key(&1) == key))
    end

    test "the same seed gives the same puzzles" do
      a = Generator.run(templates: [small_edge_chase()], seed: 3)
      b = Generator.run(templates: [small_edge_chase()], seed: 3)
      assert a == b
    end
  end

  describe "bank" do
    test "the bank in priv has both worlds, from easy to hard" do
      for world <- Puzzles.open_worlds() do
        puzzles = Puzzles.world(world)
        assert length(puzzles) >= 20
        scores = Enum.map(puzzles, & &1.grade.score)
        assert scores == Enum.sort(scores)
        assert hd(puzzles).source == :hand
      end
    end

    # The deep checks: a tempting wrong move fails, and the fort of an
    # escape puzzle lives, up to the move limit plus Go.Goal.deep() moves.
    for p <- Puzzles.all() do
      @p p
      test "#{p.id} in the bank passes all checks, also the deep ones" do
        report = Check.run(@p)
        assert report.ok, Enum.join(report.errors, "; ")
        assert report.good == [@p.answer]
      end
    end

    test "each puzzle has a book: the answer is its only first move that is not wrong" do
      for p <- Puzzles.all() do
        assert %{first: first, answer: [{:blue, answer} | _]} = p.book
        assert answer == p.answer
        not_wrong = for {point, %{kind: kind}} <- first, kind != :wrong, do: point
        assert not_wrong == [p.answer], p.id
        assert Map.keys(first) |> Enum.sort() == Go.Board.legal_moves(Puzzle.board(p), :blue)
      end
    end

    test "a puzzle with its book survives the trip to JSON and back" do
      for p <- Enum.take(Puzzles.all(), 10) do
        assert p |> Puzzle.to_map() |> JSON.encode!() |> JSON.decode!() |> Puzzle.from_map() == p
      end
    end

    test "a later tap with no time left decides with the fast search" do
      p = Puzzles.get("capture-12")
      {:ok, play} = Play.tap(Play.new(p), p.answer)
      play = Play.run_red(play)
      {us, {:ok, play}} = :timer.tc(fn -> Play.tap(play, {0, 0}, budget: 0) end)
      assert play.status == :red_turn
      assert us < 1_000_000
    end

    test "the bank has no copies" do
      keys = Enum.map(Puzzles.all(), &Symmetry.key/1)
      assert length(Enum.uniq(keys)) == length(keys)
    end

    test "a puzzle survives the trip to JSON and back" do
      for p <- Starter.all() do
        assert p |> Puzzle.to_map() |> JSON.encode!() |> JSON.decode!() |> Puzzle.from_map() == p
      end
    end

    test "next gives the first open puzzle, and a learned puzzle comes back when it is due" do
      [a, b, c | _] = Puzzles.world(:capture)
      today = ~D[2026-10-31]

      assert Puzzles.next(:capture, nil, %{}, today).id == a.id
      assert Puzzles.next(:capture, a.id, %{a.id => %{status: :solved}}, today).id == b.id

      learned = %{a.id => %{status: :learned, due: ~D[2026-11-03]}, b.id => %{status: :solved}}
      assert Puzzles.next(:capture, b.id, learned, today).id == c.id
      assert Puzzles.next(:capture, b.id, learned, ~D[2026-11-03]).id == a.id
    end
  end
end
