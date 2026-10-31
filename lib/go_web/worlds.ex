defmodule GoWeb.Worlds do
  @moduledoc """
  The names and the texts of the worlds.
  """

  @worlds %{
    capture: %{
      name: "Capture",
      about: "Close all the open roads of a red fort to catch it.",
      real:
        "Towers are <b>stones</b>, and open roads are <b>liberties</b>. When you take away the last liberty of a stone, you <b>capture</b> it."
    },
    escape: %{
      name: "Escape",
      about: "Red attacks your fort. Give it more roads to save it.",
      real:
        "A stone with only 1 liberty is in <b>atari</b>. To save it, give it more liberties: run out, join a friend, or capture."
    },
    connect: %{name: "Connect and cut", about: "Join your towers. Split the towers of Red."},
    eyes: %{name: "Two eyes", about: "A fort with two courtyards lives forever."},
    ko: %{name: "Ko", about: "No instant take-back."},
    fields: %{name: "Fields", about: "Claim the empty land."}
  }

  @doc "The texts of a world."
  def get(world), do: Map.fetch!(@worlds, world)

  @doc "Changes a world name in a URL to an atom, or gives nil."
  def parse(name) do
    Enum.find(Go.Puzzles.open_worlds(), &(Atom.to_string(&1) == name))
  end
end
