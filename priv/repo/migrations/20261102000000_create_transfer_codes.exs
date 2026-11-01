defmodule Go.Repo.Migrations.CreateTransferCodes do
  use Ecto.Migration

  def change do
    # The codes that move the progress of a player to another device (see
    # Go.Transfer). The times are ISO 8601 text in UTC.
    create table(:transfer_codes, primary_key: false) do
      add :code, :string, primary_key: true
      add :player, :string, null: false
      add :expires_at, :string, null: false
      add :used_at, :string
    end

    # The wrong codes of each browser, for the limit of tries.
    create table(:transfer_tries) do
      add :browser, :string, null: false
      add :at, :string, null: false
    end

    create index(:transfer_tries, [:browser, :at])
  end
end
