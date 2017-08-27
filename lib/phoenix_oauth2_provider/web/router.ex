defmodule PhoenixOauth2Provider.Router do
  @moduledoc """
  Handles routing for PhoenixOauth2Provider.

  ## Usage

  Configure `lib/my_project_web/router.ex` the following way:

      defmodule MyProject.Router do
        use MyProjectWeb, :router
        use PhoenixOauth2Provider.Router

        pipeline :oauth_public do
          plug :put_secure_browser_headers
        end

        pipeline :protected do
          # Require user authentication
        end

        scope "/", MyProjectWeb do
          pipe_through :oauth_public
          oauth_routes :public
        end

        scope "/", MyProjectWeb do
          pipe_through :protected
          oauth_routes :protected
        end

        ...
      end
  """

  alias PhoenixOauth2Provider.AuthorizationController
  alias PhoenixOauth2Provider.ApplicationController
  alias PhoenixOauth2Provider.TokenController
  alias PhoenixOauth2Provider.AuthorizedApplicationController

  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  PhoenixOauth2Provider router macro.
  Use this macro to define the PhoenixOauth2Provider routes.

  ## Examples:
      # Routes that are public with no CSRF protection
      scope "/" do
        pipe_through :public
        oauth_routes :public
      end

      # Routes requires authentication
      scope "/" do
        pipe_through :protected
        oauth_routes :protected
      end
  """
  defmacro oauth_routes(mode, options \\ %{}) do
    quote location: :keep do
      mode = unquote(mode)
      options = Map.merge(%{scope: "oauth"}, unquote(Macro.escape(options)))

      scope "/#{options[:scope]}", as: "oauth" do
        if mode == :protected do
          scope "/authorize" do
            get "/", AuthorizationController, :new
            post "/", AuthorizationController, :create
            get "/:code", AuthorizationController, :show
            delete "/", AuthorizationController, :delete
          end
          resources "/applications", ApplicationController, param: "uid"
          resources "/authorized_applications", AuthorizedApplicationController, only: [:index, :delete], param: "uid"
        end

        if mode == :public do
          post "/token", TokenController, :create
          post "/revoke", TokenController, :revoke
        end
      end
    end
  end
end
