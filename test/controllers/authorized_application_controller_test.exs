defmodule PhoenixOauth2Provider.AuthorizedApplicationControllerTest do
  use PhoenixOauth2Provider.Test.ConnCase

  import PhoenixOauth2Provider.Test.Fixture

  setup %{conn: conn} do
    user = fixture(:user)
    application = fixture(:application, %{user: user})

    conn = assign conn, :current_test_user, user

    {:ok, conn: conn, user: user, application: application}
  end

  test "lists all authorized applications on index", %{conn: conn} do
    conn = get conn, oauth_authorized_application_path(conn, :index)
    assert html_response(conn, 200) =~ "Your authorized applications"
  end

  test "deletes chosen authorized application", %{conn: conn, application: application} do
    conn = delete conn, oauth_authorized_application_path(conn, :delete, application)
    assert redirected_to(conn) == oauth_authorized_application_path(conn, :index)
  end
end
