defmodule PhoenixOauth2Provider.Test.PhoenixOauth2Provider.Web do
  def view do
    quote do
      use Phoenix.View, root: "tmp/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import PhoenixOauth2Provider.Test.Router.Helpers

      # Add view helpers including routes helpers
      import PhoenixOauth2Provider.ViewHelpers
    end
  end
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
