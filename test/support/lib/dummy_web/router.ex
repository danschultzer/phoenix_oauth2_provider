defmodule DummyWeb.Router do
  use Phoenix.Router
  use PhoenixOauth2Provider.Router, otp_app: :phoenix_oauth2_provider

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    oauth_api_routes()
  end

  scope "/" do
    pipe_through :browser

    oauth_routes()
  end
end
