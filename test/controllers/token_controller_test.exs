defmodule PhoenixOauth2Provider.TokenControllerTest do
  use PhoenixOauth2Provider.Test.ConnCase

  import PhoenixOauth2Provider.Test.Fixture
  import Ecto.Query

  def valid_request(%{uid: app_uid, secret: app_secret, redirect_uri: app_redirect_uri}, %{token: access_grant_token}) do
    %{client_id: app_uid,
      client_secret: app_secret,
      grant_type: "authorization_code",
      redirect_uri: app_redirect_uri,
      code: access_grant_token}
  end
  def valid_request(%{uid: app_uid, secret: app_secret, redirect_uri: app_redirect_uri}) do
    %{client_id: app_uid,
      client_secret: app_secret,
      grant_type: "client_credentials"}
  end

  def last_access_token do
    ExOauth2Provider.repo.one(from x in ExOauth2Provider.OauthAccessTokens.OauthAccessToken,
      order_by: [desc: x.id], limit: 1).token
  end

  setup %{conn: conn} do
    application = fixture(:application, %{user: fixture(:user)})

    {:ok, conn: conn, application: application}
  end

  describe "as client_credentials strategy" do
    test "create/2", %{conn: conn, application: application} do
      request = valid_request(application)
      conn = post conn, oauth_token_path(conn, :create, request)

      body = json_response(conn, 200)
      assert last_access_token() == body["access_token"]
      assert nil == body["refresh_token"]
    end
  end

  describe "as authorization_code strategy" do
    setup %{conn: conn, application: application} do
      user = fixture(:user)
      access_grant = fixture(:access_grant, %{user: user, application: application})
      request = valid_request(application, access_grant)

      {:ok, conn: conn, user: user, application: application, access_grant: access_grant, request: request}
    end

    test "create/2", %{conn: conn, request: request} do
      conn = post conn, oauth_token_path(conn, :create, request)
      body = json_response(conn, 200)
      assert last_access_token() == body["access_token"]
    end

    test "create/2 with error", %{conn: conn, request: request} do
      conn = post conn, oauth_token_path(conn, :create), Map.merge(request, %{redirect_uri: "invalid"})
      body = json_response(conn, 422)
      assert "The provided authorization grant is invalid, expired, revoked, does not match the redirection URI used in the authorization request, or was issued to another client." == body["error_description"]
    end
  end
end
