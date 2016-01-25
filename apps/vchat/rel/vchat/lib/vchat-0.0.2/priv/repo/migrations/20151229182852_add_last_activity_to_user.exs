defmodule Vchat.Repo.Migrations.AddLastActivityToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :last_activity_at, :datetime
      add :online, :boolean, default: false
    end
  end
end

