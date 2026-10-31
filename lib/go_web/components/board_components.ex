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

  def board(assigns) do
    n = assigns.board.size
    pad = if n > 5, do: 32, else: 44
    cs = (@view - 2 * pad) / (n - 1)
    r = min(cs * 0.42, 32)
    castle = assigns.look == :castle
    groups = Board.groups(assigns.board, :blue) ++ Board.groups(assigns.board, :red)
    show = fn g -> not assigns.hide_roads and (n <= 5 or length(g.liberties) <= 3) end

    danger = for g <- groups, match?([_], g.liberties), p <- g.stones, into: MapSet.new(), do: p

    roads =
      groups
      |> Enum.filter(show)
      |> Enum.flat_map(fn g -> Enum.map(g.liberties, &{&1, g.color}) end)
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      |> Enum.flat_map(fn {p, colors} ->
        colors = Enum.uniq(colors)

        Enum.with_index(colors, fn c, i ->
          {p, c, if(length(colors) > 1, do: if(i == 0, do: -6, else: 6), else: 0)}
        end)
      end)
      |> Enum.sort()

    walls =
      for {{row, col} = p, color} <- Enum.sort(assigns.board.stones),
          q <- [{row, col + 1}, {row + 1, col}],
          Board.get(assigns.board, q) == color,
          do: {p, q, color}

    badges =
      for g <- groups, show.(g) do
        {row, col} = Enum.min_by(g.stones, fn {row, col} -> {row, -col} end)

        %{
          x: x(pad, cs, col) + r * 0.85,
          y: x(pad, cs, row) - r * 0.85,
          color: g.color,
          count: length(g.liberties)
        }
      end

    assigns =
      assign(assigns,
        n: n,
        pad: pad,
        cs: cs,
        r: r,
        castle: castle,
        danger: danger,
        roads: roads,
        walls: walls,
        badges: badges,
        stones: Enum.sort(assigns.board.stones),
        points: Board.points(assigns.board)
      )

    ~H"""
    <svg
      id="board"
      class={["board", @castle && "castles"]}
      viewBox="0 0 400 400"
      role="group"
      aria-label={"Game board, #{@n} by #{@n}"}
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
        :for={k <- 0..(@n - 1)}
        x1={f(@pad)}
        y1={f(x(@pad, @cs, k))}
        x2={f(400 - @pad)}
        y2={f(x(@pad, @cs, k))}
        class={if @castle, do: "path", else: "gridline"}
      />
      <line
        :for={k <- 0..(@n - 1)}
        x1={f(x(@pad, @cs, k))}
        y1={f(@pad)}
        x2={f(x(@pad, @cs, k))}
        y2={f(400 - @pad)}
        class={if @castle, do: "path", else: "gridline"}
      />
      <circle
        :for={{row, col} <- @glow}
        class="glow"
        data-glow={"#{row}-#{col}"}
        cx={f(x(@pad, @cs, col))}
        cy={f(x(@pad, @cs, row))}
        r={f(@r * 0.95)}
      />
      <%= for {{row, col}, color, dx} <- @roads do %>
        <circle
          :if={@castle}
          class={"road road-#{color}"}
          data-road={"#{row}-#{col}"}
          cx={f(x(@pad, @cs, col) + dx)}
          cy={f(x(@pad, @cs, row))}
          r={f(max(6, @r * 0.28))}
        />
        <circle
          :if={!@castle}
          class={"dot dot-#{color}"}
          data-road={"#{row}-#{col}"}
          cx={f(x(@pad, @cs, col) + dx)}
          cy={f(x(@pad, @cs, row))}
          r={f(max(4, @r * 0.18))}
        />
      <% end %>
      <%= if @castle do %>
        <g :for={{{r1, c1}, {r2, c2}, color} <- @walls} class={"wall wall-#{color}"}>
          <line
            x1={f(x(@pad, @cs, c1))}
            y1={f(x(@pad, @cs, r1))}
            x2={f(x(@pad, @cs, c2))}
            y2={f(x(@pad, @cs, r2))}
            style={"stroke-width:#{f(@r * 0.62)}"}
            class="wall-base"
          />
          <line
            x1={f(x(@pad, @cs, c1))}
            y1={f(x(@pad, @cs, r1))}
            x2={f(x(@pad, @cs, c2))}
            y2={f(x(@pad, @cs, r2))}
            style={"stroke-width:#{f(@r * 0.4)}"}
            class="wall-top"
          />
        </g>
      <% end %>
      <%= for {{row, col} = p, color} <- @stones do %>
        <circle
          :if={MapSet.member?(@danger, p)}
          class="alarm"
          cx={f(x(@pad, @cs, col))}
          cy={f(x(@pad, @cs, row))}
          r={f(@r * 1.02)}
        />
        <.piece
          castle={@castle}
          x={x(@pad, @cs, col)}
          y={x(@pad, @cs, row)}
          r={@r}
          color={color}
          class={MapSet.member?(@danger, p) && "danger"}
          data-stone={"#{row}-#{col}"}
          data-color={color}
        />
      <% end %>
      <.flag
        :if={@target && Board.get(@board, @target)}
        x={x(@pad, @cs, elem(@target, 1))}
        y={x(@pad, @cs, elem(@target, 0))}
        r={@r}
      />
      <circle
        :for={{{row, col}, color} <- Enum.sort(@marks)}
        :if={Board.get(@board, {row, col})}
        class={"mark mark-#{color}"}
        cx={f(x(@pad, @cs, col))}
        cy={f(x(@pad, @cs, row))}
        r={f(@r + 5)}
      />
      <g :for={b <- @badges} class="count">
        <circle cx={f(b.x)} cy={f(b.y)} r="11" class={"count-ring count-#{b.color}"} />
        <text x={f(b.x)} y={f(b.y + 4.5)} text-anchor="middle">{b.count}</text>
      </g>
      <.piece
        :for={{{row, col}, color} <- @falls}
        id={"fall-#{@step}-#{row}-#{col}"}
        castle={@castle}
        x={x(@pad, @cs, col)}
        y={x(@pad, @cs, row)}
        r={@r}
        color={color}
        class="fall"
      />
      <circle
        :for={{row, col} <- @points}
        class="spot"
        data-point={"#{row}-#{col}"}
        phx-click="tap"
        phx-value-r={row}
        phx-value-c={col}
        role="button"
        aria-label={spot_label(@board, {row, col})}
        cx={f(x(@pad, @cs, col))}
        cy={f(x(@pad, @cs, row))}
        r={f(@cs / 2)}
      />
    </svg>
    """
  end

  attr :castle, :boolean, required: true
  attr :x, :float, required: true
  attr :y, :float, required: true
  attr :r, :float, required: true
  attr :color, :atom, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  defp piece(%{castle: true} = assigns) do
    s = assigns.r * 0.82
    assigns = assign(assigns, s: s)

    ~H"""
    <g class={["tower", "tower-#{@color}", @class]} {@rest}>
      <rect
        x={f(@x - @s * 0.72)}
        y={f(@y - @s * 0.45)}
        width={f(@s * 1.44)}
        height={f(@s * 1.2)}
        rx="2"
        class="body"
      />
      <rect
        :for={o <- [-0.72, -0.18, 0.36]}
        x={f(@x + o * @s)}
        y={f(@y - @s * 0.8)}
        width={f(@s * 0.36)}
        height={f(@s * 0.38)}
        class="body"
      />
      <path
        d={"M#{f(@x - @s * 0.22)} #{f(@y + @s * 0.75)}v-#{f(@s * 0.32)}a#{f(@s * 0.22)} #{f(@s * 0.22)} 0 0 1 #{f(@s * 0.44)} 0v#{f(@s * 0.32)}z"}
        class="door"
      />
      <rect
        x={f(@x - @s * 0.09)}
        y={f(@y - @s * 0.22)}
        width={f(@s * 0.18)}
        height={f(@s * 0.22)}
        class="door"
      />
    </g>
    """
  end

  defp piece(assigns) do
    ~H"""
    <circle
      class={["stone", "stone-#{@color}", @class]}
      cx={f(@x)}
      cy={f(@y)}
      r={f(@r * 0.98)}
      {@rest}
    />
    """
  end

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
