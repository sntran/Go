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
  on another turn, Blue plays its answer too.

  ## The checks of a moment

    1. The normal puzzle checks (`Go.Puzzles.Check`): exactly one correct
       move, and the tempting wrong moves fail. A moment needs at least one
       tempting wrong move.
    2. The moment matters: by the score estimate, the answer is better than
       each tempting wrong move by at least 5 points.

  During the game, a fast estimate (1 visit) does check 2. When the game is
  over, a search with more visits checks it again.

  ## The checks of a story

    1. At least 4 moments pass the checks. When more than half of the
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
  alias Go.Puzzles.{Check, Grade}

  @size 9
  @opening 8
  @gap 4
  @max_moves 160
  @check_ms 10_000
  @book_ms 10_000
  @min_diff 5
  @min_moments 4
  @margin 1..10
  @mistake_min 0.005
  @opening_min 0.02
  @mistakes 10
  @temperature 0.1
  @give_up_at 44
  @cap 9

  def opening, do: @opening
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

  Gives `%{stories: stories, games: tried, drops: %{reason => count}}`.
  """
  def build(ev, count, opts \\ []) do
    seeds = Keyword.get_lazy(opts, :seeds, fn -> Stream.iterate(opts[:from] || 1, &(&1 + 1)) end)
    report = Keyword.get(opts, :report, fn _ -> :ok end)

    {results, _found} =
      seeds
      |> Task.async_stream(
        fn seed ->
          result = seed |> game(ev, opts) |> story(ev, opts)
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

  ## One game

  @doc """
  Plays one game. Gives `%{seed, moves, moments, gave_up}`, where each
  moment is `%{index, puzzle, report, diffs, score}` (from the fast
  estimate). `gave_up` is true when the game stopped early, because it had
  fewer than 2 moments at move #{@give_up_at}.
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
      gave_up: false
    }

    state = loop(state, ev, max)

    %{
      seed: seed,
      moves: Enum.reverse(state.moves),
      moments: Enum.reverse(state.found),
      gave_up: state.gave_up
    }
  end

  defp loop(%{passes: 2} = state, _ev, _max), do: state
  defp loop(%{moves: moves} = state, _ev, max) when length(moves) >= max, do: state

  # A game with fewer than 2 moments at this move rarely gets 4. It stops
  # early, to save time.
  defp loop(%{moves: moves, found: found} = state, _ev, _max)
       when length(moves) == @give_up_at and length(found) < 2,
       do: %{state | gave_up: true}

  defp loop(state, ev, max) do
    n = length(state.moves)
    line = Enum.reverse(state.moves)
    open? = n >= @opening and n - state.last >= @gap

    state =
      case state.color do
        :blue ->
          case open? && find_moment(state.board, line, ev) do
            %{} = moment -> moment_move(state, n, moment)
            _ -> step(state, choose(Evaluator.policy(ev, line), n, state.board, :blue))
          end

        :red ->
          policy = Evaluator.policy(ev, line)

          case open? && mistake(state.board, line, policy, ev) do
            {move, moment} -> state |> step(move) |> moment_move(n + 1, moment)
            _ -> step(state, choose(policy, n, state.board, :red))
          end
      end

    loop(state, ev, max)
  end

  defp moment_move(state, n, moment) do
    state = step(state, moment.puzzle.answer)
    %{state | last: n, found: [Map.put(moment, :index, n) | state.found]}
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

  # In the opening: by chance from the moves with 2% or more. Later: a top
  # move, with a little chance (the temperature). Only legal moves.
  defp choose(policy, n, board, color) do
    legal =
      Enum.filter(policy, fn
        {:pass, _} -> true
        {p, _} -> match?({:ok, _, _}, Board.play(board, color, p))
      end)

    {temp, list} =
      if n < @opening do
        good = Enum.filter(legal, fn {m, p} -> m != :pass and p >= @opening_min end)
        {1.0, if(good == [], do: legal, else: good)}
      else
        {@temperature, legal}
      end

    weights = Enum.map(list, fn {m, p} -> {m, :math.pow(max(p, 1.0e-9), 1 / temp)} end)
    total = Enum.reduce(weights, 0.0, fn {_, w}, acc -> acc + w end)
    pick(weights, :rand.uniform() * total)
  end

  defp pick([{m, _}], _x), do: m
  defp pick([{m, w} | _], x) when x <= w, do: m
  defp pick([{_, w} | rest], x), do: pick(rest, x - w)

  # The top moves of Red. The first one that gives Blue a good moment.
  # A move that is not the top move is a mistake: Red makes it only when
  # Blue does not lead by more than the cap after the answer, so that the
  # game stays close.
  defp mistake(board, line, policy, ev) do
    policy
    |> Enum.filter(fn {m, p} -> m != :pass and p >= @mistake_min end)
    |> Enum.sort_by(fn {_m, p} -> -p end)
    |> Enum.take(@mistakes)
    |> Enum.with_index()
    |> Enum.find_value(fn {{move, _p}, i} ->
      cap = if i == 0, do: :infinity, else: @cap

      with {:ok, next, _} <- Board.play(board, :red, move),
           %{} = moment <- find_moment(next, line ++ [{:red, move}], ev, cap: cap) do
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
  each tempting wrong move by #{@min_diff} points or more. Gives
  `%{puzzle, report, diffs, score}`, or nil. `score` is the estimate after
  the answer.

  The fast checks come first: one correct move in the move limit, then the
  score estimates, and then the deep puzzle checks. Options: `:visits` (1
  by default), and `:cap`, the most that Blue may lead by after the answer.
  """
  def find_moment(board, line, ev, opts \\ []) do
    visits = Keyword.get(opts, :visits, 1)
    cap = Keyword.get(opts, :cap, :infinity)

    board
    |> goals()
    |> Enum.find_value(fn goal ->
      with {:ok, {answer, traps}} <- Go.Think.within(@check_ms, fn -> quick(board, goal) end),
           {score, diffs} <- diffs(answer, traps, line, ev, visits),
           true <- cap == :infinity or score <= cap,
           {:ok, {puzzle, report}} <-
             Go.Think.within(@check_ms, fn -> checked(board, goal, answer) end) do
        %{puzzle: puzzle, report: report, diffs: diffs, score: score}
      else
        _ -> nil
      end
    end)
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

  def story(%{gave_up: true}, _ev, _opts),
    do: {:drop, "fewer than 2 moments at move #{@give_up_at}"}

  def story(game, ev, opts) do
    visits = Keyword.get(opts, :visits, 16)
    books? = Keyword.get(opts, :books, true)
    range = Keyword.get(opts, :margin, @margin)
    final = Library.play_moves(Board.new(@size), game.moves)
    area = Score.count(final)
    margin = area.blue.total - area.red.total

    with :ok <- enough(game.moments),
         :ok <- close(margin, range, "the area score"),
         estimate = Evaluator.score(ev, before_end(game.moves), visits),
         :ok <- close(estimate, range, "the estimate"),
         moments = confirm(game, ev, visits),
         moments = limit_capture_in_1(moments),
         :ok <- enough(moments) do
      {:ok, build_story(game, moments, area, estimate, books?)}
    end
  end

  defp enough(moments) when length(moments) >= @min_moments, do: :ok
  defp enough(_moments), do: {:drop, "fewer than #{@min_moments} moments that matter"}

  defp close(margin, range, what) do
    if margin >= range.first and margin <= range.last,
      do: :ok,
      else: {:drop, "not a close game by #{what}"}
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
        book = if books?, do: book(puzzle, board, m.report), else: %{first: %{}, answer: []}
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
  tempting wrong moves, and the groups next to the target group.
  """
  def fight(board, puzzle, report) do
    group = Board.group(board, puzzle.goal.target)
    group.stones ++ group.liberties ++ [puzzle.answer | report.traps] ++ next_groups(board, group)
  end

  defp next_groups(board, group) do
    group.stones
    |> Enum.flat_map(&Board.neighbors(board, &1))
    |> Enum.filter(&(Board.get(board, &1) not in [nil, Board.get(board, hd(group.stones))]))
    |> Enum.uniq()
    |> Enum.flat_map(&Board.group(board, &1).stones)
    |> Enum.uniq()
  end

  # The book has the first moves in the window of the fight, with a time
  # limit. The answer and the traps are always in it.
  defp book(puzzle, board, report) do
    points = Library.window_points(Library.window(fight(board, puzzle, report)))

    case Go.Think.within(@book_ms, fn -> Puzzles.book(puzzle, points: points) end) do
      {:ok, book} ->
        book

      :timeout ->
        Puzzles.book(puzzle, points: [puzzle.answer | report.traps])
    end
  end

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
      "#{story.id}: #{length(story.moves)} moves. Area score: Blue #{story.score.blue}, " <>
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
