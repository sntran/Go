defmodule Mix.Tasks.Go.Gen.Stories do
  @shortdoc "Makes the story games in priv/puzzles/stories.json"

  @moduledoc """
  Makes the story games again (see `Go.Stories`).

      $ mix go.gen.stories
      $ mix go.gen.stories --count 3 --from 1 --output /tmp/stories.json

  The computer plays 9x9 games against itself (`Go.SelfPlay`). The task
  scans each game for moments: the positions where a capture or an escape
  puzzle passes the checks, and the move of the game is its answer. It
  keeps a game with at least 5 moments, until it has `--count` stories.
  Then it makes the book of each moment, and writes the file.

  Options:

    * `--count`: the number of stories (the default is 3).
    * `--from`: the first seed of the games (the default is 1).
    * `--output`: the file to write (the default is
      `priv/puzzles/stories.json`).
  """

  use Mix.Task

  @impl true
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args, strict: [count: :integer, from: :integer, output: :string])

    Mix.Task.run("compile")

    output = Keyword.get(opts, :output, "priv/puzzles/stories.json")
    count = Keyword.get(opts, :count, 3)

    {time, %{stories: stories, games: games}} =
      :timer.tc(fn ->
        Go.Stories.build(count,
          from: Keyword.get(opts, :from, 1),
          report: fn seed, moments ->
            Mix.shell().info("Game #{seed}: #{length(moments)} moments")
          end
        )
      end)

    Go.Stories.write(stories, output)

    for s <- stories do
      kinds = Enum.map_join(s.moments, ", ", &"#{&1.puzzle.goal.type} in #{&1.puzzle.goal.moves}")

      Mix.shell().info(
        "#{s.title} (game #{s.seed}): #{length(s.moves)} moves, #{length(s.moments)} moments " <>
          "(#{kinds}), Blue #{s.score.blue}, Red #{s.score.red}"
      )
    end

    Mix.shell().info(
      "Wrote #{length(stories)} stories from #{games} games to #{output} in #{div(time, 1_000_000)} s."
    )
  end
end
