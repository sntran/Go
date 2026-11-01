defmodule GoWeb.BoardJsTest do
  @moduledoc """
  The hook Anim draws the board in the browser (`assets/js/board.mjs`).
  The look must stay the same: for real positions of the library (after
  each move of some stories, with the ring of the last move and the stones
  that fell), the JavaScript SVG must be the same as the SVG of
  `GoWeb.BoardComponents.board/1`, element by element, in both looks.

  The test runs `node`. With no `node`, it is skipped.
  """

  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Go.{Board, Library}
  alias GoWeb.BoardComponents

  @node System.find_executable("node")
  @moduletag skip: if(@node, do: false, else: "no node")

  # The positions: after each move of some stories.
  defp positions do
    for story <- Enum.take_every(Library.all(), 30),
        story = Library.unpack(story),
        {{color, move}, i} <- Enum.with_index(story.moves),
        rem(i, 3) == 0 or i == length(story.moves) - 1 do
      before = Library.board_at(story, i)
      {:ok, board, captured} = Board.play(before, color, move)
      %{moves: Enum.take(story.moves, i + 1), board: board, captured: captured, color: color, move: move, step: i + 1}
    end
  end

  # The SVG of the server, without the svg tag and the spots for the taps.
  defp server_svg(pos, look) do
    assigns = %{
      board: pos.board,
      look: look,
      marks: if(pos.move == :pass, do: %{}, else: %{pos.move => pos.color}),
      falls: Enum.map(pos.captured, &{&1, Board.other(pos.color)}),
      step: pos.step
    }

    html =
      rendered_to_string(~H"""
      <BoardComponents.board board={@board} look={@look} marks={@marks} falls={@falls} step={@step} />
      """)

    elements(LazyHTML.from_fragment(html) |> LazyHTML.query("svg > *"))
    |> Enum.reject(&match?({"circle", %{"class" => "spot"}, _}, &1))
  end

  # Each element as {tag, attributes, children}, in order.
  defp elements(nodes) do
    for node <- nodes, {tag, attrs, children} <- LazyHTML.to_tree(node), is_binary(tag) do
      {tag, Map.new(attrs), normalize(children)}
    end
  end

  defp normalize(children) do
    for child <- children do
      case child do
        {tag, attrs, kids} -> {tag, Map.new(attrs), normalize(kids)}
        text when is_binary(text) -> String.trim(text)
        other -> other
      end
    end
    |> Enum.reject(&(&1 == ""))
  end

  defp falls_sorted(elements) do
    {falls, others} = Enum.split_with(elements, fn {_, attrs, _} -> attrs["class"] =~ "fall" end)
    others ++ Enum.sort_by(falls, fn {_, attrs, _} -> attrs["id"] end)
  end

  test "the JavaScript board is the same as the board of the server" do
    positions = positions()
    assert length(positions) > 100

    dir = Path.join(System.tmp_dir!(), "board-js-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    input = Path.join(dir, "input.json")
    script = Path.join(dir, "run.mjs")
    module = Path.expand("assets/js/board.mjs")

    cases =
      for pos <- positions, look <- ["castle", "board"] do
        %{
          look: look,
          step: pos.step,
          moves:
            Enum.map(pos.moves, fn {c, m} -> [c, if(m == :pass, do: "pass", else: Tuple.to_list(m))] end)
        }
      end

    File.write!(input, JSON.encode!(cases))

    File.write!(script, """
    import { readFileSync } from 'node:fs';
    import { newBoard, play, render } from '#{module}';
    const other = (c) => (c === 'blue' ? 'red' : 'blue');
    const out = JSON.parse(readFileSync(process.argv[2], 'utf8')).map((k) => {
      let board = newBoard(9, []);
      let last = null;
      for (const [color, move] of k.moves) {
        last = { color, move, ...play(board, color, move) };
        board = last.board;
      }
      return render(board, {
        look: k.look,
        marks: last.move === 'pass' ? [] : [[last.move[0], last.move[1], last.color]],
        falls: last.captured.map(([a, b]) => [a, b, other(last.color)]),
        step: k.step,
      });
    });
    console.log(JSON.stringify(out));
    """)

    {json, 0} = System.cmd(@node, [script, input])
    svgs = JSON.decode!(json)
    File.rm_rf!(dir)

    for {{pos, look}, svg} <- Enum.zip(for(p <- positions, l <- [:castle, :board], do: {p, l}), svgs) do
      js = elements(LazyHTML.from_fragment("<svg>" <> svg <> "</svg>") |> LazyHTML.query("svg > *"))
      server = server_svg(pos, look)

      # The stones that fall at one time are on other points: their order
      # changes nothing on the screen.
      {js, server} = {falls_sorted(js), falls_sorted(server)}

      assert js == server,
             "move #{pos.step} (#{look}): " <>
               inspect(List.myers_difference(server, js) |> Enum.reject(&match?({:eq, _}, &1)),
                 limit: :infinity,
                 printable_limit: 2000
               )
    end
  end
end
