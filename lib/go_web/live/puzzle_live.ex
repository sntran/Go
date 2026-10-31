defmodule GoWeb.PuzzleLive do
  @moduledoc """
  The puzzle screen. The server owns the game: the browser sends only the
  taps, and it gets only the board and the results, never the answer.

  Red's moves and the moves of "Watch again" come one by one, with a short
  time between them (see `:red_delay` and `:watch_delay` in the config).
  While Red plays, taps on the board only show "Wait".

  The same screen plays the story games (the live action `:story`, see
  `Go.Stories`): each moment is a puzzle, and between the moments the main
  line of the game plays on the board. The board shows a corner view that
  grows with the game.
  """

  use GoWeb, :live_view

  alias Go.{Board, Play, Progress, Puzzles, Score, Stories}
  alias GoWeb.{BoardComponents, Worlds}

  @impl true
  def mount(params, %{"player_id" => player}, socket) do
    socket =
      assign(socket,
        player: player,
        mode: if(socket.assigns.live_action == :story, do: :story, else: :world),
        look: Progress.look(player),
        play: nil,
        kind: :pick,
        path_next: nil,
        counted: false,
        step: 0,
        timer: nil,
        recorded: false,
        story: nil,
        story_phase: nil,
        story_view: 5,
        anim: nil,
        red_delay: Application.get_env(:go, :red_delay, 700),
        watch_delay: Application.get_env(:go, :watch_delay, 900),
        story_delay: Application.get_env(:go, :story_delay, 500),
        score: nil,
        final: nil,
        moment: nil
      )

    case socket.assigns.mode do
      :story ->
        {:ok, assign(socket, world: nil)}

      :world ->
        case Worlds.parse(params["world"]) do
          nil -> {:ok, push_navigate(socket, to: ~p"/")}
          world -> {:ok, assign(socket, world: world)}
        end
    end
  end

  @impl true
  def handle_params(_params, _uri, %{assigns: %{mode: :story}} = socket) do
    {:noreply, start_story(socket)}
  end

  def handle_params(params, _uri, socket) do
    world = socket.assigns.world

    # The kind of the puzzle: :new or :review on the path (see Go.Path), or
    # :pick when the player chose it on the world page.
    {puzzle, kind} =
      case {params["id"], socket.assigns[:path_next]} do
        {nil, _} ->
          path_next(socket) || {nil, :pick}

        {id, {id, kind}} ->
          {Puzzles.get(id), kind}

        {id, _} ->
          {with(%{world: ^world} = p <- Puzzles.get(id), do: p, else: (_ -> nil)), :pick}
      end

    socket =
      case puzzle do
        nil ->
          assign(socket, play: nil, page_title: Worlds.get(world).name)

        puzzle ->
          list = Puzzles.world(world)

          socket
          |> assign(
            index: Enum.find_index(list, &(&1.id == puzzle.id)) + 1,
            total: length(list),
            kind: kind,
            counted: false,
            page_title: if(kind == :review, do: Go.Path.review_title(puzzle), else: puzzle.title),
            recorded: false,
            timer: nil
          )
          |> put_play(Play.new(puzzle))
      end

    {:noreply, socket}
  end

  ## Events

  @impl true
  def handle_event("tap", %{"r" => r, "c" => c}, %{assigns: %{play: %Play{}}} = socket) do
    point = {String.to_integer(r), String.to_integer(c)}

    case Play.place(socket.assigns.play, point) do
      {:ok, placed} ->
        if Play.quick?(placed) or socket.assigns.red_delay == 0 do
          {:noreply, socket |> put_play(Play.think(placed)) |> after_move()}
        else
          # Show the blue stone and "Red is thinking…" first. The search
          # runs in a task, with a time limit.
          {:noreply,
           socket |> put_play(placed) |> start_async(:think, fn -> Play.think(placed) end)}
        end

      {:error, _reason, play} ->
        {:noreply, assign(socket, play: play)}
    end
  end

  def handle_event("hint", _, socket), do: {:noreply, update_play(socket, &Play.hint/1)}

  def handle_event("show_better", _, socket),
    do: {:noreply, update_play(socket, &Play.show_better/1)}

  def handle_event("back", _, socket) do
    {:noreply, socket |> update_play(&Play.back/1) |> assign(recorded: false)}
  end

  def handle_event("retry", _, socket) do
    {:noreply, socket |> update_play(&Play.retry/1) |> assign(recorded: false)}
  end

  def handle_event("show_answer", _, socket) do
    if Play.busy?(socket.assigns.play) do
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> put_play(Play.show_answer(socket.assigns.play))
       |> assign(recorded: false)
       |> after_move()}
    end
  end

  def handle_event("watch", _, socket) do
    play = socket.assigns.play

    if Play.busy?(play) or play.last_turn == nil do
      {:noreply, socket}
    else
      {:noreply,
       socket |> put_play(Play.watch(play)) |> schedule(:watch_step, socket.assigns.watch_delay)}
    end
  end

  def handle_event("next", _, socket) do
    world = socket.assigns.world

    case path_next(socket) do
      nil ->
        {:noreply, push_patch(socket, to: ~p"/play/#{world}?done=1")}

      {next, kind} ->
        socket = assign(socket, path_next: {next.id, kind})
        {:noreply, push_patch(socket, to: ~p"/play/#{world}?id=#{next.id}")}
    end
  end

  # The story: after a moment, the game goes on to the next moment.
  def handle_event("continue", _, %{assigns: %{mode: :story, play: play}} = socket) do
    if Play.over?(play), do: {:noreply, continue_story(socket)}, else: {:noreply, socket}
  end

  def handle_event("skip", _, %{assigns: %{anim: %{}}} = socket) do
    {:noreply, finish_anim(socket)}
  end

  def handle_event("next_story", _, %{assigns: %{mode: :story, story_phase: :score}} = socket) do
    case next_story(socket.assigns.story) do
      nil ->
        {:noreply, push_navigate(socket, to: ~p"/")}

      story ->
        Progress.put_story(socket.assigns.player, %{story: story.id, moment: 1})
        {:noreply, start_story(socket)}
    end
  end

  def handle_event("look", %{"look" => look}, socket) when look in ["castle", "board"] do
    look = String.to_existing_atom(look)
    Progress.put_look(socket.assigns.player, look)
    {:noreply, assign(socket, look: look)}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

  defp path_next(%{assigns: %{world: world, player: player}}) do
    Go.Path.next(
      world,
      Progress.results(player),
      Progress.since_review(player, world),
      Date.utc_today()
    )
  end

  ## The search and the timers

  @impl true
  def handle_async(
        :think,
        result,
        %{assigns: %{play: %Play{status: :thinking} = current}} = socket
      ) do
    play =
      case result do
        {:ok, %Play{puzzle: %{id: id}} = play} when id == current.puzzle.id -> play
        # The task stopped: decide with the fast search in the move limit.
        _ -> Play.think(current, budget: 0)
      end

    {:noreply, socket |> put_play(play) |> after_move()}
  end

  # A result for a play that is gone.
  def handle_async(:think, _result, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:red_step, ref}, %{assigns: %{timer: ref}} = socket) do
    socket = socket |> assign(timer: nil) |> put_play(Play.red_step(socket.assigns.play))
    {:noreply, after_move(socket)}
  end

  def handle_info({:watch_step, ref}, %{assigns: %{timer: ref}} = socket) do
    play = Play.watch_step(socket.assigns.play)
    socket = socket |> assign(timer: nil) |> put_play(play)

    if play.replay,
      do: {:noreply, schedule(socket, :watch_step, socket.assigns.watch_delay)},
      else: {:noreply, socket}
  end

  def handle_info({:story_step, ref}, %{assigns: %{timer: ref, anim: %{}}} = socket) do
    socket = socket |> assign(timer: nil) |> anim_step()

    if socket.assigns.anim.steps == [],
      do: {:noreply, finish_anim(socket)},
      else: {:noreply, schedule(socket, :story_step, socket.assigns.story_delay)}
  end

  # A timer of a play that is gone.
  def handle_info(_msg, socket), do: {:noreply, socket}

  defp after_move(socket) do
    play = socket.assigns.play

    cond do
      play.status == :red_turn and socket.assigns.red_delay == 0 ->
        socket |> put_play(Play.run_red(play)) |> record()

      play.status == :red_turn ->
        schedule(socket, :red_step, socket.assigns.red_delay)

      true ->
        record(socket)
    end
  end

  # No delay: run all steps at once (for the tests).
  defp schedule(socket, name, 0), do: run_now(socket, name)

  defp schedule(socket, name, delay) do
    ref = make_ref()
    Process.send_after(self(), {name, ref}, delay)
    assign(socket, timer: ref)
  end

  defp run_now(socket, :story_step), do: finish_anim(socket)

  defp run_now(socket, :watch_step) do
    play =
      Stream.iterate(socket.assigns.play, &Play.watch_step/1) |> Enum.find(&(&1.replay == nil))

    socket |> assign(timer: nil) |> put_play(play)
  end

  defp record(%{assigns: %{play: play, recorded: false}} = socket) do
    if Play.over?(play) do
      Progress.record(socket.assigns.player, play)
      socket |> count_path() |> assign(recorded: true)
    else
      socket
    end
  end

  defp record(socket), do: socket

  # The path counts each puzzle one time, for the reviews.
  defp count_path(%{assigns: %{counted: false, kind: kind}} = socket)
       when kind in [:new, :review] do
    Progress.count_path(socket.assigns.player, socket.assigns.world, kind)
    assign(socket, counted: true)
  end

  defp count_path(socket), do: socket

  defp put_play(%{assigns: %{mode: :story}} = socket, play) do
    # The view of a story grows with the board, and never becomes smaller.
    view = Stories.view(Play.shown_board(play), socket.assigns.story_view)
    assign(socket, play: play, story_view: view, step: socket.assigns.step + 1)
  end

  defp put_play(socket, play), do: assign(socket, play: play, step: socket.assigns.step + 1)

  ## The story

  # The place of the player: the story and the moment (from 1). At moment 1,
  # the first moves of the game play first.
  defp start_story(socket) do
    stories = Stories.all()
    place = Progress.story(socket.assigns.player) || %{story: hd(stories).id, moment: 1}
    story = Stories.get(place.story) || hd(stories)
    socket = assign(socket, story: story, story_view: 5, page_title: story.title, anim: nil)

    cond do
      place.moment == :end ->
        final = Stories.board_at(story, length(story.moves))

        assign(socket,
          story_phase: :score,
          score: Score.count(final),
          final: final,
          story_view: Stories.view(final)
        )

      place.moment == 1 ->
        first = hd(story.moments)
        start_anim(socket, 0, first.index, {:moment, 1}, "The game starts")

      true ->
        start_moment(socket, min(place.moment, length(story.moments)))
    end
  end

  defp start_moment(socket, k) do
    %{story: story, player: player} = socket.assigns
    moment = Enum.at(story.moments, k - 1)
    Progress.put_story(player, %{story: story.id, moment: k})

    socket
    |> assign(
      story_phase: :moment,
      moment: k,
      anim: nil,
      kind: :story,
      counted: false,
      recorded: false,
      timer: nil,
      story_view: max(socket.assigns.story_view, moment.view)
    )
    |> put_play(Play.new(moment.puzzle))
  end

  defp continue_story(socket) do
    %{story: story, moment: k} = socket.assigns
    from = Enum.at(story.moments, k - 1).index

    case Enum.at(story.moments, k) do
      nil -> start_anim(socket, from, length(story.moves), :score, "The end of the game")
      next -> start_anim(socket, from, next.index, {:moment, k + 1}, "The game goes on")
    end
  end

  # Plays the moves of the main line from `from` to `to` on the board.
  defp start_anim(socket, from, to, then, title) do
    %{story: story} = socket.assigns
    board = Stories.board_at(story, from)
    steps = story.moves |> Enum.slice(from, to - from)

    socket
    |> assign(
      story_phase: :anim,
      anim: %{board: board, steps: steps, falls: [], marks: %{}, then: then, title: title},
      story_view: Stories.view(board, socket.assigns.story_view),
      timer: nil
    )
    |> schedule(:story_step, socket.assigns.story_delay)
  end

  defp anim_step(%{assigns: %{anim: %{steps: [{color, move} | rest]} = a}} = socket) do
    {:ok, board, captured} = Board.play(a.board, color, move)
    marks = if move == :pass, do: %{}, else: %{move => color}

    anim = %{
      a
      | board: board,
        steps: rest,
        falls: Enum.map(captured, &{&1, Board.other(color)}),
        marks: marks
    }

    assign(socket,
      anim: anim,
      story_view: Stories.view(board, socket.assigns.story_view),
      step: socket.assigns.step + 1
    )
  end

  defp anim_step(socket), do: socket

  defp finish_anim(%{assigns: %{anim: %{steps: [_ | _]}}} = socket),
    do: socket |> anim_step() |> finish_anim()

  defp finish_anim(%{assigns: %{anim: %{then: then, board: board}}} = socket) do
    socket = assign(socket, timer: nil)

    case then do
      {:moment, k} ->
        start_moment(socket, k)

      :score ->
        Progress.put_story(socket.assigns.player, %{story: socket.assigns.story.id, moment: :end})
        assign(socket, story_phase: :score, score: Score.count(board), final: board, anim: nil)
    end
  end

  defp finish_anim(socket), do: socket

  defp next_story(story) do
    Stories.all() |> Enum.drop_while(&(&1.id != story.id)) |> Enum.at(1)
  end

  defp update_play(%{assigns: %{play: %Play{} = play}} = socket, fun),
    do: put_play(socket, fun.(play))

  defp update_play(socket, _fun), do: socket

  ## View

  @impl true
  def render(%{mode: :story, story_phase: :anim} = assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main class="main">
        <section class="head">
          <p class="kicker" id="kicker">
            <.link navigate={~p"/"} class="back-link">Home</.link> · {@story.title}
          </p>
          <h1 id="title">{@anim.title}</h1>
          <p class="say" id="say">
            Watch the moves of the game. Blue plays the black stones, Red plays the white stones.
          </p>
        </section>
        <section class="play">
          <p class="msg busy" id="message" aria-live="polite">Watch the game…</p>
          <BoardComponents.board
            board={@anim.board}
            look={@look}
            falls={@anim.falls}
            marks={@anim.marks}
            step={@step}
            view={@story_view}
          />
          <div class="row" id="actions">
            <button type="button" class="pill" id="skip" phx-click="skip">Skip</button>
          </div>
        </section>
      </main>
    </Layouts.app>
    """
  end

  def render(%{mode: :story, story_phase: :score} = assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main class="main">
        <section class="head">
          <p class="kicker" id="kicker">
            <.link navigate={~p"/"} class="back-link">Home</.link> · {@story.title}
          </p>
          <h1 id="title">The end of the game</h1>
          <p class="say" id="say">
            Both players closed their borders and passed. Your fields are the empty points that only your towers touch.
          </p>
        </section>
        <section class="notes">
          <div id="score" class="fb good" aria-live="polite">
            <p class="t" id="fb-title">
              {if @score.winner == :blue, do: "Blue wins!", else: "Red wins this time"}
            </p>
            <p id="score-blue">
              <b>Blue:</b> {@score.blue.stones} towers + {@score.blue.fields} fields = {@score.blue.total}
            </p>
            <p id="score-red">
              <b>Red:</b> {@score.red.stones} towers + {@score.red.fields} fields + {@score.red.komi} = {@score.red.total}
            </p>
            <p>Red gets {@score.red.komi} points, because Blue plays first.</p>
          </div>
          <p class="realgo">
            <b>In real Go:</b>
            fields are called <b>territory</b>. The score is your stones plus your territory.
          </p>
        </section>
        <section class="play">
          <BoardComponents.board
            board={@final}
            hide_roads={true}
            look={@look}
            step={@step}
            view={@story_view}
            fields={@score.owners}
          />
          <div class="row" id="actions">
            <button type="button" class="pill primary" id="next-story" phx-click="next_story">
              {if next_story(@story), do: "Next story", else: "Back home"}
            </button>
          </div>
        </section>
      </main>
    </Layouts.app>
    """
  end

  def render(%{play: nil} = assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main class="done">
        <h1>You finished the path of this world!</h1>
        <p class="say">
          Great work. Puzzles that you learned come back in a few days. You can play the other puzzles on the world page.
        </p>
        <div class="row">
          <.link navigate={~p"/worlds/#{@world}"} class="pill" id="world-page">See all puzzles</.link>
          <.link navigate={~p"/"} class="pill primary" id="home">Choose a world</.link>
        </div>
      </main>
    </Layouts.app>
    """
  end

  def render(assigns) do
    play = assigns.play
    board = Play.shown_board(play)

    assigns =
      assign(assigns,
        puzzle: play.puzzle,
        board: board,
        feedback: play.replay == nil && play.feedback,
        glow: glow(play),
        atari: atari?(board),
        busy: Play.busy?(play),
        world_text: Worlds.get(play.puzzle.world)
      )

    ~H"""
    <Layouts.app flash={@flash}>
      <main class="main">
        <section class="head">
          <p :if={@mode == :story} class="kicker" id="kicker">
            <.link navigate={~p"/"} class="back-link">Home</.link>
            · {@story.title} · Moment {@moment} of {length(@story.moments)}
          </p>
          <p :if={@mode == :world} class="kicker">
            <.link navigate={~p"/"} class="back-link">Worlds</.link>
            · {@world_text.name} · Puzzle {@index} of {@total}
          </p>
          <%= if @kind == :review do %>
            <h1 id="title">{Go.Path.review_title(@puzzle)}</h1>
            <p class="say" id="say">{Go.Path.review_say()}</p>
          <% else %>
            <h1 id="title">{@puzzle.title}</h1>
            <p class="say" id="say">{@puzzle.say}</p>
          <% end %>
        </section>

        <section class="notes">
          <div :if={@feedback} id="feedback" class={["fb", @feedback.tone]} aria-live="polite">
            <p class="t" id="fb-title">{@feedback.title}</p>
            <p :if={@feedback.what} id="fb-what">
              <b :if={@feedback.tone == :bad}>What happened:</b> {@feedback.what}
            </p>
            <p :if={@feedback.why} id="fb-why">
              <b :if={@feedback.tone == :bad}>Why:</b> {@feedback.why}
            </p>
            <p :if={@feedback.better} id="fb-better"><b>Better move:</b> {@feedback.better}</p>
            <p
              :if={@play.status == :solved}
              class="stars-big"
              id="stars"
              aria-label={"#{Play.stars(@play)} stars"}
            >
              <span :for={k <- 1..3} class={["star", k <= Play.stars(@play) && "on"]}>★</span>
            </p>
            <div class="row">
              <button
                :if={watch?(@play)}
                type="button"
                class="pill small"
                id="watch"
                phx-click="watch"
              >
                Watch again
              </button>
              <button
                :if={
                  @play.status == :failed and @feedback.better_point != nil and not @play.show_better
                }
                type="button"
                class="pill small"
                id="show-better"
                phx-click="show_better"
              >
                Show the better move
              </button>
              <button
                :if={@play.status == :failed and @play.history != []}
                type="button"
                class="pill small"
                id="back"
                phx-click="back"
              >
                Go back one move
              </button>
            </div>
          </div>
          <p class="realgo" id="realgo">
            <b>In real Go:</b> {raw(@world_text.real)}
            <span :if={@atari}>A tower that shakes has only 1 road left: it is in <b>atari</b>.</span>
            <span :if={@look == :board}>On this board, Blue plays the black stones, and Red plays the white stones.</span>
          </p>
        </section>

        <section class="play">
          <div class="row">
            <span class="kicker">Look</span>
            <div class="seg" role="group" aria-label="Look">
              <button
                type="button"
                id="look-castle"
                phx-click="look"
                phx-value-look="castle"
                aria-pressed={to_string(@look == :castle)}
              >
                Castles
              </button>
              <button
                type="button"
                id="look-board"
                phx-click="look"
                phx-value-look="board"
                aria-pressed={to_string(@look == :board)}
              >
                Real Go board
              </button>
            </div>
          </div>
          <p class="puzzle-status">
            <span id="moves-left">{moves_left(@play)}</span>
            <span :if={@puzzle.hide_roads} class="hidden-roads">Count the roads yourself!</span>
          </p>
          <p class={["msg", @busy && "busy"]} id="message" aria-live="polite">{@play.message}</p>
          <BoardComponents.board
            board={@board}
            look={@look}
            hide_roads={@puzzle.hide_roads}
            falls={Play.shown_falls(@play)}
            marks={Play.shown_marks(@play)}
            glow={@glow}
            target={@puzzle.goal.target}
            step={@step}
            view={if @mode == :story, do: @story_view}
          />
          <div class="row" id="actions">
            <button
              :if={@play.status == :playing}
              type="button"
              class="pill"
              id="hint"
              phx-click="hint"
              disabled={@play.hint_on}
            >
              Hint
            </button>
            <button
              :if={@play.status in [:playing, :failed] and not @play.learned}
              type="button"
              class="pill"
              id="show-answer"
              phx-click="show_answer"
              disabled={@busy}
            >
              Show the answer
            </button>
            <button
              :if={@play.moves != [] or Play.over?(@play)}
              type="button"
              class={["pill", @play.status == :failed && "primary"]}
              id="retry"
              phx-click="retry"
              disabled={@busy}
            >
              Try again
            </button>
            <button
              :if={Play.over?(@play) and @mode == :story}
              type="button"
              class="pill primary"
              id="continue"
              phx-click="continue"
              disabled={@busy}
            >
              Continue the story
            </button>
            <button
              :if={Play.over?(@play) and @mode == :world}
              type="button"
              class={["pill", @play.status != :failed && "primary"]}
              id="next"
              phx-click="next"
              disabled={@busy}
            >
              Next puzzle
            </button>
          </div>
        </section>
      </main>
    </Layouts.app>
    """
  end

  defp glow(%Play{replay: nil} = play) do
    case Play.better_spot(play) do
      nil -> Play.hint_spots(play)
      spot -> [spot]
    end
  end

  defp glow(_play), do: []

  defp watch?(%Play{last_turn: %{steps: [_, _ | _]}, status: status}),
    do: status in [:failed, :solved, :learned]

  defp watch?(_), do: false

  defp atari?(board) do
    Enum.any?(Board.groups(board, :blue) ++ Board.groups(board, :red), &match?([_], &1.liberties))
  end

  defp moves_left(%Play{puzzle: %{goal: %{type: :capture}}, left: left}),
    do: "Moves left: #{left}"

  defp moves_left(%Play{left: left}), do: "Red moves left: #{left}"
end
