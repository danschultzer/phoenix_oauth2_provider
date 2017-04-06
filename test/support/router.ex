defmodule PhoenixOauth2Provider.Test.Router do
  use Phoenix.Router
  use PhoenixOauth2Provider.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    oauth_routes :public
  end

  scope "/" do
    pipe_through :browser
    oauth_routes :protected
  end
end
