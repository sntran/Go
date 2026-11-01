defmodule Go.Library.Maker do
  @moduledoc """
  Makes the stories of `Go.Library`, offline. The mix task
  `mix go.gen.library` runs it with KataGo. It never runs on the server.

  ## The games

  An evaluator (`Go.Library.Evaluator`, normally KataGo) plays both sides
  at the same strength: each move comes from its policy. The first
  8 moves come by chance from the good moves (a real opening on the whole
  board, and a different game for each seed). After that, each side plays
  a top move of the policy, with a little chance.

  Red makes a realistic mistake only at a moment that becomes a puzzle: on
  a turn of Red, the maker tries the top moves of the Red policy. When one
  of them gives Blue a puzzle that passes all checks of a moment, Red plays
  it. Blue then plays the answer. When the solver finds a puzzle for Blue
  on another turn, Blue plays its answer too. A moment comes at least 4
  moves after the last one, or at least 2 moves after it on another group.

  ## The checks of a moment

    1. The normal puzzle checks (`Go.Puzzles.Check`): exactly one correct
       move, and the tempting wrong moves fail. A moment needs at least one
       tempting wrong move.
    2. The moment matters: by the score estimate, the answer is better than
       each tempting wrong move by at least 5 points. The answer is also a good
       move for the whole board: not more than 2 points worse than the top
       move of the policy.

  During the game, a fast estimate (1 visit) does check 2. With KataGo, a
  smaller, fast network can make these estimates (see
  `Go.Library.KatagoEvaluator`). When the game is over, a search of the
  strong network with more visits checks it again.

  ## The checks of a story

    0. The game ends with two passes (not at the move limit).
    1. At least 4 moments pass the checks, each with another answer point
       (a moment with the answer of an earlier one, for example in a ko
       fight, is not a moment). When more than half of the
       moments are "capture in 1", the maker drops some of them (the
       computer then plays them in the story).
    2. A close game: Blue wins by 1 to 10 points, by the score estimate
       before the end, and by the area score at the end.

  ## The rank score

  10 points for each moment that uses stones of an earlier moment, 5
  points for each different idea (the goal, the moves and if the answer
  touches the target), 5 points for each moment that is not easier than
  the one before it, and 10 points when the last moment is harder than the
  first.
  """

  alias Go.{Board, Goal, Library, Puzzle, Puzzles, Score, Solver}
  alias Go.Library.Evaluator
  alias Go.Puzzles.{Check, Grade, Symmetry}

  @size 9
  @opening 8
  @gap 4
  @min_gap 2
  @near_best 2
  @max_moves 160
  @check_ms 10_000
  @min_diff 5
  @min_moments 4
  @margin 1..10
  @mistake_min 0.005
  @opening_min 0.01
  @opening_choices 6
  @opening_loss 1.5
  @opening_key 10
  @opening_max 2
  @recheck_below 8
  @recheck_visits 200
  @mistakes 10
  @temperature 0.1
  @give_up_at 44
  @cap 9

  def opening, do: @opening
  def opening_max, do: @opening_max
  def min_diff, do: @min_diff
  def min_moments, do: @min_moments
  def margin, do: @margin

  ## Many stories

  @doc """
  Makes `count` stories. Options:

    * `:from`: the first seed (the default is 1).
    * `:seeds`: the seeds to try, in place of `:from`.
    * `:games`: the number of games in parallel (the default is 8).
    * `:visits`: the visits of the check after the game (the default is 16).
    * `:report`: a function that gets `{seed, result}` for each game.
    * `:stories`: the stories that the library has already. A game whose
      first #{@opening_key} moves (with the rotations) are the same as in
      #{@opening_max} stories stops at move #{@opening_key}, and a game that
      is the same as a story is dropped.

  Gives `%{stories: stories, games: tried, drops: %{reason => count}}`.
  """
  def build(ev, count, opts \\ []) do
    seeds = Keyword.get_lazy(opts, :seeds, fn -> Stream.iterate(opts[:from] || 1, &(&1 + 1)) end)
    table = :ets.new(:openings, [:public, :set])
    known = Keyword.get(opts, :stories, [])
    for s <- known, do: :ets.update_counter(table, opening_key(s.moves), 1, {nil, 0})
    for s <- known, do: :ets.insert(table, {{:game, game_key(s.moves)}, true})
    full? = fn key -> match?([{_, n}] when n >= @opening_max, :ets.lookup(table, key)) end
    opts = Keyword.put(opts, :opening_full?, full?)
    report = Keyword.get(opts, :report, fn _ -> :ok end)

    {results, _found} =
      seeds
      |> Task.async_stream(
        fn seed ->
          result = seed |> game(ev, opts) |> story(ev, opts) |> new_opening(table)
          report.({seed, result})
          {seed, result}
        end,
        max_concurrency: Keyword.get(opts, :games, 8),
        ordered: false,
        timeout: :infinity
      )
      |> Enum.reduce_while({[], 0}, fn {:ok, r}, {acc, found} ->
        found = if match?({_, {:ok, _}}, r), do: found + 1, else: found
        if found >= count, do: {:halt, {[r | acc], found}}, else: {:cont, {[r | acc], found}}
      end)

    results = Enum.reverse(results)

    stories = for {_seed, {:ok, s}} <- results, do: s

    drops =
      for({_seed, {:drop, reason}} <- results, do: reason)
      |> Enum.frequencies()

    %{stories: Enum.take(stories, count), games: length(results), drops: drops}
  end

  # The last check of the opening, and of the same game (two games that end
  # at the same time can have the same opening).
  defp new_opening({:ok, story} = result, table) do
    key = opening_key(story.moves)

    cond do
      :ets.member(table, {:game, game_key(story.moves)}) ->
        {:drop, "the same game as a story"}

      match?([{_, n}] when n >= @opening_max, :ets.lookup(table, key)) ->
        {:drop, "an opening that #{@opening_max} stories have"}

      true ->
        :ets.update_counter(table, key, 1, {nil, 0})
        :ets.insert(table, {{:game, game_key(story.moves)}, true})
        result
    end
  end

  defp new_opening(result, _table), do: result

  @doc """
  The key of the opening of a game: its first #{@opening_key} moves, the same
  for all 8 rotations and mirrors of the board.
  """
  def opening_key(moves), do: moves |> Enum.take(@opening_key) |> game_key()

  @doc "The key of a game: the same for all 8 rotations and mirrors of the board."
  def game_key(moves) do
    Symmetry.all()
    |> Enum.map(fn sym ->
      Enum.map(moves, fn
        {c, :pass} -> {c, :pass}
        {c, p} -> {c, Symmetry.map_point(sym, @size, p)}
      end)
    end)
    |> Enum.min()
  end

  ## One game

  @doc """
  Plays one game. Gives `%{seed, moves, moments, gave_up}`, where each
  moment is `%{index, puzzle, report, diffs, score}` (from the fast
  estimate). `gave_up` is the reason when the game stopped early (nil when
  it did not): fewer than 2 moments at move #{@give_up_at}, or an opening
  that #{@opening_max} stories have (see `build/3`).
  """
  def game(seed, ev, opts \\ []) do
    :rand.seed(:exsss, {seed, 211, 223})
    max = Keyword.get(opts, :max_moves, @max_moves)

    state = %{
      board: Board.new(@size),
      moves: [],
      color: :blue,
      passes: 0,
      last: -@gap,
      found: [],
      gave_up: nil,
      checked: nil,
      last_group: MapSet.new()
    }

    state = loop(state, ev, max, opts)

    %{
      seed: seed,
      moves: Enum.reverse(state.moves),
      moments: Enum.reverse(state.found),
      gave_up: state.gave_up
    }
  end

  defp loop(%{passes: 2} = state, _ev, _max, _opts), do: state
  defp loop(%{moves: moves} = state, _ev, max, _opts) when length(moves) >= max, do: state

  # A game with fewer than 2 moments at this move rarely gets 4. It stops
  # early, to save time.
  defp loop(%{moves: moves, found: found} = state, _ev, _max, _opts)
       when length(moves) == @give_up_at and length(found) < 2,
       do: %{state | gave_up: "fewer than 2 moments at move #{@give_up_at}"}

  defp loop(%{moves: moves} = state, ev, max, opts) when length(moves) == @opening_key do
    full? = Keyword.get(opts, :opening_full?, fn _ -> false end)

    if full?.(opening_key(Enum.reverse(moves))),
      do: %{state | gave_up: "an opening that #{@opening_max} stories have"},
      else: play_on(state, ev, max, opts)
  end

  defp loop(state, ev, max, opts), do: play_on(state, ev, max, opts)

  defp play_on(state, ev, max, opts) do
    n = length(state.moves)
    line = Enum.reverse(state.moves)
    # A moment soon after the last one must be on another group.
    open? = fn k -> k >= @opening and k - state.last >= @min_gap end
    avoid = fn k -> if k - state.last < @gap, do: state.last_group, else: MapSet.new() end

    state =
      case state.color do
        # The mistake search of Red checked this board already.
        :blue ->
          case open?.(n) && state.board != state.checked &&
                 find_moment(state.board, line, ev, avoid: avoid.(n)) do
            %{} = moment -> moment_move(state, n, moment)
            _ -> step(state, move(ev, line, Evaluator.policy(ev, line), n, state.board, :blue))
          end

        :red ->
          policy = Evaluator.policy(ev, line)

          case open?.(n + 1) && mistake(state.board, line, policy, ev, avoid.(n + 1)) do
            {move, moment} ->
              state |> step(move) |> moment_move(n + 1, moment)

            no ->
              state = step(state, move(ev, line, policy, n, state.board, :red))
              if no == nil, do: %{state | checked: top_board(state, line, policy)}, else: state
          end
      end

    loop(state, ev, max, opts)
  end

  defp moment_move(state, n, moment) do
    group = Board.group(state.board, moment.puzzle.goal.target).stones
    state = step(state, moment.puzzle.answer)

    %{
      state
      | last: n,
        last_group: MapSet.new(group),
        found: [Map.put(moment, :index, n) | state.found]
    }
  end

  defp step(state, move) do
    {:ok, board, _} = Board.play(state.board, state.color, move)

    %{
      state
      | board: board,
        moves: [{state.color, move} | state.moves],
        color: Board.other(state.color),
        passes: if(move == :pass, do: state.passes + 1, else: 0)
    }
  end

  # In the opening: an opening move. Later: a top move, with a little chance
  # (the temperature).
  defp move(ev, line, policy, n, board, color) when n < @opening do
    case opening_moves(ev, line, policy, board, color) do
      [] -> choose(policy, board, color)
      moves -> Enum.random(moves)
    end
  end

  defp move(_ev, _line, policy, _n, board, color), do: choose(policy, board, color)

  @doc """
  The moves of the opening, for more different games: the #{@opening_choices}
  best different moves of the policy (moves that a symmetry of the board
  makes the same count one time), with #{round(@opening_min * 100)}% or more,
  and not more than #{@opening_loss} points worse than the best of them by
  the fast estimate. The game takes one of them by chance.
  """
  def opening_moves(ev, line, policy, board, color) do
    syms = Enum.filter(1..7, fn sym -> map_stones(board, sym) == board.stones end)

    candidates =
      policy
      |> Enum.filter(fn {m, p} -> m != :pass and p >= @opening_min and legal?(board, color, m) end)
      |> Enum.sort_by(fn {_m, p} -> -p end)
      |> Enum.uniq_by(fn {m, _p} -> Enum.min([m | Enum.map(syms, &Symmetry.map_point(&1, @size, m))]) end)
      |> Enum.take(@opening_choices)
      |> Enum.map(&elem(&1, 0))

    own =
      candidates
      |> Task.async_stream(&Evaluator.score(ev, line ++ [{color, &1}], 1), timeout: :infinity)
      |> Enum.map(fn {:ok, s} -> if color == :blue, do: s, else: -s end)

    case own do
      [] ->
        []

      _ ->
        best = Enum.max(own)
        for {m, s} <- Enum.zip(candidates, own), s >= best - @opening_loss, do: m
    end
  end

  defp map_stones(board, sym),
    do: Map.new(board.stones, fn {p, c} -> {Symmetry.map_point(sym, @size, p), c} end)

  defp legal?(board, color, p), do: match?({:ok, _, _}, Board.play(board, color, p))

  # A top move, with a little chance (the temperature). Only legal moves.
  defp choose(policy, board, color) do
    list = Enum.filter(policy, fn {m, _} -> m == :pass or legal?(board, color, m) end)
    temp = @temperature
    weights = Enum.map(list, fn {m, p} -> {m, :math.pow(max(p, 1.0e-9), 1 / temp)} end)
    total = Enum.reduce(weights, 0.0, fn {_, w}, acc -> acc + w end)
    pick(weights, :rand.uniform() * total)
  end

  defp pick([{m, _}], _x), do: m
  defp pick([{m, w} | _], x) when x <= w, do: m
  defp pick([{_, w} | rest], x), do: pick(rest, x - w)

  # The board after the top move of Red (the first move that the mistake
  # search checks), when Red played it.
  defp top_board(state, line, policy) do
    case policy |> Enum.reject(&(elem(&1, 0) == :pass)) |> Enum.max_by(&elem(&1, 1), fn -> nil end) do
      {top, _p} -> if line ++ [{:red, top}] == Enum.reverse(state.moves), do: state.board
      nil -> nil
    end
  end

  # The top moves of Red. The first one that gives Blue a good moment.
  # A move that is not the top move is a mistake: Red makes it only when
  # Blue does not lead by more than the cap after the answer, so that the
  # game stays close.
  defp mistake(board, line, policy, ev, avoid) do
    policy
    |> Enum.filter(fn {m, p} -> m != :pass and p >= @mistake_min end)
    |> Enum.sort_by(fn {_m, p} -> -p end)
    |> Enum.take(@mistakes)
    |> Enum.with_index()
    |> Enum.find_value(fn {{move, _p}, i} ->
      cap = if i == 0, do: :infinity, else: @cap

      with {:ok, next, _} <- Board.play(board, :red, move),
           %{} = moment <- find_moment(next, line ++ [{:red, move}], ev, cap: cap, avoid: avoid) do
        {move, moment}
      else
        _ -> nil
      end
    end)
  end

  ## Moments

  @doc """
  Finds a moment on the board, with Blue to play: a capture or an escape
  puzzle that passes the puzzle checks, and whose answer is better than
  each tempting wrong move by #{@min_diff} points or more. The answer must
  also be a good move for the whole board: not more than #{@near_best} points
  worse than the top move of the policy. Gives
  `%{puzzle, report, diffs, score}`, or nil. `score` is the estimate after
  the answer.

  The fast checks come first: one correct move in the move limit, then the
  score estimates, and then the deep puzzle checks. Options: `:visits` (1
  by default), `:cap` (the most that Blue may lead by after the answer),
  and `:avoid` (stones: a target group with one of them is not a moment).
  """
  def find_moment(board, line, ev, opts \\ []) do
    visits = Keyword.get(opts, :visits, 1)
    cap = Keyword.get(opts, :cap, :infinity)
    avoid = Keyword.get(opts, :avoid, MapSet.new())

    board
    |> goals()
    |> Enum.reject(fn goal ->
      Enum.any?(Board.group(board, goal.target).stones, &MapSet.member?(avoid, &1))
    end)
    |> Enum.find_value(fn goal ->
      with {:ok, {answer, traps}} <- Go.Think.within(@check_ms, fn -> quick(board, goal) end),
           {score, diffs} <- diffs(answer, traps, line, ev, visits),
           true <- cap == :infinity or score <= cap,
           true <- near_best?(answer, score, line, ev, visits),
           {:ok, {puzzle, report}} <-
             Go.Think.within(@check_ms, fn -> checked(board, goal, answer) end) do
        %{puzzle: puzzle, report: report, diffs: diffs, score: score}
      else
        _ -> nil
      end
    end)
  end

  # The answer is the top move of the policy, or nearly as good.
  defp near_best?(answer, score, line, ev, visits) do
    {top, _p} = ev |> Evaluator.policy(line) |> Enum.max_by(&elem(&1, 1))
    top == answer or score >= Evaluator.score(ev, line ++ [{:blue, top}], visits) - @near_best
  end

  # One correct move in the move limit, and at least one tempting wrong move.
  defp quick(board, goal) do
    with [answer] = good <- Goal.good_moves(goal, board, goal.moves, max: 2, deep: false),
         [_ | _] = traps <- Check.traps(goal, board, good) do
      {answer, traps}
    else
      _ -> nil
    end
  end

  @doc """
  The goals on a board: a red group that Blue catches in 3 moves or fewer,
  and a blue group that Red catches in 3 moves or fewer if Blue does
  nothing.
  """
  def goals(board) do
    captures =
      for g <- Board.groups(board, :red), length(g.liberties) <= 3 do
        target = Enum.min(g.stones)
        n = Solver.moves_to_capture(board, target, :blue, :blue, 3)
        n && %{type: :capture, target: target, moves: n}
      end

    escapes =
      for g <- Board.groups(board, :blue), length(g.liberties) <= 3 do
        target = Enum.min(g.stones)

        n =
          Enum.find(
            1..3,
            &Solver.attacker_wins?(board, target, :red, :red, &1, passes_only: true)
          )

        n && %{type: :escape, target: target, moves: n}
      end

    Enum.reject(captures ++ escapes, &is_nil/1)
  end

  defp checked(board, goal, answer) do
    puzzle = %Puzzle{
      world: goal.type,
      goal: goal,
      size: @size,
      blue: Enum.sort(for {p, :blue} <- board.stones, do: p),
      red: Enum.sort(for {p, :red} <- board.stones, do: p),
      answer: answer,
      template: "story",
      source: :generated
    }

    case Check.run(puzzle) do
      %{ok: true, traps: [_ | _]} = report -> {puzzle, report}
      _ -> nil
    end
  end

  # For each trap: the estimate after the answer minus the estimate after
  # the trap, with the estimate after the answer. nil when one of them is
  # smaller than the minimum.
  defp diffs(answer, traps, line, ev, visits) do
    [best | others] =
      [answer | traps]
      |> Task.async_stream(&Evaluator.score(ev, line ++ [{:blue, &1}], visits),
        timeout: :infinity,
        max_concurrency: length(traps) + 1
      )
      |> Enum.map(fn {:ok, s} -> s end)

    diffs = Enum.zip_with(traps, others, fn t, s -> {t, best - s} end)
    if Enum.all?(diffs, fn {_t, d} -> d >= @min_diff end), do: {best, diffs}
  end

  ## One story

  @doc """
  Makes a story from a game, or drops it. Gives `{:ok, story}` or
  `{:drop, reason}`. The option `:visits` is the size of the search for
  the second check of the moments and for the estimate before the end.
  The option `:books` (true by default) makes the books. The option
  `:margin` changes the range of a close game (for the tests).
  """
  def story(game, ev, opts \\ [])

  def story(%{gave_up: reason}, _ev, _opts) when is_binary(reason), do: {:drop, reason}

  def story(%{gave_up: true}, _ev, _opts),
    do: {:drop, "fewer than 2 moments at move #{@give_up_at}"}

  def story(game, ev, opts) do
    visits = Keyword.get(opts, :visits, 16)
    books? = Keyword.get(opts, :books, true)
    range = Keyword.get(opts, :margin, @margin)
    final = Library.play_moves(Board.new(@size), game.moves)
    area = Score.count(final)
    margin = area.blue.total - area.red.total

    with :ok <- ended(game.moves),
         :ok <- enough(game.moments, game.moments),
         :ok <- close(margin, range, "the area score"),
         estimate = Evaluator.score(ev, before_end(game.moves), visits),
         :ok <- close(estimate, range, "the estimate"),
         moments = confirm(game, ev, visits),
         moments = recheck(moments, game, ev, opts),
         moments = moments |> distinct() |> limit_capture_in_1(),
         :ok <- enough(moments, game.moments) do
      {:ok, build_story(game, moments, area, estimate, books?)}
    end
  end

  # A game ends with two passes. A game that stops at the move limit (for
  # example in a cycle of captures) has no real score.
  defp ended(moves) do
    if match?([{_, :pass}, {_, :pass}], Enum.take(moves, -2)),
      do: :ok,
      else: {:drop, "the game did not end"}
  end

  defp enough(moments, _found) when length(moments) >= @min_moments, do: :ok

  defp enough(moments, found) do
    {:drop,
     "fewer than #{@min_moments} moments that matter (#{length(found)} in the game, " <>
       "#{length(moments)} after the checks)"}
  end

  defp close(margin, range, what) do
    if margin >= range.first and margin <= range.last,
      do: :ok,
      else: {:drop, "not a close game by #{what} (Blue by #{Float.round(margin * 1.0, 1)})"}
  end

  # The moves without the passes at the end.
  defp before_end(moves) do
    moves |> Enum.reverse() |> Enum.drop_while(&match?({_, :pass}, &1)) |> Enum.reverse()
  end

  # The second check of each moment, with a bigger search.
  defp confirm(game, ev, visits) do
    Enum.flat_map(game.moments, fn m ->
      line = Enum.take(game.moves, m.index)

      case diffs(m.puzzle.answer, m.report.traps, line, ev, visits) do
        nil -> []
        {_score, diffs} -> [%{m | diffs: diffs}]
      end
    end)
  end

  # Each difference under #{@recheck_below} points again, with a search of
  # #{@recheck_visits} visits (the option `:recheck_visits`). A moment with a
  # difference now under the minimum is dropped.
  defp recheck(moments, game, ev, opts) do
    visits = Keyword.get(opts, :recheck_visits, @recheck_visits)

    Enum.flat_map(moments, fn m ->
      case recheck_diffs(m.diffs, m.puzzle.answer, Enum.take(game.moves, m.index), ev, visits) do
        nil -> []
        diffs -> [%{m | diffs: diffs}]
      end
    end)
  end

  @doc """
  Checks the differences under #{@recheck_below} points again with a search
  of `visits` visits. Gives the new differences, or nil when one is now
  under #{@min_diff} points.
  """
  def recheck_diffs(diffs, answer, line, ev, visits) do
    case for({t, d} <- diffs, d < @recheck_below, do: t) do
      [] ->
        diffs

      low ->
        [best | others] =
          [answer | low]
          |> Task.async_stream(&Evaluator.score(ev, line ++ [{:blue, &1}], visits),
            timeout: :infinity
          )
          |> Enum.map(fn {:ok, s} -> s end)

        new = Map.new(Enum.zip(low, Enum.map(others, &(best - &1))))
        diffs = Enum.map(diffs, fn {t, d} -> {t, Map.get(new, t, d)} end)
        if Enum.all?(diffs, fn {_t, d} -> d >= @min_diff end), do: diffs
    end
  end

  # A moment with the answer of an earlier moment (in a ko fight, for
  # example) teaches nothing new. The computer plays it.
  defp distinct(moments), do: Enum.uniq_by(moments, & &1.puzzle.answer)

  # Not more than half "capture in 1": drop those with the smallest
  # difference first.
  defp limit_capture_in_1(moments) do
    c1 = Enum.filter(moments, &c1?/1)
    extra = length(c1) - (length(moments) - length(c1))

    if extra > 0 do
      drop = c1 |> Enum.sort_by(&min_diff/1) |> Enum.take(extra) |> MapSet.new(& &1.index)
      Enum.reject(moments, &MapSet.member?(drop, &1.index))
    else
      moments
    end
  end

  defp c1?(m), do: m.puzzle.goal.type == :capture and m.puzzle.goal.moves == 1
  defp min_diff(m), do: m.diffs |> Enum.map(&elem(&1, 1)) |> Enum.min()

  defp build_story(game, found, area, estimate, books?) do
    moments =
      Enum.map(found, fn m ->
        puzzle = m.puzzle
        grade = Grade.of(puzzle, m.report)
        board = Puzzle.board(puzzle)
        book = if books?, do: book(puzzle, board, m.report), else: %{nodes: %{}, answer: []}
        answer_line = for {_c, {_, _} = p} <- book.answer, do: p

        %{
          index: m.index,
          goal: puzzle.goal,
          answer: puzzle.answer,
          window: Library.window(fight(board, puzzle, m.report) ++ answer_line),
          grade: grade,
          diffs: m.diffs,
          book: book
        }
      end)

    story = %{
      id: "story-#{game.seed}",
      seed: game.seed,
      moves: game.moves,
      moments: moments,
      score: %{blue: area.blue.total, red: area.red.total},
      estimate: estimate,
      grade: round(Enum.sum(Enum.map(moments, & &1.grade.score)) / length(moments)),
      rank: 0
    }

    %{story | rank: rank(story)}
  end

  @doc """
  The points of a fight: the target group and its roads, the answer, the
  tempting wrong moves, the groups next to the target group, and the stones
  next to a road of the target, next to the answer and next to each
  tempting wrong move. Nothing that touches the fight is dimmed.
  """
  def fight(board, puzzle, report) do
    group = Board.group(board, puzzle.goal.target)
    moves = [puzzle.answer | report.traps]
    near = for p <- group.liberties ++ moves, q <- Board.neighbors(board, p), Board.get(board, q), do: q
    group.stones ++ group.liberties ++ moves ++ next_groups(board, group) ++ near
  end

  defp next_groups(board, group) do
    group.stones
    |> Enum.flat_map(&Board.neighbors(board, &1))
    |> Enum.filter(&(Board.get(board, &1) not in [nil, Board.get(board, hd(group.stones))]))
    |> Enum.uniq()
    |> Enum.flat_map(&Board.group(board, &1).stones)
    |> Enum.uniq()
  end

  # The book: each tap in each position that a player can reach.
  defp book(puzzle, _board, _report), do: Puzzles.book(puzzle)

  @doc "The rank score of a story (see the moduledoc)."
  def rank(story) do
    moments = story.moments
    stones = Enum.map(moments, &moment_stones(story, &1))

    links =
      stones
      |> Enum.with_index()
      |> Enum.count(fn {{_own, near}, j} ->
        Enum.any?(Enum.take(stones, j), fn {own, _} -> not MapSet.disjoint?(own, near) end)
      end)

    ideas =
      moments
      |> Enum.map(&{&1.goal.type, &1.goal.moves, &1.grade.touches_target})
      |> Enum.uniq()
      |> length()

    grades = Enum.map(moments, & &1.grade.score)
    rises = grades |> Enum.chunk_every(2, 1, :discard) |> Enum.count(fn [a, b] -> b >= a end)
    harder = if List.last(grades) > hd(grades), do: 10, else: 0

    10 * links + 5 * ideas + 5 * rises + harder
  end

  # The stones of a moment (the target group and the answer), and the
  # stones near its fight (the target group and the groups next to it).
  defp moment_stones(story, m) do
    board = Library.board_at(story, m.index)
    group = Board.group(board, m.goal.target)
    own = MapSet.new([m.answer | group.stones])
    near = MapSet.new(group.stones ++ next_groups(board, group))
    {own, near}
  end

  ## The report

  @doc "The lines of the report for one story."
  def report_lines(story) do
    margin = story.score.blue - story.score.red

    head =
      "#{story.id}: #{length(story.moves)} moves. Main line: area score Blue #{story.score.blue}, " <>
        "Red #{story.score.red} (Blue wins by #{margin}). Estimate before the end: " <>
        "Blue by #{Float.round(story.estimate * 1.0, 1)}. Grade #{story.grade}. Rank score #{story.rank}."

    moments =
      story.moments
      |> Enum.with_index(1)
      |> Enum.map(fn {m, k} ->
        diffs =
          Enum.map_join(m.diffs, ", ", fn {t, d} ->
            "#{Go.Katago.gtp(t)} #{Float.round(d * 1.0, 1)}"
          end)

        "  #{k}. Move #{m.index + 1}: #{m.goal.type} in #{m.goal.moves}, answer " <>
          "#{Go.Katago.gtp(m.answer)}, grade #{m.grade.score}. Better than: #{diffs}."
      end)

    [head | moments]
  end
end
