defmodule Mix.Tasks.Go.Gen.Puzzles do
  @shortdoc "Makes the puzzle bank in priv/puzzles/bank.json"

  @moduledoc """
  Makes the puzzle bank again.

      $ mix go.gen.puzzles
      $ mix go.gen.puzzles --seed 2 --output /tmp/bank.json

  It checks the hand-made starter set, makes puzzles from the templates,
  checks each one with the solver, and writes the bank. Then it shows the
  yield: the number of good, different puzzles from each template.

  Options:

    * `--seed`: the seed of the random choices (the default is 1).
    * `--output`: the file to write (the default is
      `priv/puzzles/bank.json`).
  """

  use Mix.Task

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [seed: :integer, output: :string])
    Mix.Task.run("compile")

    output = Keyword.get(opts, :output, "priv/puzzles/bank.json")
    {time, bank} = :timer.tc(fn -> Go.Puzzles.build(seed: Keyword.get(opts, :seed, 1)) end)
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

    counts = Enum.frequencies_by(bank.puzzles, & &1.world)

    Mix.shell().info(
      "Wrote #{length(bank.puzzles)} puzzles (capture: #{counts[:capture] || 0}, escape: #{counts[:escape] || 0}) " <>
        "to #{output} in #{div(time, 1_000_000)} s."
    )
  end
end
