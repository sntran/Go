defmodule Go.Solver do
  @moduledoc """
  Reads a capture fight to the end.

  A fight has a target (a point of the target group), an attacker color
  and a number of attacker moves. The attacker wins when it captures the
  target group in these moves. The defender plays its best defense, and
  the attacker plays its best attack.

  The search:

    * It looks only at moves near the fight: the liberties of the target,
      the liberties of these liberties, and the liberties of enemy groups
      next to the target that have 3 liberties or fewer (counter-attacks
      for the defender, rescues for the attacker), and the liberties of
      friend groups that touch a liberty of the target and have 3
      liberties or fewer.
    * It uses a sound cut: a target with L liberties needs at least L
      attacker moves. If L is more than the attacker moves that are left,
      the target survives.
    * It keeps a cache of the positions that it already checked.
    * The defender can also pass.
  """

  alias Go.Board

  # The enemy groups next to the target with this many liberties or fewer
  # are part of the fight.
  @counter_libs 3

  @type fight :: %{
          target: Board.point(),
          attacker: Board.color(),
          defender: Board.color(),
          passes_only: boolean()
        }

  @doc """
  Tells if the attacker can capture the target group in `n` attacker moves.

  `to_move` is the color that plays next. With `passes_only: true`, the
  defender only passes: this tells if the target is in danger when the
  defender does nothing. With `settled: k`, a target with k liberties or
  more has escaped: the search stops there. This is not exact, so only the
  deep checks use it (see `Go.Goal.deep/0`). With `life: true`, a target
  that is alive by Benson's algorithm (see `Go.Life`) has escaped. This is
  exact, but slow, so only the final check of the bank uses it.
  """
  @spec attacker_wins?(
          Board.t(),
          Board.point(),
          Board.color(),
          Board.color(),
          non_neg_integer(),
          keyword()
        ) ::
          boolean()
  def attacker_wins?(board, target, attacker, to_move, n, opts \\ []) do
    fight = fight(target, attacker, opts)
    {result, _cache} = search(board, fight, to_move, n, %{})
    result
  end

  @doc """
  Gives the smallest number of attacker moves (from 1 to `max`) that
  captures the target, or nil.
  """
  @spec moves_to_capture(
          Board.t(),
          Board.point(),
          Board.color(),
          Board.color(),
          non_neg_integer(),
          keyword()
        ) ::
          pos_integer() | nil
  def moves_to_capture(board, target, attacker, to_move, max, opts \\ []) do
    fight = fight(target, attacker, opts)

    {found, _cache} =
      Enum.reduce_while(1..max//1, {nil, %{}}, fn n, {nil, cache} ->
        case search(board, fight, to_move, n, cache) do
          {true, cache} -> {:halt, {n, cache}}
          {false, cache} -> {:cont, {nil, cache}}
        end
      end)

    found
  end

  @doc "Tells if the target group is captured (its point holds no defender stone)."
  @spec captured?(Board.t(), Board.point(), Board.color()) :: boolean()
  def captured?(board, target, defender), do: Board.get(board, target) != defender

  @doc """
  Gives the moves near the fight, in the order that the search tries them.
  """
  @spec candidates(Board.t(), Board.point()) :: [Board.point()]
  def candidates(board, target) do
    case Board.group(board, target) do
      nil -> []
      group -> candidates(board, group, group.liberties)
    end
  end

  defp candidates(board, group, libs) do
    second =
      libs
      |> Enum.flat_map(&Board.neighbors(board, &1))
      |> Enum.reject(&Map.has_key?(board.stones, &1))

    enemy = Board.other(group.color)

    # Counter-attacks and rescues: the liberties of the enemy groups next to
    # the target that have few liberties. The defender can attack them, and
    # the attacker can save them.
    rescue_or_take =
      group.stones
      |> Enum.flat_map(&Board.neighbors(board, &1))
      |> Enum.filter(&(Map.get(board.stones, &1) == enemy))
      |> Enum.uniq()
      |> Enum.map(&Board.group(board, &1))
      |> Enum.uniq_by(& &1.stones)
      |> Enum.filter(&(length(&1.liberties) <= @counter_libs))
      |> Enum.sort_by(&length(&1.liberties))
      |> Enum.flat_map(&Enum.sort(&1.liberties))

    # Friends: the liberties of other groups of the target color that touch
    # a liberty of the target. The defender can make them strong before it
    # joins them, and the attacker can close them.
    friends =
      libs
      |> Enum.flat_map(&Board.neighbors(board, &1))
      |> Enum.filter(&(Map.get(board.stones, &1) == group.color and &1 not in group.stones))
      |> Enum.uniq()
      |> Enum.map(&Board.group(board, &1))
      |> Enum.uniq_by(& &1.stones)
      |> Enum.filter(&(length(&1.liberties) <= @counter_libs))
      |> Enum.flat_map(&Enum.sort(&1.liberties))

    Enum.uniq(Enum.sort(libs) ++ rescue_or_take ++ Enum.sort(second) ++ friends)
  end

  defp fight(target, attacker, opts) do
    %{
      target: target,
      attacker: attacker,
      defender: Board.other(attacker),
      passes_only: Keyword.get(opts, :passes_only, false),
      settled: Keyword.get(opts, :settled),
      life: Keyword.get(opts, :life, false)
    }
  end

  defp search(board, fight, to_move, n, cache) do
    key = {board.stones, board.ko, to_move, n}

    case cache do
      %{^key => result} ->
        {result, cache}

      _ ->
        {result, cache} = compute(board, fight, to_move, n, cache)
        {result, Map.put(cache, key, result)}
    end
  end

  defp compute(board, fight, to_move, n, cache) do
    case Board.group(board, fight.target) do
      %{color: color} = group when color == fight.defender ->
        libs = length(group.liberties)

        cond do
          n == 0 or libs > n -> {false, cache}
          fight.settled != nil and libs >= fight.settled -> {false, cache}
          # An alive group has 2 liberties or more.
          fight.life and libs >= 2 and Go.Life.alive?(board, fight.target) -> {false, cache}
          to_move == fight.attacker -> attack(board, fight, group, n, cache)
          true -> defend(board, fight, group, n, cache)
        end

      _captured ->
        {true, cache}
    end
  end

  # The order of the moves does not change the result. A good order only
  # makes the search faster: the attacker tries the moves that leave the
  # target the fewest liberties first.
  defp attack(board, fight, group, n, cache) do
    board
    |> candidates(group, group.liberties)
    |> ordered(board, fight.attacker, fight.target, :asc)
    |> Enum.reduce_while({false, cache}, fn {_move, next}, {false, cache} ->
      cond do
        captured?(next, fight.target, fight.defender) ->
          {:halt, {true, cache}}

        n > 1 ->
          case search(next, fight, fight.defender, n - 1, cache) do
            {true, cache} -> {:halt, {true, cache}}
            {false, cache} -> {:cont, {false, cache}}
          end

        true ->
          {:cont, {false, cache}}
      end
    end)
  end

  # The defender tries the moves that give the target the most liberties
  # first, and the pass last.
  defp defend(board, fight, group, n, cache) do
    moves =
      if fight.passes_only,
        do: [],
        else:
          board
          |> candidates(group, group.liberties)
          |> ordered(board, fight.defender, fight.target, :desc)

    {:ok, passed, _} = Board.play(board, fight.defender, :pass)

    Enum.reduce_while(moves ++ [{:pass, passed}], {true, cache}, fn {_move, next},
                                                                    {true, cache} ->
      case search(next, fight, fight.attacker, n, cache) do
        {false, cache} -> {:halt, {false, cache}}
        {true, cache} -> {:cont, {true, cache}}
      end
    end)
  end

  # Plays each legal move and sorts the moves by the liberties of the
  # target after the move. A captured target counts as 0 liberties.
  defp ordered(moves, board, color, target, direction) do
    moves
    |> Enum.flat_map(fn move ->
      case Board.play(board, color, move) do
        {:ok, next, _} -> [{move, next, Board.liberty_count(next, target)}]
        {:error, _} -> []
      end
    end)
    |> Enum.sort_by(&elem(&1, 2), direction)
    |> Enum.map(fn {move, next, _} -> {move, next} end)
  end
end
