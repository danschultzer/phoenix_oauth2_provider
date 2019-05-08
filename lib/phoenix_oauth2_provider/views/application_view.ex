defmodule PhoenixOauth2Provider.ApplicationView do
  use PhoenixOauth2Provider.View

  template "edit.html",
  """
  <h1>Edit Application</h1>

  <%%= render "form.html", Map.put(assigns, :action, Routes.oauth_application_path(@conn, :update, @changeset.data)) %>

  <span><%%= link "Back", to: Routes.oauth_application_path(@conn, :index) %></span>
  """

  template "form.html",
  """
  <%%= form_for @changeset, @action, fn f -> %>
  <%%= if @changeset.action do %>
      <div class="alert alert-danger">
        <p>Oops, something went wrong! Please check the errors below.</p>
      </div>
  <%% end %>

    <%%= label f, :name %>
    <%%= text_input f, :name %>
    <%%= error_tag f, :name %>

    <%%= label f, :redirect_uri %>
    <%%= textarea f, :redirect_uri %>
    <%%= error_tag f, :redirect_uri %>
    <span class="help-block">Use one line per URI</span>
  <%%= unless is_nil(ExOauth2Provider.Config.native_redirect_uri([])) do %>
      <span class="help-block">
        Use <code><%%= ExOauth2Provider.Config.native_redirect_uri([]) %></code> for local tests
      </span>
  <%% end %>

    <%%= label f, :scopes %>
    <%%= text_input f, :scopes %>
    <%%= error_tag f, :scopes %>
    <span class="help-block">
      Separate scopes with spaces. Leave blank to use the default scopes.
    </span>

    <div>
      <%%= submit "Save" %>
    </div>
  <%% end %>
  """

  template "index.html",
  """
  <h1>Your applications</h1>

  <table>
    <thead>
      <tr>
        <th>Name</th>
        <th>Callback URL</th>
        <th></th>
      </tr>
    </thead>
    <tbody>
  <%%= for application <- @applications do %>
      <tr>
        <td><%%= link application.name, to: Routes.oauth_application_path(@conn, :show, application) %></td>
        <td><%%= application.redirect_uri %></td>
        <td>
          <%%= link "Edit", to: Routes.oauth_application_path(@conn, :edit, application) %>
          <%%= link "Delete", to: Routes.oauth_application_path(@conn, :delete, application), method: :delete, data: [confirm: "Are you sure?"] %>
        </td>
      </tr>
  <%% end %>
    </tbody>
  </table>

  <span><%%= link "New Application", to: Routes.oauth_application_path(@conn, :new) %></span>
  """

  template "new.html",
  """
  <h1>New Application</h1>

  <%%= render "form.html", Map.put(assigns, :action, Routes.oauth_application_path(@conn, :create)) %>

  <span><%%= link "Back", to: Routes.oauth_application_path(@conn, :index) %></span>
  """

  template "show.html", """
  <h1>Show Application</h1>

  <ul>
    <li>
      <strong>Name:</strong>
      <%%= @application.name %>
    </li>
    <li>
      <strong>ID:</strong>
      <%%= @application.uid %>
    </li>
    <li>
      <strong>Secret:</strong>
      <%%= @application.secret %>
    </li>
    <li>
      <strong>Scopes:</strong>
      <%%= @application.scopes %>
    </li>
    <li>
      <strong>Callback urls:</strong>
      <table class="table">
        <tbody>
  <%%= for redirect_uri <- String.split(@application.redirect_uri) do %>
          <tr>
            <td>
              <code><%%= redirect_uri %></code>
            </td>
            <td>
              <%%= link "Authorize", to: Routes.oauth_authorization_path(@conn, :new, client_id: @application.uid, redirect_uri: redirect_uri, response_type: "code", scope: @application.scopes), target: '_blank' %>
            </td>
          </tr>
  <%% end %>
        </tbody>
      </table>
    </li>
  </ul>

  <span><%%= link "Edit", to: Routes.oauth_application_path(@conn, :edit, @application) %></span>
  <span><%%= link "Back", to: Routes.oauth_application_path(@conn, :index) %></span>
  """
end
