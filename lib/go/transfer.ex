defmodule Go.Transfer do
  @moduledoc """
  Moves the progress of a player to another device. The player has no
  account: the progress belongs to the player id in the session cookie.

    1. On the first device, the player makes a code: 10 characters from
       the alphabet of the run codes (`Go.Runs.alphabet/0`), 32 ** 10 = 2 ** 50
       codes, so nobody can guess one. A code is valid for 24 hours, and
       only one time.
    2. On the other device, the player types the code. Then that browser
       gets the same player id, and the progress is there.

  A browser can type at most 5 wrong codes in one hour. The codes and the
  wrong tries are in SQLite (the tables `transfer_codes` and
  `transfer_tries`). The times are ISO 8601 text in UTC, so the text order
  is the time order.
  """

  import Ecto.Query

  alias Go.{Repo, Runs}

  @length 10
  @valid_hours 24
  @max_tries 5

  def length, do: @length
  def max_tries, do: @max_tries

  @doc "Makes a new code for the player. Gives `{code, expires_at}`."
  def create(player, now \\ DateTime.utc_now()) do
    code = for _ <- 1..@length, into: "", do: <<random_char()>>
    expires = now |> DateTime.add(@valid_hours, :hour)

    {count, _} =
      Repo.insert_all(
        "transfer_codes",
        [%{code: code, player: player, expires_at: time(expires)}],
        on_conflict: :nothing
      )

    # Two equal codes are nearly impossible; then make another one.
    if count == 1, do: {code, expires}, else: create(player, now)
  end

  defp random_char do
    alphabet = Runs.alphabet()
    <<n>> = :crypto.strong_rand_bytes(1)
    # 256 is 8 times 32, so each character has the same chance.
    Enum.at(alphabet, rem(n, length(alphabet)))
  end

  @doc """
  Uses a code that the browser `browser` (its player id) typed. Gives
  `{:ok, player}` (the player of the code), `{:error, :wrong}` (no such
  code, a used code, or an old code) or `{:error, :too_many_tries}` (5
  wrong codes in the last hour). A wrong code counts as a try.
  """
  def redeem(text, browser, now \\ DateTime.utc_now()) do
    if tries(browser, now) >= @max_tries do
      {:error, :too_many_tries}
    else
      code = normalize(text)

      case use_code(code, now) do
        {:ok, player} ->
          {:ok, player}

        :error ->
          Repo.insert_all("transfer_tries", [%{browser: browser, at: time(now)}])
          {:error, :wrong}
      end
    end
  end

  @doc "The wrong codes of a browser in the hour before `now`."
  def tries(browser, now \\ DateTime.utc_now()) do
    since = now |> DateTime.add(-1, :hour) |> time()

    Repo.one(
      from t in "transfer_tries",
        where: t.browser == ^browser and t.at > ^since,
        select: count()
    )
  end

  # One statement marks the code as used, only when it is not used and not
  # old. So two devices cannot both use one code.
  defp use_code(code, now) do
    t = time(now)

    {count, _} =
      Repo.update_all(
        from(c in "transfer_codes",
          where: c.code == ^code and is_nil(c.used_at) and c.expires_at > ^t
        ),
        set: [used_at: t]
      )

    if count == 1 do
      {:ok, Repo.one(from c in "transfer_codes", where: c.code == ^code, select: c.player)}
    else
      :error
    end
  end

  @doc "The code in capital letters, with no spaces and no dashes."
  def normalize(text), do: text |> to_string() |> String.upcase() |> String.replace(~r/[\s-]/, "")

  @doc "The code in two groups of 5, easier to read: `ABCDE-FGHJK`."
  def format(code), do: String.slice(code, 0, 5) <> "-" <> String.slice(code, 5, 5)

  defp time(datetime), do: datetime |> DateTime.truncate(:second) |> DateTime.to_iso8601()
end
