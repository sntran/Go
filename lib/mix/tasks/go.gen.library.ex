defmodule Mix.Tasks.Go.Gen.Library do
  @shortdoc "Makes the library of strong stories with KataGo"

  @moduledoc """
  Makes the library of strong stories (see `Go.Library` and
  `Go.Library.Maker`). It runs on a computer or in CI, never on the
  server. It needs KataGo and a network (see the README).

      $ mix go.gen.library --katago ~/katago/katago --model ~/katago/kata9x9.bin.gz
      $ mix go.gen.library --count 100   # 100 more stories

  The task adds new stories to the library file. It never plays a seed
  again: the library file keeps the next seed. During the run, the task
  saves each game to the parts file at once. When the run stops early, the
  next run goes on from the parts file. When it has `--count` new stories,
  it writes the library file (the old stories and the new ones) and the
  report, and it deletes the parts file.

  Options:

    * `--count`: the number of new stories (the default is 300).
    * `--katago`, `--model`: the paths of KataGo and of the network (else
      `$KATAGO` and `$KATAGO_MODEL`).
    * `--fast-model`: a smaller network for the search of moments during a
      game (else `$KATAGO_FAST_MODEL`, else none). The strong network still
      plays all moves and checks each moment again after the game.
    * `--games`: the number of games in parallel (the default is 8).
    * `--visits`: the visits of the second check (the default is 16).
    * `--parts`: the parts file (the default is `library-parts.jsonl`).
    * `--output`: the library file (the default is
      `priv/library/stories.json`).
    * `--report`: the report (the default is `docs/library-report.md`).
    * `--write-only`: do not play; only write the library and the report
      from the parts file.
  """

  use Mix.Task

  alias Go.Library
  alias Go.Library.Maker

  @switches [
    count: :integer,
    katago: :string,
    model: :string,
    fast_model: :string,
    games: :integer,
    visits: :integer,
    parts: :string,
    output: :string,
    report: :string,
    write_only: :boolean
  ]

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: @switches)
    Mix.Task.run("compile")
    Mix.Task.run("app.config")

    parts = Keyword.get(opts, :parts, "library-parts.jsonl")
    output = Keyword.get(opts, :output, "priv/library/stories.json")
    report = Keyword.get(opts, :report, "docs/library-report.md")

    base =
      if File.exists?(output),
        do: Library.read(output),
        else: %{stories: [], games: 0, next_seed: 1}

    unless opts[:write_only], do: play(opts, parts, base)

    lines = read_lines(parts)
    new = for %{"story" => s} <- lines, do: Library.decode(s)
    seeds = Enum.map(lines, & &1["seed"])
    ids = MapSet.new(new, & &1.id)

    stories =
      (Enum.reject(base.stories, &MapSet.member?(ids, &1.id)) ++ new)
      |> Enum.sort_by(&{&1.grade, -&1.rank, &1.seed})

    games = base.games + length(lines)
    next_seed = max(base.next_seed, Enum.max(seeds, fn -> 0 end) + 1)
    Library.write(stories, output, games: games, next_seed: next_seed)
    write_report(stories, games, report, output)
    File.rm(parts)

    Mix.shell().info(
      "Wrote #{length(stories)} stories (from #{games} games) to #{output}, " <>
        "#{File.stat!(output).size} bytes. Report: #{report}."
    )
  end

  defp play(opts, parts, base) do
    lines = read_lines(parts)
    done = Enum.count(lines, &Map.has_key?(&1, "story"))
    next = max(base.next_seed, Enum.max(Enum.map(lines, & &1["seed"]), fn -> 0 end) + 1)
    count = Keyword.get(opts, :count, 300) - done

    {:ok, katago} = Go.Katago.start_link(katago: opts[:katago], model: opts[:model])
    fast_model = opts[:fast_model] || System.get_env("KATAGO_FAST_MODEL")

    fast =
      if fast_model do
        {:ok, fast} = Go.Katago.start_link(katago: opts[:katago], model: fast_model, threads: 2)
        fast
      end

    ev = {Go.Library.KatagoEvaluator, %{strong: katago, fast: fast}}
    file = File.open!(parts, [:append, :utf8])
    start = System.monotonic_time(:second)

    Mix.shell().info(
      "#{length(base.stories)} stories in the library, #{done} new in #{parts}. Next seed: #{next}."
    )

    Maker.build(ev, count,
      from: next,
      games: Keyword.get(opts, :games, 8),
      visits: Keyword.get(opts, :visits, 16),
      report: fn {seed, result} ->
        line =
          case result do
            {:ok, story} -> %{"seed" => seed, "story" => Library.encode(story)}
            {:drop, reason} -> %{"seed" => seed, "drop" => reason}
          end

        IO.write(file, JSON.encode!(line) <> "\n")
        time = System.monotonic_time(:second) - start
        what = if match?({:ok, _}, result), do: "a story", else: elem(result, 1)
        Mix.shell().info("#{time} s: game #{seed}: #{what}")
      end
    )

    File.close(file)
    Go.Katago.stop(katago)
    if fast, do: Go.Katago.stop(fast)
  end

  defp read_lines(parts) do
    if File.exists?(parts) do
      parts
      |> File.stream!()
      |> Enum.reject(&(String.trim(&1) == ""))
      |> Enum.map(&JSON.decode!/1)
    else
      []
    end
  end

  defp write_report(stories, tried, path, output) do
    moments = Enum.flat_map(stories, & &1.moments)
    kinds = Enum.frequencies_by(moments, &"#{&1.goal.type} in #{&1.goal.moves}")

    body = """
    # The library report

    Made by `mix go.gen.library`. Do not change this file by hand.

    - Stories: #{length(stories)}, from #{tried} games.
    - Moments: #{length(moments)}. #{Enum.map_join(Enum.sort(kinds), ", ", fn {k, n} -> "#{k}: #{n}" end)}.
    - Size of `#{output}`: #{if File.exists?(output), do: File.stat!(output).size, else: 0} bytes.

    For each story: the area score at the end, the score estimate of KataGo
    before the end, the grade and the rank score. For each moment: the move,
    the goal, the answer, the grade, and how many points the answer is better
    than each tempting wrong move (by the score estimate of KataGo). The
    points use the KataGo coordinates: the columns A to J (no I) from the
    left, and the rows 1 to 9 from the bottom.

    ```
    #{Enum.map_join(stories, "\n\n", &Enum.join(Maker.report_lines(&1), "\n"))}
    ```
    """

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, body)
  end
end
