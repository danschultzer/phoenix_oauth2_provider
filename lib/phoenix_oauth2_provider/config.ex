defmodule PhoenixOauth2Provider.Config do
  @moduledoc false

  @spec current_resource_owner(keyword()) :: atom()
  def current_resource_owner(config), do: get(config, :current_resource_owner, :current_user)

  @spec web_module(keyword()) :: atom()
  def web_module(config), do: get(config, :web_module)

  defp get(config, key, value \\ nil) do
    otp_app = Keyword.get(config, :otp_app)

    config
    |> get_from_config(key)
    |> get_from_app_env(otp_app, key)
    |> get_from_global_env(key)
    |> case do
      :not_found -> value
      value      -> value
    end
  end

  defp get_from_config(config, key), do: Keyword.get(config, key, :not_found)

  defp get_from_app_env(:not_found, nil, _key), do: :not_found
  defp get_from_app_env(:not_found, otp_app, key) do
    otp_app
    |> Application.get_env(PhoenixOauth2Provider, [])
    |> Keyword.get(key, :not_found)
  end
  defp get_from_app_env(value, _otp_app, _key), do: value

  defp get_from_global_env(:not_found, key) do
    :phoenix_oauth2_provider
    |> Application.get_env(PhoenixOauth2Provider, [])
    |> Keyword.get(key, :not_found)
  end
  defp get_from_global_env(value, _key), do: value
end
