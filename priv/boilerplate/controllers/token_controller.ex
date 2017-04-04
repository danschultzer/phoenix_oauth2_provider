defmodule PhoenixOauth2Provider.TokenController do
  use PhoenixOauth2Provider.Web, :controller

  alias ExOauth2Provider.Authorization.Grant
  import PhoenixOauth2Provider

  def create(conn, params) do
    case Grant.authorize(params) do
      {:ok, access_token} ->
        conn
        |> put_resp_content_type("text/json")
        |> json(access_token)
      {:error, error, status} ->
        conn
        |> put_resp_content_type("text/json")
        |> put_status(status)
        |> json(error)
    end
  end
end
