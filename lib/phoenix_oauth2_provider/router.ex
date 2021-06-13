defmodule PhoenixOauth2Provider.Router do
  @moduledoc """
  Handles routes for PhoenixOauth2Provider.

  ## Usage

  Configure `lib/my_app_web/router.ex` the following way:

      defmodule MyAppWeb.Router do
        use MyAppWeb, :router
        use PhoenixOauth2Provider.Router

        pipeline :browser do
          plug :accepts, ["html"]
          plug :fetch_session
          plug :fetch_flash
          plug :protect_from_forgery
          plug :put_secure_browser_headers
        end

        pipeline :api do
          plug :accepts, ["json"]
        end

        pipeline :protected do
          # Require user authentication
        end

        scope "/" do
          pipe_through [:browser, :protected]

          oauth_routes()
        end

        scope "/" do
          pipe_through :api

          oauth_api_routes()
        end

        # ...
      end
  """

  defmacro __using__(config \\ []) do
    quote do
      @phoenix_oauth2_provider_config unquote(config)
      import unquote(__MODULE__)
    end
  end

  @doc """
  OAuth 2.0 browser routes macro.

  Use this macro to define the protected browser oauth routes.

  ## Example

      scope "/" do
        pipe_through [:browser, :protected]

        oauth_routes()
      end

      # equivalent to
      scope "/" do
        pipe_through [:browser, :protected]

        oauth_authorize_routes()
        oauth_applications_routes()
      end
  """
  defmacro oauth_routes(options \\ []) do
    quote location: :keep do
      oauth_authorize_routes(unquote(options))
      oauth_applications_routes(unquote(options))
    end
  end

  @doc """
  OAuth 2.0 browser routes macro.

  Use this macro to define the authorization related protected browser oauth routes (authorize application by user and revoke previous approvals).

  ## Example

      scope "/" do
        pipe_through [:browser, :protected]

        oauth_authorize_routes()
      end
  """
  defmacro oauth_authorize_routes(options \\ []) do
    quote location: :keep do
      oauth_scope unquote(options), @phoenix_oauth2_provider_config do
        scope "/authorize" do
          get "/", AuthorizationController, :new
          post "/", AuthorizationController, :create
          get "/:code", AuthorizationController, :show
          delete "/", AuthorizationController, :delete
        end
        resources "/authorized_applications", AuthorizedApplicationController, only: [:index, :delete], param: "uid"
      end
    end
  end

  @doc """
  OAuth 2.0 browser routes macro.

  Use this macro to define the applications related protected browser oauth routes (list, create, edit oauth applications).

  ## Example

      scope "/" do
        pipe_through [:browser, :admin_protected]

        oauth_applications_routes()
      end
  """
  defmacro oauth_applications_routes(options \\ []) do
    quote location: :keep do
      oauth_scope unquote(options), @phoenix_oauth2_provider_config do
        resources "/applications", ApplicationController, param: "uid"
      end
    end
  end

  @doc """
  OAuth 2.0 API routes macro.

  Use this macro to define the public API oauth routes. These routes
  should not have CSRF protection.

  ## Example

      scope "/" do
        pipe_through :api

        oauth_api_routes()
      end
  """
  defmacro oauth_api_routes(options \\ []) do
    quote location: :keep do
      oauth_scope unquote(options), @phoenix_oauth2_provider_config do
        post "/token", TokenController, :create
        post "/revoke", TokenController, :revoke
      end
    end
  end

  @doc false
  defmacro oauth_scope(options \\ [], config \\ [], do: context) do
    quote do
      path = Keyword.get(unquote(options), :path, "oauth")

      scope "/#{path}", PhoenixOauth2Provider, as: "oauth", private: %{phoenix_oauth2_provider_config: unquote(config)} do
        unquote(context)
      end
    end
  end

  defmodule Helpers do
    @moduledoc false

    alias Plug.Conn
    alias PhoenixOauth2Provider.Controller

    @spec oauth_application_path(Conn.t(), atom()) :: binary()
    def oauth_application_path(conn, action), do: Controller.routes(conn).oauth_application_path(conn, action)

    @spec oauth_application_path(Conn.t(), atom(), map()) :: binary()
    def oauth_application_path(conn, action, application), do: Controller.routes(conn).oauth_application_path(conn, action, application)

    @spec oauth_authorization_path(Conn.t(), atom()) :: binary()
    def oauth_authorization_path(conn, action), do: Controller.routes(conn).oauth_authorization_path(conn, action)

    @spec oauth_authorization_path(Conn.t(), atom(), binary()) :: binary()
    def oauth_authorization_path(conn, action, code), do: Controller.routes(conn).oauth_authorization_path(conn, action, code)

    @spec oauth_application_path(Conn.t(), atom()) :: binary()
    def oauth_authorized_application_path(conn, action), do: Controller.routes(conn).oauth_authorized_application_path(conn, action)

    @spec oauth_application_path(Conn.t(), atom(), map()) :: binary()
    def oauth_authorized_application_path(conn, action, application), do: Controller.routes(conn).oauth_authorized_application_path(conn, action, application)
  end
end
