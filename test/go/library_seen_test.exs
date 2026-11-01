defmodule Go.Library.SeenTest do
  @moduledoc """
  A new version of the library starts daily runs only when it is live: on
  the later of its `daily_from` date and the first date that had not
  started anywhere on Earth when the server first saw it.
  """

  use ExUnit.Case, async: true

  alias Go.Library
  alias Go.Library.Seen

  test "a version first seen after its daily_from starts on the next free date" do
    # November 5 at 10:00 UTC is already November 6 in UTC+14.
    assert Library.daily_start(~D[2026-11-03], ~U[2026-11-05 10:00:00Z]) == ~D[2026-11-07]
    assert Library.daily_start(~D[2026-11-03], ~U[2026-11-05 09:59:59Z]) == ~D[2026-11-06]
    # Seen on its daily_from: that date has started somewhere already.
    assert Library.daily_start(~D[2026-11-03], ~U[2026-11-03 00:00:00Z]) == ~D[2026-11-04]
  end

  test "a version first seen early starts on its daily_from" do
    assert Library.daily_start(~D[2026-11-03], ~U[2026-11-01 09:00:00Z]) == ~D[2026-11-03]
    # The next free date is the daily_from.
    assert Library.daily_start(~D[2026-11-03], ~U[2026-11-01 10:00:00Z]) == ~D[2026-11-03]
  end

  test "the daily run of a date keeps its version when a version is live late" do
    versions = Library.versions()
    [older, newest] = Enum.take(versions, -2)
    from = Library.daily_from(newest)
    early = Map.new(versions, &{&1, ~U[2000-01-01 00:00:00Z]})

    # Seen early: the newest version starts on its daily_from.
    assert Library.daily_version(Date.add(from, -1), early) == older
    assert Library.daily_version(from, early) == newest

    # Seen at noon UTC 2 days after its daily_from (then the next date has
    # started in UTC+14): the dates up to that next date keep the older
    # version, and the date after it takes the new one.
    late = Map.put(early, newest, DateTime.new!(Date.add(from, 2), ~T[12:00:00], "Etc/UTC"))
    assert Library.daily_version(Date.add(from, 2), late) == older
    assert Library.daily_version(Date.add(from, 3), late) == older
    assert Library.daily_version(Date.add(from, 4), late) == newest
  end

  test "the server stores the first time of a version one time" do
    # Versions that are not files, so that the test does not touch the real ones.
    t1 = ~U[2026-11-01 08:00:00Z]
    t2 = ~U[2026-11-04 08:00:00Z]
    v = 9000 + System.unique_integer([:positive])

    assert Seen.fetch([v, v + 1], t1) == %{v => t1, (v + 1) => t1}
    assert Seen.fetch([v, v + 1, v + 2], t2) == %{v => t1, (v + 1) => t1, (v + 2) => t2}
  end

  test "each version of the library has a first time" do
    seen = Seen.all()
    assert Enum.sort(Map.keys(seen)) == Library.versions()
  end
end
