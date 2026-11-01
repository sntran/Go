defmodule GoWeb.HomeLive do
  @moduledoc """
  The first page: continue the run or start a new one (see `Go.Runs`),
  or choose a world.
  """

  use GoWeb, :live_view

  alias Go.{Progress, Puzzle, Puzzles}
  alias GoWeb.Worlds

  @impl true
  def mount(_params, %{"player_id" => player}, socket) do
    results = Progress.results(player)

    worlds =
      for world <- Puzzle.worlds() do
        puzzles = Puzzles.world(world)
        solved = Enum.filter(puzzles, &match?(%{status: :solved}, results[&1.id]))

        %{
          id: world,
          text: Worlds.get(world),
          open: world in Puzzles.open_worlds(),
          total: length(puzzles),
          solved: length(solved),
          stars: solved |> Enum.map(&results[&1.id].stars) |> Enum.sum()
        }
      end

    {:ok,
     assign(socket,
       worlds: worlds,
       run: run_place(player),
       runs?: Go.Library.newest() != nil,
       # The daily run of the date of the player (from the browser).
       daily: if(connected?(socket), do: Go.Runs.daily_code(daily_date(socket))),
       page_title: "Tower Go"
     )}
  end

  defp daily_date(socket), do: Go.Runs.today(get_connect_params(socket)["date"])

  # The run that the player plays now, for the main button, or nil.
  defp run_place(player) do
    with seed when seed != nil <- Progress.current_run(player),
         %{stage: stage} when is_integer(stage) <- Progress.run_place(player, seed) do
      %{seed: seed, where: "Run #{seed} · Stage #{stage} of #{Go.Runs.stages()}"}
    else
      _ -> nil
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main class="home">
        <section class="intro">
          <h1>Play a real game, one moment at a time</h1>
          <p class="say">
            You are Blue. Red is the computer. A run has 5 stages, and each stage is a real game of Go. At each key moment, it is your turn to find the best move.
          </p>
          <div :if={@runs? and @run} class="story-start">
            <.link navigate={~p"/run/#{@run.seed}"} class="pill primary" id="continue-run">
              Continue the run
            </.link>
            <span class="story-where">{@run.where}</span>
          </div>
          <div :if={@runs?} class="story-start">
            <.link navigate={~p"/run/new"} class={["pill", !@run && "primary"]} id="new-run">
              Start a new run
            </.link>
            <.link navigate={~p"/run/daily"} class="pill" id="daily-run">Play the daily run</.link>
            <span :if={@daily} class="story-where" id="daily-code">Today: {@daily}</span>
          </div>
        </section>
        <section class="intro">
          <h2>Worlds</h2>
          <p class="say">Each world teaches one idea of the game of Go.</p>
        </section>
        <ul class="worlds">
          <li :for={w <- @worlds} class={["world", !w.open && "soon"]}>
            <%= if w.open do %>
              <.link navigate={~p"/play/#{w.id}"} class="world-link" id={"world-#{w.id}"}>
                <span class="world-name">{w.text.name}</span>
                <span class="world-about">{w.text.about}</span>
                <span class="world-progress">
                  {w.solved} of {w.total} solved
                  <span :if={w.stars > 0} class="stars" aria-label={"#{w.stars} stars"}>★ {w.stars}</span>
                </span>
              </.link>
              <.link navigate={~p"/worlds/#{w.id}"} class="world-all" id={"world-all-#{w.id}"}>
                See all puzzles
              </.link>
            <% else %>
              <div class="world-link" aria-disabled="true">
                <span class="world-name">{w.text.name}</span>
                <span class="world-about">{w.text.about}</span>
                <span class="world-progress">Soon</span>
              </div>
            <% end %>
          </li>
        </ul>
        <p class="move-link">
          <.link navigate={~p"/move"} id="move-link">Move my progress to another device</.link>
        </p>
      </main>
    </Layouts.app>
    """
  end
end
