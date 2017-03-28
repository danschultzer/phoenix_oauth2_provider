use Mix.Config

config :ex_oauth2_provider, ExOauth2Provider,
  repo: ExOauth2Phoenix.Test.Repo,
  resource_owner: ExOauth2Phoenix.Test.User,
  scopes: ~w(read write)

config :ex_oauth2_phoenix, ExOauth2Phoenix,
  module: ExOauth2Phoenix.Test,
  current_resource_owner: :current_test_user

config :ex_oauth2_phoenix, ecto_repos: [ExOauth2Phoenix.Test.Repo]
config :ex_oauth2_phoenix, ExOauth2Phoenix.Test.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "ex_oauth2_phoenix_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/test"
config :ex_oauth2_phoenix, ExOauth2Phoenix.Test.Endpoint,
  secret_key_base: "1lJGFCaor+gPGc21GCvn+NE0WDOA5ujAMeZoy7oC5un7NPUXDir8LAE+Iba5bpGH",
  render_errors: [view: ExOauth2Phoenix.Test.ErrorView, accepts: ~w(html json)]
