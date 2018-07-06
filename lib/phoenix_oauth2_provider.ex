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

  @doc """
  Will get current resource owner from endpoint
  """
  def current_resource_owner(conn) do
    resource_owner_key = Keyword.get(config(), :current_resource_owner, :current_user)

    case conn.assigns[resource_owner_key] do
      nil            -> raise "Resource owner was not found with :#{resource_owner_key} assigns"
      resource_owner -> resource_owner
    end
  end

  @doc false
  def config do
    Application.get_env(:phoenix_oauth2_provider, PhoenixOauth2Provider, [])
  end

  @doc false
  def router_helpers do
    module = Keyword.get(config(), :router, router_module())

    Module.concat([module, "Helpers"])
  end

  defp router_module do
    Module.concat([web_module(), "Router"])
  end

  defp web_module do
    config()
    |> Keyword.get(:module, Mix.Phoenix.base())
    |> Kernel.to_string()
    |> Kernel.<>("Web")
  end
end
