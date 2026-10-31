defmodule GoWeb.PageController do
  use GoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
