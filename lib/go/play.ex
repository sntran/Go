defmodule Go.Play do
  @moduledoc """
  One player on one puzzle: the board, the moves, the help that the
  player used, and the result.

  The caller (the LiveView) shows each step and calls `red_step/1` and
  `watch_step/1` again after a short time. Thus the player sees Blue's
  move first, and then Red's reply.

  A tap must be fast. For a first move, the answer is in the book of the
  puzzle (see `Go.Puzzle`). For a later move, the deep search runs with a
  time limit (`Go.Think.budget/0`). When the time is over, a fast search
  in the move limit decides.

  The statuses:

    * `:playing`: Blue can tap.
    * `:thinking`: the blue stone stands, and the server looks for Red's
      reply (`think/2`). Taps are ignored.
    * `:red_turn`: Red plays the moves in `pending`. Taps are ignored.
    * `:solved`: the goal is reached.
    * `:failed`: the goal cannot be reached in the moves that are left.
    * `:learned`: the player used "Show the answer".
  """

  import Kernel, except: [tap: 2]

  require Logger

  alias Go.{Board, Book, Explain, Goal, Puzzle}

  defstruct [
    :puzzle,
    :board,
    :left,
    status: :playing,
    moves: [],
    history: [],
    pending: [],
    outcome: nil,
    last_turn: nil,
    feedback: nil,
    message: nil,
    learned: false,
    hints: 0,
    backs: 0,
    tries: 1,
    hint_on: false,
    show_better: false,
    falls: [],
    marks: %{},
    replay: nil,
    thinking: nil,
    hint_list: [],
    reply_done: nil
  ]

  @type t :: %__MODULE__{}

  @doc "Starts a puzzle."
  @spec new(Puzzle.t()) :: t()
  def new(%Puzzle{} = puzzle) do
    %__MODULE__{
      puzzle: puzzle,
      board: Puzzle.board(puzzle),
      left: puzzle.goal.moves,
      message: start_message(puzzle)
    }
  end

  defp start_message(%Puzzle{goal: %{type: :capture}}),
    do: "You are Blue. Tap a spot to build a tower."

  defp start_message(%Puzzle{goal: %{type: :escape}}),
    do: "You are Blue. Red attacks your fort. Tap a spot to build."

  @doc "True while the player must wait (Red plays, or a replay runs)."
  @spec busy?(t()) :: boolean()
  def busy?(%__MODULE__{status: status}) when status in [:red_turn, :thinking], do: true
  def busy?(%__MODULE__{replay: replay}), do: replay != nil

  @doc "True when the puzzle is over (solved, failed or learned)."
  @spec over?(t()) :: boolean()
  def over?(%__MODULE__{status: status}), do: status in [:solved, :failed, :learned]

  @doc "The board to show now (the replay board during \"Watch again\")."
  @spec shown_board(t()) :: Board.t()
  def shown_board(%__MODULE__{replay: %{board: board}}), do: board
  def shown_board(%__MODULE__{board: board}), do: board

  @doc """
  The player taps a point: `place/2`, then `think/2`. Gives `{:ok, play}` or
  `{:error, reason, play}`. On an error, the message tells the player what
  to do. The option `budget` is the time limit of the deep search
  (`Go.Think.budget/0` by default).
  """
  @spec tap(t(), Board.point(), keyword()) :: {:ok, t()} | {:error, atom(), t()}
  def tap(%__MODULE__{} = play, point, opts \\ []) do
    with {:ok, play} <- place(play, point), do: {:ok, think(play, opts)}
  end

  @doc """
  Places the blue stone. The play then has the status `:thinking`, and
  `think/2` finds the result. Gives `{:ok, play}` or
  `{:error, reason, play}`.
  """
  @spec place(t(), Board.point()) :: {:ok, t()} | {:error, atom(), t()}
  def place(%__MODULE__{} = play, point) do
    cond do
      busy?(play) ->
        {:error, :busy, %{play | message: "Wait. Red is thinking."}}

      over?(play) ->
        {:error, :over, %{play | message: over_message(play)}}

      true ->
        case Board.play(play.board, :blue, point) do
          {:ok, next, captured} -> {:ok, placed(play, point, next, captured)}
          {:error, reason} -> {:error, reason, %{play | message: illegal_message(reason)}}
        end
    end
  end

  @doc "True when `think/2` needs no search: the book has the answer."
  @spec quick?(t()) :: boolean()
  def quick?(%__MODULE__{status: :thinking, thinking: %{point: point}} = play),
    do: Book.lookup(play.puzzle, taps_before(play), point) != nil

  def quick?(_play), do: false

  # The blue taps before the tap that `place/2` placed.
  defp taps_before(play), do: for({:blue, p} <- Enum.drop(play.moves, -1), do: p)

  # The blue taps so far.
  defp taps(play), do: for({:blue, p} <- play.moves, do: p)

  defp over_message(%{status: :solved}),
    do: "You solved this puzzle! Tap Next puzzle, or Try again."

  defp over_message(%{status: :learned}),
    do: "Now you know the answer. Tap Next puzzle, or Try again."

  defp over_message(_), do: "Tap Try again or Go back one move."

  defp illegal_message(:occupied), do: "There is a tower on that spot already. Tap an empty spot."

  defp illegal_message(:suicide),
    do:
      "You cannot build there. A tower on that spot would have no open road. You may build there only when it closes the last road of a red fort."

  defp illegal_message(:ko),
    do: "Not yet! You cannot take back at once. Build somewhere else first."

  defp illegal_message(:off_board), do: "Tap a spot on the board."

  defp placed(play, point, next, captured) do
    goal = play.puzzle.goal
    before = play.board
    snapshot = Map.take(play, [:board, :left, :moves, :message])

    %{
      play
      | board: next,
        left: Goal.after_blue(goal, play.left),
        moves: play.moves ++ [{:blue, point}],
        history: [snapshot | play.history],
        status: :thinking,
        feedback: nil,
        hint_on: false,
        hint_list: [],
        show_better: false,
        falls: Enum.map(captured, &{&1, :red}),
        marks: %{point => :blue},
        last_turn: %{board: before, steps: [{:blue, point}]},
        message: "Red is thinking…",
        thinking: %{
          point: point,
          before: before,
          captured: captured,
          left_before: snapshot.left,
          start?: snapshot.moves == []
        }
    }
  end

  @doc """
  Finds the result of the blue move that `place/2` placed: the goal is
  reached, or Red replies, or Red punishes a wrong move.
  """
  @spec think(t(), keyword()) :: t()
  def think(play, opts \\ [])

  def think(%__MODULE__{status: :thinking} = play, opts) do
    case Book.lookup(play.puzzle, taps_before(play), play.thinking.point) do
      nil ->
        searched(play, "tap #{inspect(play.thinking.point)}", taps_before(play))
        apply_decision(play, search(play, Keyword.get(opts, :budget, Go.Think.budget())))

      %{kind: :solved} ->
        apply_decision(play, :solved)

      %{kind: :good, line: line, done: done} ->
        play |> apply_decision({:good, line}) |> Map.put(:reply_done, done)

      %{kind: :wrong, line: line, better: better} ->
        apply_decision(play, {:wrong, line, better})
    end
  end

  def think(play, _opts), do: play

  @doc false
  # Shows a decision: the goal is reached, or Red replies, or Red punishes.
  def apply_decision(%__MODULE__{thinking: t} = play, decision) do
    play = %{play | thinking: nil, reply_done: nil}

    case decision do
      :solved ->
        solved(play, t.captured)

      {:good, steps} ->
        %{play | status: :red_turn, pending: steps, outcome: :continue}

      {:wrong, steps, better} ->
        line = with_captures(play.board, steps)

        feedback =
          Explain.wrong(play.puzzle, t.before, t.point, line, t.left_before, better, t.start?)

        %{play | status: :red_turn, pending: steps, outcome: {:failed, feedback}}
    end
  end

  @doc false
  # The better move of a position (for a wrong tap).
  def better_move(puzzle, board, left, start?, deep?) do
    prefer = if start?, do: puzzle.answer
    Goal.blue_move(puzzle.goal, board, left, prefer, deep: deep?)
  end

  # A position that the book does not have: the server searches. This
  # must not happen during play (see Go.Book). The log and the telemetry
  # event [:go, :play, :search] tell the gap.
  defp searched(%{puzzle: puzzle}, what, taps) do
    if Book.full?(puzzle) do
      Logger.warning("The book of #{puzzle.id} has no #{what} after the taps #{inspect(taps)}")
      :telemetry.execute([:go, :play, :search], %{count: 1}, %{puzzle: puzzle.id, what: what, taps: taps})
    end
  end

  # The deep search, with a time limit. When the time is over, the search
  # in the move limit decides (it is fast).
  defp search(play, budget) do
    case Go.Think.within(budget, fn -> decide(play, true) end) do
      {:ok, decision} -> decision
      :timeout -> decide(play, false)
    end
  end

  @doc false
  # The result of the blue move of `play.thinking`. With `deep?` false, it
  # looks only to the move limit.
  # The option `better` gives the better move of a wrong tap, when the
  # caller knows it already (the book build: it is the same for all taps
  # of a position).
  def decide(%{puzzle: puzzle, thinking: t} = play, deep?, opts \\ []) do
    goal = puzzle.goal
    good = Goal.good_move?(goal, t.before, t.left_before, t.point, deep: deep?)

    cond do
      good and Goal.reached_after_good?(goal, play.board, play.left) ->
        :solved

      good ->
        {:good, [{:red, Goal.red_move(goal, play.board, play.left, line_reply(play))}]}

      true ->
        hand = if t.start?, do: Map.get(puzzle.wrong, t.point)
        reply = if hand, do: Map.get(hand, :reply)
        line = punish_line(goal, play.board, play.left, reply, deep?)
        better =
          Keyword.get_lazy(opts, :better, fn -> better_move(puzzle, t.before, t.left_before, t.start?, deep?) end)
        {:wrong, Enum.map(line, fn {color, move, _} -> {color, move} end), better}
    end
  end

  # The next red move of the answer line, when the player follows the line
  # (the line of "Show the answer"). Red plays it when it is as good as its
  # best move, so that a player who repeats the shown answer wins.
  defp line_reply(%{puzzle: puzzle, moves: moves}) do
    line = answer_line(puzzle)

    with true <- List.starts_with?(line, moves),
         {:red, move} <- Enum.at(line, length(moves)) do
      move
    else
      _ -> nil
    end
  end

  # Adds the captured stones to each move of a line.
  defp with_captures(board, steps) do
    {line, _} =
      Enum.map_reduce(steps, board, fn {color, move}, b ->
        {:ok, b, captured} = Board.play(b, color, move)
        {{color, move, captured}, b}
      end)

    line
  end

  # Red's punishment. In an escape puzzle, play it out until the fort falls.
  # `reply` is a hand-written red reply. It is used only if it punishes.
  defp punish_line(%{type: :capture} = goal, board, left, reply, _deep?) do
    move =
      if punishes?(goal, board, left, reply), do: reply, else: Goal.red_move(goal, board, left)

    {:ok, _, captured} = Board.play(board, :red, move)
    [{:red, move, captured}]
  end

  # In an escape puzzle, Red can need more moves than the limit: a wrong
  # move is wrong if the fort dies in the moves left plus Goal.deep().
  defp punish_line(%{type: :escape} = goal, board, left, reply, deep?) do
    horizon = if deep?, do: left + Goal.deep(), else: left
    first = if punishes?(goal, board, left, reply), do: reply
    escape_line(goal, board, horizon, first, [], 12)
  end

  @doc false
  def punishes?(_goal, _board, _left, nil), do: false

  def punishes?(goal, board, left, reply) do
    case Board.play(board, :red, reply) do
      {:ok, next, _} ->
        case goal.type do
          :capture ->
            not Go.Solver.captured?(next, goal.target, :red) and
              not Goal.reachable?(goal, next, left)

          :escape ->
            Go.Solver.captured?(next, goal.target, :blue) or
              Go.Solver.attacker_wins?(
                next,
                goal.target,
                :red,
                :blue,
                left - 1 + Goal.deep(),
                Goal.deep_opts()
              )
        end

      {:error, _} ->
        false
    end
  end

  defp escape_line(_goal, _board, _left, _first, acc, 0), do: Enum.reverse(acc)

  # `left` is the horizon: the red moves that are left for the capture.
  defp escape_line(_goal, _board, 0, _first, acc, _budget), do: Enum.reverse(acc)

  defp escape_line(goal, board, left, first, acc, budget) do
    red = first || Goal.red_move(goal, board, left)
    {:ok, board, captured} = Board.play(board, :red, red)
    acc = [{:red, red, captured} | acc]
    left = left - 1

    cond do
      Go.Solver.captured?(board, goal.target, :blue) or left == 0 ->
        Enum.reverse(acc)

      true ->
        case Goal.blue_resist(goal, board, left) do
          # No blue move helps. Stop here: Red does not play two moves in a row.
          :pass ->
            Enum.reverse(acc)

          blue ->
            {:ok, board, caps} = Board.play(board, :blue, blue)
            escape_line(goal, board, left, nil, [{:blue, blue, caps} | acc], budget - 1)
        end
    end
  end

  @doc """
  Plays the next pending move. When no move is left, it shows the result.
  """
  @spec red_step(t()) :: t()
  def red_step(%__MODULE__{status: :red_turn, pending: [{color, move} | rest]} = play) do
    goal = play.puzzle.goal
    before = play.board
    {:ok, next, captured} = Board.play(before, color, move)

    left =
      if color == :blue,
        do: Goal.after_blue(goal, play.left),
        else: Goal.after_red(goal, play.left)

    play = %{
      play
      | board: next,
        left: left,
        pending: rest,
        moves: play.moves ++ [{color, move}],
        falls: Enum.map(captured, &{&1, Board.other(color)}),
        marks: if(move == :pass, do: %{}, else: %{move => color}),
        last_turn: add_step(play.last_turn, {color, move})
    }

    if rest == [], do: finish(play, before, move, captured), else: play
  end

  def red_step(play), do: play

  defp add_step(nil, _step), do: nil
  defp add_step(last_turn, step), do: %{last_turn | steps: last_turn.steps ++ [step]}

  defp finish(%{outcome: {:failed, feedback}} = play, _before, _move, _captured) do
    %{
      play
      | status: :failed,
        outcome: nil,
        feedback: feedback,
        message: "Red got the better of that move."
    }
  end

  defp finish(%{outcome: :answer} = play, _before, _move, _captured) do
    %{
      play
      | status: :learned,
        outcome: nil,
        feedback: %{
          tone: :good,
          title: "Now you know it",
          what: play.puzzle.better,
          why: "This puzzle comes back in a few days. Then you can solve it on your own.",
          better: nil,
          better_point: nil
        },
        message: "That is the answer."
    }
  end

  defp finish(%{outcome: :continue} = play, before, move, captured) do
    goal = play.puzzle.goal

    # The book tells if the goal is reached after the reply.
    done =
      case play.reply_done do
        nil ->
          searched(play, "result after the red reply", taps(play))
          Goal.reached_after_good?(goal, play.board, play.left)

        done ->
          done
      end

    play = %{play | outcome: nil, reply_done: nil}

    cond do
      # The last blue move was good, so Blue can still reach the goal.
      done ->
        solved(play, captured)

      true ->
        %{
          play
          | status: :playing,
            message: Explain.after_reply(goal, before, move, play.board, play.left)
        }
    end
  end

  defp solved(play, captured) do
    text = Explain.win(play.puzzle, play.board, captured, play.left)
    stars = stars(play)

    # "Safe" needs a proof that the fort is alive for good (see Go.Life).
    title =
      cond do
        play.puzzle.goal.type == :capture -> "You caught Red!"
        Go.Life.alive?(play.board, play.puzzle.goal.target) -> "Your fort is safe!"
        true -> "Your fort escaped the attack!"
      end

    %{
      play
      | status: :solved,
        pending: [],
        feedback: %{
          tone: :good,
          title: title,
          what: nil,
          why: text,
          better: nil,
          better_point: nil
        },
        message: star_message(stars)
    }
  end

  defp star_message(3), do: "3 stars! You solved it on the first try."
  defp star_message(2), do: "2 stars! You solved it with a little help."
  defp star_message(_), do: "1 star! You solved it. Next time, try with less help."

  @doc """
  The stars of a solved puzzle: 3 on the first try with no help, 2 with
  one help, and 1 with more help. A help is a hint, a "Go back", a "Show
  the better move" or a new try.
  """
  @spec stars(t()) :: 1..3
  def stars(%__MODULE__{} = play) do
    case help(play) do
      0 -> 3
      1 -> 2
      _ -> 1
    end
  end

  @doc "The number of times that the player used help."
  def help(%__MODULE__{} = play), do: play.hints + play.backs + play.tries - 1

  @doc "Goes back to the position before the last blue move."
  @spec back(t()) :: t()
  def back(%__MODULE__{history: [snap | rest]} = play) do
    if busy?(play) or play.status in [:solved, :learned] do
      play
    else
      %{
        play
        | board: snap.board,
          left: snap.left,
          moves: snap.moves,
          history: rest,
          status: :playing,
          pending: [],
          outcome: nil,
          feedback: nil,
          hint_on: false,
          show_better: false,
          falls: [],
          marks: %{},
          last_turn: nil,
          backs: play.backs + 1,
          message: "You went back one move. Try a different move!"
      }
    end
  end

  def back(play), do: play

  @doc "Starts the puzzle again. The help that was used stays counted."
  @spec retry(t()) :: t()
  def retry(%__MODULE__{} = play) do
    cond do
      busy?(play) ->
        play

      play.moves == [] and play.status == :playing ->
        play

      true ->
        fresh = new(play.puzzle)

        %{
          fresh
          | hints: play.hints,
            backs: play.backs,
            tries: play.tries + 1,
            learned: play.learned,
            message: "Here is the puzzle again. You can do it!"
        }
    end
  end

  @doc "Shows a hint: some glowing spots and a text. It counts as help."
  @spec hint(t(), keyword()) :: t()
  def hint(play, opts \\ [])

  def hint(%__MODULE__{status: :playing, hint_on: false} = play, opts) do
    spots = find_hint_spots(play, Keyword.get(opts, :budget, Go.Think.budget()))
    %{play | hint_on: true, hint_list: spots, hints: play.hints + 1, message: hint_text(play)}
  end

  def hint(play, _opts), do: play

  defp hint_text(%{puzzle: puzzle, history: []}) when is_binary(puzzle.hint), do: puzzle.hint

  defp hint_text(%{puzzle: %{goal: %{type: :capture}}}),
    do: "Look at the glowing spots. Which one closes Red's way out?"

  defp hint_text(%{puzzle: %{goal: %{type: :escape}}}),
    do: "Look at the glowing spots. Which one gives your fort more roads?"

  @doc "The glowing spots of the hint. The correct move is one of them."
  @spec hint_spots(t()) :: [Board.point()]
  def hint_spots(%__MODULE__{hint_on: false}), do: []
  def hint_spots(%__MODULE__{hint_list: spots}), do: spots

  # At the start, the answer is the only good move. Later, the deep search
  # runs with a time limit, and else the search in the move limit.
  defp find_hint_spots(play, budget) do
    goal = play.puzzle.goal

    good =
      cond do
        play.moves == [] and play.puzzle.answer != nil ->
          [play.puzzle.answer]

        good = Book.hint(play.puzzle, taps(play)) ->
          good

        true ->
          searched(play, "hint", taps(play))

          case Go.Think.within(budget, fn -> Goal.good_moves(goal, play.board, play.left) end) do
            {:ok, good} -> good
            :timeout -> Goal.good_moves(goal, play.board, play.left, deep: false)
          end
      end

    roads =
      case Board.group(play.board, goal.target) do
        nil -> []
        g -> g.liberties
      end

    Enum.uniq(good ++ roads) |> Enum.take(5) |> Enum.sort()
  end

  @doc "Marks the better move after a wrong move. It counts as help."
  @spec show_better(t()) :: t()
  def show_better(
        %__MODULE__{status: :failed, show_better: false, feedback: %{better_point: p}} = play
      )
      when p != nil do
    %{
      play
      | show_better: true,
        hints: play.hints + 1,
        message: "Look at the glowing spot. Go back one move and build there."
    }
  end

  def show_better(play), do: play

  @doc "The spot that \"Show the better move\" marks."
  def better_spot(%__MODULE__{show_better: true, feedback: %{better_point: p}}), do: p
  def better_spot(_), do: nil

  @doc """
  Shows the answer from the start. The puzzle is then "learned", not
  "solved".
  """
  @spec show_answer(t()) :: t()
  def show_answer(%__MODULE__{} = play) do
    if busy?(play) do
      play
    else
      fresh = new(play.puzzle)

      %{
        fresh
        | status: :red_turn,
          pending: answer_line(play.puzzle),
          outcome: :answer,
          learned: true,
          hints: play.hints,
          backs: play.backs,
          tries: play.tries,
          last_turn: %{board: fresh.board, steps: []},
          message: "Watch the answer."
      }
    end
  end

  @doc """
  The answer line from the start: the moves of Blue and Red. The book has
  it, when the puzzle has a book.
  """
  @spec answer_line(Puzzle.t()) :: [{Board.color(), Board.point() | :pass}]
  def answer_line(%Puzzle{book: %{answer: _}} = puzzle), do: Book.answer(puzzle)

  def answer_line(%Puzzle{} = puzzle) do
    answer_line(puzzle.goal, Puzzle.board(puzzle), puzzle.goal.moves, puzzle.answer, [], 20)
  end

  defp answer_line(_goal, _board, _left, _prefer, acc, 0), do: Enum.reverse(acc)

  defp answer_line(goal, board, left, prefer, acc, budget) do
    case Goal.blue_move(goal, board, left, prefer) do
      nil ->
        Enum.reverse(acc)

      blue ->
        {:ok, board, _} = Board.play(board, :blue, blue)
        left = Goal.after_blue(goal, left)
        acc = [{:blue, blue} | acc]

        if Goal.reached_after_good?(goal, board, left) do
          Enum.reverse(acc)
        else
          red = Goal.red_move(goal, board, left)
          {:ok, board, _} = Board.play(board, :red, red)
          left = Goal.after_red(goal, left)
          acc = [{:red, red} | acc]

          if Goal.reached_after_good?(goal, board, left),
            do: Enum.reverse(acc),
            else: answer_line(goal, board, left, nil, acc, budget - 1)
        end
    end
  end

  @doc "Starts \"Watch again\": the last moves play again."
  @spec watch(t()) :: t()
  def watch(%__MODULE__{last_turn: %{board: board, steps: [_ | _] = steps}} = play) do
    if busy?(play) do
      play
    else
      %{
        play
        | replay: %{board: board, steps: steps, falls: [], marks: %{}, message: play.message},
          message: "Watch…"
      }
    end
  end

  def watch(play), do: play

  @doc "Plays the next move of the replay, or ends the replay."
  @spec watch_step(t()) :: t()
  def watch_step(%__MODULE__{replay: %{steps: [{color, move} | rest]} = r} = play) do
    {:ok, board, captured} = Board.play(r.board, color, move)
    who = if color == :blue, do: "Your move…", else: "…then Red's move."

    %{
      play
      | replay: %{
          r
          | board: board,
            steps: rest,
            falls: Enum.map(captured, &{&1, Board.other(color)}),
            marks: if(move == :pass, do: %{}, else: %{move => color})
        },
        message: who
    }
  end

  def watch_step(%__MODULE__{replay: %{steps: []} = r} = play),
    do: %{play | replay: nil, message: r.message}

  def watch_step(play), do: play

  @doc "The stones that fell on the last step, to show them crumble."
  def shown_falls(%__MODULE__{replay: %{falls: falls}}), do: falls
  def shown_falls(%__MODULE__{falls: falls}), do: falls

  @doc "The rings on the last moves."
  def shown_marks(%__MODULE__{replay: %{marks: marks}}), do: marks
  def shown_marks(%__MODULE__{marks: marks}), do: marks

  @doc "The result of the play for the records."
  @spec result(t()) :: :solved | :failed | :learned | :open
  def result(%__MODULE__{learned: true}), do: :learned
  def result(%__MODULE__{status: status}) when status in [:solved, :failed], do: status
  def result(_), do: :open

  @doc """
  Plays a list of blue moves from the start, with the server's red
  replies, with no time limit. Gives the play at the end, or
  `{:error, reason}` for an illegal move.
  """
  @spec replay(Puzzle.t(), [Board.point()]) :: {:ok, t()} | {:error, atom()}
  def replay(%Puzzle{} = puzzle, blue_moves) do
    Enum.reduce_while(blue_moves, {:ok, new(puzzle)}, fn point, {:ok, play} ->
      case tap(play, point, budget: :infinity) do
        {:ok, play} -> {:cont, {:ok, run_red(play)}}
        {:error, reason, _} -> {:halt, {:error, reason}}
      end
    end)
  end

  @doc """
  Checks a list of moves with the rules engine, before the server counts
  a result. Each move must be legal, Blue and Red must take turns, and a
  `:solved` result must reach the goal in the move limit. Gives `:ok` or
  `{:error, reason}`.
  """
  @spec verify(Puzzle.t(), [{Board.color(), Board.point() | :pass}], atom()) ::
          :ok | {:error, atom()}
  def verify(%Puzzle{goal: goal} = puzzle, moves, result) do
    colors = Enum.map(moves, &elem(&1, 0))
    turns = Enum.take(Stream.cycle([:blue, :red]), length(moves))

    replayed =
      Enum.reduce_while(moves, {:ok, Puzzle.board(puzzle), goal.moves}, fn {color, move},
                                                                           {:ok, b, left} ->
        case Board.play(b, color, move) do
          {:ok, b, _} ->
            left =
              if color == :blue, do: Goal.after_blue(goal, left), else: Goal.after_red(goal, left)

            {:cont, {:ok, b, left}}

          {:error, reason} ->
            {:halt, {:error, reason}}
        end
      end)

    case replayed do
      {:error, reason} ->
        {:error, reason}

      {:ok, _b, _left} when colors != turns ->
        {:error, :turns}

      {:ok, b, left} when result == :solved ->
        # With a full book, the book tells the result (no search).
        solved =
          case Book.full?(puzzle) && solved_by_book?(puzzle, moves) do
            nil -> solved_in_limit?(goal, moves, b, left)
            solved -> solved
          end

        if solved, do: :ok, else: {:error, :not_solved}

      {:ok, _b, _left} ->
        :ok
    end
  end

  # Follows the moves in the book: true when they end with a solved tap, or
  # with the red reply of a good tap that reaches the goal. nil when the
  # book does not have a position.
  defp solved_by_book?(puzzle, moves), do: walk(puzzle, [], moves)

  defp walk(puzzle, taps, [{:blue, p} | rest]) do
    case {Book.lookup(puzzle, taps, p), rest} do
      {nil, _} -> nil
      {%{kind: :solved}, []} -> true
      {%{kind: :good, line: [red], done: true}, [red]} -> true
      {%{kind: :good, line: [red], done: false}, [red | more]} -> walk(puzzle, taps ++ [p], more)
      _ -> false
    end
  end

  defp walk(_puzzle, _taps, _moves), do: false

  defp solved_in_limit?(%{type: :capture} = goal, moves, board, _left),
    do:
      Go.Solver.captured?(board, goal.target, :red) and
        Enum.count(moves, &match?({:blue, _}, &1)) <= goal.moves

  defp solved_in_limit?(%{type: :escape} = goal, _moves, board, left),
    do: Goal.reached_after_good?(goal, board, left)

  @doc "Plays all pending moves at once."
  @spec run_red(t()) :: t()
  def run_red(%__MODULE__{status: :red_turn} = play), do: play |> red_step() |> run_red()
  def run_red(play), do: play
end
