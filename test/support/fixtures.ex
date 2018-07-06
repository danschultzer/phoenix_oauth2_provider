defmodule PhoenixOauth2Provider.Test.Fixtures do
  @moduledoc false

  alias PhoenixOauth2Provider.Test.{Repo, User}
  alias ExOauth2Provider.{Config,
                          OauthAccessTokens,
                          OauthAccessTokens.OauthAccessToken,
                          OauthAccessGrants,
                          OauthAccessGrants.OauthAccessGrant,
                          OauthApplications,
                          OauthApplications.OauthApplication}

  @spec user :: User.t()
  def user do
    %User{}
    |> User.changeset(%{email: "user@example.com"})
    |> Repo.insert!()
  end

  @spec application(map()) :: OauthApplication.t()
  def application(%{user: user} = attrs) do
    attrs = Map.merge(%{name: "Example", redirect_uri: "https://example.com"}, attrs)
    {:ok, application} = OauthApplications.create_application(user, attrs)

    application
  end

  @spec access_token(map()) :: OauthAccessToken.t()
  def access_token(%{application: application, user: user} = attrs) do
    attrs = %{redirect_uri: application.redirect_uri,
              application: application}
            |> Map.merge(attrs)

    {:ok, access_token} = OauthAccessTokens.create_token(user, attrs)

    access_token
  end

  @spec access_grant(map()) :: OauthAccessGrant.t()
  def access_grant(%{application: application, user: user} = attrs) do
    attrs = %{redirect_uri: application.redirect_uri,
              expires_in: Config.authorization_code_expires_in()}
            |> Map.merge(attrs)

    {:ok, access_token} = OauthAccessGrants.create_grant(user, application, attrs)

    access_token
  end
end
