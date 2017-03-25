defmodule ExOauth2Phoenix.AuthorizationController do
  use ExOauth2Phoenix.Web, :controller

  alias ExOauth2Provider.Grant.AuthorizationCode
  import ExOauth2Phoenix

  def new(conn, params) do
    case AuthorizationCode.preauthorize(current_resource_owner(conn), params) do
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
    AuthorizationCode.authorize(current_resource_owner(conn), params)
    |> redirect_or_render(conn)
  end

  def delete(conn, params) do
    AuthorizationCode.deny(current_resource_owner(conn), params)
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
    |> put_resp_content_type("text/json")
    |> put_status(status)
    |> json(error)
  end
end
