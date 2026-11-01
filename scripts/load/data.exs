# The data of the load test (scripts/load/run.mjs): for each run code, the
# taps of each puzzle of each stage at level 1 (a new player): the blue taps
# of the shown answer line, and one wrong first tap. Only this tool knows
# the answers; the browser never gets them.
#
#   OUT=/tmp/load-data.json mix run scripts/load/data.exs
alias Go.{Board, Book, Library, Play, Puzzle, Runs}

version = Library.newest()

runs =
  for i <- 1..40 do
    seed = :erlang.phash2({:load, i}, 32 * 32 * 32 * 32)
    code = Runs.code(version, Enum.map_join(0..3, &<<Enum.at(Runs.alphabet(), rem(div(seed, Integer.pow(32, &1)), 32))>>))

    stages =
      for st <- Runs.run(code, 1).stages do
        for m <- st.puzzles do
          puzzle = Runs.puzzle(st, m)
          answer = for {:blue, {r, c}} <- Play.answer_line(puzzle), do: [r, c]

          {wr, wc} =
            puzzle
            |> Puzzle.board()
            |> Board.legal_moves(:blue)
            |> Enum.filter(&match?(%{kind: :wrong}, Book.lookup(puzzle, [], &1)))
            |> Enum.at(i)
            |> Kernel.||(puzzle.answer)

          %{answer: answer, wrong: [wr, wc]}
        end
      end

    %{code: code, stages: stages}
  end

File.write!(System.fetch_env!("OUT"), JSON.encode!(runs))
