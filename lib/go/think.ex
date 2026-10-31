defmodule Go.Think do
  @moduledoc """
  Runs a search with a time limit, so that a tap never waits long.
  """

  @doc """
  Runs `fun` for at most `ms` milliseconds. Gives `{:ok, result}`, or
  `:timeout` when the time is over. With `:infinity`, it waits for the
  result.
  """
  @spec within(timeout(), (-> term())) :: {:ok, term()} | :timeout
  def within(:infinity, fun), do: {:ok, fun.()}

  def within(ms, fun) do
    task = Task.async(fun)

    case Task.yield(task, ms) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> {:ok, result}
      _ -> :timeout
    end
  end

  @doc "The time limit of a search during play (`:think_ms` in the config)."
  @spec budget() :: timeout()
  def budget, do: Application.get_env(:go, :think_ms, 700)
end
