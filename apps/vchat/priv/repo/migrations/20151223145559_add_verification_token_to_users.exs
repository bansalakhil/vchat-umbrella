defmodule Vchat.Repo.Migrations.AddVerificationTokenToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :activation_token, :string
      add :activated_at, :datetime
    end
  end
end
