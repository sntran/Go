defmodule GoWeb.BoardComponents do
  @moduledoc """
  Draws the board as SVG: castles, or a real Go board.

  Each picture shows a real Go rule, and nothing moves after it is placed:

    * a tower is a stone (Blue = black stones, Red = white stones on the
      real board),
    * a wall between towers shows connected stones,
    * an open road (a dashed ring on an empty point) is a liberty,
    * a tower with 1 road left shakes (atari),
    * a captured tower crumbles.
  """

  use Phoenix.Component

  alias Go.Board

  @view 400

  attr :board, Board, required: true
  attr :look, :atom, default: :castle, values: [:castle, :board]
  attr :hide_roads, :boolean, default: false
  attr :falls, :list, default: [], doc: "the stones that fell, as {point, color}"
  attr :marks, :map, default: %{}, doc: "rings on the last moves, as point => color"
  attr :glow, :list, default: [], doc: "the glowing spots (hint or better move)"
  attr :target, :any, default: nil
  attr :step, :integer, default: 0, doc: "a number that changes on each move, for the animations"

  attr :view, :integer,
    default: nil,
    doc: "the size of the top-left window to show (the full board when nil)"

  attr :fields, :map, default: %{}, doc: "the fields at the end of a game, as point => color"

  attr :window, :any,
    default: nil,
    doc: "the square of the fight, as {row, column, size}: the board dims the points outside it"

  # Each list of the board is a keyed comprehension (`:key`), and each item
  # holds all its values, as text. So LiveView compares each item with the
  # item of the same key in the last render, and a move sends only the
  # points that changed: not the whole board. The expressions in a list use
  # only the item: an assign made in this function counts as changed on
  # each render.
  def board(assigns) do
    full = assigns.board.size
    n = min(assigns.view || full, full)
    inside? = fn {r, c} -> r < n and c < n end
    pad = if n > 5, do: 32, else: 44
    cs = (@view - 2 * pad) / (n - 1)
    r = min(cs * 0.42, 32)
    castle = assigns.look == :castle
    px = fn k -> f(x(pad, cs, k)) end
    groups = Board.groups(assigns.board, :blue) ++ Board.groups(assigns.board, :red)
    show = fn g -> not assigns.hide_roads and (full <= 5 or length(g.liberties) <= 3) end
    open = n < full
    far = f(if open, do: 396, else: 400 - pad)
    line_class = if castle, do: "path", else: "gridline"

    danger = for g <- groups, match?([_], g.liberties), p <- g.stones, into: MapSet.new(), do: p

    lines =
      for(
        k <- 0..(n - 1),
        do: %{id: "h#{k}", x1: f(pad), y1: px.(k), x2: far, y2: px.(k), class: line_class}
      ) ++
        for(
          k <- 0..(n - 1),
          do: %{id: "v#{k}", x1: px.(k), y1: f(pad), x2: px.(k), y2: far, class: line_class}
        )

    roads =
      groups
      |> Enum.filter(show)
      |> Enum.flat_map(fn g -> for l <- g.liberties, inside?.(l), do: {l, g.color} end)
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      |> Enum.flat_map(fn {p, colors} ->
        colors = Enum.uniq(colors)

        Enum.with_index(colors, fn c, i ->
          {p, c, if(length(colors) > 1, do: if(i == 0, do: -6, else: 6), else: 0)}
        end)
      end)
      |> Enum.sort()
      |> Enum.map(fn {{row, col}, color, dx} ->
        %{
          id: "#{row}-#{col}-#{color}",
          point: "#{row}-#{col}",
          class: if(castle, do: "road road-#{color}", else: "dot dot-#{color}"),
          cx: f(x(pad, cs, col) + dx),
          cy: px.(row),
          r: if(castle, do: f(max(6, r * 0.28)), else: f(max(4, r * 0.18)))
        }
      end)

    walls =
      for {{row, col} = p, color} <- Enum.sort(assigns.board.stones),
          castle,
          {r2, c2} = q <- [{row, col + 1}, {row + 1, col}],
          Board.get(assigns.board, q) == color,
          inside?.(p) and inside?.(q) do
        %{
          id: "#{row}-#{col}-#{r2}-#{c2}",
          class: "wall wall-#{color}",
          x1: px.(col),
          y1: px.(row),
          x2: px.(c2),
          y2: px.(r2),
          base: "stroke-width:#{f(r * 0.62)}",
          top: "stroke-width:#{f(r * 0.4)}"
        }
      end

    stones =
      for {{row, col} = p, color} <- Enum.sort(assigns.board.stones), inside?.(p) do
        %{
          id: "#{row}-#{col}",
          castle: castle,
          geo: piece_geo(castle, x(pad, cs, col), x(pad, cs, row), r),
          cx: px.(col),
          cy: px.(row),
          color: color,
          danger: MapSet.member?(danger, p)
        }
      end

    alarms =
      for s <- stones, s.danger, do: %{id: s.id, cx: s.cx, cy: s.cy, r: f(r * 1.02)}

    badges =
      for g <- groups, show.(g), Enum.all?(g.stones, inside?) do
        {row, col} = Enum.min_by(g.stones, fn {row, col} -> {row, -col} end)
        bx = x(pad, cs, col) + r * 0.85
        by = x(pad, cs, row) - r * 0.85

        %{
          id: "#{g.color}-#{row}-#{col}",
          x: f(bx),
          y: f(by),
          ty: f(by + 4.5),
          class: "count-ring count-#{g.color}",
          count: length(g.liberties)
        }
      end

    marks =
      for {{row, col} = p, color} <- Enum.sort(assigns.marks),
          inside?.(p),
          Board.get(assigns.board, p) do
        %{
          id: "#{row}-#{col}",
          class: "mark mark-#{color}",
          cx: px.(col),
          cy: px.(row),
          r: f(r + 5)
        }
      end

    falls =
      for {{row, col} = p, color} <- assigns.falls, inside?.(p) do
        %{
          id: "fall-#{assigns.step}-#{row}-#{col}",
          castle: castle,
          geo: piece_geo(castle, x(pad, cs, col), x(pad, cs, row), r),
          color: color
        }
      end

    glow =
      for {row, col} = p <- assigns.glow, inside?.(p) do
        %{id: "#{row}-#{col}", cx: px.(col), cy: px.(row), r: f(r * 0.95)}
      end

    fields =
      for {{row, col} = p, color} <- Enum.sort(assigns.fields), inside?.(p) do
        cx = x(pad, cs, col)
        cy = x(pad, cs, row)

        %{
          id: "#{row}-#{col}",
          color: color,
          land: %{
            x: f(cx - cs * 0.31),
            y: f(cy - cs * 0.31),
            size: f(cs * 0.62)
          },
          crops:
            for(
              o <- [-0.22, 0, 0.22],
              do: %{x: f(cx + o * cs * 0.62), y1: f(cy - cs * 0.15), y2: f(cy + cs * 0.15)}
            ),
          mark: %{x: f(cx - cs * 0.12), y: f(cy - cs * 0.12), size: f(cs * 0.24)}
        }
      end

    spots =
      for {row, col} = p <- Board.points(assigns.board), inside?.(p) do
        %{
          id: "#{row}-#{col}",
          row: row,
          col: col,
          label: spot_label(assigns.board, p),
          cx: px.(col),
          cy: px.(row),
          r: f(cs / 2)
        }
      end

    assigns =
      assign(assigns,
        n: n,
        full: full,
        open: open,
        r: r,
        pad: pad,
        cs: cs,
        castle: castle,
        lines: lines,
        roads: roads,
        walls: walls,
        alarms: alarms,
        stones: stones,
        badges: badges,
        marks: marks,
        falls: falls,
        glow: glow,
        castle_fields: if(castle, do: fields, else: []),
        board_fields: if(castle, do: [], else: fields),
        spots: spots,
        dim: dim_path(assigns.window, full, pad, cs)
      )

    ~H"""
    <svg
      id="board"
      class={["board", @castle && "castles"]}
      viewBox="0 0 400 400"
      role="group"
      aria-label={
        if @open,
          do: "Game board, the corner #{@n} by #{@n} of #{@full} by #{@full}",
          else: "Game board, #{@n} by #{@n}"
      }
    >
      <rect
        x="4"
        y="4"
        width="392"
        height="392"
        rx="20"
        class={if @castle, do: "ground-grass", else: "ground-wood"}
      />
      <line
        :for={l <- @lines}
        :key={l.id}
        x1={l.x1}
        y1={l.y1}
        x2={l.x2}
        y2={l.y2}
        class={l.class}
      />
      <%!-- The board goes on past the right side and the bottom of the view. --%>
      <defs :if={@open}>
        <linearGradient id="fade-right" x1="0" x2="1" y1="0" y2="0">
          <stop offset="0" class={["fade-stop", !@castle && "wood"]} stop-opacity="0" />
          <stop offset="1" class={["fade-stop", !@castle && "wood"]} stop-opacity="1" />
        </linearGradient>
        <linearGradient id="fade-bottom" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0" class={["fade-stop", !@castle && "wood"]} stop-opacity="0" />
          <stop offset="1" class={["fade-stop", !@castle && "wood"]} stop-opacity="1" />
        </linearGradient>
      </defs>
      <g :if={@open} class="board-goes-on" aria-hidden="true">
        <rect x="364" y="4" width="32" height="392" class="fade-right" />
        <rect x="4" y="364" width="392" height="32" class="fade-bottom" />
      </g>
      <g
        :for={fd <- @castle_fields}
        :key={fd.id}
        class={"field field-#{fd.color}"}
        data-field={fd.id}
      >
        <rect
          x={fd.land.x}
          y={fd.land.y}
          width={fd.land.size}
          height={fd.land.size}
          rx="5"
          class="field-land"
        />
        <line :for={c <- fd.crops} x1={c.x} y1={c.y1} x2={c.x} y2={c.y2} class="crop" />
      </g>
      <rect
        :for={fd <- @board_fields}
        :key={fd.id}
        class={"field-mark field-#{fd.color}"}
        data-field={fd.id}
        x={fd.mark.x}
        y={fd.mark.y}
        width={fd.mark.size}
        height={fd.mark.size}
      />
      <circle
        :for={g <- @glow}
        :key={g.id}
        class="glow"
        data-glow={g.id}
        cx={g.cx}
        cy={g.cy}
        r={g.r}
      />
      <circle
        :for={rd <- @roads}
        :key={rd.id}
        class={rd.class}
        data-road={rd.point}
        cx={rd.cx}
        cy={rd.cy}
        r={rd.r}
      />
      <g :for={w <- @walls} :key={w.id} class={w.class}>
        <line x1={w.x1} y1={w.y1} x2={w.x2} y2={w.y2} style={w.base} class="wall-base" />
        <line x1={w.x1} y1={w.y1} x2={w.x2} y2={w.y2} style={w.top} class="wall-top" />
      </g>
      <circle :for={a <- @alarms} :key={a.id} class="alarm" cx={a.cx} cy={a.cy} r={a.r} />
      <.piece
        :for={s <- @stones}
        :key={s.id}
        castle={s.castle}
        geo={s.geo}
        color={s.color}
        class={s.danger && "danger"}
        data-stone={s.id}
        data-color={s.color}
      />
      <.flag
        :if={@target && Board.get(@board, @target)}
        x={x(@pad, @cs, elem(@target, 1))}
        y={x(@pad, @cs, elem(@target, 0))}
        r={@r}
      />
      <%!-- The part outside the fight is dimmed. A tap there still plays. --%>
      <path :if={@dim} class="dim-outside" d={@dim} fill-rule="evenodd" aria-hidden="true" />
      <circle :for={m <- @marks} :key={m.id} class={m.class} cx={m.cx} cy={m.cy} r={m.r} />
      <g :for={b <- @badges} :key={b.id} class="count">
        <circle cx={b.x} cy={b.y} r="11" class={b.class} />
        <text x={b.x} y={b.ty} text-anchor="middle">{b.count}</text>
      </g>
      <.piece
        :for={fl <- @falls}
        :key={fl.id}
        id={fl.id}
        castle={fl.castle}
        geo={fl.geo}
        color={fl.color}
        class="fall"
      />
      <circle
        :for={sp <- @spots}
        :key={sp.id}
        class="spot"
        data-point={sp.id}
        phx-click="tap"
        phx-value-r={sp.row}
        phx-value-c={sp.col}
        role="button"
        aria-label={sp.label}
        cx={sp.cx}
        cy={sp.cy}
        r={sp.r}
      />
    </svg>
    """
  end

  attr :castle, :boolean, required: true
  attr :geo, :map, required: true, doc: "the numbers of the piece, as text (see piece_geo/4)"
  attr :color, :atom, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  # The piece reads only the attributes that it gets: no assign made here.
  # So when only the class changes, LiveView sends only the class.
  defp piece(%{castle: true} = assigns) do
    ~H"""
    <g class={["tower", "tower-#{@color}", @class]} {@rest}>
      <rect
        x={@geo.x}
        y={@geo.y}
        width={@geo.width}
        height={@geo.height}
        rx="2"
        class="body"
      />
      <rect
        :for={m <- @geo.merlons}
        x={m}
        y={@geo.merlon_y}
        width={@geo.merlon_width}
        height={@geo.merlon_height}
        class="body"
      />
      <path d={@geo.door} class="door" />
      <rect
        x={@geo.window_x}
        y={@geo.window_y}
        width={@geo.window_width}
        height={@geo.window_height}
        class="door"
      />
    </g>
    """
  end

  defp piece(assigns) do
    ~H"""
    <circle
      class={["stone", "stone-#{@color}", @class]}
      cx={@geo.cx}
      cy={@geo.cy}
      r={@geo.r}
      {@rest}
    />
    """
  end

  # The numbers of a piece on (x, y), as text: a tower, or a stone.
  defp piece_geo(true, x, y, r) do
    s = r * 0.82

    %{
      x: f(x - s * 0.72),
      y: f(y - s * 0.45),
      width: f(s * 1.44),
      height: f(s * 1.2),
      merlons: for(o <- [-0.72, -0.18, 0.36], do: f(x + o * s)),
      merlon_y: f(y - s * 0.8),
      merlon_width: f(s * 0.36),
      merlon_height: f(s * 0.38),
      door:
        "M#{f(x - s * 0.22)} #{f(y + s * 0.75)}v-#{f(s * 0.32)}a#{f(s * 0.22)} #{f(s * 0.22)} 0 0 1 #{f(s * 0.44)} 0v#{f(s * 0.32)}z",
      window_x: f(x - s * 0.09),
      window_y: f(y - s * 0.22),
      window_width: f(s * 0.18),
      window_height: f(s * 0.22)
    }
  end

  defp piece_geo(false, x, y, r), do: %{cx: f(x), cy: f(y), r: f(r * 0.98)}

  attr :x, :float, required: true
  attr :y, :float, required: true
  attr :r, :float, required: true

  # A small flag over the target.
  defp flag(assigns) do
    ~H"""
    <g class="flag" aria-hidden="true">
      <line
        x1={f(@x - @r * 0.75)}
        y1={f(@y - @r * 0.35)}
        x2={f(@x - @r * 0.75)}
        y2={f(@y - @r * 1.35)}
        class="flag-pole"
      />
      <path
        d={"M#{f(@x - @r * 0.75)} #{f(@y - @r * 1.35)}l#{f(@r * 0.55)} #{f(@r * 0.2)}l-#{f(@r * 0.55)} #{f(@r * 0.2)}z"}
        class="flag-cloth"
      />
    </g>
    """
  end

  defp x(pad, cs, k), do: pad + k * cs

  # The whole board, with a hole for the window. Nil when the window holds
  # the whole board.
  defp dim_path(nil, _full, _pad, _cs), do: nil
  defp dim_path({_r, _c, s}, full, _pad, _cs) when s >= full, do: nil

  defp dim_path({r0, c0, s}, full, pad, cs) do
    edge = fn k -> if k <= 0, do: 4, else: x(pad, cs, k) - cs / 2 end
    far = fn k -> if k >= full, do: 396, else: x(pad, cs, k) - cs / 2 end
    {x1, y1, x2, y2} = {edge.(c0), edge.(r0), far.(c0 + s), far.(r0 + s)}

    "M4 4H396V396H4Z M#{f(x1)} #{f(y1)}H#{f(x2)}V#{f(y2)}H#{f(x1)}Z"
  end

  defp f(v) when is_integer(v), do: Integer.to_string(v)
  defp f(v), do: :erlang.float_to_binary(v / 1, decimals: 1)

  defp spot_label(board, {row, col} = p) do
    what =
      case Board.get(board, p) do
        :blue -> "blue tower"
        :red -> "red tower"
        nil -> "empty"
      end

    "Row #{row + 1}, column #{col + 1}: #{what}"
  end
end
