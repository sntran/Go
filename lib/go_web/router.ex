defmodule GoWeb.Router do
  use GoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug GoWeb.Player
    # A new player gets "Too many players" when the VM is full.
    plug GoWeb.Capacity
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GoWeb do
    pipe_through :browser

    live_session :default,
      session: {GoWeb.Player, :session, []},
      on_mount: GoWeb.Capacity do
      live "/", HomeLive
      live "/play/:world", PuzzleLive
      live "/worlds/:world", WorldLive
      live "/run/:seed", PuzzleLive, :run
      live "/move", MoveLive
    end

    post "/move", MoveController, :create
  end

  # The memory of the VM, for the load test (only with MEMORY_STATS=1).
  scope "/stats", GoWeb do
    pipe_through :api
    get "/memory", StatsController, :memory
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:go, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GoWeb.Telemetry
    end
  end
end
