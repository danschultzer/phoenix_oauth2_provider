defmodule ExOauth2Phoenix.ExOauth2PhoenixView do
  use ExOauth2Phoenix.Test.ExOauth2Phoenix.Web, :view
end
defmodule ExOauth2Phoenix.LayoutView do
  use ExOauth2Phoenix.Test.ExOauth2Phoenix.Web, :view
end
defmodule ExOauth2Phoenix.ApplicationView do
  use ExOauth2Phoenix.Test.ExOauth2Phoenix.Web, :view
end
defmodule ExOauth2Phoenix.AuthorizationView do
  use ExOauth2Phoenix.Test.ExOauth2Phoenix.Web, :view
end
defmodule ExOauth2Phoenix.Test.ErrorView do
  def render("500.html", _changeset), do: "500.html"
  def render("400.html", _changeset), do: "400.html"
  def render("404.html", _changeset), do: "404.html"
end
