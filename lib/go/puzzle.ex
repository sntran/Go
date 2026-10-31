defmodule Go.Puzzle do
  @moduledoc """
  One puzzle of the bank.

  The server keeps the puzzles. The browser gets only the board and the
  results, never the answer.

  The fields:

    * `id`: a unique name, for example `"capture-01"`.
    * `world`: one of `worlds/0`. Only `:capture` and `:escape` have
      puzzles now.
    * `goal`: see `Go.Goal`.
    * `size`, `blue`, `red`: the start position. Blue plays first.
    * `answer`: the one correct first move.
    * `template`: the Go idea of the puzzle, for example `"edge_chase"`.
    * `source`: `:hand` (the starter set) or `:generated`.
    * `title`, `say`, `hint`, `better`, `win`: the texts. `better` tells
      the correct first move in words.
    * `wrong`: hand-written texts for typical wrong first moves, as a map
      from a point to `%{what: text, why: text}`, and an optional `reply`:
      the red reply to show. A nil `what` means: make it from the line.
    * `grade`: the difficulty (see `Go.Puzzles.Grade`).
    * `hide_roads`: true when the road counts are hidden.
    * `book`: the answers that the server knows already, from the time it
      made the bank: for each legal first move, its kind (`:solved`,
      `:good` or `:wrong`) and the moves that follow it (the red reply, or
      Red's punishment), and the answer line. Thus a first tap needs no
      search. nil when the puzzle has no book (the starter set in the
      code).
  """

  alias Go.Board

  @worlds [:capture, :escape, :connect, :eyes, :ko, :fields]

  defstruct [
    :id,
    :world,
    :goal,
    :size,
    :answer,
    :template,
    :title,
    :say,
    :hint,
    :better,
    :win,
    blue: [],
    red: [],
    source: :hand,
    wrong: %{},
    grade: %{},
    hide_roads: false,
    book: nil
  ]

  @type t :: %__MODULE__{}

  @doc "All the worlds, in the order of the game."
  def worlds, do: @worlds

  @doc "The start board of a puzzle."
  @spec board(t()) :: Board.t()
  def board(%__MODULE__{} = p), do: Board.new(p.size, p.blue, p.red)

  @doc "Changes a puzzle to a map that JSON can encode."
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = p) do
    %{
      "id" => p.id,
      "world" => Atom.to_string(p.world),
      "goal" => %{
        "type" => Atom.to_string(p.goal.type),
        "target" => pt(p.goal.target),
        "moves" => p.goal.moves
      },
      "size" => p.size,
      "blue" => Enum.map(Enum.sort(p.blue), &pt/1),
      "red" => Enum.map(Enum.sort(p.red), &pt/1),
      "answer" => pt(p.answer),
      "template" => p.template,
      "source" => Atom.to_string(p.source),
      "title" => p.title,
      "say" => p.say,
      "hint" => p.hint,
      "better" => p.better,
      "win" => p.win,
      "wrong" =>
        p.wrong
        |> Enum.sort()
        |> Enum.map(fn {point, t} ->
          %{
            "at" => pt(point),
            "what" => t.what,
            "why" => t.why,
            "reply" => t[:reply] && pt(t[:reply])
          }
        end),
      "grade" => Map.new(p.grade, fn {k, v} -> {Atom.to_string(k), v} end),
      "hide_roads" => p.hide_roads,
      "book" => book_to_map(p.book)
    }
  end

  defp book_to_map(nil), do: nil

  defp book_to_map(book) do
    %{
      "first" =>
        book.first
        |> Enum.sort()
        |> Enum.map(fn {point, e} ->
          %{"at" => pt(point), "kind" => Atom.to_string(e.kind), "line" => line_to_list(e.line)}
        end),
      "answer" => line_to_list(book.answer)
    }
  end

  defp book_from_map(nil), do: nil

  defp book_from_map(m) do
    %{
      first:
        Map.new(m["first"], fn e ->
          {point(e["at"]), %{kind: kind(e["kind"]), line: line_from_list(e["line"])}}
        end),
      answer: line_from_list(m["answer"])
    }
  end

  defp line_to_list(line),
    do: Enum.map(line, fn {color, move} -> [Atom.to_string(color), move_to(move)] end)

  defp line_from_list(list),
    do: Enum.map(list, fn [color, move] -> {color(color), move_from(move)} end)

  defp move_to(:pass), do: "pass"
  defp move_to(point), do: pt(point)
  defp move_from("pass"), do: :pass
  defp move_from(point), do: point(point)

  defp color("blue"), do: :blue
  defp color("red"), do: :red

  defp kind("solved"), do: :solved
  defp kind("good"), do: :good
  defp kind("wrong"), do: :wrong

  @doc "Makes a puzzle from a map of `to_map/1`."
  @spec from_map(map()) :: t()
  def from_map(m) do
    %__MODULE__{
      id: m["id"],
      world: world(m["world"]),
      goal: %{
        type: goal_type(m["goal"]["type"]),
        target: point(m["goal"]["target"]),
        moves: m["goal"]["moves"]
      },
      size: m["size"],
      blue: Enum.map(m["blue"], &point/1),
      red: Enum.map(m["red"], &point/1),
      answer: point(m["answer"]),
      template: m["template"],
      source: if(m["source"] == "hand", do: :hand, else: :generated),
      title: m["title"],
      say: m["say"],
      hint: m["hint"],
      better: m["better"],
      win: m["win"],
      wrong: Map.new(m["wrong"] || [], &{point(&1["at"]), wrong(&1)}),
      grade: Map.new(m["grade"] || %{}, fn {k, v} -> {grade_key(k), v} end),
      hide_roads: m["hide_roads"] || false,
      book: book_from_map(m["book"])
    }
  end

  defp wrong(%{"reply" => [_, _] = reply} = w),
    do: %{what: w["what"], why: w["why"], reply: point(reply)}

  defp wrong(w), do: %{what: w["what"], why: w["why"]}

  defp pt(nil), do: nil
  defp pt({r, c}), do: [r, c]
  defp point(nil), do: nil
  defp point([r, c]), do: {r, c}

  for w <- @worlds do
    defp world(unquote(Atom.to_string(w))), do: unquote(w)
  end

  for t <- Go.Goal.types() do
    defp goal_type(unquote(Atom.to_string(t))), do: unquote(t)
  end

  for k <- [:moves, :traps, :touches_target, :size, :score] do
    defp grade_key(unquote(Atom.to_string(k))), do: unquote(k)
  end
end
