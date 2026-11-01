defmodule Go.Cache do
  @moduledoc """
  Values that the app makes one time and keeps in `:persistent_term` (the
  library, the bank, the tiers of the runs).

  One process makes a value, under a lock: when many pages start at the
  same time, the others wait and read it. Without the lock, each of them
  made the value and put its own copy, and on WebAssembly the memory of
  the VM (which never shrinks) grew by hundreds of MB (see
  docs/load-test.md).
  """

  @doc """
  The value of `key`; `make` makes it when it is not there yet. A short
  process makes the value and puts it: the garbage of the making (the
  decode of a file) goes away with that process, and is not left in the
  heap of a page.
  """
  def fetch(key, make) do
    case :persistent_term.get(key, :none) do
      :none ->
        :global.trans({{__MODULE__, key}, self()}, fn ->
          if :persistent_term.get(key, :none) == :none do
            Task.async(fn -> :persistent_term.put(key, make.()) end) |> Task.await(:infinity)
          end
        end)

        :persistent_term.get(key)

      value ->
        value
    end
  end
end
