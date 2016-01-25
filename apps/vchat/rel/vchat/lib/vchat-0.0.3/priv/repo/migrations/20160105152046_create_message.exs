defmodule Vchat.Repo.Migrations.CreateMessage do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :from_id, :integer
      add :body, :text
      add :info, :text

      timestamps
    end

    create index(:messages, [:from_id])

  end
end
