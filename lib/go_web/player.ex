defmodule GoWeb.Player do
  @moduledoc """
  Gives each browser a player id in the session cookie. There are no
  accounts yet. The progress of a player uses this id.
  """

  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case get_session(conn, "player_id") do
      nil -> put_session(conn, "player_id", new_id())
      _ -> conn
    end
  end

  @doc "The session of the live views: the player id."
  def session(conn), do: %{"player_id" => get_session(conn, "player_id") || new_id()}

  defp new_id, do: 16 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
end
