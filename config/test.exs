use Mix.Config

config :phoenix, :json_library, Jason

config :phoenix_oauth2_provider, namespace: Dummy

config :phoenix_oauth2_provider, DummyWeb.Endpoint,
  secret_key_base: "1lJGFCaor+gPGc21GCvn+NE0WDOA5ujAMeZoy7oC5un7NPUXDir8LAE+Iba5bpGH",
  render_errors: [view: DummyWeb.ErrorView, accepts: ~w(html json)]

config :phoenix_oauth2_provider, Dummy.Repo,
  database: "phoenix_oauth2_provider_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support/priv"

config :phoenix_oauth2_provider, ExOauth2Provider,
  repo: Dummy.Repo,
  resource_owner: Dummy.Users.User,
  scopes: ~w(read write),
  use_refresh_token: true

config :phoenix_oauth2_provider, PhoenixOauth2Provider,
  current_resource_owner: :current_test_user
