defmodule PhoenixOauth2Provider.AuthorizationView do
  use PhoenixOauth2Provider.View

  template "error.html",
  """
  <h1>An error has occurred</h1>

  <div>
    <p><%%= @error[:error_description] %></p>
  </div>
  """

  template "new.html",
  """
  <h1>Authorize <strong><%%= @client.name %></strong> to use your account?</h1>

  <div>
    <p>This application will be able to:</p>
    <ul>
  <%%= for scope <- @scopes do %>
      <li><%%= scope %></li>
  <%% end %>
    </ul>
  </div>

  <div>
    <%%= form_tag Routes.oauth_authorization_path(@conn, :create), method: :post do %>
      <input type="hidden" name="client_id" value="<%%= @params["client_id"] %>" />
      <input type="hidden" name="redirect_uri" value="<%%= @params["redirect_uri"] %>" />
      <input type="hidden" name="state" value="<%%= @params["state"] %>" />
      <input type="hidden" name="response_type" value="<%%= @params["response_type"] %>" />
      <input type="hidden" name="scope" value="<%%= @params["scope"] %>" />
      <%%= if @params["code_challenge"] do %>
        <input type="hidden" name="code_challenge" value="<%%= @params["code_challenge"] %>" />
      <%% end %>
      <%%= if @params["code_challenge_method"] do %>
        <input type="hidden" name="code_challenge_method" value="<%%= @params["code_challenge_method"] %>" />
      <%% end %>
      <%%= submit "Authorize" %>
    <%% end %>
    <%%= form_tag Routes.oauth_authorization_path(@conn, :delete), method: :delete do %>
      <input type="hidden" name="client_id" value="<%%= @params["client_id"] %>" />
      <input type="hidden" name="redirect_uri" value="<%%= @params["redirect_uri"] %>" />
      <input type="hidden" name="state" value="<%%= @params["state"] %>" />
      <input type="hidden" name="response_type" value="<%%= @params["response_type"] %>" />
      <input type="hidden" name="scope" value="<%%= @params["scope"] %>" />
      <%%= if @params["code_challenge"] do %>
        <input type="hidden" name="code_challenge" value="<%%= @params["code_challenge"] %>" />
      <%% end %>
      <%%= if @params["code_challenge_method"] do %>
        <input type="hidden" name="code_challenge_method" value="<%%= @params["code_challenge_method"] %>" />
      <%% end %>
      <%%= submit "Deny" %>
    <%% end %>
  </div>
  """

  template "show.html",
  """
  <h1>Authorization code</h1>

  <code><%%= @code %></code>
  """
end
