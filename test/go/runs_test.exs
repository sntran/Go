defmodule Go.RunsTest do
  use ExUnit.Case, async: true

  alias Go.{Library, Runs}
  alias Go.Puzzles.Symmetry

  # The run 1-8F3K at level 1, as the first deploy made it (version 1).
  @run_1_8f3k [
    {"story-2964", 4},
    {"story-787", 0},
    {"story-315", 0},
    {"story-2000", 6},
    {"story-348", 1}
  ]

  defp c(seed), do: Runs.code(Library.newest(), seed)

  defp summary(run) do
    for st <- run.stages do
      {st.story.id, st.sym, st.from, st.to, Enum.map(st.moments, & &1.index),
       Enum.map(st.puzzles, & &1.index), Enum.map(st.puzzles, & &1.answer)}
    end
  end

  test "the same seed gives the same run, also after a restart" do
    for level <- 1..3 do
      first = Runs.run(c("8F3K"), level)
      assert Runs.run(c("8F3K"), level) == first

      # A restart: the library comes from the file again.
      Library.reload()
      assert summary(Runs.run(c("8F3K"), level)) == summary(first)
    end
  end

  test "different seeds give different runs" do
    runs = for seed <- ~w(2222 8F3K ZZZZ AB7Q 9XK3), do: summary(Runs.run(c(seed), 2))
    assert length(Enum.uniq(runs)) > 1
  end

  test "a run has 5 stages, from short parts to the full game" do
    for seed <- ~w(8F3K AB7Q 9XK3) do
      run = Runs.run(c(seed), 1)
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
    run = Runs.run(c("8F3K"), 3)

    for st <- run.stages do
      original = Library.get(st.story.id, Library.newest())
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
      [l1, l2, l3] = for level <- 1..3, do: Runs.run(c(seed), level)

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

  test "the seeds and the run codes" do
    seed = Runs.new_seed()
    newest = Library.newest()
    assert Runs.parse(c(seed)) == c(seed)
    assert Runs.parse(String.downcase(c(seed))) == c(seed)
    assert Runs.parse(" #{newest}-8f3k ") == c("8F3K")
    assert Runs.new_code() =~ ~r/^#{newest}-[2-9A-Z]{4}$/
    assert Runs.split(c("8F3K")) == {newest, "8F3K"}
    # An old link with no version is a run of version 1.
    assert Runs.parse("8F3K") == "1-8F3K"
    assert Runs.parse("#{newest + 1}-8F3K") == nil
    assert Runs.parse("O0I1") == nil
    assert Runs.parse("ABCDE") == nil
    assert Runs.parse("1-2-ABCD") == nil

    day = ~D[2026-11-01]
    assert Runs.daily_seed(day) == Runs.daily_seed(day)
    assert Runs.daily_seed(day) != Runs.daily_seed(Date.add(day, 1))
    assert Runs.parse(Runs.daily_code(day)) == Runs.daily_code(day)
  end

  test "the daily run uses the date of the player, when it is today somewhere" do
    noon = ~U[2026-11-01 12:00:00Z]
    # Today in UTC+14 (2 in the morning of November 2).
    assert Runs.today("2026-11-02", noon) == ~D[2026-11-02]
    # Not today anywhere: the UTC date.
    assert Runs.today("2026-11-03", noon) == ~D[2026-11-01]
    assert Runs.today("2026-10-30", noon) == ~D[2026-11-01]
    # October 31 ends at noon UTC in UTC-12.
    assert Runs.today("2026-10-31", ~U[2026-11-01 11:59:00Z]) == ~D[2026-10-31]
    assert Runs.today("2026-10-31", noon) == ~D[2026-11-01]
    # No date, or no real date.
    assert Runs.today(nil, noon) == ~D[2026-11-01]
    assert Runs.today("tomorrow", noon) == ~D[2026-11-01]
    # Texas at 7 pm on November 1 (1 in the morning UTC on November 2).
    assert Runs.today("2026-11-01", ~U[2026-11-02 01:00:00Z]) == ~D[2026-11-01]
  end

  test "a seed keeps its run: the run depends only on the stories of its version" do
    for version <- Library.versions() do
      code = Runs.code(version, "8F3K")
      assert Runs.run(code, 2) == Runs.run(code, 2, Library.all(version))
    end

    # One story more would change the run, so a change is a new version.
    stories = Library.all(1)
    extra = %{hd(stories) | id: "story-extra", rank: 1000}
    refute summary(Runs.run("1-8F3K", 2)) == summary(Runs.run("1-8F3K", 2, stories ++ [extra]))
  end

  test "the run of an old link stays the same in each later version" do
    # Version 1 is the library of the first deploy. Its run 1-8F3K at level
    # 1 must never change.
    run = Runs.run("1-8F3K", 1)
    assert Enum.map(run.stages, &{&1.story.id, &1.sym}) == @run_1_8f3k
  end

  test "the level of a new player is 1" do
    assert Runs.level("test-new-#{System.unique_integer([:positive])}") == 1
  end
end
