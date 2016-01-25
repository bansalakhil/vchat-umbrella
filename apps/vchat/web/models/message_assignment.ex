defmodule Vchat.MessageAssignment do
  use Vchat.Web, :model

  schema "message_assignments" do
    # field :receiver_id, :integer
    field :seen, :boolean, default: false
    # field :message_id, :integer

    timestamps

    belongs_to :receiver, Vchat.User, foreign_key: :receiver_id
    belongs_to :message, Vchat.Message
  end

  @required_fields ~w(receiver_id message_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
