defmodule Vchat.Repo.Migrations.AddUniqueIndexOnEmailAndUsername do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
  end
end
