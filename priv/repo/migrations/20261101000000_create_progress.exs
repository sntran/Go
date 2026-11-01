defmodule Go.Repo.Migrations.CreateProgress do
  use Ecto.Migration

  def change do
    # One value for each player and key (see Go.Progress). The key is text
    # (inspect/1 of the term), and the value is an Erlang term
    # (term_to_binary/1) in Base64: the SQLite of beam.com on Workers takes
    # only text and numbers.
    create table(:progress, primary_key: false) do
      add :player, :string, null: false, primary_key: true
      add :key, :string, null: false, primary_key: true
      add :value, :text, null: false
    end

    # The attempts, for the leaderboard (later).
    create table(:attempts) do
      add :player, :string, null: false
      add :puzzle_id, :string, null: false
      add :value, :text, null: false
    end

    create index(:attempts, [:player])
  end
end
