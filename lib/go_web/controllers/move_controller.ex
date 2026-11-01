defmodule GoWeb.MoveController do
  @moduledoc """
  Takes the code of the page "Move my progress to another device" (see
  `Go.Transfer`). A correct code puts the player id of the code into the
  session cookie of this browser. Only a plug can change the cookie, so
  the form comes here and not to the live view.
  """

  use GoWeb, :controller

  alias Go.Transfer

  def create(conn, %{"code" => code}) do
    browser = get_session(conn, "player_id")

    case Transfer.redeem(code, browser) do
      {:ok, player} ->
        conn
        |> put_session("player_id", player)
        |> put_flash(:info, "Your progress is here now.")
        |> redirect(to: ~p"/")

      {:error, :wrong} ->
        conn
        |> put_flash(
          :error,
          "This code does not work. It works one time, for 24 hours. Check it, or make a new code on the other device."
        )
        |> redirect(to: ~p"/move")

      {:error, :too_many_tries} ->
        conn
        |> put_flash(:error, "Too many wrong codes. Try again in one hour.")
        |> redirect(to: ~p"/move")
    end
  end

  def create(conn, _params), do: redirect(conn, to: ~p"/move")
end
