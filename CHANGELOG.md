# Changelog

## v0.5.0 (2019-05-08)

This is a full rewrite of the library, and are several breaking changes. You're encouraged to test your app well if you upgrade from 0.4.x.

### 1. ExOauth2Provider

Read the [ExOauth2Provider](https://github.com/danschultzer/ex_oauth2_provider) CHANGELOG.md for upgrade instructions.

### 2. Configuration

Configuration has been split up so now it should look like this (`:module` and `:current_resource_owner` should be moved to the separate configuration for PhoenixOauth2Provider):

```elixir
config :my_app, ExOauth2Provider,
  repo: MyApp.Repo,
  resource_owner: MyApp.Users.User,
  # ...

config :my_app, PhoenixOauth2Provider,
  current_resource_owner: :current_user,
  web_module: MyAppWeb
```

### 3. Routes

Routes are now separated into api and non api routes. Remove the old `oauth_routes/1` routes, and update your `router.ex` to look like this instead:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use PhoenixOauth2Provider.Router

  # ...

  pipeline :protected do
    # Require user authentication
  end

  scope "/" do
    pipe_through :api

    oauth_api_routes()
  end

  scope "/" do
    pipe_through [:browser, :protected]

    oauth_routes()
  end

  # ...
end
```

Remember to remove the `:oauth_public` pipeline. The default `:api` pipeline will be used instead.

### 4. Templates and views

Remove the old `module: MyApp` setting in your PhoenixOauth2Provider configuration, and instead set `web_module: MyAppWeb`.

However, templates and views are no longer required to be generated so you can remove them and the `:web_module` configuration setting entirely if the default ones work for you.

The easiest migration of templates and views are to just delete the folders (`lib/my_app_web/templates/{application, authorization, authorized_application}` and `lib/my_app_web/views/phoenix_oauth2_provider`), and then run `mix phoenix_oauth2_provider.gen.templates` to regenerate them. Then you can go into the templates and update them to use your old markup.