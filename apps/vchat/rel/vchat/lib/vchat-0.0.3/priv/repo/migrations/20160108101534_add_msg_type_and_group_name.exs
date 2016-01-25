defmodule Vchat.Repo.Migrations.AddMsgTypeAndGroupName do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :msg_type, :string
      add :group_name, :string
    end
  end
end
