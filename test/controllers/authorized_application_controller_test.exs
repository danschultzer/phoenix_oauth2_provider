defmodule PhoenixOauth2Provider.AuthorizedApplicationControllerTest do
  use PhoenixOauth2Provider.Test.ConnCase
  alias PhoenixOauth2Provider.Test.Fixtures

  setup %{conn: conn} do
    user = Fixtures.user()
    application = Fixtures.application(%{user: user})

    conn = assign conn, :current_test_user, user

    {:ok, conn: conn, user: user, application: application}
  end

  test "lists all authorized applications on index", %{conn: conn, user: user} do
    application1 = Fixtures.application(%{user: Fixtures.user(), name: "Application 1"})
    Fixtures.access_token(%{application: application1, user: user})
    application2 = Fixtures.application(%{user: Fixtures.user(), name: "Application 2"})
    Fixtures.access_token(%{application: application2, user: user})
    application3 = Fixtures.application(%{user: Fixtures.user(), name: "Application 3"})

    conn = get conn, Routes.oauth_authorized_application_path(conn, :index)
    body = html_response(conn, 200)

    assert body =~ "Your authorized applications"
    assert body =~ application1.name
    assert body =~ application2.name
    refute body =~ application3.name
  end

  test "deletes chosen authorized application", %{conn: conn, application: application} do
    conn = delete conn, Routes.oauth_authorized_application_path(conn, :delete, application)
    assert redirected_to(conn) == Routes.oauth_authorized_application_path(conn, :index)
  end
end
