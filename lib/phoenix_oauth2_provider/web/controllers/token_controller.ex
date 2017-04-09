defmodule PhoenixOauth2Provider.TokenController do
  use PhoenixOauth2Provider.Web, :controller

  alias ExOauth2Provider.Token

  def create(conn, params) do
    case Token.grant(params) do
      {:ok, access_token} ->
        conn
        |> json(access_token)
      {:error, error, status} ->
        conn
        |> put_status(status)
        |> json(error)
    end
  end

  def revoke(conn, params) do
    case Token.revoke(params) do
      {:ok, response} ->
        conn
        |> json(response)
      {:error, error, status} ->
        conn
        |> put_status(status)
        |> json(error)
    end
  end
end
