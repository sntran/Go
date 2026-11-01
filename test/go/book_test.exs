defmodule Go.BookTest do
  @moduledoc """
  The books have every position that a player can reach: this test plays
  each tap in each position of each book (the bank, and each moment of
  each version of the library, unturned and turned), and the hint in each
  position, and checks that the server never searches (the telemetry event
  `[:go, :play, :search]`, see `Go.Play`).
  """

  use ExUnit.Case, async: true

  alias Go.{Board, Book, Library, Play, Puzzle, Puzzles}
  alias Go.Puzzles.Symmetry

  setup do
    test = self()
    id = {__MODULE__, make_ref()}

    :telemetry.attach(
      id,
      [:go, :play, :search],
      fn _event, _measure, meta, _ -> if self() == test, do: send(test, {:search, meta}) end,
      nil
    )

    on_exit(fn -> :telemetry.detach(id) end)
  end

  # Plays the blue taps (on the board that the player sees), with the red
  # replies.
  defp play_taps(puzzle, taps) do
    Enum.reduce(taps, Play.new(puzzle), fn p, play ->
      {:ok, play} = Play.tap(play, p)
      Play.run_red(play)
    end)
  end

  # Each tap and the hint in each position of the book of the puzzle.
  defp play_all(%Puzzle{} = puzzle) do
    turn = &Symmetry.map_point(puzzle.sym, puzzle.size, &1)

    for {key, node} <- Book.positions(puzzle.book) do
      at = play_taps(puzzle, Enum.map(key, turn))
      assert at.status == :playing, "#{puzzle.id} at #{inspect(key)}: #{at.status}"

      assert Board.legal_moves(at.board, :blue)
             |> Enum.map(&Symmetry.map_point(Symmetry.inverse(puzzle.sym), puzzle.size, &1))
             |> Enum.sort() == node.taps |> Map.keys() |> Enum.sort()

      hint = Play.hint(at)
      assert Play.hint_spots(hint) != []

      for p <- Board.legal_moves(at.board, :blue) do
        {:ok, played} = Play.tap(at, p)
        played = Play.run_red(played)
        assert played.status in [:solved, :failed, :playing]
      end
    end

    # The shown answer line solves the puzzle, and the result checks with
    # the book.
    solved = play_taps(puzzle, for({:blue, p} <- Play.answer_line(puzzle), do: p))
    assert solved.status == :solved
    assert Play.verify(puzzle, solved.moves, :solved) == :ok

    refute_received {:search, _}, "#{puzzle.id}: the server searched"
  end

  test "the bank: no search in any position" do
    for p <- Puzzles.all(), do: play_all(p)
  end

  for version <- Library.versions(), story <- Library.all(version) do
    @story story
    @sym :erlang.phash2(story.id, 7) + 1
    @tag timeout: :infinity
    test "version #{version}, #{story.id}: no search in any position, unturned and turned" do
      for s <- [@story, Library.rotate(@story, @sym)], m <- s.moments do
        play_all(Library.puzzle(s, m))
      end
    end
  end

  test "a position that the book does not have searches, and tells it" do
    p = Puzzles.get("capture-12")
    puzzle = %{p | book: %{p.book | nodes: Map.delete(p.book.nodes, [])}}
    {:ok, _} = Play.tap(Play.new(puzzle), p.answer)
    assert_received {:search, %{puzzle: "capture-12", what: "tap " <> _, taps: []}}
  end

  test "the bytes of a book give the same book" do
    for p <- Enum.take(Puzzles.all(), 20) do
      assert p.book |> Book.encode() |> Book.decode() == p.book
    end
  end
end
