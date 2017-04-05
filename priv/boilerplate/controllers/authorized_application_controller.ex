defmodule PhoenixOauth2Provider.AuthorizedApplicationController do
  use PhoenixOauth2Provider.Web, :controller

  alias ExOauth2Provider.OauthApplications
  import PhoenixOauth2Provider

  def index(conn, _params) do
    applications = OauthApplications.get_authorized_applications_for(current_resource_owner(conn))
    render(conn, "index.html", applications: applications)
  end

  def delete(conn, %{"uid" => uid}) do
    application = OauthApplications.get_application!(uid)
    {:ok, _application} = OauthApplications.revoke_all_access_tokens_for(application, current_resource_owner(conn))

    conn
    |> put_flash(:info, "Application revoked.")
    |> redirect(to: router_helpers().oauth_authorized_application_path(conn, :index))
  end
end
