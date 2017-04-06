ExUnit.start()

Mix.Task.run "ex_oauth2_provider.install", ~w(--no-config)
Mix.Task.run "ecto.create", ~w(--quiet)
Mix.Task.run "ecto.migrate", ~w(--quiet)

# Install all template files
PhoenixOauth2Provider.Mix.Utils.rm_dir! "tmp"
for {name, files} <- [
  application: ~w(edit new form index show),
  authorization: ~w(error new show),
  authorized_application: ~w(index),
  layout: ~w(app)
] do
  files = for fname <- files do
    fname = "#{fname}.html.eex"
    {:eex, fname, "tmp/templates/#{name}/#{fname}"}
  end

  Mix.Phoenix.copy_from [".", :phoenix_oauth2_provider],
    "priv/boilerplate/templates/#{name}", "", binding(), files
end
IEx.Helpers.recompile
#

Logger.configure(level: :info)

{:ok, _pid} = PhoenixOauth2Provider.Test.Endpoint.start_link
{:ok, _pid} = PhoenixOauth2Provider.Test.Repo.start_link

Ecto.Adapters.SQL.Sandbox.mode(PhoenixOauth2Provider.Test.Repo, :manual)
