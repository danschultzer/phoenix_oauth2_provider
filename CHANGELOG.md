# Changelog

## v0.5.0 (TBA)

This is a full rewrite of the library, and are several breaking changes. You're encouraged to test your app well if you upgrade from 0.4.x.

### 1. ExOauth2Provider

Read the [ExOauth2Provider CHANGELOG.md](https://github.com/danschultzer/ex_oauth2_provider) for upgrade instructions.

### 2. Routes

Routes are now separated into api and non api routes. Update your routes like so:

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

### 3. Templates and views

Update `:module` to `:web_module` in your configuration. Templates and views are no longer required to be generated so you can remove them entirely if the default ones work for you.