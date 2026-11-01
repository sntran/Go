defmodule Go.RunsTest do
  use ExUnit.Case, async: true

  alias Go.{Library, Runs}
  alias Go.Puzzles.Symmetry

  defp summary(run) do
    for st <- run.stages do
      {st.story.id, st.sym, st.from, st.to, Enum.map(st.moments, & &1.index),
       Enum.map(st.puzzles, & &1.index), Enum.map(st.puzzles, & &1.answer)}
    end
  end

  test "the same seed gives the same run, also after a restart" do
    for level <- 1..3 do
      first = Runs.run("8F3K", level)
      assert Runs.run("8F3K", level) == first

      # A restart: the library comes from the file again.
      Library.reload()
      assert summary(Runs.run("8F3K", level)) == summary(first)
    end
  end

  test "different seeds give different runs" do
    runs = for seed <- ~w(2222 8F3K ZZZZ AB7Q 9XK3), do: summary(Runs.run(seed, 2))
    assert length(Enum.uniq(runs)) > 1
  end

  test "a run has 5 stages, from short parts to the full game" do
    for seed <- ~w(8F3K AB7Q 9XK3) do
      run = Runs.run(seed, 1)
      assert Enum.map(run.stages, & &1.number) == [1, 2, 3, 4, 5]
      [s1, s2, s3, s4, s5] = run.stages

      for {st, n} <- [{s1, 2}, {s2, 2}, {s3, 3}, {s4, 4}] do
        assert length(st.moments) == min(n, length(st.story.moments))
        refute st.full
        assert st.from <= hd(st.moments).index
        assert st.to > List.last(st.moments).index
      end

      assert s5.full
      assert s5.from == 0 and s5.to == length(s5.story.moves)
      assert s5.moments == s5.story.moments
    end
  end

  test "the seed chooses a rotation, and the moments of the rotated story are correct" do
    run = Runs.run("8F3K", 3)

    for st <- run.stages do
      original = Library.get(st.story.id)
      assert Library.rotate(original, st.sym) == st.story
      f = &Symmetry.map_point(st.sym, 9, &1)

      for m <- st.moments do
        om = Enum.find(original.moments, &(&1.index == m.index))
        assert m.answer == f.(om.answer)
        assert Enum.at(st.story.moves, m.index) == {:blue, m.answer}
      end
    end
  end

  test "a stronger player gets more puzzles, and harder ones" do
    for seed <- ~w(8F3K AB7Q) do
      [l1, l2, l3] = for level <- 1..3, do: Runs.run(seed, level)

      for {a, b, c} <- Enum.zip([l1.stages, l2.stages, l3.stages]) do
        # The same stories and rotations for all levels.
        assert {a.story.id, a.sym} == {b.story.id, b.sym}
        assert {b.story.id, b.sym} == {c.story.id, c.sym}
        assert length(a.puzzles) <= length(b.puzzles)
        assert length(b.puzzles) <= length(c.puzzles)
        assert c.puzzles == c.moments
        assert a.puzzles != [] and Enum.all?(a.puzzles, &(&1 in a.moments))
      end
    end
  end

  test "the seeds" do
    seed = Runs.new_seed()
    assert Runs.parse(seed) == seed
    assert Runs.parse(String.downcase(seed)) == seed
    assert Runs.parse("8f3k ") == "8F3K"
    assert Runs.parse("O0I1") == nil
    assert Runs.parse("ABCDE") == nil

    day = ~D[2026-11-01]
    assert Runs.daily_seed(day) == Runs.daily_seed(day)
    assert Runs.parse(Runs.daily_seed(day)) == Runs.daily_seed(day)
    assert Runs.daily_seed(day) != Runs.daily_seed(Date.add(day, 1))
  end

  test "the level of a new player is 1" do
    assert Runs.level("test-new-#{System.unique_integer([:positive])}") == 1
  end
end
