defmodule TwitterRetargetingWeb.Router do
  use TwitterRetargetingWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug TwitterRetargeting.Auth, repo: TwitterRetargeting.Repo
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TwitterRetargetingWeb do
    pipe_through :browser

    get "/", PageController, :index
    resources "/user", UserController, only: [:new, :create] #, :edit, :update]
    resources "/session", SessionController, only: [:new, :create, :delete]
    resources "/twitter_oauth", TwitterOauthController, only: [:create]
    get "/twitter_oauth/callback", TwitterOauthController, :register_callback
    resources "/task", TaskController, only: [:new, :create, :show]
  end

  # Other scopes may use custom stacks.
  # scope "/api", TwitterRetargetingWeb do
  #   pipe_through :api
  # end
end
