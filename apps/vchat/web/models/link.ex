defmodule Vchat.Link do
  use Vchat.Web, :model

  schema "links" do
    field :url, :string
    field :title, :string
    field :description, :string
    belongs_to :message, Vchat.Message

    timestamps
  end

  @required_fields ~w(url )
  @optional_fields ~w(title description)

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
