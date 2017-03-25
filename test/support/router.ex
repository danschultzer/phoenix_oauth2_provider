defmodule ExOauth2Phoenix.Test.Router do
  use Phoenix.Router
  use ExOauth2Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser
    oauth_routes()
  end
end
