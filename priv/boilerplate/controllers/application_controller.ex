defmodule ExOauth2Phoenix.ApplicationController do
  use ExOauth2Phoenix.Web, :controller

  alias ExOauth2Provider.OauthApplications
  import ExOauth2Phoenix

  def index(conn, _params) do
    applications = OauthApplications.list_applications()
    render(conn, "index.html", applications: applications)
  end

  def new(conn, _params) do
    changeset = OauthApplications.change_application(%OauthApplications.OauthApplication{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"application" => application_params}) do
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
    application = OauthApplications.get_application!(uid)
    render(conn, "show.html", application: application)
  end

  def edit(conn, %{"uid" => uid}) do
    application = OauthApplications.get_application!(uid)
    changeset = OauthApplications.change_application(application)
    render(conn, "edit.html", application: application, changeset: changeset)
  end

  def update(conn, %{"uid" => uid, "application" => application_params}) do
    application = OauthApplications.get_application!(uid)

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
    application = OauthApplications.get_application!(uid)
    {:ok, _application} = OauthApplications.delete_application(application)

    conn
    |> put_flash(:info, "Application deleted successfully.")
    |> redirect(to: router_helpers().oauth_application_path(conn, :index))
  end
end
