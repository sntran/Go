defmodule Go.TransferTest do
  use ExUnit.Case, async: true

  alias Go.Transfer

  defp player, do: "test-transfer-#{System.unique_integer([:positive])}"

  test "a code has 10 characters of the alphabet of the run codes" do
    {code, _} = Transfer.create(player())
    assert String.length(code) == 10
    assert code |> to_charlist() |> Enum.all?(&(&1 in Go.Runs.alphabet()))
    assert Transfer.format(code) =~ ~r/^\w{5}-\w{5}$/
  end

  test "a correct code gives the player, one time only" do
    owner = player()
    {code, _} = Transfer.create(owner)
    other = player()

    # Small letters, spaces and the dash of the shown code are allowed.
    typed = code |> Transfer.format() |> String.downcase()
    assert Transfer.redeem(" #{typed} ", other) == {:ok, owner}

    # A used code does not work again.
    assert Transfer.redeem(code, player()) == {:error, :wrong}
  end

  test "a code works for 24 hours" do
    owner = player()
    now = ~U[2026-11-02 10:00:00Z]
    {code, expires} = Transfer.create(owner, now)
    assert expires == ~U[2026-11-03 10:00:00Z]

    assert Transfer.redeem(code, player(), ~U[2026-11-03 10:00:01Z]) == {:error, :wrong}
    assert Transfer.redeem(code, player(), ~U[2026-11-03 09:59:00Z]) == {:ok, owner}
  end

  test "a wrong code does not work" do
    assert Transfer.redeem("AAAAAAAAAA", player()) == {:error, :wrong}
    assert Transfer.redeem("", player()) == {:error, :wrong}
  end

  test "a browser can type at most 5 wrong codes in one hour" do
    browser = player()
    owner = player()
    now = ~U[2026-11-02 10:00:00Z]
    {code, _} = Transfer.create(owner, now)

    for k <- 1..5 do
      assert Transfer.redeem("WRONG#{k}2345", browser, DateTime.add(now, k, :minute)) ==
               {:error, :wrong}
    end

    # Now even the correct code does not work, for this browser.
    assert Transfer.redeem(code, browser, DateTime.add(now, 10, :minute)) ==
             {:error, :too_many_tries}

    assert Transfer.tries(browser, DateTime.add(now, 10, :minute)) == 5

    # Another browser can still use it, and this browser can try again
    # one hour after its first wrong code.
    later = DateTime.add(now, 61, :minute)
    assert Transfer.tries(browser, later) == 4
    assert Transfer.redeem(code, browser, later) == {:ok, owner}
  end
end
