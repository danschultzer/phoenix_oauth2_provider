defmodule PhoenixOauth2Provider.Test.Fixtures do
  @moduledoc false

  alias Dummy.Repo
  alias ExOauth2Provider.{AccessGrants, AccessTokens, Applications, Config}
  alias Dummy.Users.User
  alias Ecto.Changeset

  def user do
    User
    |> struct()
    |> Changeset.change(%{email: "user@example.com"})
    |> Repo.insert!()
  end

  def application(%{user: user} = attrs \\ []) do
    attrs = Map.merge(%{name: "Example", redirect_uri: "https://example.com"}, attrs)
    {:ok, application} = Applications.create_application(user, attrs)

    application
  end

  def access_token(%{application: application, user: user} = attrs) do
    attrs = Map.put_new(attrs, :redirect_uri, application.redirect_uri)

    {:ok, access_token} = AccessTokens.create_token(user, attrs)

    access_token
  end

  def access_grant(%{application: application, user: user} = attrs) do
    attrs  =
      attrs
      |> Map.put_new(:redirect_uri, application.redirect_uri)
      |> Map.put_new(:expires_in, Config.authorization_code_expires_in([]))

    {:ok, access_token} = AccessGrants.create_grant(user, application, attrs)

    access_token
  end
end
