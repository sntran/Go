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

  @doc "The value of `key`; `make` makes it when it is not there yet."
  def fetch(key, make) do
    case :persistent_term.get(key, :none) do
      :none ->
        :global.trans({{__MODULE__, key}, self()}, fn ->
          case :persistent_term.get(key, :none) do
            :none ->
              value = make.()
              :persistent_term.put(key, value)
              value

            value ->
              value
          end
        end)

      value ->
        value
    end
  end
end
