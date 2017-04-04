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

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, oauth_application_path(conn, :index)
    assert html_response(conn, 200) =~ "Your applications"
  end

  test "renders form for new applications", %{conn: conn} do
    conn = get conn, oauth_application_path(conn, :new)
    assert html_response(conn, 200) =~ "New Application"
  end

  test "creates application and redirects to show when data is valid", %{conn: conn} do
    conn = post conn, oauth_application_path(conn, :create), application: @create_attrs

    assert %{uid: uid} = redirected_params(conn)
    assert redirected_to(conn) == oauth_application_path(conn, :show, uid)

    conn = get conn, oauth_application_path(conn, :show, uid)
    assert html_response(conn, 200) =~ "Application: "
  end

  test "does not create application and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, oauth_application_path(conn, :create), application: @invalid_attrs
    assert html_response(conn, 200) =~ "New Application"
  end

  test "renders form for editing chosen application", %{conn: conn, user: user} do
    application = fixture(:application, %{user: user})
    conn = get conn, oauth_application_path(conn, :edit, application)
    assert html_response(conn, 200) =~ "Edit Application"
  end

  test "updates chosen application and redirects when data is valid", %{conn: conn, user: user} do
    application = fixture(:application, %{user: user})
    conn = put conn, oauth_application_path(conn, :update, application), application: @update_attrs
    assert redirected_to(conn) == oauth_application_path(conn, :show, application)

    conn = get conn, oauth_application_path(conn, :show, application)
    assert html_response(conn, 200) =~ @update_attrs.name
  end

  test "does not update chosen application and renders errors when data is invalid", %{conn: conn, user: user} do
    application = fixture(:application, %{user: user})
    conn = put conn, oauth_application_path(conn, :update, application), application: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit Application"
  end

  test "deletes chosen application", %{conn: conn, user: user} do
    application = fixture(:application, %{user: user})
    conn = delete conn, oauth_application_path(conn, :delete, application)
    assert redirected_to(conn) == oauth_application_path(conn, :index)
    assert_error_sent 404, fn ->
      get conn, oauth_application_path(conn, :show, application)
    end
  end
end
