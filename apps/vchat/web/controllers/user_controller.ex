defmodule Vchat.UserController do
  use Vchat.Web, :controller

  alias Vchat.User

  plug :scrub_params, "user" when action in [:create, :update]

  def index(conn, _params) do
    users = Repo.all(User)
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = User.changeset(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    changeset = User.changeset_for_signup(%User{}, user_params)
    changeset = User.generate_activation_token(changeset)
    case Repo.insert(changeset) do
      {:ok, user} ->
        Vchat.UserMailer.send_account_verification_email(conn, user)
        conn
        |> put_flash(:info, "User created successfully, please verify your email.")
        |> redirect(to: chat_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def activate(conn, %{"t" => t}) do
    user = Repo.get_by!(User, activation_token: t)
    changeset = User.changeset_for_activation(user, %{})
    # changeset
      # |> put_change(:activation_token, nil)    
      # |> put_change(:activated_at, Ecto.DateTime.utc)    
# raise changeset
    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Your account activated successfully.")
        |> redirect(to: chat_path(conn, :index))
      {:error, changeset} ->
        raise changeset.errors
        conn
        |> put_flash(:error, "Can not activate your account, may be invalid URL")
        |> redirect(to: chat_path(conn, :index))
    end      
  end

  # def record_last_activity(user) do
  #   user = Repo.get_by!(User, id: user.id)
  #   changeset = User.record_last_activity(user)
  #   Repo.update(changeset)
  # end

  def find_by_id(user_id) do
    case user_id do
      nil -> nil
      _ -> Repo.get(User, user_id)
    end
  end  

  # def show(conn, %{"id" => id}) do
  #   user = Repo.get!(User, id)
  #   render(conn, "show.html", user: user)
  # end

  # def edit(conn, %{"id" => id}) do
  #   user = Repo.get!(User, id)
  #   changeset = User.changeset(user)
  #   render(conn, "edit.html", user: user, changeset: changeset)
  # end

  # def update(conn, %{"id" => id, "user" => user_params}) do
  #   user = Repo.get!(User, id)
  #   changeset = User.changeset(user, user_params)

  #   case Repo.update(changeset) do
  #     {:ok, user} ->
  #       conn
  #       |> put_flash(:info, "User updated successfully.")
  #       |> redirect(to: user_path(conn, :show, user))
  #     {:error, changeset} ->
  #       render(conn, "edit.html", user: user, changeset: changeset)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   user = Repo.get!(User, id)

  #   # Here we use delete! (with a bang) because we expect
  #   # it to always work (and if it does not, it will raise).
  #   Repo.delete!(user)

  #   conn
  #   |> put_flash(:info, "User deleted successfully.")
  #   |> redirect(to: user_path(conn, :index))
  # end
end
