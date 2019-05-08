defmodule PhoenixOauth2Provider.AuthorizedApplicationController do
  @moduledoc false
  use PhoenixOauth2Provider.Controller
  alias ExOauth2Provider.Applications

  @spec index(Conn.t(), map(), map()) :: Conn.t()
  def index(conn, _params, resource_owner) do
    applications = Applications.get_authorized_applications_for(resource_owner)

    render(conn, "index.html", applications: applications)
  end

  @spec delete(Conn.t(), map(), map()) :: Conn.t()
  def delete(conn, %{"uid" => uid}, resource_owner) do
    {:ok, _application} =
      uid
      |> Applications.get_application!()
      |> Applications.revoke_all_access_tokens_for(resource_owner)

    conn
    |> put_flash(:info, "Application revoked.")
    |> redirect(to: Routes.oauth_authorized_application_path(conn, :index))
  end
end
