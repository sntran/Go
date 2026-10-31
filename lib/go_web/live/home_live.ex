defmodule GoWeb.HomeLive do
  @moduledoc """
  The first page: choose a world.
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

    {:ok, assign(socket, worlds: worlds, page_title: "Choose a world")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main class="home">
        <section class="intro">
          <h1>Choose a world</h1>
          <p class="say">
            You are Blue. Red is the computer. Build towers, close roads, and save your forts.
            Each world teaches one idea of the game of Go.
          </p>
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
            <% else %>
              <div class="world-link" aria-disabled="true">
                <span class="world-name">{w.text.name}</span>
                <span class="world-about">{w.text.about}</span>
                <span class="world-progress">Soon</span>
              </div>
            <% end %>
          </li>
        </ul>
      </main>
    </Layouts.app>
    """
  end
end
