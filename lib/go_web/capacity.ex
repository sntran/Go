defmodule GoWeb.Capacity do
  @moduledoc """
  Refuses a new player when the memory of the VM is above the limit (see
  `Go.Capacity`). A player who is already here continues to play.

  - As a plug (in the pipeline `:browser`): a GET of a page by a new player
    gets the page "Too many players are here now" (status 503), with a
    button to try again.
  - As an `on_mount` hook of the live views: a new connection of a live
    view by a new player goes to the same page. Each mount and each event
    of a connected live view records an action of the player, so that the
    player stays "here".
  """

  @behaviour Plug

  import Plug.Conn
  import Phoenix.LiveView, only: [connected?: 1, redirect: 2]

  alias Go.Capacity

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{method: "GET"} = conn, _opts) do
    if Capacity.admit?(get_session(conn, "player_id")) do
      conn
    else
      conn
      |> put_resp_header("retry-after", "60")
      |> put_status(503)
      |> Phoenix.Controller.put_view(html: GoWeb.BusyHTML)
      |> Phoenix.Controller.render(:busy, retry: retry_path(conn), page_title: "Too many players")
      |> halt()
    end
  end

  def call(conn, _opts), do: conn

  def on_mount(:default, _params, session, socket) do
    player = session["player_id"]

    cond do
      not connected?(socket) ->
        {:cont, socket}

      Capacity.admit?(player) ->
        Capacity.seen(player)

        {:cont,
         Phoenix.LiveView.attach_hook(socket, :capacity, :handle_event, fn _event,
                                                                           _params,
                                                                           socket ->
           Capacity.seen(player)
           {:cont, socket}
         end)}

      # The browser loads the page again, and the plug gives the page
      # "Too many players". The browser sends its path in "_here" (see
      # assets/js/app.js).
      true ->
        here = Phoenix.LiveView.get_connect_params(socket)["_here"]
        {:halt, redirect(socket, to: safe_path(here))}
    end
  end

  # The path of the page that the player wanted (only a path of this site).
  defp retry_path(conn) do
    case conn.query_string do
      "" -> conn.request_path
      q -> conn.request_path <> "?" <> q
    end
  end

  @doc "A safe path to try again: a path of this site, or /."
  def safe_path("/" <> rest = path) do
    if String.starts_with?(rest, ["/", "\\"]), do: "/", else: path
  end

  def safe_path(_), do: "/"
end
