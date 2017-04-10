defmodule PhoenixOauth2Provider.ApplicationController do
  @moduledoc false
  use PhoenixOauth2Provider.Web, :controller

  alias ExOauth2Provider.OauthApplications
  import PhoenixOauth2Provider

  def index(conn, _params) do
    applications = OauthApplications.get_applications_for(current_resource_owner(conn))
    render(conn, "index.html", applications: applications)
  end

  def new(conn, _params) do
    changeset = OauthApplications.change_application(%OauthApplications.OauthApplication{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"oauth_application" => application_params}) do
    case OauthApplications.create_application(current_resource_owner(conn), application_params) do
      {:ok, application} ->
        conn
        |> put_flash(:info, "Application created successfully.")
        |> redirect(to: router_helpers().oauth_application_path(conn, :show, application))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"uid" => uid}) do
    application = get_application_for!(conn, uid)
    render(conn, "show.html", application: application)
  end

  def edit(conn, %{"uid" => uid}) do
    application = get_application_for!(conn, uid)
    changeset = OauthApplications.change_application(application)
    render(conn, "edit.html", application: application, changeset: changeset)
  end

  def update(conn, %{"uid" => uid, "oauth_application" => application_params}) do
    application = get_application_for!(conn, uid)

    case OauthApplications.update_application(application, application_params) do
      {:ok, application} ->
        conn
        |> put_flash(:info, "Application updated successfully.")
        |> redirect(to: router_helpers().oauth_application_path(conn, :show, application))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", application: application, changeset: changeset)
    end
  end

  def delete(conn, %{"uid" => uid}) do
    application = get_application_for!(conn, uid)
    {:ok, _application} = OauthApplications.delete_application(application)

    conn
    |> put_flash(:info, "Application deleted successfully.")
    |> redirect(to: router_helpers().oauth_application_path(conn, :index))
  end

  defp get_application_for!(conn, uid) do
    OauthApplications.get_application_for!(current_resource_owner(conn), uid)
  end
end
