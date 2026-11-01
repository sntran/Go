defmodule Go.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GoWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:go, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Go.PubSub},
      Go.Repo,
      # The migrations run at each start (also in a release).
      {Ecto.Migrator, repos: [Go.Repo]},
      Go.Progress,
      # Read the puzzle bank and the library one time at the start, so that
      # no action of a player waits for it.
      {Task, fn -> {Go.Puzzles.all(), Go.Library.all()} end},
      # Start to serve requests, typically the last entry
      GoWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Go.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
