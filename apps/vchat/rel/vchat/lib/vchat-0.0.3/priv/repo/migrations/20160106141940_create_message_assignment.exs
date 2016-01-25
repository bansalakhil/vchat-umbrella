defmodule Vchat.Repo.Migrations.CreateMessageAssignment do
  use Ecto.Migration

  def change do
    create table(:message_assignments) do
      add :receiver_id, :integer
      add :seen, :boolean, default: false
      add :message_id, :integer

      timestamps
    end
    create index(:message_assignments, [:message_id, :receiver_id])
  end
end
