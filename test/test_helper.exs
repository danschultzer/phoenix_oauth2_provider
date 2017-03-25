ExUnit.start()

Code.require_file "../priv/boilerplate/controllers/application_controller.ex", __DIR__
Code.require_file "../priv/boilerplate/controllers/authorization_controller.ex", __DIR__

Mix.Task.run "ex_oauth2_provider.install", ~w(--config-file=config/test.exs)
Mix.Task.run "ecto.create", ~w(--quiet)
Mix.Task.run "ecto.migrate", ~w(--quiet)

# Install all template files
ExOauth2Phoenix.Mix.Utils.rm_dir! "tmp"
for {name, files} <- [
  application: ~w(edit new form index show),
  authorization: ~w(error new show),
  layout: ~w(app)
] do
  files = for fname <- files do
    fname = "#{fname}.html.eex"
    {:eex, fname, "tmp/templates/#{name}/#{fname}"}
  end

  Mix.Phoenix.copy_from [".", :ex_oauth2_phoenix],
    "priv/boilerplate/templates/#{name}", "", binding(), files
end
IEx.Helpers.recompile
#

Logger.configure(level: :info)

{:ok, _pid} = ExOauth2Phoenix.Test.Endpoint.start_link
{:ok, _pid} = ExOauth2Phoenix.Test.Repo.start_link

Ecto.Adapters.SQL.Sandbox.mode(ExOauth2Phoenix.Test.Repo, :manual)
