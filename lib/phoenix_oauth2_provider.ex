defmodule PhoenixOauth2Provider do
  @moduledoc """
  A module that provides OAuth 2 based server for Phoenix applications.
  ## Configuration
      config :phoenix_oauth2_provider, PhoenixOauth2Provider,
        current_resource_owner: :current_user,
        module: MyApp,
        router: MyApp.Router
  """
  @config             Application.get_env(:phoenix_oauth2_provider, PhoenixOauth2Provider, [])
  @module             Keyword.get(@config, :module, Mix.Phoenix.base())
  @router_helpers     Module.concat([Keyword.get(@config, :router, Module.concat([@module, "Router"])), "Helpers"])
  @resource_owner_key Keyword.get(@config, :current_resource_owner, :current_user)

  @doc false
  def router_helpers, do: @router_helpers

  # @doc """
  # Will get current resource owner from endpoint
  # """
  def current_resource_owner(conn) do
    case conn.assigns[@resource_owner_key] do
      nil -> raise "Resource owner was not found with :#{@resource_owner_key} assigns"
      resource_owner -> resource_owner
    end
  end
end
