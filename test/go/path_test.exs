defmodule Go.PathTest do
  use ExUnit.Case, async: true

  alias Go.Path

  @today ~D[2026-11-01]

  defp ideas, do: Path.ideas(:capture)
  defp first_of(idea), do: hd(idea.puzzles)

  test "the ideas of a world come in the order of the world, and the first one is a test" do
    [first | _] = ideas()
    assert first.idea == "capture_in_1"
    assert {p, :new} = Path.next(:capture, %{}, 0, @today)
    assert p.id == first_of(first).id
  end

  test "a clean solve of the first puzzle skips the other puzzles of the idea" do
    [first, second | _] = ideas()
    results = %{first_of(first).id => %{status: :solved, stars: 3}}

    assert {p, :new} = Path.next(:capture, results, 1, @today)
    assert p.template == second.idea
    assert Path.status(Enum.at(first.puzzles, 1), first, results) == :skipped
  end

  test "a solve with a hint gives the next puzzle of the same idea" do
    [first | _] = ideas()
    results = %{first_of(first).id => %{status: :solved, stars: 2}}

    assert {p, :new} = Path.next(:capture, results, 1, @today)
    assert p.template == first.idea
    assert p.id == Enum.at(first.puzzles, 1).id
  end

  test "a failure gives the next puzzle of the same idea" do
    [first | _] = ideas()
    results = %{first_of(first).id => %{status: :tried}}

    assert {p, :new} = Path.next(:capture, results, 1, @today)
    assert p.id == Enum.at(first.puzzles, 1).id
  end

  test "after 2 finished ideas, every 4th puzzle is a review of an earlier idea" do
    [first, second, third | _] = ideas()

    results = %{
      first_of(first).id => %{status: :solved, stars: 3},
      first_of(second).id => %{status: :solved, stars: 3}
    }

    assert {p, :new} = Path.next(:capture, results, 2, @today)
    assert p.template == third.idea

    assert {review, :review} = Path.next(:capture, results, 3, @today)
    assert review.template == first.idea
    assert results[review.id] == nil
  end

  test "with 1 finished idea, there is no review" do
    [first | _] = ideas()
    results = %{first_of(first).id => %{status: :solved, stars: 3}}
    assert {_p, :new} = Path.next(:capture, results, 10, @today)
  end

  test "a review title tells only the goal" do
    p = Enum.find(Go.Puzzles.all(), &(&1.id == "capture-12"))
    assert p.title == "The big net"
    assert Path.review_title(p) == "Catch the red tower in 3 moves"
  end
end
