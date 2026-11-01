defmodule GoWeb.PuzzleLive do
  @moduledoc """
  The puzzle screen. The server owns the game: the browser sends only the
  taps, and it gets only the board and the results, never the answer.

  Red's moves and the moves of "Watch again" come one by one, with a short
  time between them (see `:red_delay` and `:watch_delay` in the config).
  While Red plays, taps on the board only show "Wait".

  The same screen plays the runs (the live action `:run`, see `Go.Runs`):
  5 stages, and each stage is a story of `Go.Library`. Each puzzle is a
  moment of the game, and between the puzzles the main line of the game
  plays on the board. The board shows the whole board. During a puzzle, it
  dims the part outside the fight. The place of the player in the run
  stays in `Go.Progress`.
  """

  use GoWeb, :live_view

  alias Go.{Board, Library, Play, Progress, Puzzles, Runs, Score}
  alias GoWeb.{BoardComponents, Worlds}

  @impl true
  def mount(params, %{"player_id" => player}, socket) do
    socket =
      assign(socket,
        player: player,
        mode: if(socket.assigns.live_action == :run, do: :run, else: :world),
        look: Progress.look(player),
        play: nil,
        kind: :pick,
        path_next: nil,
        counted: false,
        step: 0,
        timer: nil,
        recorded: false,
        run: nil,
        stage: nil,
        place: nil,
        phase: nil,
        anim: nil,
        red_delay: Application.get_env(:go, :red_delay, 700),
        watch_delay: Application.get_env(:go, :watch_delay, 900),
        story_delay: Application.get_env(:go, :story_delay, 500),
        score: nil,
        final: nil,
        moment: nil,
        puzzle_no: nil
      )

    case socket.assigns.mode do
      :run ->
        mount_run(assign(socket, world: nil, seed: nil), params["seed"])

      :world ->
        case Worlds.parse(params["world"]) do
          nil -> {:ok, push_navigate(socket, to: ~p"/")}
          world -> {:ok, assign(socket, world: world)}
        end
    end
  end

  @impl true
  def handle_params(_params, _uri, %{assigns: %{mode: :run, seed: nil}} = socket),
    do: {:noreply, socket}

  def handle_params(params, _uri, %{assigns: %{mode: :run}} = socket) do
    {:noreply, start_run(socket, params["day"])}
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

  # The run: after a puzzle, the game goes on to the next puzzle.
  def handle_event("continue", _, %{assigns: %{mode: :run, phase: :moment, play: play}} = socket) do
    if Play.over?(play), do: {:noreply, continue_run(socket)}, else: {:noreply, socket}
  end

  def handle_event("skip", _, %{assigns: %{anim: %{}}} = socket) do
    {:noreply, finish_anim(socket)}
  end

  # The hook Anim played all moves of the animation (in the browser).
  def handle_event("anim_done", %{"id" => id}, %{assigns: %{anim: %{id: id}}} = socket) do
    {:noreply, finish_anim(socket)}
  end

  def handle_event("anim_done", _, socket), do: {:noreply, socket}

  def handle_event("next_stage", _, %{assigns: %{mode: :run, phase: :stage_end}} = socket) do
    {:noreply, next_stage(socket)}
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

  # The hook did not tell the end of the animation in time (no JavaScript,
  # or a lost message): the server goes on by itself.
  def handle_info({:anim_timeout, ref}, %{assigns: %{timer: ref, anim: %{}}} = socket) do
    {:noreply, finish_anim(socket)}
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
      socket |> count_path() |> record_run() |> assign(recorded: true)
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

  # The puzzle, its world and the number of puzzles of the stage change
  # only with a new puzzle. They are assigns (not values made in render), so
  # LiveView does not send their texts again after each move.
  defp put_play(socket, play) do
    assign(socket,
      play: play,
      step: socket.assigns.step + 1,
      puzzle: play.puzzle,
      world_text: Worlds.get(play.puzzle.world),
      run_total: if(socket.assigns.mode == :run, do: length(current_stage(socket).puzzles))
    )
  end

  ## The run

  defp mount_run(socket, param) do
    cond do
      Library.newest() == nil ->
        {:ok,
         socket |> put_flash(:error, "There are no stories yet.") |> push_navigate(to: ~p"/")}

      param == "new" ->
        {:ok, push_navigate(socket, to: ~p"/run/#{Runs.new_code()}")}

      # The date of the player comes with the connection of the browser.
      param == "daily" and not connected?(socket) ->
        {:ok, assign(socket, phase: :loading, page_title: "The daily run")}

      param == "daily" ->
        date = Runs.today(get_connect_params(socket)["date"])

        {:ok,
         push_navigate(socket, to: ~p"/run/#{Runs.daily_code(date)}?day=#{Date.to_iso8601(date)}")}

      (code = Runs.parse(param)) && code != param ->
        {:ok, push_navigate(socket, to: ~p"/run/#{code}")}

      # The first page (before the WebSocket) does not make the run: the
      # run is made one time, when the page connects.
      Runs.parse(param) && not connected?(socket) ->
        {:ok, assign(socket, phase: :loading, page_title: "Run #{param}")}

      seed = Runs.parse(param) ->
        {:ok, assign(socket, seed: seed)}

      true ->
        {:ok,
         socket |> put_flash(:error, "This is not the code of a run.") |> push_navigate(to: ~p"/")}
    end
  end

  # The place of the player in the run of the code. A new place starts at
  # stage 1, and fixes the level of the player for the whole run. A daily
  # run keeps its date (the date must be today somewhere, and the code must
  # be the code of the date).
  defp start_run(socket, day) do
    %{player: player, seed: seed} = socket.assigns

    place =
      Progress.run_place(player, seed) ||
        %{
          seed: seed,
          level: Runs.level(player),
          stage: 1,
          moment: :start,
          results: [],
          daily: daily_date(day, seed)
        }

    Progress.put_run_place(player, place)

    socket
    |> assign(run: %{seed: seed, level: place.level}, place: place, page_title: "Run #{seed}")
    |> load_stage()
    |> resume()
  end

  defp daily_date(day, code) do
    with true <- is_binary(day),
         {:ok, date} <- Date.from_iso8601(day),
         true <- Runs.today_somewhere?(date),
         true <- Runs.daily_code(date) == code do
      date
    else
      _ -> nil
    end
  end

  defp resume(%{assigns: %{place: place}} = socket) do
    case place do
      %{stage: :done} ->
        assign(socket, phase: :run_end, anim: nil, play: nil)

      %{moment: :start} ->
        stage = current_stage(socket)
        first = hd(stage.puzzles)
        title = "Stage #{stage.number} of #{Runs.stages()}"
        start_anim(socket, stage.from, first.index, {:puzzle, 1}, title)

      %{moment: :end} ->
        end_stage(socket)

      %{moment: n} ->
        start_puzzle(socket, n)
    end
  end

  # The page keeps only the stage of the place (see Go.Runs.stage/3).
  defp current_stage(%{assigns: %{stage: stage}}), do: stage

  defp load_stage(%{assigns: %{run: run, place: %{stage: k}}} = socket) when is_integer(k),
    do: assign(socket, stage: Runs.stage(run.seed, run.level, k))

  defp load_stage(socket), do: assign(socket, stage: nil)

  defp save_place(socket, place) do
    Progress.put_run_place(socket.assigns.player, place)
    assign(socket, place: place)
  end

  defp start_puzzle(socket, n) do
    stage = current_stage(socket)

    case Enum.at(stage.puzzles, n - 1) do
      # A new library can change a run: then the stage starts again.
      nil ->
        socket |> save_place(%{socket.assigns.place | moment: :start, results: []}) |> resume()

      moment ->
        show_puzzle(socket, stage, n, moment)
    end
  end

  defp show_puzzle(socket, stage, n, moment) do
    socket
    |> save_place(%{socket.assigns.place | moment: n})
    |> assign(
      phase: :moment,
      moment: moment,
      puzzle_no: n,
      anim: nil,
      kind: :run,
      counted: false,
      recorded: false,
      timer: nil
    )
    |> put_play(Play.new(Runs.puzzle(stage, moment)))
  end

  # The game goes on from the moment, with its correct move, to the next
  # puzzle, or to the end of the stage. The computer plays the moments that
  # are not puzzles.
  defp continue_run(socket) do
    %{moment: moment, puzzle_no: n} = socket.assigns
    stage = current_stage(socket)

    # The place moves on at once: a reload during the moves does not show
    # this puzzle again.
    place = socket.assigns.place

    case Enum.at(stage.puzzles, n) do
      nil ->
        title = if stage.full, do: "The end of the game", else: "The end of the stage"

        socket
        |> save_place(%{place | moment: :end})
        |> start_anim(moment.index, stage.to, :stage_end, title)

      next ->
        socket
        |> save_place(%{place | moment: n + 1})
        |> start_anim(moment.index, next.index, {:puzzle, n + 1}, "The game goes on")
    end
  end

  # The result of each puzzle of the stage, the first time that it ends.
  defp record_run(
         %{assigns: %{mode: :run, phase: :moment, place: place, moment: m, play: play}} = socket
       ) do
    if Enum.any?(place.results, &(&1.index == m.index)) do
      socket
    else
      result = Play.result(play)

      entry = %{
        index: m.index,
        result: result,
        stars: if(result == :solved, do: Play.stars(play), else: 0),
        help: Play.help(play)
      }

      save_place(socket, %{place | results: place.results ++ [entry]})
    end
  end

  defp record_run(socket), do: socket

  defp end_stage(socket) do
    stage = current_stage(socket)
    socket = save_place(socket, %{socket.assigns.place | moment: :end})
    Progress.record_stage(socket.assigns.player, socket.assigns.place)
    board = Library.board_at(stage.story, stage.to)

    assign(socket,
      phase: :stage_end,
      anim: nil,
      play: nil,
      final: board,
      score: if(stage.full, do: Score.count(board))
    )
  end

  defp next_stage(%{assigns: %{place: place}} = socket) do
    place =
      if place.stage >= Runs.stages(),
        do: %{place | stage: :done, moment: :end},
        else: %{place | stage: place.stage + 1, moment: :start, results: []}

    socket |> save_place(place) |> load_stage() |> resume()
  end

  # Plays the moves of the main line from `from` to `to` on the board. The
  # server renders the first board one time, with all moves; the hook Anim
  # plays them in the browser, and sends "anim_done" at the end. The server
  # renders nothing for each move (see docs/load-test.md). The place of
  # the player is already after the animation. With no delay (the tests),
  # the animation ends at once.
  defp start_anim(socket, from, to, then, title) do
    story = current_stage(socket).story
    board = Library.board_at(story, from)
    steps = story.moves |> Enum.slice(from, to - from)
    delay = socket.assigns.story_delay

    anim = %{
      board: board,
      steps: steps,
      then: then,
      title: title,
      id: "anim-#{System.unique_integer([:positive])}"
    }

    socket = assign(socket, phase: :anim, play: nil, anim: anim, timer: nil)

    if delay == 0 or steps == [] do
      finish_anim(socket)
    else
      # A safety net: the server goes on by itself after the time of the
      # animation and 5 s more.
      schedule(socket, :anim_timeout, delay * length(steps) + 5_000)
    end
  end

  defp finish_anim(%{assigns: %{anim: %{then: then}}} = socket) do
    socket = assign(socket, timer: nil, anim: nil)

    case then do
      {:puzzle, k} -> start_puzzle(socket, k)
      :stage_end -> end_stage(socket)
    end
  end

  defp finish_anim(socket), do: socket

  # The moves of an animation, for the hook: [color, [row, column]] or
  # [color, "pass"].
  defp anim_steps(steps) do
    JSON.encode!(
      for {color, move} <- steps,
          do: [color, if(move == :pass, do: "pass", else: Tuple.to_list(move))]
    )
  end

  defp anim_stones(board),
    do: JSON.encode!(for({{r, c}, color} <- Enum.sort(board.stones), do: [r, c, color]))

  defp stage_stars(results), do: results |> Enum.map(& &1.stars) |> Enum.sum()

  defp update_play(%{assigns: %{play: %Play{} = play}} = socket, fun),
    do: put_play(socket, fun.(play))

  defp update_play(socket, _fun), do: socket

  ## View

  @impl true
  def render(%{mode: :run, phase: :loading} = assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main class="done">
        <h1 id="title">Opening the run…</h1>
      </main>
    </Layouts.app>
    """
  end

  def render(%{mode: :run, phase: :anim} = assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main class="main">
        <section class="head">
          <.run_kicker place={@place} />
          <h1 id="title">{@anim.title}</h1>
          <p class="say" id="say">
            Watch the moves of the game. Blue plays the black stones, Red plays the white stones.
          </p>
        </section>
        <section class="play">
          <p class="msg busy" id="message" aria-live="polite">Watch the game…</p>
          <div
            id={@anim.id}
            phx-hook="Anim"
            phx-update="ignore"
            data-steps={anim_steps(@anim.steps)}
            data-stones={anim_stones(@anim.board)}
            data-size={@anim.board.size}
            data-delay={@story_delay}
            data-look={@look}
          >
            <BoardComponents.board board={@anim.board} look={@look} step={@step} />
          </div>
          <div class="row" id="actions">
            <button type="button" class="pill" id="skip" phx-click="skip">Skip</button>
          </div>
        </section>
      </main>
    </Layouts.app>
    """
  end

  def render(%{mode: :run, phase: :stage_end} = assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main class="main">
        <section class="head">
          <.run_kicker place={@place} />
          <h1 id="title">
            {if @score, do: "The end of the game", else: "Stage #{@place.stage} is over"}
          </h1>
          <p :if={@score} class="say" id="say">
            Both players closed their borders and passed. Your fields are the empty points that only your towers touch.
          </p>
          <p :if={!@score} class="say" id="say">
            The game goes on, but this stage ends here.
          </p>
        </section>
        <section class="notes">
          <div :if={@score} id="score" class="fb good" aria-live="polite">
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
          <div class="fb" id="stage-result">
            <p class="t">Your puzzles in this stage</p>
            <.stage_line results={@place.results} />
          </div>
          <p :if={@score} class="realgo">
            <b>In real Go:</b>
            fields are called <b>territory</b>. The score is your stones plus your territory.
          </p>
        </section>
        <section class="play">
          <BoardComponents.board
            board={@final}
            hide_roads={@score != nil}
            look={@look}
            step={@step}
            fields={if @score, do: @score.owners, else: %{}}
          />
          <div class="row" id="actions">
            <button type="button" class="pill primary" id="next-stage" phx-click="next_stage">
              {if @place.stage < Runs.stages(), do: "Next stage", else: "See the result of the run"}
            </button>
          </div>
        </section>
      </main>
    </Layouts.app>
    """
  end

  def render(%{mode: :run, phase: :run_end} = assigns) do
    stages =
      assigns.player
      |> Progress.stage_results()
      |> Enum.filter(&(&1.seed == assigns.place.seed))
      |> Enum.sort_by(& &1.stage)

    assigns = assign(assigns, stages: stages)

    ~H"""
    <Layouts.app flash={@flash}>
      <main class="done">
        <p class="kicker" id="kicker">
          <.link navigate={~p"/"} class="back-link">Home</.link>
          · Run <span id="seed">{@place.seed}</span>
        </p>
        <h1 id="title">You finished the run!</h1>
        <p class="say">
          Five games, one moment at a time. Here are your stars.
        </p>
        <div class="fb" id="run-result">
          <p :for={st <- @stages} id={"stage-#{st.stage}"}>
            <b>Stage {st.stage}:</b> <.stage_line results={st.results} />
          </p>
          <p id="run-stars">
            <b>All stages:</b> ★ {Enum.sum(Enum.map(@stages, &stage_stars(&1.results)))}
          </p>
        </div>
        <p class="say" id="share">
          Share this run: <code>/run/{@place.seed}</code>. Your friends get the same games.
        </p>
        <div class="row">
          <.link navigate={~p"/run/new"} class="pill primary" id="new-run">Start a new run</.link>
          <.link navigate={~p"/"} class="pill" id="home">Home</.link>
        </div>
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
        board: board,
        feedback: play.replay == nil && play.feedback,
        glow: glow(play),
        atari: atari?(board),
        busy: Play.busy?(play)
      )

    ~H"""
    <Layouts.app flash={@flash}>
      <main class="main">
        <section class="head">
          <.run_kicker
            :if={@mode == :run}
            place={@place}
            puzzle={"Puzzle #{@puzzle_no} of #{@run_total}"}
          />
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
            window={if @mode == :run, do: @moment.window}
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
              :if={Play.over?(@play) and @mode == :run}
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

  attr :place, :map, required: true
  attr :puzzle, :string, default: nil

  # The kicker of a run page: the seed, the stage and the puzzle.
  defp run_kicker(assigns) do
    ~H"""
    <p class="kicker" id="kicker">
      <.link navigate={~p"/"} class="back-link">Home</.link>
      · Run <span id="seed">{@place.seed}</span>
      <span :if={Map.get(@place, :daily)} id="daily">
        · Daily run of {Calendar.strftime(@place.daily, "%B %-d")}
      </span>
      <span :if={is_integer(@place.stage)}>· Stage {@place.stage} of {Runs.stages()}</span>
      <span :if={@puzzle}>· {@puzzle}</span>
    </p>
    """
  end

  attr :results, :list, required: true

  # The stars of each puzzle of a stage. A puzzle that the player learned
  # or failed has no star.
  defp stage_line(assigns) do
    ~H"""
    <span class="stage-line">
      <span
        :for={r <- @results}
        class="stars"
        aria-label={"#{r.stars} stars"}
      >{String.duplicate("★", r.stars)}{String.duplicate("☆", 3 - r.stars)}</span>
    </span>
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
