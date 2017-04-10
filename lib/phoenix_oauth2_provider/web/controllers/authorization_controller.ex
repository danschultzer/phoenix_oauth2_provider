defmodule PhoenixOauth2Provider.AuthorizationController do
  @moduledoc false
  use PhoenixOauth2Provider.Web, :controller

  alias ExOauth2Provider.Authorization
  import PhoenixOauth2Provider

  def new(conn, params) do
    case Authorization.preauthorize(current_resource_owner(conn), params) do
      {:ok, client, scopes} ->
        render(conn, "new.html", params: params, client: client, scopes: scopes)
      {:native_redirect, %{code: code}} ->
        redirect(conn, to: router_helpers().oauth_authorization_path(conn, :show, code))
      {:redirect, redirect_uri} ->
        redirect(conn, external: redirect_uri)
      {:error, error, status} ->
        conn
        |> put_status(status)
        |> render("error.html", error: error)
    end
  end

  def create(conn, params) do
    conn
    |> current_resource_owner
    |> Authorization.authorize(params)
    |> redirect_or_render(conn)
  end

  def delete(conn, params) do
    conn
    |> current_resource_owner
    |> Authorization.deny(params)
    |> redirect_or_render(conn)
  end

  def show(conn, %{"code" => code}) do
    render(conn, "show.html", code: code)
  end

  defp redirect_or_render({:redirect, redirect_uri}, conn) do
    redirect(conn, external: redirect_uri)
  end
  defp redirect_or_render({:native_redirect, payload}, conn) do
    json conn, payload
  end
  defp redirect_or_render({:error, error, status}, conn) do
    conn
    |> put_status(status)
    |> json(error)
  end
end
