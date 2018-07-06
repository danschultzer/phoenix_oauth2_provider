defmodule PhoenixOauth2Provider.AuthorizedApplicationController do
  @moduledoc false
  use PhoenixOauth2Provider.Web, :controller
  alias ExOauth2Provider.OauthApplications

  def index(conn, _params) do
    applications = conn
                   |> PhoenixOauth2Provider.current_resource_owner()
                   |> OauthApplications.get_authorized_applications_for()

                   render(conn, "index.html", applications: applications)
  end

  def delete(conn, %{"uid" => uid}) do
    application = OauthApplications.get_application!(uid)
    {:ok, _application} = OauthApplications.revoke_all_access_tokens_for(application, PhoenixOauth2Provider.current_resource_owner(conn))

    conn
    |> put_flash(:info, "Application revoked.")
    |> redirect(to: PhoenixOauth2Provider.router_helpers().oauth_authorized_application_path(conn, :index))
  end
end
