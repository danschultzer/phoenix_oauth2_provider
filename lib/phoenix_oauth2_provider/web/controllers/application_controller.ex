defmodule PhoenixOauth2Provider.ApplicationController do
  @moduledoc false
  use PhoenixOauth2Provider.Web, :controller

  alias ExOauth2Provider.OauthApplications
  alias Plug.Conn

  @spec index(Conn.t(), map()) :: Conn.t()
  def index(conn, _params) do
    applications = conn
                   |> PhoenixOauth2Provider.current_resource_owner()
                   |> OauthApplications.get_applications_for()

    render(conn, "index.html", applications: applications)
  end

  @spec new(Conn.t(), map()) :: Conn.t()
  def new(conn, _params) do
    changeset = OauthApplications.change_application(%OauthApplications.OauthApplication{})

    render(conn, "new.html", changeset: changeset)
  end

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, %{"oauth_application" => application_params}) do
    conn
    |> PhoenixOauth2Provider.current_resource_owner()
    |> OauthApplications.create_application(application_params)
    |> case do
      {:ok, application} ->
        conn
        |> put_flash(:info, "Application created successfully.")
        |> redirect(to: PhoenixOauth2Provider.router_helpers().oauth_application_path(conn, :show, application))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  @spec show(Conn.t(), map()) :: Conn.t()
  def show(conn, %{"uid" => uid}) do
    application = get_application_for!(conn, uid)

    render(conn, "show.html", application: application)
  end

  @spec edit(Conn.t(), map()) :: Conn.t()
  def edit(conn, %{"uid" => uid}) do
    application = get_application_for!(conn, uid)
    changeset = OauthApplications.change_application(application)

    render(conn, "edit.html", application: application, changeset: changeset)
  end

  @spec update(Conn.t(), map()) :: Conn.t()
  def update(conn, %{"uid" => uid, "oauth_application" => application_params}) do
    application = get_application_for!(conn, uid)

    case OauthApplications.update_application(application, application_params) do
      {:ok, application} ->
        conn
        |> put_flash(:info, "Application updated successfully.")
        |> redirect(to: PhoenixOauth2Provider.router_helpers().oauth_application_path(conn, :show, application))
      {:error, %Ecto.Changeset{} = changeset} ->

        render(conn, "edit.html", application: application, changeset: changeset)
    end
  end

  @spec delete(Conn.t(), map()) :: Conn.t()
  def delete(conn, %{"uid" => uid}) do
    {:ok, _application} = conn
                          |> get_application_for!(uid)
                          |> OauthApplications.delete_application()

    conn
    |> put_flash(:info, "Application deleted successfully.")
    |> redirect(to: PhoenixOauth2Provider.router_helpers().oauth_application_path(conn, :index))
  end

  defp get_application_for!(conn, uid) do
    OauthApplications.get_application_for!(PhoenixOauth2Provider.current_resource_owner(conn), uid)
  end
end
