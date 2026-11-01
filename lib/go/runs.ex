defmodule Go.Runs do
  @moduledoc """
  Runs: 5 stages, and each stage is one story of `Go.Library`. A seed (4
  letters and digits, for example `8F3K`) chooses the run. The same seed
  always gives the same run, on each device and after a restart: the
  server makes all choices with its own random generator from the seed.
  No neural network runs on the server.

  For each stage, the seed chooses the story and one of the 8 rotations or
  mirrors (`Go.Puzzles.Symmetry`). The stages become harder:

    * The stories come from 5 tiers of the library, from the easiest grade
      to the hardest. Stage 1 takes a story of tier 1, and so on. A story
      with a higher rank score has a bigger chance.
    * Stages 1 and 2 are short parts of a story: the 2 easiest moments
      that come one after the other. Stages 3 and 4 are longer parts (3
      and 4 moments, the hardest ones). Stage 5 is the full game, to the
      score.

  The level of the player (1 to 3) chooses which moments are puzzles. The
  computer plays the other moments. A stronger player gets more moments as
  puzzles, and harder ones. The level is fixed at the start of a run.
  """

  alias Go.{Library, Path, Progress, Puzzles}

  @stages 5
  @alphabet ~c"23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
  @length 4
  @moves_before 6
  @moves_after 2

  # For each level: the highest grade of a puzzle, and the most puzzles in
  # a stage.
  @levels %{1 => {34, 2}, 2 => {46, 3}, 3 => {:infinity, 99}}

  def stages, do: @stages

  ## Seeds

  @doc "A new seed, by chance."
  def new_seed, do: for(_ <- 1..@length, into: "", do: <<Enum.random(@alphabet)>>)

  @doc "The seed of the daily run: one seed for each day, the same for all players."
  def daily_seed(date \\ Date.utc_today()) do
    n =
      :erlang.phash2({:daily_run, Date.to_iso8601(date)}, Integer.pow(length(@alphabet), @length))

    encode(n, @length, "")
  end

  defp encode(_n, 0, acc), do: acc

  defp encode(n, k, acc),
    do:
      encode(
        div(n, length(@alphabet)),
        k - 1,
        <<Enum.at(@alphabet, rem(n, length(@alphabet)))>> <> acc
      )

  ## Run codes

  @doc """
  The code of a run: the version of the library and the seed, for example
  `2-8F3K`. The link of a run has its code (`/run/2-8F3K`), so a run stays
  the same when the library has a new version.
  """
  def code(version, seed), do: "#{version}-#{seed}"

  @doc "The code of a new run: the newest version of the library, and a new seed."
  def new_code, do: code(Library.newest(), new_seed())

  @doc "The version and the seed of a run code."
  def split(code) do
    [version, seed] = String.split(code, "-")
    {String.to_integer(version), seed}
  end

  @doc """
  The run code in its normal form, or nil when it is not a code of a run of
  this library. A code with no version (an old link, for example `8F3K`)
  is a run of version 1.
  """
  def parse(text) when is_binary(text) do
    text = text |> String.trim() |> String.upcase()

    {version, seed} =
      case String.split(text, "-") do
        [seed] -> {"1", seed}
        [version, seed] -> {version, seed}
        _ -> {nil, nil}
      end

    with true <- is_binary(seed) and seed?(seed),
         {v, ""} <- Integer.parse(version || ""),
         true <- Library.version?(v) do
      code(v, seed)
    else
      _ -> nil
    end
  end

  def parse(_text), do: nil

  defp seed?(seed),
    do: byte_size(seed) == @length and seed |> to_charlist() |> Enum.all?(&(&1 in @alphabet))

  ## The daily run

  @doc """
  The code of the daily run of a date: the seed of the date, and the
  version of the library for the date (see `Go.Library.daily_version/2`).
  All players of one date play the same run.
  """
  def daily_code(date),
    do: code(Library.daily_version(date, Library.Seen.all()), daily_seed(date))

  @doc """
  The date of the daily run for a player: the date that the browser sends
  (the date of its time zone), when it is today somewhere on Earth. Else
  (no date, or a date that is not today anywhere) the UTC date. Thus a
  changed time zone cannot open the run of tomorrow early.
  """
  def today(text, now \\ DateTime.utc_now()) do
    with true <- is_binary(text),
         {:ok, date} <- Date.from_iso8601(text),
         true <- today_somewhere?(date, now) do
      date
    else
      _ -> DateTime.to_date(now)
    end
  end

  @doc """
  True when the date is today somewhere on Earth: the time zones go from
  14 hours before UTC (UTC+14) to 12 hours after it (UTC-12).
  """
  def today_somewhere?(date, now \\ DateTime.utc_now()) do
    first = date |> DateTime.new!(~T[00:00:00], "Etc/UTC") |> DateTime.add(-14, :hour)

    last =
      date |> Date.add(1) |> DateTime.new!(~T[00:00:00], "Etc/UTC") |> DateTime.add(12, :hour)

    DateTime.compare(now, first) != :lt and DateTime.compare(now, last) == :lt
  end

  ## The run

  @doc """
  The run of a run code (see `code/2`), for a player level. The stories
  come from the version of the code. Gives
  `%{seed: code, level: level, stages: [stage]}`. A stage:

    * `number`: 1 to 5.
    * `story`: the story, turned with `sym`.
    * `sym`: the symmetry (0 to 7).
    * `from`: the number of moves on the board at the start of the stage.
    * `to`: the number of moves at the end of the stage.
    * `full`: true for the full game (the last stage). It ends with the
      score.
    * `moments`: the moments in the stage.
    * `puzzles`: the moments that the player plays. The computer plays the
      other moments.
  """
  def run(code, level, stories \\ nil) do
    {version, seed} = split(code)
    stories = stories || Library.all(version)
    tiers = tiers(stories)
    rng = rng(seed)

    {stages, _rng} =
      Enum.map_reduce(1..@stages, rng, fn k, rng ->
        {story, rng} = choose(Enum.at(tiers, k - 1), rng)
        {sym, rng} = :rand.uniform_s(8, rng)
        {stage(k, Library.rotate(story, sym - 1), sym - 1, level), rng}
      end)

    %{seed: code, level: level, stages: stages}
  end

  # The random generator of a seed. :erlang.phash2/2 and the exsss
  # generator are the same on each computer and in each version.
  defp rng(seed) do
    :rand.seed_s(
      :exsss,
      {:erlang.phash2({seed, 1}), :erlang.phash2({seed, 2}), :erlang.phash2({seed, 3})}
    )
  end

  # 5 tiers from the easiest grade to the hardest. A small library gives
  # all stories to each tier.
  defp tiers(stories) do
    sorted = Enum.sort_by(stories, &{&1.grade, &1.id})
    n = length(sorted)

    if n < @stages do
      List.duplicate(sorted, @stages)
    else
      groups = sorted |> Enum.with_index() |> Enum.group_by(fn {_s, i} -> div(i * @stages, n) end)
      for k <- 0..(@stages - 1), do: Enum.map(groups[k], &elem(&1, 0))
    end
  end

  # A story with a higher rank score has a bigger chance.
  defp choose(stories, rng) do
    total = Enum.sum(Enum.map(stories, &weight/1))
    {x, rng} = :rand.uniform_s(total, rng)
    {pick(stories, x), rng}
  end

  defp weight(story), do: max(story.rank, 0) + 1

  defp pick([s], _x), do: s
  defp pick([s | rest], x), do: if(x <= weight(s), do: s, else: pick(rest, x - weight(s)))

  defp stage(k, story, sym, level) do
    {moments, full} =
      case k do
        5 -> {story.moments, true}
        k when k <= 2 -> {part(story.moments, 2, :easy), false}
        k -> {part(story.moments, k, :hard), false}
      end

    first = hd(moments)
    last = List.last(moments)

    %{
      number: k,
      story: story,
      sym: sym,
      from: if(full, do: 0, else: max(first.index - @moves_before, 0)),
      to:
        if(full,
          do: length(story.moves),
          else: min(last.index + 1 + @moves_after, length(story.moves))
        ),
      full: full,
      moments: moments,
      puzzles: puzzles(moments, level)
    }
  end

  # The `n` moments that come one after the other, with the smallest (or
  # the biggest) sum of the grades. The first such part wins a tie.
  defp part(moments, n, kind) do
    parts = Enum.chunk_every(moments, min(n, length(moments)), 1, :discard)
    sum = fn part -> Enum.sum(Enum.map(part, & &1.grade.score)) end

    case kind do
      :easy -> Enum.min_by(parts, sum)
      :hard -> Enum.max_by(parts, sum)
    end
  end

  @doc """
  The moments that are puzzles for a level: the moments up to the highest
  grade of the level, not more than its count. When no moment is easy
  enough, the easiest one.
  """
  def puzzles(moments, level) do
    {max_grade, count} = Map.fetch!(@levels, level)

    case Enum.filter(moments, &(max_grade == :infinity or &1.grade.score <= max_grade)) do
      [] ->
        [Enum.min_by(moments, & &1.grade.score)]

      list ->
        list
        |> Enum.sort_by(&{-&1.grade.score, &1.index})
        |> Enum.take(count)
        |> Enum.sort_by(& &1.index)
    end
  end

  @doc "The puzzle (`Go.Puzzle`) of a moment of a stage."
  def puzzle(stage, moment), do: Library.puzzle(stage.story, moment)

  ## The level

  @doc """
  The level of a player, from 1 to 3: the ideas that the player knows in
  the worlds (`Go.Path`), and the runs that the player finished with 2
  stars or more for each puzzle on average.
  """
  def level(player) do
    results = Progress.results(player)

    known =
      Puzzles.open_worlds()
      |> Enum.flat_map(&Path.ideas/1)
      |> Enum.count(&Path.known?(&1, results))

    good_runs = Enum.count(Progress.finished_runs(player), &(&1.stars_per_puzzle >= 2))
    points = known + 2 * good_runs

    cond do
      points < 3 -> 1
      points < 6 -> 2
      true -> 3
    end
  end
end
