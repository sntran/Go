defmodule GoWeb.PuzzleLive do
  @moduledoc """
  The puzzle screen. The server owns the game: the browser sends only the
  taps, and it gets only the board and the results, never the answer.

  Red's moves and the moves of "Watch again" come one by one, with a short
  time between them (see `:red_delay` and `:watch_delay` in the config).
  While Red plays, taps on the board only show "Wait".
  """

  use GoWeb, :live_view

  alias Go.{Board, Play, Progress, Puzzles}
  alias GoWeb.{BoardComponents, Worlds}

  @impl true
  def mount(%{"world" => name}, %{"player_id" => player}, socket) do
    case Worlds.parse(name) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/")}

      world ->
        {:ok,
         assign(socket,
           world: world,
           player: player,
           look: Progress.look(player),
           play: nil,
           step: 0,
           timer: nil,
           recorded: false,
           red_delay: Application.get_env(:go, :red_delay, 700),
           watch_delay: Application.get_env(:go, :watch_delay, 900)
         )}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    world = socket.assigns.world
    results = Progress.results(socket.assigns.player)

    puzzle =
      case params["id"] do
        nil -> Puzzles.next(world, nil, results, Date.utc_today())
        id -> with %{world: ^world} = p <- Puzzles.get(id), do: p, else: (_ -> nil)
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
            page_title: puzzle.title,
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
    %{world: world, play: play, player: player} = socket.assigns
    current = play && play.puzzle.id

    case Puzzles.next(world, current, Progress.results(player), Date.utc_today()) do
      nil -> {:noreply, push_patch(socket, to: ~p"/play/#{world}?done=1")}
      next -> {:noreply, push_patch(socket, to: ~p"/play/#{world}?id=#{next.id}")}
    end
  end

  def handle_event("look", %{"look" => look}, socket) when look in ["castle", "board"] do
    look = String.to_existing_atom(look)
    Progress.put_look(socket.assigns.player, look)
    {:noreply, assign(socket, look: look)}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}

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

  defp run_now(socket, :watch_step) do
    play =
      Stream.iterate(socket.assigns.play, &Play.watch_step/1) |> Enum.find(&(&1.replay == nil))

    socket |> assign(timer: nil) |> put_play(play)
  end

  defp record(%{assigns: %{play: play, recorded: false}} = socket) do
    if Play.over?(play) do
      Progress.record(socket.assigns.player, play)
      assign(socket, recorded: true)
    else
      socket
    end
  end

  defp record(socket), do: socket

  defp put_play(socket, play), do: assign(socket, play: play, step: socket.assigns.step + 1)

  defp update_play(%{assigns: %{play: %Play{} = play}} = socket, fun),
    do: put_play(socket, fun.(play))

  defp update_play(socket, _fun), do: socket

  ## View

  @impl true
  def render(%{play: nil} = assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main class="done">
        <h1>You solved every puzzle in this world!</h1>
        <p class="say">Great work. Puzzles that you learned come back in a few days.</p>
        <.link navigate={~p"/"} class="pill primary" id="home">Choose a world</.link>
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
        world_text: Worlds.get(assigns.world)
      )

    ~H"""
    <Layouts.app flash={@flash}>
      <main class="main">
        <section class="head">
          <p class="kicker">
            <.link navigate={~p"/"} class="back-link">Worlds</.link>
            · {@world_text.name} · Puzzle {@index} of {@total}
          </p>
          <h1 id="title">{@puzzle.title}</h1>
          <p class="say" id="say">{@puzzle.say}</p>
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
              :if={Play.over?(@play)}
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
