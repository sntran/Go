defmodule GoWeb.PuzzleHelpers do
  @moduledoc """
  Helpers for the LiveView tests: taps and clicks as a child does them.
  """

  import Phoenix.LiveViewTest
  import ExUnit.Assertions

  @doc "A connection with a new player."
  def new_player(conn) do
    id = "test-" <> Integer.to_string(System.unique_integer([:positive]))
    {Plug.Test.init_test_session(conn, %{"player_id" => id}), id}
  end

  @doc "Taps a point of the board."
  def tap_point(view, {r, c}), do: view |> element(~s{[data-point="#{r}-#{c}"]}) |> render_click()

  @doc "Clicks a button by its id."
  def click(view, id), do: view |> element("##{id}") |> render_click()

  @doc "The color of the stone on a point in the HTML, or nil."
  def stone(html, {r, c}) do
    case html
         |> LazyHTML.from_document()
         |> LazyHTML.query(~s{[data-stone="#{r}-#{c}"]})
         |> LazyHTML.attribute("data-color") do
      [color] -> String.to_existing_atom(color)
      [] -> nil
    end
  end

  @doc "The text of an element, or nil if it is not there."
  def text(html, selector) do
    case html |> LazyHTML.from_document() |> LazyHTML.query(selector) do
      found ->
        if Enum.empty?(found),
          do: nil,
          else: found |> LazyHTML.text() |> String.trim() |> squeeze()
    end
  end

  defp squeeze(text), do: String.replace(text, ~r/\s+/, " ")

  @doc """
  Checks that the screen always gives a next step: the board takes taps,
  or there is a button to go on.
  """
  def assert_next_step(html) do
    playing = text(html, "#hint") != nil
    buttons = Enum.any?(["#retry", "#next", "#show-answer"], &(text(html, &1) != nil))
    assert playing or buttons, "the screen gives no next step"
  end
end
