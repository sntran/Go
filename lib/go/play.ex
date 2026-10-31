defmodule Go.Play do
  @moduledoc """
  One player on one puzzle: the board, the moves, the help that the
  player used, and the result.

  This module has no processes and no timers. The caller (the LiveView)
  shows each step and calls `red_step/1` and `watch_step/1` again after a
  short time. Thus the player sees Blue's move first, and then Red's reply.

  The statuses:

    * `:playing`: Blue can tap.
    * `:red_turn`: Red plays the moves in `pending`. Taps are ignored.
    * `:solved`: the goal is reached.
    * `:failed`: the goal cannot be reached in the moves that are left.
    * `:learned`: the player used "Show the answer".
  """

  import Kernel, except: [tap: 2]

  alias Go.{Board, Explain, Goal, Puzzle}

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
    replay: nil
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

  defp start_message(%Puzzle{goal: %{type: :capture}}), do: "You are Blue. Tap a spot to build a tower."
  defp start_message(%Puzzle{goal: %{type: :escape}}), do: "You are Blue. Red attacks your fort. Tap a spot to build."

  @doc "True while the player must wait (Red plays, or a replay runs)."
  @spec busy?(t()) :: boolean()
  def busy?(%__MODULE__{status: :red_turn}), do: true
  def busy?(%__MODULE__{replay: replay}), do: replay != nil

  @doc "True when the puzzle is over (solved, failed or learned)."
  @spec over?(t()) :: boolean()
  def over?(%__MODULE__{status: status}), do: status in [:solved, :failed, :learned]

  @doc "The board to show now (the replay board during \"Watch again\")."
  @spec shown_board(t()) :: Board.t()
  def shown_board(%__MODULE__{replay: %{board: board}}), do: board
  def shown_board(%__MODULE__{board: board}), do: board

  @doc """
  The player taps a point. Gives `{:ok, play}` or `{:error, reason, play}`.
  On an error, the message tells the player what to do.
  """
  @spec tap(t(), Board.point()) :: {:ok, t()} | {:error, atom(), t()}
  def tap(%__MODULE__{} = play, point) do
    cond do
      busy?(play) ->
        {:error, :busy, %{play | message: "Wait. Red is thinking."}}

      over?(play) ->
        {:error, :over, %{play | message: over_message(play)}}

      true ->
        case Board.play(play.board, :blue, point) do
          {:ok, next, captured} -> {:ok, blue_moved(play, point, next, captured)}
          {:error, reason} -> {:error, reason, %{play | message: illegal_message(reason)}}
        end
    end
  end

  defp over_message(%{status: :solved}), do: "You solved this puzzle! Tap Next puzzle, or Try again."
  defp over_message(%{status: :learned}), do: "Now you know the answer. Tap Next puzzle, or Try again."
  defp over_message(_), do: "Tap Try again or Go back one move."

  defp illegal_message(:occupied), do: "There is a tower on that spot already. Tap an empty spot."

  defp illegal_message(:suicide),
    do:
      "You cannot build there. A tower on that spot would have no open road. You may build there only when it closes the last road of a red fort."

  defp illegal_message(:ko), do: "Not yet! You cannot take back at once. Build somewhere else first."
  defp illegal_message(:off_board), do: "Tap a spot on the board."

  defp blue_moved(play, point, next, captured) do
    goal = play.puzzle.goal
    before = play.board
    left = Goal.after_blue(goal, play.left)
    snapshot = Map.take(play, [:board, :left, :moves, :message])

    play = %{
      play
      | board: next,
        left: left,
        moves: play.moves ++ [{:blue, point}],
        history: [snapshot | play.history],
        feedback: nil,
        hint_on: false,
        show_better: false,
        falls: Enum.map(captured, &{&1, :red}),
        marks: %{point => :blue},
        last_turn: %{board: before, steps: [{:blue, point}]}
    }

    cond do
      Goal.reached?(goal, next, left) ->
        solved(play, captured)

      Goal.good_move?(goal, before, snapshot.left, point) ->
        red = Goal.red_move(goal, next, left)
        %{play | status: :red_turn, pending: [{:red, red}], outcome: :continue, message: "Red is thinking…"}

      true ->
        punish(play, goal, before, point, snapshot.left, snapshot.moves == [])
    end
  end

  defp punish(play, goal, before, point, left_before, start?) do
    hand = if start?, do: Map.get(play.puzzle.wrong, point), else: nil
    reply = if hand, do: Map.get(hand, :reply)
    line = punish_line(goal, play.board, play.left, reply)
    better = Goal.blue_move(goal, before, left_before, if(start?, do: play.puzzle.answer))
    feedback = Explain.wrong(play.puzzle, before, point, line, left_before, better, start?)
    steps = Enum.map(line, fn {color, move, _} -> {color, move} end)

    %{play | status: :red_turn, pending: steps, outcome: {:failed, feedback}, message: "Red is thinking…"}
  end

  # Red's punishment. In an escape puzzle, play it out until the fort falls.
  # `reply` is a hand-written red reply. It is used only if it punishes.
  defp punish_line(%{type: :capture} = goal, board, left, reply) do
    move = if punishes?(goal, board, left, reply), do: reply, else: Goal.red_move(goal, board, left)
    {:ok, _, captured} = Board.play(board, :red, move)
    [{:red, move, captured}]
  end

  defp punish_line(%{type: :escape} = goal, board, left, reply) do
    first = if punishes?(goal, board, left, reply), do: reply
    escape_line(goal, board, left, first, [], 12)
  end

  @doc false
  def punishes?(_goal, _board, _left, nil), do: false

  def punishes?(goal, board, left, reply) do
    case Board.play(board, :red, reply) do
      {:ok, next, _} ->
        case goal.type do
          :capture ->
            not Go.Solver.captured?(next, goal.target, :red) and not Goal.reachable?(goal, next, left)

          :escape ->
            Go.Solver.captured?(next, goal.target, :blue) or
              Go.Solver.attacker_wins?(next, goal.target, :red, :blue, left - 1)
        end

      {:error, _} ->
        false
    end
  end

  defp escape_line(_goal, _board, _left, _first, acc, 0), do: Enum.reverse(acc)

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
    %{play | status: :failed, outcome: nil, feedback: feedback, message: "Red got the better of that move."}
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
    play = %{play | outcome: nil}

    cond do
      Goal.reached?(goal, play.board, play.left) ->
        solved(play, captured)

      not Goal.reachable?(goal, play.board, play.left) ->
        # The solver said that the blue move was good, so this does not happen.
        %{play | status: :failed, message: "Red got away."}

      true ->
        %{play | status: :playing, message: Explain.after_reply(goal, before, move, play.board, play.left)}
    end
  end

  defp solved(play, captured) do
    text = Explain.win(play.puzzle, play.board, captured, play.left)
    stars = stars(play)

    title =
      case play.puzzle.goal.type do
        :capture -> "You caught Red!"
        :escape -> "Your fort is safe!"
      end

    %{
      play
      | status: :solved,
        pending: [],
        feedback: %{tone: :good, title: title, what: nil, why: text, better: nil, better_point: nil},
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
  @spec hint(t()) :: t()
  def hint(%__MODULE__{status: :playing, hint_on: false} = play) do
    %{play | hint_on: true, hints: play.hints + 1, message: hint_text(play)}
  end

  def hint(play), do: play

  defp hint_text(%{puzzle: puzzle, history: []}) when is_binary(puzzle.hint), do: puzzle.hint

  defp hint_text(%{puzzle: %{goal: %{type: :capture}}}),
    do: "Look at the glowing spots. Which one closes Red's way out?"

  defp hint_text(%{puzzle: %{goal: %{type: :escape}}}),
    do: "Look at the glowing spots. Which one gives your fort more roads?"

  @doc "The glowing spots of the hint. The correct move is one of them."
  @spec hint_spots(t()) :: [Board.point()]
  def hint_spots(%__MODULE__{hint_on: false}), do: []

  def hint_spots(%__MODULE__{} = play) do
    goal = play.puzzle.goal
    good = Goal.good_moves(goal, play.board, play.left)

    roads =
      case Board.group(play.board, goal.target) do
        nil -> []
        g -> g.liberties
      end

    Enum.uniq(good ++ roads) |> Enum.take(5) |> Enum.sort()
  end

  @doc "Marks the better move after a wrong move. It counts as help."
  @spec show_better(t()) :: t()
  def show_better(%__MODULE__{status: :failed, show_better: false, feedback: %{better_point: p}} = play)
      when p != nil do
    %{play | show_better: true, hints: play.hints + 1, message: "Look at the glowing spot. Go back one move and build there."}
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

  @doc "The answer line from the start: the moves of Blue and Red."
  @spec answer_line(Puzzle.t()) :: [{Board.color(), Board.point() | :pass}]
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

        if Goal.reached?(goal, board, left) do
          Enum.reverse(acc)
        else
          red = Goal.red_move(goal, board, left)
          {:ok, board, _} = Board.play(board, :red, red)
          left = Goal.after_red(goal, left)
          acc = [{:red, red} | acc]

          if Goal.reached?(goal, board, left),
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
      %{play | replay: %{board: board, steps: steps, falls: [], marks: %{}, message: play.message}, message: "Watch…"}
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

  def watch_step(%__MODULE__{replay: %{steps: []} = r} = play), do: %{play | replay: nil, message: r.message}
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
  replies. The server uses it to check a result before it counts it.
  Gives the play at the end, or `{:error, reason}` for an illegal move.
  """
  @spec replay(Puzzle.t(), [Board.point()]) :: {:ok, t()} | {:error, atom()}
  def replay(%Puzzle{} = puzzle, blue_moves) do
    Enum.reduce_while(blue_moves, {:ok, new(puzzle)}, fn point, {:ok, play} ->
      case tap(play, point) do
        {:ok, play} -> {:cont, {:ok, run_red(play)}}
        {:error, reason, _} -> {:halt, {:error, reason}}
      end
    end)
  end

  @doc "Plays all pending moves at once."
  @spec run_red(t()) :: t()
  def run_red(%__MODULE__{status: :red_turn} = play), do: play |> red_step() |> run_red()
  def run_red(play), do: play
end
