defmodule Vchat.User do
  use Vchat.Web, :model
  
  # use Comeonin for password encryption 
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  # before_insert :generate_activation_token
  alias Vchat.User

  schema "users" do
    field :name, :string
    field :username, :string
    field :email, :string
    field :password_digest, :string
    field :activation_token, :string
    field :activated_at, Ecto.DateTime
    field :last_activity_at, Ecto.DateTime
    field :online, :boolean, default: false

    #virtual fields
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    has_many :sent_messages, Vchat.Message, foreign_key: :from_id
    has_many :message_assignments, Vchat.MessageAssignment, foreign_key: :receiver_id
    has_many :received_messages, through: [:message_assignments, :message]

    timestamps
  end

  @required_fields ~w(name username email password password_confirmation)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset_for_signup(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> common_validations
    |> validate_confirmation(:password)
    |> validate_length(:password, min: 6)
    |> validate_length(:password_confirmation, min: 6)
    |> hash_password
  end  

  def changeset_for_activation(model, params \\ :empty) do
    model
    |> cast(params, [])
    |> put_change(:activation_token, nil)
    |> put_change(:activated_at,  Ecto.DateTime.utc)
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> common_validations
  end  

  def active(query \\ User) do
    from u in query,
    where: is_nil(u.activation_token) and not is_nil(u.activated_at) 
  end

  def activated?(user) do
    is_nil(user.activation_token) && !is_nil(user.activated_at)
  end

  def record_last_activity(model) do
    model
        |> cast(%{}, [], [])
        |> put_change(:last_activity_at, Ecto.DateTime.utc)
        |> force_change(:online, true)
  end

  def mark_offline(model) do
    model
        |> cast(%{}, [])
        |> put_change(:last_activity_at, Ecto.DateTime.utc)
        |> force_change(:online, false)
  end


  def generate_activation_token(changeset) do
    length = 32
    random_string = :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
    changeset = put_change(changeset, :activation_token, random_string)
  end

  defp common_validations(changeset) do
    changeset
    |> validate_length(:username, min: 2)
    |> validate_format(:username, ~r(\A[a-z0-9A-Z]+\Z), message: "can be alphanumeric only")
    |> validate_length(:name, min: 2)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end



  defp hash_password(changeset) do
    if password = get_change(changeset, :password) do
      # if password is changed. Then set password_digest using comeonin
      changeset
        |> put_change(:password_digest, hashpwsalt(password))
      
    # dont do anything if password is not changed
    else
      changeset
    end
  end
end
