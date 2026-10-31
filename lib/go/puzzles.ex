defmodule Go.Puzzles do
  @moduledoc """
  The puzzle bank.

  The bank is the data file `priv/puzzles/bank.json`. The mix task
  `mix go.gen.puzzles` makes it again from the starter set and the
  generator. The app reads it one time, and keeps it in memory.
  """

  alias Go.Puzzle
  alias Go.Puzzles.{Check, Generator, Grade, Starter}

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
      |> Enum.with_index()
      |> Enum.sort_by(fn {p, i} -> {world_index(p.world), p.grade.score, p.source != :hand, i} end)
      |> Enum.map(&elem(&1, 0))

    %{puzzles: puzzles, stats: generated.stats}
  end

  defp world_index(world), do: Enum.find_index(Puzzle.worlds(), &(&1 == world))

  @doc "Writes a bank to a file, with one puzzle on each line."
  @spec write(map(), Path.t()) :: :ok
  def write(%{puzzles: puzzles, stats: stats}, path) do
    lines = fn list -> Enum.map_join(list, ",\n", &("    " <> JSON.encode!(&1))) end
    stats = Enum.map(stats, fn s -> Map.new(s, fn {k, v} -> {Atom.to_string(k), v} end) end)

    body = """
    {
      "version": 1,
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
