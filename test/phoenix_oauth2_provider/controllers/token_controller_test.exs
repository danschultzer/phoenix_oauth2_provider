defmodule PhoenixOauth2Provider.TokenControllerTest do
  use PhoenixOauth2Provider.ConnCase

  alias Dummy.Repo
  alias PhoenixOauth2Provider.Test.Fixtures
  alias ExOauth2Provider.AccessTokens
  alias Dummy.OauthAccessTokens.OauthAccessToken

  setup %{conn: conn} do
    application = Fixtures.application(%{user: Fixtures.user()})

    {:ok, conn: conn, application: application}
  end

  describe "with authorization_code strategy" do
    setup %{conn: conn, application: application} do
      user = Fixtures.user()
      access_grant = Fixtures.access_grant(%{user: user, application: application})
      request = %{client_id: application.uid,
                  client_secret: application.secret,
                  grant_type: "authorization_code",
                  redirect_uri: application.redirect_uri,
                  code: access_grant.token}

      {:ok, conn: conn,  request: request}
    end

    test "create/2", %{conn: conn, request: request} do
      conn = post conn, Routes.oauth_token_path(conn, :create, request)
      body = json_response(conn, 200)
      assert last_access_token() == body["access_token"]
    end

    test "create/2 with error", %{conn: conn, request: request} do
      conn = post conn, Routes.oauth_token_path(conn, :create), Map.merge(request, %{redirect_uri: "invalid"})
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
      conn = post conn, Routes.oauth_token_path(conn, :create, request)

      body = json_response(conn, 200)
      assert last_access_token() == body["access_token"]
      assert is_nil(body["refresh_token"])
    end

    test "create/2 with error", %{conn: conn, request: request} do
      conn = post conn, Routes.oauth_token_path(conn, :create, Map.merge(request, %{client_id: "invalid"}))
      body = json_response(conn, 422)
      assert "Client authentication failed due to unknown client, no client authentication included, or unsupported authentication method." == body["error_description"]
    end
  end

  describe "as refresh_token strategy" do
    setup %{conn: conn, application: application} do
      user = Fixtures.user()
      access_token = Fixtures.access_token(%{application: application, user: user, use_refresh_token: true})
      request = %{client_id: application.uid,
                  client_secret: application.secret,
                  grant_type: "refresh_token",
                  refresh_token: access_token.refresh_token}

      {:ok, conn: conn,  request: request}
    end

    test "create/2", %{conn: conn, request: request} do
      conn = post conn, Routes.oauth_token_path(conn, :create, request)

      body = json_response(conn, 200)
      assert last_access_token() == body["access_token"]
      refute is_nil(body["refresh_token"])
    end

    test "create/2 with error", %{conn: conn, request: request} do
      conn = post conn, Routes.oauth_token_path(conn, :create, Map.merge(request, %{client_id: "invalid"}))
      body = json_response(conn, 422)
      assert "Client authentication failed due to unknown client, no client authentication included, or unsupported authentication method." == body["error_description"]
    end
  end

  describe "with revocation strategy" do
    setup %{conn: conn, application: application} do
      user = Fixtures.user()
      access_token = Fixtures.access_token(%{application: application, user: user})
      request = %{client_id: application.uid,
                  client_secret: application.secret,
                  token: access_token.token}

      {:ok, conn: conn,  request: request}
    end

    test "revoke/2", %{conn: conn, request: request} do
      conn = post conn, Routes.oauth_token_path(conn, :revoke, request)
      body = json_response(conn, 200)
      assert body == %{}
      assert AccessTokens.is_revoked?(last_access_token())
    end

    test "revoke/2 with invalid token", %{conn: conn, request: request} do
      conn = post conn, Routes.oauth_token_path(conn, :revoke, Map.merge(request, %{token: "invalid"}))
      body = json_response(conn, 200)
      assert body == %{}
    end
  end

  defp last_access_token do
    OauthAccessToken
    |> Repo.all()
    |> List.last()
    |> Map.get(:token)
  end

  describe "with introspection strategy" do
    setup %{conn: conn, application: application} do
      user = Fixtures.user()
      access_token = Fixtures.access_token(%{application: application, user: user, use_refresh_token: true})
      request = %{client_id: application.uid,
                  client_secret: application.secret,
                  token: access_token.token}

      {:ok, conn: conn, request: request, access_token: access_token}
    end

    test "introspect/2 with access token", %{conn: conn, request: request, access_token: access_token} do
      conn = post conn, Routes.oauth_token_path(conn, :introspect, request)
      body = json_response(conn, 200)
      assert %{"active" => true, "scope" => actual_scopes} = body
      assert actual_scopes == access_token.scopes
    end

    test "introspect/2 with refresh token", %{conn: conn, request: request, access_token: access_token} do
      IO.inspect(conn)
      conn = post conn, Routes.oauth_token_path(conn, :introspect, Map.merge(request, %{token: access_token.refresh_token}))
      body = json_response(conn, 200)
      assert %{"active" => true} = body
    end

    test "introspect/2 with invalid token", %{conn: conn, request: request} do
      conn = post conn, Routes.oauth_token_path(conn, :introspect, Map.merge(request, %{token: "invalid"}))
      body = json_response(conn, 200)
      assert body == %{"active" => false}
    end
  end
end
