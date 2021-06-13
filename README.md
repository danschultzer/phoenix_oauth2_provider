# PhoenixOauth2Provider

[![Build Status](https://travis-ci.org/danschultzer/phoenix_oauth2_provider.svg?branch=master)](https://travis-ci.org/danschultzer/phoenix_oauth2_provider) [![hex.pm](http://img.shields.io/hexpm/v/phoenix_oauth2_provider.svg?style=flat)](https://hex.pm/packages/phoenix_oauth2_provider) [![hex.pm downloads](https://img.shields.io/hexpm/dt/phoenix_oauth2_provider.svg?style=flat)](https://hex.pm/packages/phoenix_oauth2_provider)

Get an OAuth 2.0 provider running in your Phoenix app with schema modules and templates in just two minutes.

## Installation

Add PhoenixOauth2Provider to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    # ...
    {:phoenix_oauth2_provider, "~> 0.5.1"}
    # ...
  ]
end
```

Run `mix deps.get` to install it.

## Getting started

Install ExOauthProvider first:

```bash
mix ex_oauth2_provider.install
```

Follow the instructions to update `config/config.exs`.

Set up routes:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use PhoenixOauth2Provider.Router, otp_app: :my_app

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

> Instead of `oauth_routes()` you can use both `oauth_authorize_routes()` and `oauth_applications_routes()` for more granular control.

That's it! The following OAuth 2.0 routes will now be available in your app:

```text
oauth_authorize_path  GET    /oauth/authorize         AuthorizationController :new
oauth_authorize_path  POST   /oauth/authorize         AuthorizationController :create
oauth_authorize_path  GET    /oauth/authorize/:code   AuthorizationController :show
oauth_authorize_path  DELETE /oauth/authorize         AuthorizationController :delete
oauth_token_path      POST   /oauth/token             TokenController :create
oauth_token_path      POST   /oauth/revoke            TokenController :revoke
```

Please read the [ExOauth2Provider](https://github.com/danschultzer/ex_oauth2_provider) documentation for further customization.

## Configuration

### Templates

To generate views and templates run:

```bash
mix phoenix_oauth2_provider.gen.templates
```

Set up the PhoenixOauth2Provider configuration with `:web_module`:

```elixir
config :my_app, PhoenixOauth2Provider,
  web_module: MyAppWeb
```

### Current resource owner

Set up what key in the plug conn `assigns` that PhoenixOauth2Provider should use to fetch the current resource owner.

```elixir
config :my_app, PhoenixOauth2Provider,
  current_resource_owner: :current_user
```

## LICENSE

(The MIT License)

Copyright (c) 2017-2019 Dan Schultzer & the Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
