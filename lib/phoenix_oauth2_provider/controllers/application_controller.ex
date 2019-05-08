defmodule PhoenixOauth2Provider.ApplicationController do
  @moduledoc false
  use PhoenixOauth2Provider.Controller

  alias ExOauth2Provider.Applications
  alias Plug.Conn

  @spec index(Conn.t(), map(), map()) :: Conn.t()
  def index(conn, _params, resource_owner) do
    applications = Applications.get_applications_for(resource_owner)

    render(conn, "index.html", applications: applications)
  end

  @spec new(Conn.t(), map(), map()) :: Conn.t()
  def new(conn, _params, _resource_owner) do
    changeset =
      ExOauth2Provider.Config.application([])
      |> struct()
      |> Applications.change_application()

    render(conn, "new.html", changeset: changeset)
  end

  @spec create(Conn.t(), map(), map()) :: Conn.t()
  def create(conn, %{"oauth_application" => application_params}, resource_owner) do
    resource_owner
    |> Applications.create_application(application_params)
    |> case do
      {:ok, application} ->
        conn
        |> put_flash(:info, "Application created successfully.")
        |> redirect(to: Routes.oauth_application_path(conn, :show, application))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  @spec show(Conn.t(), map(), map()) :: Conn.t()
  def show(conn, %{"uid" => uid}, resource_owner) do
    application = get_application_for!(resource_owner, uid)

    render(conn, "show.html", application: application)
  end

  @spec edit(Conn.t(), map(), map()) :: Conn.t()
  def edit(conn, %{"uid" => uid}, resource_owner) do
    application = get_application_for!(resource_owner, uid)
    changeset   = Applications.change_application(application)

    render(conn, "edit.html", application: application, changeset: changeset)
  end

  @spec update(Conn.t(), map(), map()) :: Conn.t()
  def update(conn, %{"uid" => uid, "oauth_application" => application_params}, resource_owner) do
    application = get_application_for!(resource_owner, uid)

    case Applications.update_application(application, application_params) do
      {:ok, application} ->
        conn
        |> put_flash(:info, "Application updated successfully.")
        |> redirect(to: Routes.oauth_application_path(conn, :show, application))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", application: application, changeset: changeset)
    end
  end

  @spec delete(Conn.t(), map(), map()) :: Conn.t()
  def delete(conn, %{"uid" => uid}, resource_owner) do
    {:ok, _application} =
      resource_owner
      |> get_application_for!(uid)
      |> Applications.delete_application()

    conn
    |> put_flash(:info, "Application deleted successfully.")
    |> redirect(to: Routes.oauth_application_path(conn, :index))
  end

  defp get_application_for!(resource_owner, uid) do
    Applications.get_application_for!(resource_owner, uid)
  end
end
