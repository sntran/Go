defmodule GoWeb.BusyHTML do
  @moduledoc """
  The page for a new player when the server is full (see
  `GoWeb.Capacity`).
  """

  use GoWeb, :html

  embed_templates "busy_html/*"
end
