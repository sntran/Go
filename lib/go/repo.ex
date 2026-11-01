defmodule Go.Repo do
  @moduledoc """
  The database of the progress of the players (see `Go.Progress`): SQLite.
  On Cloudflare Workers, beam.com sends each statement to the SQLite
  storage of the Durable Object, so the progress stays after a deploy.
  """

  use Ecto.Repo,
    otp_app: :go,
    adapter: Ecto.Adapters.SQLite3
end
