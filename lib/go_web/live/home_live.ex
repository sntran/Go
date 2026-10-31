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

    {:ok, assign(socket, worlds: worlds, story: story_place(player), page_title: "Tower Go")}
  end

  # The place of the player in the stories, for the main button.
  defp story_place(player) do
    stories = Go.Stories.all()

    case Progress.story(player) do
      nil ->
        %{label: "Start the story", where: hd(stories).title}

      %{story: id, moment: :end} ->
        %{label: "Continue the story", where: "#{Go.Stories.get(id).title}: the end of the game"}

      %{story: id, moment: k} ->
        story = Go.Stories.get(id)

        %{
          label: "Continue the story",
          where: "#{story.title} · Moment #{k} of #{length(story.moments)}"
        }
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
            You are Blue. Red is the computer. A story is one full game of Go. At each key moment, it is your turn to find the best move.
          </p>
          <div class="story-start">
            <.link navigate={~p"/story"} class="pill primary" id="story">{@story.label}</.link>
            <span class="story-where">{@story.where}</span>
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
      </main>
    </Layouts.app>
    """
  end
end
