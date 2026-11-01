defmodule Go.Puzzles do
  @moduledoc """
  The puzzle bank.

  The bank is the data file `priv/puzzles/bank.json`. The mix task
  `mix go.gen.puzzles` makes it again from the starter set and the
  generator. The app reads it one time, and keeps it in memory.
  """

  alias Go.Puzzle
  alias Go.Puzzles.{Check, Generator, Grade, Proof, Starter}

  @key {__MODULE__, :bank}

  @doc "The worlds that have puzzles now."
  def open_worlds, do: [:capture, :escape]

  @doc "All puzzles of the bank, in the order of the game."
  @spec all() :: [Puzzle.t()]
  def all do
    case :persistent_term.get(@key, nil) do
      nil ->
        puzzles = load(path())
        :persistent_term.put(@key, puzzles)
        puzzles

      puzzles ->
        puzzles
    end
  end

  @doc "The puzzle with this id, or nil."
  @spec get(String.t()) :: Puzzle.t() | nil
  def get(id), do: Enum.find(all(), &(&1.id == id))

  @doc "The puzzles of a world, from easy to hard."
  @spec world(atom()) :: [Puzzle.t()]
  def world(world), do: Enum.filter(all(), &(&1.world == world))

  @doc "The path of the bank file."
  def path, do: Application.app_dir(:go, "priv/puzzles/bank.json")

  @doc "Reads a bank file."
  @spec load(Path.t()) :: [Puzzle.t()]
  def load(path) do
    path
    |> File.read!()
    |> JSON.decode!()
    |> Map.fetch!("puzzles")
    |> Enum.map(&Puzzle.from_map/1)
  end

  @doc """
  Chooses the next puzzle of a world for a player.

  `results` maps a puzzle id to `%{status: :solved | :learned, due: date}`.
  It gives the first puzzle after `current_id` that is not solved and is
  not learned for later. A learned puzzle comes back on its due date. It
  gives nil when nothing is left.
  """
  @spec next(atom(), String.t() | nil, map(), Date.t()) :: Puzzle.t() | nil
  def next(world, current_id, results, today) do
    puzzles = world(world)
    {before, rest} = Enum.split_while(puzzles, &(&1.id != current_id))
    after_current = if rest == [], do: before, else: tl(rest)
    order = after_current ++ if(rest == [], do: [], else: before ++ [hd(rest)])
    open = Enum.filter(order, &open?(Map.get(results, &1.id), today))

    # A learned puzzle that is due comes first: it waited some days.
    due = Enum.find(open, &match?(%{status: :learned}, Map.get(results, &1.id)))
    due || List.first(open)
  end

  defp open?(nil, _today), do: true
  defp open?(%{status: :solved}, _today), do: false
  defp open?(%{status: :learned, due: due}, today), do: Date.compare(today, due) != :lt
  defp open?(_, _today), do: true

  @doc """
  Makes the bank: the checked starter set and the generated puzzles.
  Raises if a starter puzzle fails a check. Gives
  `%{puzzles: puzzles, stats: stats}`.
  """
  @spec build(keyword()) :: %{puzzles: [Puzzle.t()], stats: [map()]}
  def build(opts \\ []) do
    starter =
      Enum.map(Starter.all(), fn p ->
        report = Check.run(p)

        unless report.ok,
          do: raise("the starter puzzle #{p.id} fails: #{Enum.join(report.errors, "; ")}")

        grade = Grade.of(p, report)
        %{p | grade: grade, hide_roads: Grade.hide_roads?(grade)}
      end)

    generated = Generator.run(Keyword.put(opts, :known, starter))

    puzzles =
      (starter ++ generated.puzzles)
      |> Task.async_stream(&%{&1 | book: book(&1)},
        ordered: true,
        timeout: :infinity,
        max_concurrency: System.schedulers_online()
      )
      |> Enum.map(fn {:ok, p} -> p end)

    {puzzles, proof} = final_check(puzzles, Keyword.get(opts, :proof_ms, 20_000))

    puzzles =
      puzzles
      |> Enum.with_index()
      |> Enum.sort_by(fn {p, i} ->
        {world_index(p.world), p.grade.score, p.source != :hand, i}
      end)
      |> Enum.map(&elem(&1, 0))

    %{puzzles: puzzles, stats: generated.stats, proof: proof}
  end

  # The final check of each kept puzzle (see Go.Puzzles.Proof). It drops a
  # generated escape puzzle when its fort dies. A starter puzzle must pass.
  defp final_check(puzzles, :skip), do: {puzzles, nil}

  defp final_check(puzzles, ms) do
    checked =
      puzzles
      |> Task.async_stream(&{&1, Proof.run(&1, ms)},
        ordered: true,
        timeout: :infinity,
        max_concurrency: System.schedulers_online()
      )
      |> Enum.map(fn {:ok, result} -> result end)

    for {%{source: :hand} = p, claims} <- checked, Proof.fort_dies?(claims) do
      raise "the starter puzzle #{p.id} fails the final check: the fort dies after the answer"
    end

    {dropped, kept} = Enum.split_with(checked, fn {_p, claims} -> Proof.fort_dies?(claims) end)
    claims = Enum.flat_map(kept, &elem(&1, 1))

    proof = %{
      extra: Proof.extra(),
      ms: ms,
      claims: length(claims),
      proven: Enum.count(claims, &(&1.result == :holds)),
      late_catches:
        for({p, cs} <- kept, c <- cs, c.result == false, do: "#{p.id} #{inspect(c.at)}"),
      unproven: Enum.count(claims, &(&1.result == :unproven)),
      dropped: Enum.map(dropped, fn {p, _} -> p.id end)
    }

    {Enum.map(kept, &elem(&1, 0)), proof}
  end

  @doc """
  Makes the book of a puzzle: the result of each legal first move, and the
  answer line. The search has no time limit here, so the book has the
  results of the deep search.

  With `points: list`, the book has only the first moves on these points.
  """
  @spec book(Puzzle.t(), keyword()) :: map()
  def book(%Puzzle{} = puzzle, opts \\ []) do
    puzzle = %{puzzle | book: nil}
    start = Go.Play.new(puzzle)
    legal = Go.Board.legal_moves(start.board, :blue)
    points = if opts[:points], do: Enum.filter(legal, &(&1 in opts[:points])), else: legal

    first =
      for point <- points, into: %{} do
        {:ok, play} = Go.Play.tap(start, point, budget: :infinity)

        entry =
          case play do
            %{status: :solved} -> %{kind: :solved, line: []}
            %{outcome: :continue, pending: line} -> %{kind: :good, line: line}
            %{outcome: {:failed, _}, pending: line} -> %{kind: :wrong, line: line}
          end

        {point, entry}
      end

    %{first: first, answer: Go.Play.answer_line(puzzle)}
  end

  defp world_index(world), do: Enum.find_index(Puzzle.worlds(), &(&1 == world))

  @doc "Writes a bank to a file, with one puzzle on each line."
  @spec write(map(), Path.t()) :: :ok
  def write(%{puzzles: puzzles, stats: stats} = bank, path) do
    lines = fn list -> Enum.map_join(list, ",\n", &("    " <> JSON.encode!(&1))) end
    stats = Enum.map(stats, fn s -> Map.new(s, fn {k, v} -> {Atom.to_string(k), v} end) end)
    proof = Map.new(bank[:proof] || %{}, fn {k, v} -> {Atom.to_string(k), v} end)

    body = """
    {
      "version": 1,
      "proof": #{JSON.encode!(proof)},
      "yield": [
    #{lines.(stats)}
      ],
      "puzzles": [
    #{lines.(Enum.map(puzzles, &Puzzle.to_map/1))}
      ]
    }
    """

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, body)
  end

  @doc "Removes the bank from memory, so that the next call reads the file again."
  def reload, do: :persistent_term.erase(@key)
end
