defmodule PhoenixOauth2Provider.Controller do
  @moduledoc false

  alias PhoenixOauth2Provider.Config
  alias Plug.Conn

  @doc false
  defmacro __using__(type) do
    quote do
      use Phoenix.Controller

      alias PhoenixOauth2Provider.Router.Helpers, as: Routes

      plug :put_web_module_view, unquote(type)

      defdelegate put_web_module_view(conn, type), to: unquote(__MODULE__), as: :__put_web_module_view__

      def action(conn, _opts) do
        params = unquote(__MODULE__).__action_params__(conn, unquote(type))

        apply(__MODULE__, action_name(conn), params)
      end
    end
  end

  @doc false
  def __put_web_module_view__(conn, :api), do: conn
  def __put_web_module_view__(conn, _type) do
    web_module =
      conn
      |> load_config()
      |> Config.web_module()

    conn
    |> put_layout(web_module)
    |> put_view(web_module)
  end

  defp put_layout(conn, nil) do
    ["Endpoint" | web_context] =
      conn
      |> Phoenix.Controller.endpoint_module()
      |> Module.split()
      |> Enum.reverse()

    web_module =
      web_context
      |> Enum.reverse()
      |> Module.concat()

    put_layout(conn, web_module)
  end
  defp put_layout(conn, web_module) do
    conn
    |> Phoenix.Controller.layout()
    |> case do
      {PhoenixOauth2Provider.LayoutView, template} ->
        view = Module.concat([web_module, LayoutView])

        Phoenix.Controller.put_layout(conn, {view, template})

      _layout ->
        conn
    end
  end

  defp put_view(conn, nil), do: conn
  defp put_view(%{private: %{phoenix_view: phoenix_view}} = conn, web_module) do
    view_module = Module.concat([web_module, phoenix_view])

    Phoenix.Controller.put_view(conn, view_module)
  end

  defp load_config(conn), do: Map.get(conn.private, :phoenix_oauth2_provider_config, [])

  @doc false
  def __action_params__(conn, :api), do: [conn, conn.params]
  def __action_params__(conn, _any), do: [conn, conn.params, current_resource_owner(conn)]

  defp current_resource_owner(conn) do
    resource_owner_key = Config.current_resource_owner([])

    case Map.get(conn.assigns, resource_owner_key) do
      nil            -> raise "Resource owner was not found with :#{resource_owner_key} assigns"
      resource_owner -> resource_owner
    end
  end

  @spec routes(Conn.t()) :: module()
  def routes(conn) do
    Module.concat([conn.private[:phoenix_router], Helpers])
  end
end
