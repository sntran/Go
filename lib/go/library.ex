defmodule Go.Library do
  @moduledoc """
  The library of strong stories. Each story is one 9x9 game that KataGo
  played, with its moments: the positions before a key move of Blue that
  are capture or escape puzzles. The mix task `mix go.gen.library` makes
  the library offline (see `Go.Library.Maker`). The server only reads the
  files `priv/library/stories-N.etf`. No neural network runs on the server.

  ## Versions

  Each file is one version of the library (N = 1, 2, …). A change of the
  library (one story more or less) changes almost all runs, so a change is
  always a new version, and the old files stay. A run keeps the version of
  its start (see `Go.Runs`), so an old link still opens the same run. A new
  run uses the newest version. The daily run of a date uses the newest
  version that has started daily runs on that date (see `daily_start/2`),
  so that all players of one date play the same run.

  ## The file

  A file is in the Erlang term format (`term_to_binary/1`), not JSON: the
  decode of a big JSON file made a big temporary peak of memory, and on
  WebAssembly the memory of the VM never shrinks (see docs/load-test.md).
  The file starts with a small head (the version, the `daily_from` date),
  that `read_head/1` reads with no read of the stories. The server decodes
  the stories of a version only when a run needs them (`all/1`). In the
  file and in memory, the moves of a story are bytes (one byte for each
  move, `pack/1`), and the book of a moment is bytes (see `Go.Book`): only
  the stories of a run and the puzzles that a player plays are decoded
  (`unpack/1`, `puzzle/2`).

  The parts file of `mix go.gen.library` keeps each story as compact JSON
  (`encode/1`, `decode/1`): each move is one byte (`row * 9 + column`, and
  81 for a pass), in Base64.

  A story (a map):

    * `id`, `seed`: the name, and the seed of the game.
    * `moves`: `[{color, point | :pass}]`.
    * `moments`: `[moment]`, in the order of the game.
    * `score`: the area score at the end, `%{blue: n, red: n}` (Red has the
      komi).
    * `estimate`: the score estimate of KataGo before the end (for Blue).
    * `grade`: the mean of the grades of the moments.
    * `rank`: the rank score (see `Go.Library.Maker`).

  A moment (a map):

    * `index`: the number of moves before the moment.
    * `goal`: as in `Go.Goal`.
    * `answer`: the one correct move.
    * `window`: `{row, column, size}`, the square of the fight. The board
      dims the points outside it.
    * `grade`: as in `Go.Puzzles.Grade`.
    * `diffs`: `[{trap, points}]`: for each tempting wrong move, how many
      points better the answer is, by the score estimate of KataGo.
    * `book`: the book of the puzzle.
  """

  alias Go.{Board, Puzzle}
  alias Go.Puzzles.{Generator, Grade, Symmetry}

  @key {__MODULE__, :stories}
  @dir "priv/library"
  @size 9
  @pass 81

  ## Reading

  @doc """
  All stories of a version (the newest by default), in the order of the
  file. Their moves are bytes: `unpack/1` gives the list.
  """
  def all(version \\ newest()) do
    Go.Cache.fetch({@key, version}, fn -> if version, do: read_packed(path(version)), else: [] end)
  end

  @doc "A story with its moves as a list of `{color, point | :pass}`."
  def unpack(%{moves: moves} = story) when is_binary(moves) do
    list =
      for {b, i} <- Enum.with_index(:binary.bin_to_list(moves)) do
        {if(rem(i, 2) == 0, do: :blue, else: :red), move(b)}
      end

    %{story | moves: list}
  end

  def unpack(story), do: story

  @doc "A story with its moves as bytes (Blue plays first, and the colors take turns)."
  def pack(%{moves: moves} = story) when is_list(moves),
    do: %{story | moves: for({_c, m} <- moves, into: <<>>, do: <<byte(m)>>)}

  def pack(story), do: story

  @doc "The story with this id in a version (the newest by default), or nil."
  def get(id, version \\ newest()), do: Enum.find(all(version), &(&1.id == id))

  @doc "The versions of the library, from the oldest."
  def versions do
    case :persistent_term.get({@key, :versions}, nil) do
      nil ->
        versions = list_versions(Application.app_dir(:go, @dir))
        :persistent_term.put({@key, :versions}, versions)
        versions

      versions ->
        versions
    end
  end

  @doc "The versions of the library files in a directory, from the oldest."
  def list_versions(dir) do
    for name <- File.ls!(dir),
        [_, n] <- [Regex.run(~r/^stories-(\d+)\.etf$/, name)],
        do: String.to_integer(n)
  rescue
    File.Error -> []
  else
    list -> Enum.sort(list)
  end

  @doc "The newest version, or nil when there is no library."
  def newest, do: List.last(versions())

  @doc "True when the version exists."
  def version?(version), do: version in versions()

  @doc "The path of the file of a version."
  def path(version), do: Application.app_dir(:go, Path.join(@dir, "stories-#{version}.etf"))

  @doc """
  The version of the daily run of a date: the newest version whose daily
  start (`daily_start/2`) is not after the date (the oldest version when
  none). `first_seen` maps each version to the time when the server first
  saw it (see `Go.Library.Seen`).
  """
  def daily_version(date, first_seen) do
    versions()
    |> Enum.filter(fn v ->
      Date.compare(daily_start(daily_from(v), Map.fetch!(first_seen, v)), date) != :gt
    end)
    |> List.last()
    |> Kernel.||(List.first(versions()))
  end

  @doc """
  The first date of the daily runs of a version: the later of its
  `daily_from` date, and the first date that had not started anywhere on
  Earth when the server first saw the version (the date in UTC+14 at that
  time, plus one day). So a version that is live late never changes a daily
  run that a player started already.
  """
  def daily_start(daily_from, first_seen) do
    free = first_seen |> DateTime.add(14, :hour) |> DateTime.to_date() |> Date.add(1)
    if Date.compare(daily_from, free) == :gt, do: daily_from, else: free
  end

  @doc "The `daily_from` date of a version (from its file)."
  def daily_from(version),
    do: Go.Cache.fetch({@key, :daily_from, version}, fn -> read_head(path(version)).daily_from end)

  @magic "GOLIB1"

  @doc """
  The head of a file: `%{version, daily_from, games, next_seed}`. It reads
  only the start of the file.
  """
  def read_head(path) do
    {:ok, file} = :file.open(path, [:read, :binary, :raw])
    {:ok, <<@magic, size::32>>} = :file.read(file, byte_size(@magic) + 4)
    {:ok, head} = :file.read(file, size)
    :ok = :file.close(file)
    :erlang.binary_to_term(head)
  end

  @doc "Reads the stories of a library file (their moves as lists)."
  def load(path), do: path |> read() |> Map.fetch!(:stories)

  @doc """
  Reads a library file with its counts: `%{version, daily_from, stories,
  games, next_seed}`. `games` is the number of games that the maker played,
  and `next_seed` the first seed that it did not play. The moves of the
  stories are lists.
  """
  def read(path) do
    {head, stories} = split(File.read!(path))
    Map.put(head, :stories, Enum.map(stories, &unpack/1))
  end

  # The stories as in memory: their moves as bytes.
  defp read_packed(path), do: path |> File.read!() |> split() |> elem(1)

  defp split(<<@magic, size::32, head::binary-size(size), stories::binary>>),
    do: {:erlang.binary_to_term(head), :erlang.binary_to_term(stories)}

  @doc "Removes the library from memory, so that the next call reads the files again."
  def reload do
    for {{@key, _} = key, _} <- :persistent_term.get(), do: :persistent_term.erase(key)
    for {{@key, _, _} = key, _} <- :persistent_term.get(), do: :persistent_term.erase(key)
    :ok
  end

  @doc "The board after the first `n` moves of a story."
  @spec board_at(map(), non_neg_integer()) :: Board.t()
  def board_at(story, n), do: play_moves(Board.new(@size), Enum.take(unpack(story).moves, n))

  @doc "Plays moves on a board."
  def play_moves(board, moves) do
    Enum.reduce(moves, board, fn {color, move}, b ->
      {:ok, b, _} = Board.play(b, color, move)
      b
    end)
  end

  @doc "The board at the end of a story."
  def final_board(story), do: story |> unpack() |> then(&board_at(&1, length(&1.moves)))

  @doc """
  The puzzle of a moment, with its texts. The texts come from the board of
  the moment, thus they are correct after a rotation too.
  """
  @spec puzzle(map(), map()) :: Puzzle.t()
  def puzzle(story, moment) do
    board = board_at(story, moment.index)
    k = Enum.find_index(story.moments, &(&1.index == moment.index)) + 1

    puzzle = %Puzzle{
      id: "#{story.id}-#{k}",
      world: moment.goal.type,
      goal: moment.goal,
      size: @size,
      blue: Enum.sort(for {p, :blue} <- board.stones, do: p),
      red: Enum.sort(for {p, :red} <- board.stones, do: p),
      answer: moment.answer,
      template: "story",
      source: :generated,
      grade: moment.grade,
      hide_roads: Grade.hide_roads?(moment.grade),
      book: book(moment.book),
      sym: Map.get(story, :sym, 0)
    }

    %{puzzle | title: Generator.title(puzzle), say: say(moment.goal)}
  end

  # The book stays as bytes in memory, until a puzzle needs it.
  defp book(bytes) when is_binary(bytes), do: Go.Book.decode(bytes)
  defp book(book), do: book

  defp say(%{type: :capture}),
    do: "This is a moment of the game. Look at the board, and find the weak red fort. Catch it!"

  defp say(%{type: :escape}),
    do: "This is a moment of the game. Red attacks one of your forts. Find it, and save it!"

  @doc "True when a moment is \"capture in 1\"."
  def capture_in_1?(%{goal: %{type: :capture, moves: 1}}), do: true
  def capture_in_1?(_moment), do: false

  ## Rotation

  @doc """
  Turns or mirrors a whole story with one of the 8 symmetries of
  `Go.Puzzles.Symmetry`: the moves, the moments and the windows. The books
  stay unturned: the story keeps the symmetry in `sym`, and each puzzle
  gets it (see `Go.Book`).
  """
  def rotate(story, 0), do: unpack(story)

  def rotate(story, sym) do
    story = unpack(story)
    f = &Symmetry.map_point(sym, @size, &1)

    story
    |> Map.put(:sym, sym)
    |> Map.merge(%{
      moves: map_line(story.moves, f),
      moments:
        Enum.map(story.moments, fn m ->
          %{
            m
            | goal: %{m.goal | target: f.(m.goal.target)},
              answer: f.(m.answer),
              window: map_window(m.window, f),
              diffs: Enum.map(m.diffs, fn {t, d} -> {f.(t), d} end)
          }
        end)
    })
  end

  defp map_line(line, f), do: Enum.map(line, fn {c, m} -> {c, map_move(m, f)} end)
  defp map_move(:pass, _f), do: :pass
  defp map_move(p, f), do: f.(p)

  # The square goes to a square: its new corner is the smallest corner.
  defp map_window({r, c, s}, f) do
    corners = for dr <- [0, s - 1], dc <- [0, s - 1], do: f.({r + dr, c + dc})
    {Enum.min(Enum.map(corners, &elem(&1, 0))), Enum.min(Enum.map(corners, &elem(&1, 1))), s}
  end

  ## The window

  @doc "The points of a window."
  def window_points({r0, c0, s}),
    do: for(r <- r0..(r0 + s - 1), c <- c0..(c0 + s - 1), do: {r, c})

  @doc "True when the point is in the window."
  def in_window?({r0, c0, s}, {r, c}), do: r >= r0 and r < r0 + s and c >= c0 and c < c0 + s

  @doc """
  The window of a fight: the smallest square of 5, 7 or 9 points that holds
  all the points. The square is near the middle of the points, and stays on
  the board.
  """
  @spec window([Board.point()]) :: {non_neg_integer(), non_neg_integer(), pos_integer()}
  def window(points) do
    rows = Enum.map(points, &elem(&1, 0))
    cols = Enum.map(points, &elem(&1, 1))
    {r1, r2} = Enum.min_max(rows)
    {c1, c2} = Enum.min_max(cols)
    span = max(r2 - r1, c2 - c1) + 1
    s = Enum.find([5, 7], @size, &(&1 >= span))
    {place(r1, r2, s), place(c1, c2, s), s}
  end

  defp place(lo, hi, s) do
    start = lo - div(s - (hi - lo + 1), 2)
    start |> max(0) |> min(@size - s)
  end

  ## The file

  @doc """
  Writes a library file (see "The file" above). The options `version`,
  `daily_from`, `games` and `next_seed` are as in `read/1`.
  """
  def write(stories, path, opts \\ []) do
    stories = stories |> Enum.map(&book_bytes/1) |> Enum.map(&pack/1)

    head =
      :erlang.term_to_binary(%{
        version: Keyword.get(opts, :version, 1),
        daily_from: Keyword.get(opts, :daily_from, ~D[2000-01-01]),
        games: Keyword.get(opts, :games, 0),
        next_seed: Keyword.get(opts, :next_seed, 1)
      })

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, [@magic, <<byte_size(head)::32>>, head, :erlang.term_to_binary(stories)])
  end

  # The books stay as bytes in the file and in memory.
  defp book_bytes(story) do
    moments = for m <- story.moments, do: %{m | book: bytes(m.book)}
    %{story | moments: moments} |> Map.delete(:sym)
  end

  defp bytes(nil), do: nil
  defp bytes(bytes) when is_binary(bytes), do: bytes
  defp bytes(book), do: Go.Book.encode(book)

  @doc "Changes a story to the compact map of the file."
  def encode(s) do
    %{
      "id" => s.id,
      "seed" => s.seed,
      "moves" => Base.encode64(pack(s).moves),
      "moments" =>
        Enum.map(s.moments, fn m ->
          %{
            "at" => m.index,
            "type" => Atom.to_string(m.goal.type),
            "target" => byte(m.goal.target),
            "n" => m.goal.moves,
            "answer" => byte(m.answer),
            "window" => Tuple.to_list(m.window),
            "grade" => [
              m.grade.moves,
              m.grade.traps,
              if(m.grade.touches_target, do: 1, else: 0),
              m.grade.score
            ],
            "diffs" => Enum.map(m.diffs, fn {t, d} -> [byte(t), Float.round(d * 1.0, 1)] end),
            "tree" => m.book |> bytes() |> base64()
          }
        end),
      "score" => [s.score.blue, s.score.red],
      "estimate" => Float.round(s.estimate * 1.0, 1),
      "grade" => s.grade,
      "rank" => s.rank
    }
  end

  @doc "Makes a story from the compact map of the file."
  def decode(m) do
    moves =
      for {b, i} <- Enum.with_index(:binary.bin_to_list(Base.decode64!(m["moves"]))) do
        {if(rem(i, 2) == 0, do: :blue, else: :red), move(b)}
      end

    %{
      id: m["id"],
      seed: m["seed"],
      moves: moves,
      moments:
        Enum.map(m["moments"], fn x ->
          [moves_n, traps, touches, score] = x["grade"]
          [r, c, s] = x["window"]

          %{
            index: x["at"],
            goal: %{type: goal_type(x["type"]), target: move(x["target"]), moves: x["n"]},
            answer: move(x["answer"]),
            window: {r, c, s},
            grade: %{
              moves: moves_n,
              traps: traps,
              touches_target: touches == 1,
              size: @size,
              score: score
            },
            diffs: Enum.map(x["diffs"], fn [t, d] -> {move(t), d} end),
            # The tree has all positions (see Go.Book).
            book: x["tree"] && Base.decode64!(x["tree"])
          }
        end),
      score: %{blue: Enum.at(m["score"], 0), red: Enum.at(m["score"], 1)},
      estimate: m["estimate"],
      grade: m["grade"],
      rank: m["rank"]
    }
  end

  defp goal_type("capture"), do: :capture
  defp goal_type("escape"), do: :escape

  defp byte(:pass), do: @pass
  defp byte({r, c}), do: r * @size + c
  defp move(@pass), do: :pass
  defp move(b), do: {div(b, @size), rem(b, @size)}

  defp base64(nil), do: nil
  defp base64(bytes), do: Base.encode64(bytes)
end
