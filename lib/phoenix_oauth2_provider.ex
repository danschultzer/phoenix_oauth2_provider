defmodule PhoenixOauth2Provider do
  @moduledoc """
  A module that provides OAuth 2 server capabilities for Phoenix applications.

  ## Configuration
      config :phoenix_oauth2_provider, PhoenixOauth2Provider,
        current_resource_owner: :current_user,
        module: MyApp,
        router: MyApp.Router

  You can find more config options in the
  [ex_oauth2_provider](https://github.com/danschultzer/ex_oauth2_provider)
  library.
  """
end
