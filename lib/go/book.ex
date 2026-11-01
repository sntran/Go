defmodule Go.Book do
  @moduledoc """
  The book of a puzzle: the result of each tap in each position that a
  player can reach, made before play (`build/2`). During play, a tap is
  only a lookup in the book. The server does not search.

  A position is the list of the blue taps from the start (the red replies
  come from the book, so the taps give the board). For each position:

    * `taps`: for each legal blue tap, its entry:
      * `%{kind: :solved}`: the tap reaches the goal.
      * `%{kind: :good, line: [red reply], done: done}`: a good tap. Red
        replies with the move of the shown answer line when the player
        follows that line. `done` is true when the goal is reached after
        the reply.
      * `%{kind: :wrong, line: steps, better: point}`: Red's punishment
        (in an escape puzzle, the moves until the fort falls), and the
        better move. The explanation comes from these data and the board.
    * `hint`: the good taps, for the glowing spots of the hint.

  A wrong tap ends the puzzle, so the tree is small: it grows only along
  the good taps.

  The book is for the unturned board. A turned puzzle (a run, see
  `Go.Runs`) has its symmetry in `Go.Puzzle` `sym`: a lookup turns the
  taps back, and turns the result again.

  The file format is compact bytes (`encode/1`): a point is one byte
  (`row * 9 + column`, 81 for a pass, 255 for none), and a red move has 128
  added.
  """

  alias Go.{Board, Play, Puzzle}
  alias Go.Puzzles.Symmetry

  @pass 81
  @none 255
  @red_bit 128
  @size_max 9
  # The time limit of the deep search of one tap, during the build. When it
  # is over, the book keeps the result of the search in the move limit, as
  # the old search during play did.
  @tap_ms 60_000

  @type entry :: map()
  @type t :: %{nodes: %{[Board.point()] => %{taps: %{Board.point() => entry}, hint: list}}, answer: list}

  ## Build

  @doc """
  Makes the book of a puzzle: all positions that a player can reach. Gives
  the book and the count of taps whose deep search took too long
  (`{book, slow}`).
  """
  def build(%Puzzle{} = puzzle) do
    puzzle = %{puzzle | book: nil, sym: 0}
    answer = Play.answer_line(puzzle)
    # A book in the making: the answer line, and no positions yet.
    puzzle = %{puzzle | book: %{nodes: nil, answer: answer}}
    {nodes, slow} = grow(Play.new(puzzle), [], %{}, 0)
    {%{nodes: nodes, answer: answer}, slow}
  end

  defp grow(play, key, nodes, slow) do
    # The better move of a wrong tap is the same for all taps here.
    better = Play.better_move(play.puzzle, play.board, play.left, key == [], true)

    {taps, children, slow} =
      play.board
      |> Board.legal_moves(:blue)
      |> Enum.reduce({%{}, [], slow}, fn point, {taps, children, slow} ->
        {:ok, placed} = Play.place(play, point)

        {decision, slow} =
          case Go.Think.within(@tap_ms, fn -> Play.decide(placed, true, better: better) end) do
            {:ok, d} -> {d, slow}
            :timeout -> {Play.decide(placed, false), slow + 1}
          end

        case decision do
          :solved ->
            {Map.put(taps, point, %{kind: :solved}), children, slow}

          {:good, line} ->
            after_reply = placed |> Play.apply_decision(decision) |> Play.run_red()
            done = after_reply.status == :solved
            entry = %{kind: :good, line: line, done: done}
            children = if done, do: children, else: [{point, after_reply} | children]
            {Map.put(taps, point, entry), children, slow}

          {:wrong, line, better} ->
            {Map.put(taps, point, %{kind: :wrong, line: line, better: better}), children, slow}
        end
      end)

    hint = for {p, %{kind: kind}} <- taps, kind != :wrong, do: p
    nodes = Map.put(nodes, key, %{taps: taps, hint: Enum.sort(hint)})

    Enum.reduce(children, {nodes, slow}, fn {point, child}, {nodes, slow} ->
      grow(child, key ++ [point], nodes, slow)
    end)
  end

  ## Lookup (with the symmetry of the puzzle)

  @doc """
  The entry of a tap, for the blue taps before it (all on the board that
  the player sees). nil when the book does not have the position.
  """
  def lookup(%Puzzle{book: %{nodes: %{} = nodes}, sym: sym, size: size}, taps, point) do
    back = &Symmetry.map_point(Symmetry.inverse(sym), size, &1)

    with %{taps: entries} <- Map.get(nodes, Enum.map(taps, back)),
         %{} = entry <- Map.get(entries, back.(point)) do
      turn_entry(entry, sym, size)
    else
      _ -> nil
    end
  end

  def lookup(_puzzle, _taps, _point), do: nil

  @doc "The good taps of a position (for the hint), or nil when it is not in the book."
  def hint(%Puzzle{book: %{nodes: %{} = nodes}, sym: sym, size: size}, taps) do
    back = &Symmetry.map_point(Symmetry.inverse(sym), size, &1)

    case Map.get(nodes, Enum.map(taps, back)) do
      %{hint: hint} -> hint |> Enum.map(&Symmetry.map_point(sym, size, &1)) |> Enum.sort()
      nil -> nil
    end
  end

  def hint(_puzzle, _taps), do: nil

  @doc "The answer line, on the board that the player sees."
  def answer(%Puzzle{book: %{answer: line}, sym: sym, size: size}), do: turn_line(line, sym, size)

  @doc "True when the puzzle has a full book (not one in the making)."
  def full?(%Puzzle{book: %{nodes: %{}}}), do: true
  def full?(_puzzle), do: false

  defp turn_entry(%{line: line} = entry, sym, size) do
    entry = %{entry | line: turn_line(line, sym, size)}

    case entry do
      %{better: p} when p != nil -> %{entry | better: Symmetry.map_point(sym, size, p)}
      _ -> entry
    end
  end

  defp turn_entry(entry, _sym, _size), do: entry

  defp turn_line(line, 0, _size), do: line

  defp turn_line(line, sym, size) do
    Enum.map(line, fn
      {c, :pass} -> {c, :pass}
      {c, p} -> {c, Symmetry.map_point(sym, size, p)}
    end)
  end

  @doc "All positions of a book: `[{taps, node}]` (for the tests)."
  def positions(%{nodes: nodes}), do: Enum.sort(nodes)

  ## The bytes

  @doc """
  The book as bytes: the count of positions, then each position (its taps,
  its hint, and its entries), then the answer line.
  """
  def encode(%{nodes: nodes, answer: answer}) do
    body =
      for {key, node} <- Enum.sort(nodes), into: <<>> do
        entries =
          for {p, e} <- Enum.sort(node.taps), into: <<>> do
            <<byte(p)>> <> entry_bytes(e)
          end

        list(Enum.map(key, &byte/1)) <>
          list(Enum.map(node.hint, &byte/1)) <> <<map_size(node.taps)::16>> <> entries
      end

    <<map_size(nodes)::16>> <> body <> line_bytes(answer)
  end

  defp entry_bytes(%{kind: :solved}), do: <<0>>
  defp entry_bytes(%{kind: :good, line: line, done: false}), do: <<1>> <> line_bytes(line)
  defp entry_bytes(%{kind: :good, line: line, done: true}), do: <<2>> <> line_bytes(line)

  defp entry_bytes(%{kind: :wrong, line: line, better: better}),
    do: <<3>> <> line_bytes(line) <> <<byte(better)>>

  defp list(bytes), do: <<length(bytes)>> <> :binary.list_to_bin(bytes)

  defp line_bytes(line) do
    bytes = for {color, m} <- line, do: byte(m) + if(color == :red, do: @red_bit, else: 0)
    list(bytes)
  end

  @doc "The book from its bytes."
  def decode(<<count::16, rest::binary>>) do
    {nodes, rest} =
      Enum.map_reduce(1..count//1, rest, fn _, rest ->
        {key, rest} = take_points(rest)
        {hint, rest} = take_points(rest)
        <<n::16, rest::binary>> = rest

        {taps, rest} =
          Enum.map_reduce(1..n//1, rest, fn _, <<p, kind, rest::binary>> ->
            {entry, rest} = take_entry(kind, rest)
            {{point(p), entry}, rest}
          end)

        {{key, %{taps: Map.new(taps), hint: hint}}, rest}
      end)

    {answer, <<>>} = take_line(rest)
    %{nodes: Map.new(nodes), answer: answer}
  end

  defp take_entry(0, rest), do: {%{kind: :solved}, rest}

  defp take_entry(kind, rest) when kind in [1, 2] do
    {line, rest} = take_line(rest)
    {%{kind: :good, line: line, done: kind == 2}, rest}
  end

  defp take_entry(3, rest) do
    {line, <<better, rest::binary>>} = take_line(rest)
    {%{kind: :wrong, line: line, better: point(better)}, rest}
  end

  defp take_points(<<n, bytes::binary-size(n), rest::binary>>),
    do: {Enum.map(:binary.bin_to_list(bytes), &point/1), rest}

  defp take_line(<<n, bytes::binary-size(n), rest::binary>>) do
    line =
      for b <- :binary.bin_to_list(bytes) do
        if b >= @red_bit, do: {:red, point(b - @red_bit)}, else: {:blue, point(b)}
      end

    {line, rest}
  end

  defp byte(nil), do: @none
  defp byte(:pass), do: @pass
  defp byte({r, c}), do: r * @size_max + c

  defp point(@none), do: nil
  defp point(@pass), do: :pass
  defp point(b), do: {div(b, @size_max), rem(b, @size_max)}
end
