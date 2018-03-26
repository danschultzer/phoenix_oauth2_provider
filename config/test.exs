use Mix.Config

config :phoenix_oauth2_provider, PhoenixOauth2Provider,
  module: PhoenixOauth2Provider.Test,
  current_resource_owner: :current_test_user,
  repo: PhoenixOauth2Provider.Test.Repo,
  resource_owner: PhoenixOauth2Provider.Test.User,
  scopes: ~w(read write),
  router: PhoenixOauth2Provider.Test.Router,
  use_refresh_token: true

config :phoenix_oauth2_provider, ecto_repos: [PhoenixOauth2Provider.Test.Repo]
config :phoenix_oauth2_provider, PhoenixOauth2Provider.Test.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "phoenix_oauth2_provider_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/test"
config :phoenix_oauth2_provider, PhoenixOauth2Provider.Test.Endpoint,
  secret_key_base: "1lJGFCaor+gPGc21GCvn+NE0WDOA5ujAMeZoy7oC5un7NPUXDir8LAE+Iba5bpGH",
  render_errors: [view: PhoenixOauth2Provider.Test.ErrorView, accepts: ~w(html json)]

if System.get_env("UUID") == "all" do
config :phoenix_oauth2_provider, PhoenixOauth2Provider,
  app_schema: ExOauth2Provider.Schema.UUID
end
