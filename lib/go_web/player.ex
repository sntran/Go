defmodule GoWeb.Player do
  @moduledoc """
  Gives each browser a player id in the session cookie. There are no
  accounts yet. The progress of a player uses this id.

  The cookie lives for one year (see the session options of
  `GoWeb.Endpoint`). Each visit writes the player id again, so the cookie
  is sent again with a new year.
  """

  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    put_session(conn, "player_id", get_session(conn, "player_id") || new_id())
  end

  @doc "The session of the live views: the player id."
  def session(conn), do: %{"player_id" => get_session(conn, "player_id") || new_id()}

  defp new_id, do: 16 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
end
