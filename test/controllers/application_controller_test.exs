defmodule PhoenixOauth2Provider.ApplicationControllerTest do
  use PhoenixOauth2Provider.Test.ConnCase

  import PhoenixOauth2Provider.Test.Fixture

  @create_attrs %{name: "Example", redirect_uri: "https://example.com"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup %{conn: conn} do
    user = fixture(:user)
    conn = assign conn, :current_test_user, user
    {:ok, conn: conn, user: user}
  end

  test "index/2 lists all entries on index", %{conn: conn, user: user} do
    application1 = fixture(:application, %{user: user, name: "Application 1"})
    application2 = fixture(:application, %{user: fixture(:user), name: "Application 2"})

    conn = get conn, oauth_application_path(conn, :index)
    body = html_response(conn, 200)

    assert body =~ "Your applications"
    assert body =~ application1.name
    refute body =~ application2.name
  end

  test "new/2 renders form for new applications", %{conn: conn} do
    conn = get conn, oauth_application_path(conn, :new)
    assert html_response(conn, 200) =~ "New Application"
  end

  test "create/2 creates application and redirects to show when data is valid", %{conn: conn} do
    new_conn = post conn, oauth_application_path(conn, :create), oauth_application: @create_attrs

    assert %{uid: uid} = redirected_params(new_conn)
    assert redirected_to(new_conn) == oauth_application_path(new_conn, :show, uid)

    new_conn = get conn, oauth_application_path(conn, :show, uid)
    assert html_response(new_conn, 200) =~ "Application: "
  end

  test "create/2 does not create application and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, oauth_application_path(conn, :create), oauth_application: @invalid_attrs
    assert html_response(conn, 200) =~ "New Application"
  end

  test "edit/2 renders form for editing chosen application", %{conn: conn, user: user} do
    application = fixture(:application, %{user: user})
    conn = get conn, oauth_application_path(conn, :edit, application)
    assert html_response(conn, 200) =~ "Edit Application"
  end

  test "update/2 updates chosen application and redirects when data is valid", %{conn: conn, user: user} do
    application = fixture(:application, %{user: user})
    new_conn = put conn, oauth_application_path(conn, :update, application), oauth_application: @update_attrs
    assert redirected_to(new_conn) == oauth_application_path(new_conn, :show, application)

    new_conn = get conn, oauth_application_path(conn, :show, application)
    assert html_response(new_conn, 200) =~ @update_attrs.name
  end

  test "update/2 does not update chosen application and renders errors when data is invalid", %{conn: conn, user: user} do
    application = fixture(:application, %{user: user})
    conn = put conn, oauth_application_path(conn, :update, application), oauth_application: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit Application"
  end

  test "delete/2 deletes chosen application", %{conn: conn, user: user} do
    application = fixture(:application, %{user: user})
    new_conn = delete conn, oauth_application_path(conn, :delete, application)
    assert redirected_to(new_conn) == oauth_application_path(new_conn, :index)

    assert_error_sent 404, fn ->
      get conn, oauth_application_path(conn, :show, application)
    end
  end
end
