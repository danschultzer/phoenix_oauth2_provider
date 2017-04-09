defmodule PhoenixOauth2Provider.Router do
  @moduledoc """
  Handles routing for PhoenixOauth2Provider.
  ## Usage
  Add the following to your `web/router.ex` file
      defmodule MyProject.Router do
        use MyProject.Web, :router
        use PhoenixOauth2Provider.Router         # Add this
        scope "/" do
          pipe_through :protected
          oauth_routes()                    # Add this
        end
        # ...
      end
  Alternatively, you may want to use the login plug in individual controllers. In
  this case, you can have one pipeline, one scope and call `oauth_routes :all`.
  In this case, it will add both the public and protected routes.
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
  PhoenixOauth2Provider Router macro.
  Use this macro to define the various PhoenixOauth2Provider Routes.
  ## Examples:
      # Routes that are open with no CSRF protection
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
