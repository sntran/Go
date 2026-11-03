import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/go start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :go, GoWeb.Endpoint, server: true
end

config :go, GoWeb.Endpoint, http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :dev do
  # Reload browser tabs when matching files change.
  config :go, GoWeb.Endpoint,
    live_reload: [
      web_console_logger: true,
      patterns: [
        # Static assets, except user uploads
        ~r"priv/static/(?!uploads/).*\.(js|css|png|jpeg|jpg|gif|svg)$"E,
        # Gettext translations
        ~r"priv/gettext/.*\.po$"E,
        # Router, Controllers, LiveViews and LiveComponents
        ~r"lib/go_web/router\.ex$"E,
        ~r"lib/go_web/(controllers|live|components)/.*\.(ex|heex)$"E
      ]
    ]
end

# The guard of the number of players (see Go.Capacity): at most this many
# connected pages (WebSocket connections with a live view). A new player
# at the limit gets the page "Too many players are here now"; a player who
# is connected continues to play.
#
# Why a count and not the memory: the memory of the VM in WebAssembly
# never shrinks, but the VM uses its free memory again. After one peak
# above a memory limit, a guard of the memory refuses all new players
# until Cloudflare evicts the Durable Object, also when only one player
# plays.
#
# Why 8: on Cloudflare (with -Mea min), 10 players who start at the same
# time passed in 3 of 3 runs (VM 123 to 127 MB), and 15 reset in 2 of 2
# (docs/load-test.md). 8 leaves space for players who reload, and for
# the growth of the VM. Set PLAYER_LIMIT to change it, or to "off". The
# guard is on only in prod.
player_limit =
  case System.get_env("PLAYER_LIMIT") do
    nil -> if config_env() == :prod, do: 8
    "off" -> nil
    n -> String.to_integer(n)
  end

config :go, :player_limit, player_limit

# GET /stats/memory gives the memory of the VM (for the load test).
config :go, :memory_stats, System.get_env("MEMORY_STATS") in ["1", "true"]

if config_env() == :prod do
  # The progress of the players. beam.com gives DATABASE_PATH on Cloudflare
  # Workers (the SQLite storage of the Durable Object).
  # Many players write at the same time: a statement waits up to 2 s for a
  # connection, and is not dropped after 100 ms (see docs/load-test.md).
  config :go, Go.Repo,
    database: System.get_env("DATABASE_PATH") || "go.db",
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "4"),
    queue_target: 2_000,
    queue_interval: 10_000

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :go, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :go, GoWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://bandit.hexdocs.pm/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      # On Cloudflare Workers, the host of beam.com has one listener, so one
      # acceptor is enough. Each acceptor is a process that takes memory.
      thousand_island_options: [num_acceptors: 1]
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :go, GoWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://plug.hexdocs.pm/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :go, GoWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
