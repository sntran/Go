defmodule GoWeb.MoveLive do
  @moduledoc """
  The page "Move my progress to another device" (see `Go.Transfer`). The
  code shows on this device. The other device types it in a form, and the
  form goes to `GoWeb.MoveController`, which changes the session cookie.
  """

  use GoWeb, :live_view

  alias Go.Transfer

  @impl true
  def mount(_params, %{"player_id" => player}, socket) do
    {:ok, assign(socket, player: player, code: nil, page_title: "Move my progress")}
  end

  @impl true
  def handle_event("make_code", _, socket) do
    {code, expires} = Transfer.create(socket.assigns.player)
    {:noreply, assign(socket, code: code, expires: expires)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main class="main">
        <section class="head">
          <p class="kicker"><.link navigate={~p"/"} class="back-link">Home</.link></p>
          <h1 id="title">Move my progress to another device</h1>
          <p class="say">
            Your stars, your puzzles and your runs belong to this browser. A code moves them to another device.
          </p>
        </section>
        <section class="notes">
          <div class="fb" id="show-code">
            <p class="t">1. On this device</p>
            <%= if @code do %>
              <p>Type this code on the other device:</p>
              <p class="move-code" id="code">{Transfer.format(@code)}</p>
              <p>The code works one time, for 24 hours.</p>
            <% else %>
              <button type="button" class="pill primary" id="make-code" phx-click="make_code">
                Show my code
              </button>
            <% end %>
          </div>
          <div class="fb" id="use-code">
            <p class="t">2. On the other device</p>
            <p>Type the code here. The progress of the code then replaces the progress of this browser.</p>
            <form action={~p"/move"} method="post" id="code-form">
              <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
              <input
                type="text"
                name="code"
                id="code-input"
                class="code-input"
                autocomplete="off"
                autocapitalize="characters"
                maxlength="16"
                aria-label="The code"
                placeholder="ABCDE-FGHJK"
              />
              <button type="submit" class="pill" id="use-code-button">Move the progress here</button>
            </form>
          </div>
        </section>
      </main>
    </Layouts.app>
    """
  end
end
