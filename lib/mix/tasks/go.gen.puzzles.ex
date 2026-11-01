defmodule Mix.Tasks.Go.Gen.Puzzles do
  @shortdoc "Makes the puzzle bank in priv/puzzles/bank.etf"

  @moduledoc """
  Makes the puzzle bank again.

      $ mix go.gen.puzzles
      $ mix go.gen.puzzles --seed 2 --output /tmp/bank.etf

  It checks the hand-made starter set, makes puzzles from the templates,
  checks each one with the solver, makes the book of each puzzle (each tap
  in each position that a player can reach, see `Go.Book`), runs the
  final check (see
  `Go.Puzzles.Proof`), and writes the bank. Then it shows the
  yield: the number of good, different puzzles from each template.

  Options:

    * `--seed`: the seed of the random choices (the default is 1).
    * `--proof-ms`: the time limit of each claim of the final check, in
      milliseconds (the default is 20000). See `Go.Puzzles.Proof`.
    * `--output`: the file to write (the default is
      `priv/puzzles/bank.etf`).
  """

  use Mix.Task

  @impl true
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args, strict: [seed: :integer, output: :string, proof_ms: :integer])

    Mix.Task.run("compile")

    output = Keyword.get(opts, :output, "priv/puzzles/bank.etf")

    build_opts = [
      seed: Keyword.get(opts, :seed, 1),
      proof_ms: Keyword.get(opts, :proof_ms, 20_000)
    ]

    {time, bank} = :timer.tc(fn -> Go.Puzzles.build(build_opts) end)
    Go.Puzzles.write(bank, output)

    Mix.shell().info("Template               Variations  Different  Good  Kept")

    for s <- bank.stats do
      Mix.shell().info(
        String.pad_trailing(s.template, 22) <>
          String.pad_leading(Integer.to_string(s.variations), 11) <>
          String.pad_leading(Integer.to_string(s.different), 11) <>
          String.pad_leading(Integer.to_string(s.good), 6) <>
          String.pad_leading(Integer.to_string(s.kept), 6)
      )
    end

    p = bank.proof

    Mix.shell().info(
      "Final check (move limit + #{p.extra}, #{p.ms} ms for each claim): #{p.claims} claims, " <>
        "#{p.proven} proven, #{length(p.late_catches)} late catches, #{p.unproven} unproven. " <>
        "Dropped: #{Enum.join(p.dropped, ", ")}."
    )

    if p.late_catches != [],
      do: Mix.shell().info("Late catches: #{Enum.join(p.late_catches, ", ")}.")

    counts = Enum.frequencies_by(bank.puzzles, & &1.world)

    Mix.shell().info(
      "Wrote #{length(bank.puzzles)} puzzles (capture: #{counts[:capture] || 0}, escape: #{counts[:escape] || 0}) " <>
        "to #{output} in #{div(time, 1_000_000)} s."
    )
  end
end
