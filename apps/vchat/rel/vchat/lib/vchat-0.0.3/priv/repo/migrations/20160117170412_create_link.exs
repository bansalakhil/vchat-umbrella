defmodule Vchat.Repo.Migrations.CreateLink do
  use Ecto.Migration

  def change do
    create table(:links) do
      add :url, :string
      add :title, :string
      add :description, :text
      add :message_id, references(:messages, on_delete: :nothing)

      timestamps
    end
    create index(:links, [:message_id])

  end
end
