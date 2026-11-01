defmodule Go.Library do
  @moduledoc """
  The library of strong stories. Each story is one 9x9 game that KataGo
  played, with its moments: the positions before a key move of Blue that
  are capture or escape puzzles. The mix task `mix go.gen.library` makes
  the library offline (see `Go.Library.Maker`). The server only reads the
  file `priv/library/stories.json`. No neural network runs on the server.

  The file is compact: each move is one byte (`row * 9 + column`, and 81 for
  a pass), in Base64. Blue plays first, and the colors take turns. The
  board of a moment comes from the moves. The book of a moment (see
  `Go.Puzzle`) is bytes too: a move of Red has 128 added.

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
  @size 9
  @pass 81
  @red_bit 128

  ## Reading

  @doc "All stories, in the order of the file."
  def all do
    case :persistent_term.get(@key, nil) do
      nil ->
        stories = if File.exists?(path()), do: load(path()), else: []
        :persistent_term.put(@key, stories)
        stories

      stories ->
        stories
    end
  end

  @doc "The story with this id, or nil."
  def get(id), do: Enum.find(all(), &(&1.id == id))

  @doc "The path of the library file."
  def path, do: Application.app_dir(:go, "priv/library/stories.json")

  @doc "Reads a library file."
  def load(path), do: path |> read() |> Map.fetch!(:stories)

  @doc """
  Reads a library file with its counts: `%{stories, games, next_seed}`.
  `games` is the number of games that the maker played, and `next_seed`
  the first seed that it did not play.
  """
  def read(path) do
    data = path |> File.read!() |> JSON.decode!()

    %{
      stories: Enum.map(data["stories"], &decode/1),
      games: data["games"] || 0,
      next_seed: data["next_seed"] || 1
    }
  end

  @doc "Removes the library from memory, so that the next call reads the file again."
  def reload, do: :persistent_term.erase(@key)

  @doc "The board after the first `n` moves of a story."
  @spec board_at(map(), non_neg_integer()) :: Board.t()
  def board_at(story, n), do: play_moves(Board.new(@size), Enum.take(story.moves, n))

  @doc "Plays moves on a board."
  def play_moves(board, moves) do
    Enum.reduce(moves, board, fn {color, move}, b ->
      {:ok, b, _} = Board.play(b, color, move)
      b
    end)
  end

  @doc "The board at the end of a story."
  def final_board(story), do: board_at(story, length(story.moves))

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
      book: moment.book
    }

    %{puzzle | title: Generator.title(puzzle), say: say(moment.goal)}
  end

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
  `Go.Puzzles.Symmetry`: the moves, the moments, the windows and the books.
  """
  def rotate(story, 0), do: story

  def rotate(story, sym) do
    f = &Symmetry.map_point(sym, @size, &1)

    %{
      story
      | moves: map_line(story.moves, f),
        moments:
          Enum.map(story.moments, fn m ->
            %{
              m
              | goal: %{m.goal | target: f.(m.goal.target)},
                answer: f.(m.answer),
                window: map_window(m.window, f),
                diffs: Enum.map(m.diffs, fn {t, d} -> {f.(t), d} end),
                book: Symmetry.map_book(m.book, f)
            }
          end)
    }
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
  def window_points({r0, c0, s}), do: for(r <- r0..(r0 + s - 1), c <- c0..(c0 + s - 1), do: {r, c})

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
  Writes the library file, with one story on each line. The options
  `games` and `next_seed` are as in `read/1`.
  """
  def write(stories, path, opts \\ []) do
    body = """
    {
      "version": 1,
      "games": #{Keyword.get(opts, :games, 0)},
      "next_seed": #{Keyword.get(opts, :next_seed, 1)},
      "stories": [
    #{Enum.map_join(stories, ",\n", &("    " <> JSON.encode!(encode(&1))))}
      ]
    }
    """

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, body)
  end

  @doc "Changes a story to the compact map of the file."
  def encode(s) do
    %{
      "id" => s.id,
      "seed" => s.seed,
      "moves" => Base.encode64(for({_c, m} <- s.moves, into: <<>>, do: <<byte(m)>>)),
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
            "book" => Base.encode64(book_bytes(m.book))
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
            book: book_from(Base.decode64!(x["book"]))
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

  defp line_bytes(line) do
    for {color, m} <- line, into: <<>> do
      <<byte(m) + if(color == :red, do: @red_bit, else: 0)>>
    end
  end

  defp line_from(bytes) do
    for b <- :binary.bin_to_list(bytes) do
      if b >= @red_bit, do: {:red, move(b - @red_bit)}, else: {:blue, move(b)}
    end
  end

  # The count of entries, then each entry (point, kind, length, line), then
  # the answer line (length, line).
  defp book_bytes(book) do
    entries =
      for {p, e} <- Enum.sort(book.first), into: <<>> do
        line = line_bytes(e.line)
        <<byte(p), kind_byte(e.kind), byte_size(line), line::binary>>
      end

    answer = line_bytes(book.answer)
    <<map_size(book.first), entries::binary, byte_size(answer), answer::binary>>
  end

  defp book_from(<<count, rest::binary>>) do
    {first, rest} =
      Enum.map_reduce(1..count//1, rest, fn _, <<p, k, n, line::binary-size(n), rest::binary>> ->
        {{move(p), %{kind: kind(k), line: line_from(line)}}, rest}
      end)

    <<n, answer::binary-size(n)>> = rest
    %{first: Map.new(first), answer: line_from(answer)}
  end

  defp kind_byte(:solved), do: 0
  defp kind_byte(:good), do: 1
  defp kind_byte(:wrong), do: 2
  defp kind(0), do: :solved
  defp kind(1), do: :good
  defp kind(2), do: :wrong
end
