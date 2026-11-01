defmodule Go.Repo.Migrations.CreateLibraryVersions do
  use Ecto.Migration

  def change do
    # The time when the server first saw each version of the library (see
    # Go.Library.Seen), as ISO 8601 text.
    create table(:library_versions, primary_key: false) do
      add :version, :integer, primary_key: true
      add :first_seen, :string, null: false
    end
  end
end
