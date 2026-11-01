defmodule Mix.Tasks.Go.Gen.Books do
  @shortdoc "Makes the full books of the bank and of each library version"

  @moduledoc """
  Makes the book of each puzzle again (see `Go.Book`): the puzzles of the
  bank (`priv/puzzles/bank.etf`) and each moment of each version of the
  library (`priv/library/stories-N.etf`). Only the books change: the
  puzzles, the stories and the runs stay the same.

      $ mix go.gen.books
      $ mix go.gen.books --only bank
      $ mix go.gen.books --only library

  `mix go.gen.puzzles` and `mix go.gen.library` make the books too. This
  task is for a change of the book format, or of the search.
  """

  use Mix.Task

  alias Go.{Book, Library}

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [only: :string])
    Mix.Task.run("compile")
    Mix.Task.run("app.config")

    only = opts[:only]
    start = System.monotonic_time(:millisecond)

    if only in [nil, "bank"], do: bank("priv/puzzles/bank.etf")

    if only in [nil, "library"] do
      for v <- Library.list_versions("priv/library"),
          do: library("priv/library/stories-#{v}.etf")
    end

    Mix.shell().info("All books: #{seconds(start)} s.")
  end

  defp bank(path) do
    start = System.monotonic_time(:millisecond)
    data = Go.Puzzles.read(path)
    puzzles = Enum.map(data.puzzles, &%{&1 | book: nil})
    {books, slow} = build_all(puzzles)
    puzzles = Enum.zip_with(puzzles, books, &%{&1 | book: &2})
    Go.Puzzles.write(%{puzzles: puzzles, stats: data.yield, proof: data.proof}, path)
    report(path, length(puzzles), books, slow, start)
  end

  defp library(path) do
    start = System.monotonic_time(:millisecond)
    lib = Library.read(path)
    puzzles = for s <- lib.stories, m <- s.moments, do: Library.puzzle(s, %{m | book: nil})
    {books, slow} = build_all(puzzles)
    books = Map.new(Enum.zip(Enum.map(puzzles, & &1.id), books))

    stories =
      for s <- lib.stories do
        moments =
          s.moments
          |> Enum.with_index(1)
          |> Enum.map(fn {m, k} -> %{m | book: Map.fetch!(books, "#{s.id}-#{k}")} end)

        %{s | moments: moments}
      end

    Library.write(stories, path,
      version: lib.version,
      daily_from: lib.daily_from,
      games: lib.games,
      next_seed: lib.next_seed
    )

    report(path, length(puzzles), Map.values(books), slow, start)
  end

  # All books, on all cores.
  defp build_all(puzzles) do
    results =
      puzzles
      |> Task.async_stream(&Book.build/1, timeout: :infinity, ordered: true)
      |> Enum.map(fn {:ok, r} -> r end)

    {Enum.map(results, &elem(&1, 0)), Enum.sum(Enum.map(results, &elem(&1, 1)))}
  end

  defp report(path, count, books, slow, start) do
    bytes = books |> Enum.map(&byte_size(Book.encode(&1))) |> Enum.sum()
    positions = books |> Enum.map(&map_size(&1.nodes)) |> Enum.sum()

    taps =
      books |> Enum.flat_map(&Map.values(&1.nodes)) |> Enum.map(&map_size(&1.taps)) |> Enum.sum()

    Mix.shell().info(
      "#{path}: #{count} books, #{positions} positions, #{taps} taps, #{bytes} bytes " <>
        "(#{File.stat!(path).size} bytes in the file), #{slow} slow taps, #{seconds(start)} s."
    )
  end

  defp seconds(start), do: div(System.monotonic_time(:millisecond) - start, 1000)
end
