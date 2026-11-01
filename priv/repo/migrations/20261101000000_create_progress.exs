defmodule Go.Repo.Migrations.CreateProgress do
  use Ecto.Migration

  def change do
    # One value for each player and key (see Go.Progress). The key and the
    # value are Erlang terms (term_to_binary).
    create table(:progress, primary_key: false) do
      add :player, :string, null: false, primary_key: true
      add :key, :binary, null: false, primary_key: true
      add :value, :binary, null: false
    end

    # The attempts, for the leaderboard (later).
    create table(:attempts) do
      add :player, :string, null: false
      add :puzzle_id, :string, null: false
      add :value, :binary, null: false
    end

    create index(:attempts, [:player])
  end
end
