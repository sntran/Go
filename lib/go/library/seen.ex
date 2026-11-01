defmodule Go.Library.Seen do
  @moduledoc """
  The time when the server first saw each version of the library, in
  SQLite (the table `library_versions`). A new version starts daily runs
  only after this time (see `Go.Library.daily_start/2`). The time stays
  after a restart and after a deploy, so it is the time of the first
  deploy with the version.
  """

  import Ecto.Query

  alias Go.{Library, Repo}

  @key {__MODULE__, :first_seen}

  @doc """
  The first time of each version: `%{version => DateTime}`. A version with
  no time gets the time now.
  """
  def all do
    versions = Library.versions()
    Go.Cache.fetch({@key, versions}, fn -> fetch(versions, DateTime.utc_now()) end)
  end

  @doc """
  Stores the time `now` for each version that has no time, and gives the
  time of each version. A time that is in the database stays.
  """
  def fetch(versions, now) do
    now = now |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    rows =
      for v <- versions do
        %{version: v, first_seen: now}
      end

    Repo.insert_all("library_versions", rows, on_conflict: :nothing, conflict_target: [:version])

    from(v in "library_versions",
      where: v.version in ^versions,
      select: {v.version, v.first_seen}
    )
    |> Repo.all()
    |> Map.new(fn {v, time} ->
      {:ok, time, _} = DateTime.from_iso8601(time)
      {v, time}
    end)
  end

  @doc "Removes the times from memory, so that the next call reads the database."
  def reload do
    for {{@key, _} = key, _} <- :persistent_term.get(), do: :persistent_term.erase(key)
    :ok
  end
end
