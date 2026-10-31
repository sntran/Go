defmodule GoWeb.WorldLive do
  @moduledoc """
  The page of a world: all its puzzles, by idea, with the result of each
  one. A skipped puzzle stays available.
  """

  use GoWeb, :live_view

  alias Go.{Path, Progress}
  alias GoWeb.Worlds

  @impl true
  def mount(%{"world" => name}, %{"player_id" => player}, socket) do
    case Worlds.parse(name) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/")}

      world ->
        results = Progress.results(player)

        ideas =
          for idea <- Path.ideas(world) do
            %{
              name: Path.name(idea.idea),
              puzzles:
                Enum.map(idea.puzzles, &{&1, Path.status(&1, idea, results), results[&1.id]})
            }
          end

        {:ok,
         assign(socket,
           world: world,
           text: Worlds.get(world),
           ideas: ideas,
           page_title: Worlds.get(world).name
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main class="home">
        <section class="intro">
          <p class="kicker">
            <.link navigate={~p"/"} class="back-link">Worlds</.link> · {@text.name}
          </p>
          <h1>{@text.name}</h1>
          <p class="say">{@text.about}</p>
          <div class="row">
            <.link navigate={~p"/play/#{@world}"} class="pill primary" id="play-path">Play the next puzzle</.link>
          </div>
        </section>
        <section :for={idea <- @ideas} class="idea">
          <h2>{idea.name}</h2>
          <ul class="puzzle-list">
            <li
              :for={{p, status, result} <- idea.puzzles}
              id={"puzzle-#{p.id}"}
              class={["puzzle-item", "status-#{status}"]}
            >
              <.link navigate={~p"/play/#{@world}?id=#{p.id}"}>
                <span class="puzzle-title">{p.title}</span>
                <span class="puzzle-status-text">{status_text(status, result)}</span>
              </.link>
            </li>
          </ul>
        </section>
      </main>
    </Layouts.app>
    """
  end

  defp status_text(:solved, %{stars: stars}), do: String.duplicate("★", stars)
  defp status_text(:learned, _), do: "Learned. It comes back soon."
  defp status_text(:tried, _), do: "Tried. Play it again!"
  defp status_text(:skipped, _), do: "Skipped. You know this one."
  defp status_text(:open, _), do: ""
end
