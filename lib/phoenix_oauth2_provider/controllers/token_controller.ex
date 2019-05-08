defmodule PhoenixOauth2Provider.TokenController do
  @moduledoc false
  use PhoenixOauth2Provider.Controller, :api

  alias ExOauth2Provider.Token

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, params) do
    params
    |> Token.grant()
    |> case do
      {:ok, access_token} ->
        json(conn, access_token)

      {:error, error, status} ->
        conn
        |> put_status(status)
        |> json(error)
    end
  end

  @spec revoke(Conn.t(), map()) :: Conn.t()
  def revoke(conn, params) do
    params
    |> Token.revoke()
    |> case do
      {:ok, response} ->
        json(conn, response)

      {:error, error, status} ->
        conn
        |> put_status(status)
        |> json(error)
    end
  end
end
