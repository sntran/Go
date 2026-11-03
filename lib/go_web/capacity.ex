defmodule GoWeb.Capacity do
  @moduledoc """
  Refuses a new player when the number of connected pages is at the limit
  (see `Go.Capacity`). A player who is already connected continues to
  play.

  - As a plug (in the pipeline `:browser`): a GET of a page by a new player
    gets the page "Too many players are here now" (status 503), with a
    button to try again.
  - As an `on_mount` hook of the live views: a connected live view joins
    the count (`Go.Capacity.join/2`). A new connection at the limit loads
    the page again, and then gets the same page.
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
    cond do
      not connected?(socket) ->
        {:cont, socket}

      Capacity.join(session["player_id"], socket.transport_pid) == :ok ->
        {:cont, socket}

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
