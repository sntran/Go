import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :go, GoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "zZ0nL22IPaH/aJ/FQQn7Z3xIK2hV6uvOw9GWib38xCu8M2EdmjhO2RvHyRYM76y+",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Red plays at once in the tests. A test can set a delay to check the
# screen while Red plays.
config :go, red_delay: 0, watch_delay: 0, story_delay: 0

# The tests wait for each deep search, so that the results are always the
# same. A test that needs the time limit sets it.
config :go, think_ms: :infinity
