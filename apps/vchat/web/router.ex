defmodule Vchat.Router do
  use Vchat.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_current_user
  end

  pipeline :auth do
    plug :authenticate
  end  

  pipeline :anon do
    plug :anonymous
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Vchat do
    pipe_through [:browser, :anon] # Use the default browser stack

    resources "/users", UserController, only: [:index, :new, :create]
    resources "/sessions", SessionController, only: [:new, :create]
    
    get "users/activate/:t", UserController, :activate
  end

  scope "/", Vchat do
    pipe_through [:browser, :auth]  # Use the default browser stack

    resources "/sessions", SessionController, only: [:delete]
    resources "/chat", ChatController, only: [:index]
    get "/", ChatController, :index
    
  end



  # Fetch the current user from the session and add it to `conn.assigns`. This
  # will allow you to have access to the current user in your views with
  # `@current_user`.
  defp assign_current_user(conn, _) do
    user_id = get_session(conn, :current_user)
    assign(conn, :current_user, Vchat.UserController.find_by_id(user_id))
  end

  defp authenticate(conn, _) do
    current_user_id = get_session(conn, :current_user)
    current_user = Vchat.UserController.find_by_id(current_user_id)
    if current_user do
      assign(conn, :current_user, current_user)
      token = Phoenix.Token.sign(conn, "user socket", current_user.id)
      assign(conn, :user_token, token)      
    else
      conn
        |> put_flash(:error, 'You need to be signed in to view this page')
        |> redirect(to: "/sessions/new")
        |> halt()
    end    
  end


  defp anonymous(conn, _) do
    current_user_id = get_session(conn, :current_user)
    if current_user_id do
      conn
        |> put_flash(:error, 'You are already logged in.')
        |> redirect(to: "/")
        |> halt()
    else
      conn
    end    
  end  

  # Other scopes may use custom stacks.
  # scope "/api", Vchat do
  #   pipe_through :api
  # end
end
