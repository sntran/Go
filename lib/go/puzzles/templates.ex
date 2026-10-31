defmodule Go.Puzzles.Templates do
  @moduledoc """
  The templates of the puzzle generator. Each template is a real Go idea.

  A template gives base positions. The generator makes variations of each
  base (helper stones, shifts, the 8 symmetries, swapped sides), and the
  solver checks each variation. Random boards do not give good puzzles, so
  all puzzles come from templates.

  A base is a map with `:size`, `:blue`, `:red`, `:target` and `:max`
  (the most moves to try). The generator finds the smallest number of
  moves that solves it. A template also has `:min`, the fewest moves of
  its idea: an edge chase in 1 move is not an edge chase.

  Templates for the worlds that come later (connect, cut, two eyes, ko)
  go here too, with their goal types in `Go.Goal`.
  """

  @type base :: %{
          size: pos_integer(),
          blue: [Go.Board.point()],
          red: [Go.Board.point()],
          target: Go.Board.point(),
          max: pos_integer()
        }

  @type t :: %{
          name: String.t(),
          type: Go.Goal.type(),
          bases: (-> [base()]),
          helpers: boolean(),
          swap: boolean(),
          limit: pos_integer(),
          min: pos_integer(),
          say: String.t(),
          hint: String.t(),
          better: String.t() | nil,
          trap_why: String.t() | nil
        }

  @doc "All templates."
  @spec all() :: [t()]
  def all do
    [capture_in_1(), edge_chase(), ladder(), net(), escape_extend(), escape_capture(), escape_connect()]
  end

  @doc "Capture in 1: the red group has 1 road left."
  def capture_in_1 do
    %{
      name: "capture_in_1",
      type: :capture,
      helpers: false,
      swap: false,
      limit: 6,
      min: 1,
      say: "A red fort has only 1 open road left. It shakes! Close its last road.",
      hint: "Find the red fort that shakes. Count its open roads.",
      better: "Build on the last open road of the shaking fort.",
      trap_why: nil,
      bases: fn ->
        for size <- [5],
            {stones, _} <- red_lines(size),
            open <- roads(size, stones),
            do: %{size: size, red: stones, blue: roads(size, stones) -- [open], target: hd(stones), max: 1}
      end
    }
  end

  defp red_lines(size) do
    for r <- 0..2, c <- 0..2, len <- 1..3, dir <- [:h, :v], len == 1 or dir == :h or r + len <= size do
      stones = for k <- 0..(len - 1), do: if(dir == :h, do: {r, c + k}, else: {r + k, c})
      {stones, len}
    end
    |> Enum.filter(fn {stones, _} -> Enum.all?(stones, fn {r, c} -> r < size and c < size end) end)
    |> Enum.uniq_by(fn {s, _} -> Enum.sort(s) end)
  end

  defp roads(size, stones) do
    stones
    |> Enum.flat_map(&Go.Board.neighbors(%Go.Board{size: size}, &1))
    |> Enum.uniq()
    |> Kernel.--(stones)
    |> Enum.sort()
  end

  @doc "Edge chase: atari from the open side, so Red runs along the edge."
  def edge_chase do
    %{
      name: "edge_chase",
      type: :capture,
      helpers: true,
      swap: true,
      limit: 10,
      min: 2,
      say: "The red tower stands on the edge of the board. The edge closes roads for free. Chase Red along the edge.",
      hint: "Close the road that leads away from the edge and the corner.",
      better: "Close the road on the open side. Then Red can only run toward the corner, where it has no roads.",
      trap_why: "Your move chased Red away from the corner, into open space.",
      bases: fn ->
        for size <- [5, 7], c <- 1..(size - 2) do
          %{size: size, red: [{0, c}], blue: [{1, c}], target: {0, c}, max: 3}
        end
      end
    }
  end

  @doc "Ladder: atari again and again, so Red runs to the edge."
  def ladder do
    %{
      name: "ladder",
      type: :capture,
      helpers: true,
      swap: true,
      limit: 8,
      min: 3,
      say: "Chase Red in steps, like a ladder. Each time, leave Red only 1 road, and push it toward the edge.",
      hint: "Close the road that leaves Red only 1 road, and push Red toward your towers or the edge.",
      better: nil,
      trap_why: "Your move left Red 2 roads, so Red could run.",
      bases: fn ->
        for size <- [5, 7], r <- 1..3, c <- 1..3, r < size - 1, c < size - 1 do
          %{size: size, red: [{r, c}], blue: [{r - 1, c}, {r, c - 1}, {r + 1, c + 1}], target: {r, c}, max: 4}
        end
      end
    }
  end

  @doc "Net: an answer that does not touch Red. It closes the way out."
  def net do
    %{
      name: "net",
      type: :capture,
      helpers: true,
      swap: false,
      limit: 10,
      min: 3,
      say: "Red wants to run to its friends. Throw a net: you do not need to touch Red to catch it.",
      hint: "Do not touch Red. Close the way out with one tower.",
      better: "Build corner to corner from Red. That closes both ways out, like a net.",
      trap_why: "Your move touched Red, but Red could run away to its friend on the other side.",
      bases: fn ->
        for size <- [7, 9], r <- 2..(size - 4), c <- 2..(size - 4), fr <- [2, 3], fc <- [2, 3] do
          %{
            size: size,
            blue: [{r - 1, c}, {r - 1, c + 1}, {r, c - 1}, {r + 1, c - 1}],
            red: [{r, c}, {r, min(c + fc, size - 1)}, {min(r + fr, size - 1), c}],
            target: {r, c},
            max: 3
          }
        end
      end
    }
  end

  @doc "Escape by running: your tower has 1 road. Build on it to get more."
  def escape_extend do
    %{
      name: "escape_extend",
      type: :escape,
      helpers: true,
      swap: false,
      limit: 8,
      min: 1,
      say: "Your fort has only 1 open road, so it shakes. Red attacks. Save your fort!",
      hint: "Build on the last open road. Will your fort get more roads there?",
      better: "Run out on the last open road. There your fort gets new roads.",
      trap_why: nil,
      bases: fn ->
        for size <- [5, 7], r <- 1..2, c <- 1..2, open <- [:down, :right] do
          {dr, dc} = if open == :down, do: {1, 0}, else: {0, 1}
          t = {r, c}
          around = Go.Board.neighbors(%Go.Board{size: size}, t) -- [{r + dr, c + dc}]
          %{size: size, blue: [t], red: around, target: t, max: 2}
        end
      end
    }
  end

  @doc "Escape by capture: take the red tower that has 1 road."
  def escape_capture do
    %{
      name: "escape_capture",
      type: :escape,
      helpers: true,
      swap: false,
      limit: 8,
      min: 1,
      say: "Your fort shakes. One red tower next to it shakes too. Who is faster?",
      hint: "Look for a red tower with only 1 open road.",
      better: "Take the shaking red tower. Then your fort gets the roads that the red tower had.",
      trap_why: "Running did not help. Your fort was still in a small space.",
      bases: fn ->
        for size <- [5, 7], r <- 1..2, c <- 1..2 do
          t = {r, c}

          %{
            size: size,
            blue: [t, {r - 1, c + 1}, {r + 1, c + 1}],
            red: [{r - 1, c}, {r, c - 1}, {r, c + 1}],
            target: t,
            max: 2
          }
        end
      end
    }
  end

  @doc "Escape by joining: run to a friend and share its roads."
  def escape_connect do
    %{
      name: "escape_connect",
      type: :escape,
      helpers: true,
      swap: false,
      limit: 8,
      min: 1,
      say: "Your tower is in danger. A friend is near. Towers that touch join into one fort and share their roads.",
      hint: "Which spot joins your tower to its friend?",
      better: "Join your friend. Then your fort shares all the roads of both towers.",
      trap_why: "Your move did not join your tower to its friend.",
      bases: fn ->
        for size <- [5, 7], r <- 1..2, c <- 1..2 do
          t = {r, c}

          %{
            size: size,
            blue: [t, {r + 1, c + 1}],
            red: [{r - 1, c}, {r, c - 1}, {r + 1, c - 1}],
            target: t,
            max: 3
          }
        end
      end
    }
  end
end
