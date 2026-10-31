defmodule Go.Explain do
  @moduledoc """
  Makes the texts that teach after a move.

  After a wrong move, the player sees three parts: what happened, why, and
  a better move. A puzzle can have hand-written texts for its typical
  wrong first moves. For all other wrong moves, this module makes the
  texts from the solver's line: the road counts before and after, "joined
  its friend", "escaped with N roads".
  """

  alias Go.{Board, Puzzle, Solver}

  @type feedback :: %{
          tone: :good | :bad,
          title: String.t(),
          what: String.t() | nil,
          why: String.t() | nil,
          better: String.t() | nil,
          better_point: Board.point() | nil
        }

  @doc """
  Explains a wrong blue move.

    * `before`: the board before the blue move.
    * `move`: the blue move.
    * `line`: the moves after it, as `{color, move, captured}`. The first
      one is Red's punishment.
    * `left`: the "moves left" before the blue move.
    * `better`: the better move on `before`, or nil.
    * `start?`: true if `before` is the start of the puzzle. Then the
      hand-written texts of the puzzle apply.

  The option `caught_later: true` tells that Blue can still capture Red
  later, but not in the moves that are left. Then the texts do not say
  that Red got away.
  """
  @spec wrong(
          Puzzle.t(),
          Board.t(),
          Board.point(),
          list(),
          non_neg_integer(),
          Board.point() | nil,
          boolean(),
          keyword()
        ) ::
          feedback()
  def wrong(puzzle, before, move, line, left, better, start?, opts \\ []) do
    goal = puzzle.goal
    {:ok, after_blue, _} = Board.play(before, :blue, move)
    final = replay(after_blue, line)
    hand = if start?, do: Map.get(puzzle.wrong, move), else: nil
    better_text = if start? && better == puzzle.answer && puzzle.better, do: puzzle.better

    made =
      case goal.type do
        :capture ->
          later = Keyword.get(opts, :caught_later, false)
          capture_texts(goal, before, move, after_blue, line, final, left, better, later)

        :escape -> escape_texts(goal, before, move, after_blue, line, final, better)
      end

    %{
      tone: :bad,
      title: made.title,
      what: (hand && hand.what) || made.what,
      why: (hand && hand.why) || made.why,
      better: better_text || made.better,
      better_point: better
    }
  end

  @doc "Plays a line of `{color, move, captured}` on a board."
  def replay(board, line) do
    Enum.reduce(line, board, fn {color, m, _}, b ->
      {:ok, b, _} = Board.play(b, color, m)
      b
    end)
  end

  ## Capture: Blue attacks, Red escapes.

  defp capture_texts(goal, before, move, after_blue, line, final, left, better, later) do
    target = goal.target
    roads_before = Board.liberty_count(before, target)
    roads_after = Board.liberty_count(final, target)
    blue_left = left - 1

    {what, joined?, took} =
      case line do
        [{:red, :pass, _} | _] ->
          {"Red did not need to move. Red still has #{roads(roads_after)}.", false, 0}

        [{:red, r, captured} | _] ->
          joined? = joined?(after_blue, final, target)
          dir = direction(after_blue, target, r)

          cond do
            captured != [] ->
              {"Red took #{towers(length(captured))} of yours. Now Red has #{roads(roads_after)}.",
               joined?, length(captured)}

            joined? ->
              {"Red ran #{dir} and joined its friend. Now Red has #{roads(roads_after)}.", true,
               0}

            true ->
              {"Red ran #{dir}. Now Red has #{roads(roads_after)}.", false, 0}
          end

        [] ->
          {nil, false, 0}
      end

    touch = touch(before, target, move)

    first =
      case touch do
        :touch when joined? ->
          "Your move touched Red, but it left Red a road toward its friend."

        :touch when took > 0 ->
          "Your move left one of your towers with only 1 road, so Red took it."

        :touch ->
          "Your move closed one road, but it left Red a way out. Red had #{roads(roads_before)}, and after its run it has #{roads(roads_after)}."

        :corner ->
          "You built corner to corner with Red. Roads go only up, down, left and right, so your move closed no road."

        :near when joined? ->
          "Your move did not close a road, and it left Red a road toward its friend."

        :near ->
          "Your move did not close a road of Red, so Red got a free move."

        :far ->
          "Your move was far from the fight. It closed no road of Red, so Red got a free move."
      end

    second =
      cond do
        later and blue_left == 0 ->
          " You have no moves left. You could catch Red later, but not in time."

        later ->
          " You can still catch Red later, but not in #{moves(blue_left)}."

        blue_left == 0 ->
          " You have no moves left."

        roads_after > blue_left ->
          " You have #{moves(blue_left)} left. That is not enough to close #{roads(roads_after)}."

        true ->
          " Red can now run away from each of your moves."
      end

    %{
      title: if(later, do: "Not fast enough", else: "Red got away"),
      what: what,
      why: first <> second,
      better: better_capture(before, target, better)
    }
  end

  defp better_capture(_before, _target, nil), do: nil

  defp better_capture(before, target, better) do
    {:ok, next, captured} = Board.play(before, :blue, better)

    cond do
      Solver.captured?(next, target, :red) ->
        "Build on the glowing spot. It closes the last road, and Red falls."

      captured != [] ->
        "Build on the glowing spot. It takes a red tower first."

      touch(before, target, better) == :touch ->
        "Build on the glowing spot. Then Red has only #{roads(Board.liberty_count(next, target))} left, and Red cannot get away."

      true ->
        "Build on the glowing spot. It does not touch Red, but it closes the way out, like a net."
    end
  end

  ## Escape: Red attacks, Blue defends.

  defp escape_texts(goal, before, move, after_blue, line, final, better) do
    target = goal.target
    fallen = Solver.captured?(final, target, :blue)
    roads_after_blue = Board.liberty_count(after_blue, target)
    {:ok, _, took} = Board.play(before, :blue, move)

    lost =
      line
      |> Enum.filter(&match?({:red, _, _}, &1))
      |> Enum.flat_map(&elem(&1, 2))
      |> length()

    what =
      cond do
        fallen and length(line) <= 1 ->
          "Red closed the last road of your fort, and #{towers(lost)} fell."

        fallen ->
          "Red closed the roads of your fort one by one, and #{towers(lost)} fell."

        true ->
          "Red closed a road. Now Red can catch your fort, whatever you do."
      end

    why =
      cond do
        roads_after_blue == 0 ->
          "Your fort had no road left."

        took != [] ->
          "You took a red tower, but your fort still had too few roads."

        touch(before, target, move) == :corner ->
          "Your new tower touched your fort only at a corner, so it did not join. Towers join only up, down, left and right."

        touch(before, target, move) != :touch ->
          "Your move did not touch your fort, so your fort got no new roads."

        roads_after_blue == 1 ->
          "After your move, your fort had only 1 road left."

        true ->
          "Your move gave your fort only #{roads(roads_after_blue)}. Red could close them one at a time."
      end

    %{
      title: "Your fort fell",
      what: what,
      why: why,
      better: better_escape(before, target, better)
    }
  end

  defp better_escape(_before, _target, nil), do: nil

  defp better_escape(before, target, better) do
    {:ok, next, captured} = Board.play(before, :blue, better)
    n = Board.liberty_count(next, target)

    cond do
      captured != [] ->
        "Take the red tower on the glowing spot. Then your fort gets new roads."

      joined?(before, next, target) ->
        "Build on the glowing spot to join your friend. Then your fort has #{roads(n)}."

      true ->
        "Build on the glowing spot. Then your fort has #{roads(n)}."
    end
  end

  ## Texts after good moves.

  @doc "The message after a good blue move and Red's reply."
  @spec after_reply(Go.Goal.t(), Board.t(), Board.point() | :pass, Board.t(), non_neg_integer()) ::
          String.t()
  def after_reply(%{type: :capture} = goal, before_red, red, final, left) do
    n = Board.liberty_count(final, goal.target)

    ran =
      case red do
        :pass ->
          "Red waited."

        r ->
          if joined?(before_red, final, goal.target),
            do: "Red joined its friend.",
            else: "Red ran #{direction(before_red, goal.target, r)}."
      end

    "Good move! #{ran} Red has #{roads(n)}. You have #{moves(left)} left."
  end

  def after_reply(%{type: :escape} = goal, _before_red, red, final, left) do
    n = Board.liberty_count(final, goal.target)
    built = if red == :pass, do: "Red waited.", else: "Red closed a road."
    "Good move! #{built} Your fort has #{roads(n)}. Red has #{moves(left)} left."
  end

  @doc "The text when the goal is reached."
  @spec win(Puzzle.t(), Board.t(), [Board.point()], non_neg_integer()) :: String.t()
  def win(%Puzzle{win: win}, _board, _captured, _left) when is_binary(win), do: win

  def win(%Puzzle{goal: %{type: :capture}}, _board, captured, _left),
    do: "You closed all of Red's roads, and #{towers(length(captured))} fell."

  def win(%Puzzle{goal: %{type: :escape} = goal}, board, _captured, left) do
    n = Board.liberty_count(board, goal.target)

    if left == 0,
      do: "Red has no moves left, and your fort still stands with #{roads(n)}. It is safe.",
      else: "Your fort has #{roads(n)}. It is safe now: Red cannot catch it, not even with more moves."
  end

  ## Helpers.

  @doc """
  Tells how a move relates to the target group: `:touch` (next to it),
  `:corner` (only corner to corner), `:near` (near the fight) or `:far`.
  """
  @spec touch(Board.t(), Board.point(), Board.point()) :: :touch | :corner | :near | :far
  def touch(board, target, move) do
    group = Board.group(board, target)
    stones = MapSet.new(group.stones)

    cond do
      Enum.any?(Board.neighbors(board, move), &MapSet.member?(stones, &1)) -> :touch
      Enum.any?(Board.diagonals(board, move), &MapSet.member?(stones, &1)) -> :corner
      move in Solver.candidates(board, target) -> :near
      true -> :far
    end
  end

  # True if the target group took in stones of another group of its color.
  defp joined?(before, final, target) do
    with %{} = g0 <- Board.group(before, target),
         %{} = g1 <- Board.group(final, target) do
      color = g0.color
      old = MapSet.new(g0.stones)

      Enum.any?(g1.stones, fn p ->
        not MapSet.member?(old, p) and Board.get(before, p) == color
      end)
    else
      _ -> false
    end
  end

  @doc "Tells the direction from the target group to a point next to it."
  @spec direction(Board.t(), Board.point(), Board.point()) :: String.t()
  def direction(board, target, {r, c} = point) do
    case Board.group(board, target) do
      nil ->
        "away"

      g ->
        from = Enum.find(g.stones, &(&1 in Board.neighbors(board, point))) || target
        {fr, fc} = from

        cond do
          r > fr -> "down"
          r < fr -> "up"
          c > fc -> "right"
          c < fc -> "left"
          true -> "away"
        end
    end
  end

  def roads(1), do: "1 road"
  def roads(n), do: "#{n} roads"
  def towers(1), do: "1 tower"
  def towers(n), do: "#{n} towers"
  def moves(1), do: "1 move"
  def moves(n), do: "#{n} moves"
end
