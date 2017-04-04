defmodule PhoenixOauth2Provider.PhoenixOauth2ProviderView do
  use PhoenixOauth2Provider.Test.PhoenixOauth2Provider.Web, :view
end
defmodule PhoenixOauth2Provider.LayoutView do
  use PhoenixOauth2Provider.Test.PhoenixOauth2Provider.Web, :view
end
defmodule PhoenixOauth2Provider.ApplicationView do
  use PhoenixOauth2Provider.Test.PhoenixOauth2Provider.Web, :view
end
defmodule PhoenixOauth2Provider.AuthorizationView do
  use PhoenixOauth2Provider.Test.PhoenixOauth2Provider.Web, :view
end
defmodule PhoenixOauth2Provider.Test.ErrorView do
  def render("500.html", _changeset), do: "500.html"
  def render("400.html", _changeset), do: "400.html"
  def render("404.html", _changeset), do: "404.html"
end
