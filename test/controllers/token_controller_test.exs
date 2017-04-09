defmodule PhoenixOauth2Provider.TokenControllerTest do
  use PhoenixOauth2Provider.Test.ConnCase

  import PhoenixOauth2Provider.Test.Fixture
  import Ecto.Query

  def last_access_token do
    ExOauth2Provider.repo.one(from x in ExOauth2Provider.OauthAccessTokens.OauthAccessToken,
      order_by: [desc: x.id], limit: 1).token
  end

  setup %{conn: conn} do
    application = fixture(:application, %{user: fixture(:user)})

    {:ok, conn: conn, application: application}
  end

  describe "with authorization_code strategy" do
    setup %{conn: conn, application: application} do
      user = fixture(:user)
      access_grant = fixture(:access_grant, %{user: user, application: application})
      request = %{client_id: application.uid,
                  client_secret: application.secret,
                  grant_type: "authorization_code",
                  redirect_uri: application.redirect_uri,
                  code: access_grant.token}

      {:ok, conn: conn,  request: request}
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

  describe "as client_credentials strategy" do
    setup %{conn: conn, application: application} do
      request = %{client_id: application.uid,
                  client_secret: application.secret,
                  grant_type: "client_credentials"}

      {:ok, conn: conn,  request: request}
    end

    test "create/2", %{conn: conn, request: request} do
      conn = post conn, oauth_token_path(conn, :create, request)

      body = json_response(conn, 200)
      assert last_access_token() == body["access_token"]
      assert is_nil(body["refresh_token"])
    end

    test "create/2 with error", %{conn: conn, request: request} do
      conn = post conn, oauth_token_path(conn, :create, Map.merge(request, %{client_id: "invalid"}))
      body = json_response(conn, 422)
      assert "Client authentication failed due to unknown client, no client authentication included, or unsupported authentication method." == body["error_description"]
    end
  end

  describe "as refresh_token strategy" do
    setup %{conn: conn, application: application} do
      user = fixture(:user)
      access_token = fixture(:access_token, %{application: application, user: user, use_refresh_token: true})
      request = %{client_id: application.uid,
                  client_secret: application.secret,
                  grant_type: "refresh_token",
                  refresh_token: access_token.refresh_token}

      {:ok, conn: conn,  request: request}
    end

    test "create/2", %{conn: conn, request: request} do
      conn = post conn, oauth_token_path(conn, :create, request)

      body = json_response(conn, 200)
      assert last_access_token() == body["access_token"]
      refute is_nil(body["refresh_token"])
    end

    test "create/2 with error", %{conn: conn, request: request} do
      conn = post conn, oauth_token_path(conn, :create, Map.merge(request, %{client_id: "invalid"}))
      body = json_response(conn, 422)
      assert "Client authentication failed due to unknown client, no client authentication included, or unsupported authentication method." == body["error_description"]
    end
  end

  describe "with revocation strategy" do
    setup %{conn: conn, application: application} do
      user = fixture(:user)
      access_token = fixture(:access_token, %{application: application, user: user})
      request = %{client_id: application.uid,
                  client_secret: application.secret,
                  token: access_token.token}

      {:ok, conn: conn,  request: request}
    end

    test "revoke/2", %{conn: conn, request: request} do
      conn = post conn, oauth_token_path(conn, :revoke, request)
      body = json_response(conn, 200)
      assert body == %{}
      assert ExOauth2Provider.OauthAccessTokens.is_revoked?(last_access_token())
    end

    test "revoke/2 with invalid token", %{conn: conn, request: request} do
      conn = post conn, oauth_token_path(conn, :revoke, Map.merge(request, %{token: "invalid"}))
      body = json_response(conn, 200)
      assert body == %{}
    end
  end
end
