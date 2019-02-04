# PhoenixOauth2Provider

[![Build Status](https://travis-ci.org/danschultzer/phoenix_oauth2_provider.svg?branch=master)](https://travis-ci.org/danschultzer/phoenix_oauth2_provider) [![hex.pm](http://img.shields.io/hexpm/v/phoenix_oauth2_provider.svg?style=flat)](https://hex.pm/packages/phoenix_oauth2_provider) [![hex.pm downloads](https://img.shields.io/hexpm/dt/phoenix_oauth2_provider.svg?style=flat)](https://hex.pm/packages/phoenix_oauth2_provider)

Get an OAuth 2 provider running in your Phoenix app with controllers, views and models in just two minutes.

> This version requires Phoenix 1.3 or higher. If you use a previous Phoenix version, please use v0.2.0 instead.

## Installation

Add PhoenixOauth2Provider to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    # ...
    {:phoenix_oauth2_provider, "~> 0.5.0"}
    # ...
  ]
end
```

Run `mix deps.get` to install it.

Add migrations and set up `config/config.exs`:

```bash
mix phoenix_oauth2_provider.install
```

Set up routes:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use PhoenixOauth2Provider.Router

  # ...

  pipeline :protected do
    # Require user authentication
  end

  scope "/", MyAppWeb do
    pipe_through :browser
    oauth_routes :public
  end

  scope "/", MyAppWeb do
    pipe_through [:browser, :protected]
    oauth_routes :protected
  end

  # ...
end
```

That's it! The following OAuth 2.0 routes will now be available in your app:

```
oauth_authorize_path  GET    /oauth/authorize         AuthorizationController :new
oauth_authorize_path  POST   /oauth/authorize         AuthorizationController :create
oauth_authorize_path  GET    /oauth/authorize/:code   AuthorizationController :show
oauth_authorize_path  DELETE /oauth/authorize         AuthorizationController :delete
oauth_token_path      POST   /oauth/token             TokenController :create
oauth_token_path      POST   /oauth/revoke            TokenController :revoke
```

Please read the [ex_oauth2_provider](https://github.com/danschultzer/ex_oauth2_provider) documentation for further customization.

## Configuration

### Resource owner schema

By default `MyApp.Users.User` is used as the `resource_owner`, you can change that in the following way:

```elixir
config :phoenix_oauth2_provider, PhoenixOauth2Provider,
  repo: MyApp.Repo,
  resource_owner: MyApp.CustomUsers.CustomUser
```

### Resource owner

Set up what `assigns` in the plug that PhoenixOauth2Provider should gather the authorized user from.

```elixir
config :phoenix_oauth2_provider, PhoenixOauth2Provider,
  current_resource_owner: :current_user
```

## Acknowledgement

This library was made thanks to [coherence](https://github.com/smpallen99/coherence) that gave the conceptual building blocks.

## LICENSE

(The MIT License)

Copyright (c) 2017 Dan Schultzer & the Contributors Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
