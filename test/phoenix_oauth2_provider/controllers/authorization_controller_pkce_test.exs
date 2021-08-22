defmodule PhoenixOauth2Provider.AuthorizationControllerPkceTest do
  use PhoenixOauth2Provider.ConnCase

  alias Dummy.{OauthAccessGrants.OauthAccessGrant, Repo}
  alias PhoenixOauth2Provider.Test.Fixtures
  alias Plug.Conn

  @code_challenge "1234567890123456789012345678900123456789012345"

  setup_all %{} do
    new_conf = Application.get_env(:phoenix_oauth2_provider, ExOauth2Provider) ++ [use_pkce: true]
    Application.put_env(:phoenix_oauth2_provider, ExOauth2Provider, new_conf)

    :ok
  end

  setup %{conn: conn} do
    user = Fixtures.user()
    conn = Conn.assign(conn, :current_test_user, user)
    application = Fixtures.application(%{user: user})
    {:ok, conn: conn, user: user, application: application}
  end

  test "create/2 redirects with code_challenge, code_challenge_method", %{
    conn: conn,
    user: %{id: user_id},
    application: application
  } do
    request = valid_request(application, @code_challenge, "plain")
    conn = post(conn, Routes.oauth_authorization_path(conn, :create, request))
    assert redirected_to(conn) == "https://example.com?code=#{last_grant_token()}"

    assert %{
             resource_owner_id: ^user_id,
             code_challenge: @code_challenge,
             code_challenge_method: "plain"
           } = last_grant()
  end

  test "create/2 redirects with code_challenge", %{
    conn: conn,
    user: %{id: user_id},
    application: application
  } do
    request = valid_request(application, @code_challenge)
    conn = post(conn, Routes.oauth_authorization_path(conn, :create, request))
    assert redirected_to(conn) == "https://example.com?code=#{last_grant_token()}"

    assert %{
             resource_owner_id: ^user_id,
             code_challenge: @code_challenge,
             code_challenge_method: "plain"
           } = last_grant()
  end

  test "delete/2 redirects with pkce params", %{conn: conn, application: application} do
    conn = delete(
      conn, Routes.oauth_authorization_path(conn, :delete, valid_request(application, @code_challenge, "plain"))
    )

    assert redirected_to(conn) ==
             "https://example.com?error=access_denied&error_description=The+resource+owner+or+authorization+server+denied+the+request."
  end

  defp valid_request(%{uid: uid}, code_challenge),
    do: %{client_id: uid, response_type: "code", code_challenge: code_challenge}

  defp valid_request(application, code_challenge, code_challenge_method),
    do:
      Map.merge(valid_request(application, code_challenge), %{"code_challenge_method" => code_challenge_method})

  defp last_grant do
    OauthAccessGrant
    |> Repo.all()
    |> List.last()
  end

  defp last_grant_token, do: last_grant().token
end
