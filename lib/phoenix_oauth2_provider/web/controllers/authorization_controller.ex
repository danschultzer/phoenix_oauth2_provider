defmodule PhoenixOauth2Provider.AuthorizationController do
  @moduledoc false
  use PhoenixOauth2Provider.Web, :controller

  alias ExOauth2Provider.Authorization
  alias Plug.Conn

  @spec new(Conn.t(), map()) :: Conn.t()
  def new(conn, params) do
    conn
    |> PhoenixOauth2Provider.current_resource_owner()
    |> Authorization.preauthorize(params)
    |> case do
      {:ok, client, scopes} ->
        render(conn, "new.html", params: params, client: client, scopes: scopes)
      {:native_redirect, %{code: code}} ->
        redirect(conn, to: PhoenixOauth2Provider.router_helpers().oauth_authorization_path(conn, :show, code))
      {:redirect, redirect_uri} ->
        redirect(conn, external: redirect_uri)
      {:error, error, status} ->
        conn
        |> put_status(status)
        |> render("error.html", error: error)
    end
  end

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, params) do
    conn
    |> PhoenixOauth2Provider.current_resource_owner()
    |> Authorization.authorize(params)
    |> redirect_or_render(conn)
  end

  @spec delete(Conn.t(), map()) :: Conn.t()
  def delete(conn, params) do
    conn
    |> PhoenixOauth2Provider.current_resource_owner()
    |> Authorization.deny(params)
    |> redirect_or_render(conn)
  end

  @spec show(Conn.t(), map()) :: Conn.t()
  def show(conn, %{"code" => code}) do
    render(conn, "show.html", code: code)
  end

  defp redirect_or_render({:redirect, redirect_uri}, conn) do
    redirect(conn, external: redirect_uri)
  end
  defp redirect_or_render({:native_redirect, payload}, conn) do
    json(conn, payload)
  end
  defp redirect_or_render({:error, error, status}, conn) do
    conn
    |> put_status(status)
    |> json(error)
  end
end
