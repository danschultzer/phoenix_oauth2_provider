alias PhoenixOauth2Provider.Test.{Endpoint, MixHelpers, Repo}
ExUnit.start()

install_opts = "UUID"
               |> System.get_env()
               |> case do
                    nil -> []
                    uuid -> ["--uuid", uuid]
                  end
               |> Enum.concat(["--no-config"])

Mix.shell.cmd("rm priv/test/migrations/*_create_oauth_tables.exs")
Mix.Task.run("ex_oauth2_provider.install", install_opts)
Mix.Task.run("ecto.create", ~w(--quiet))
Mix.Task.run("ecto.migrate")

# Install all template files
File.rm_rf(MixHelpers.tmp_path())

templates = [application: ~w(edit new form index show),
             authorization: ~w(error new show),
             authorized_application: ~w(index),
             layout: ~w(app)]

for {name, files} <- templates do
  apps   = [".", :phoenix_oauth2_provider]
  source = "priv/boilerplate/templates/#{name}"
  mapping = Enum.map(files, fn file -> {:eex, "#{file}.html.eex", "priv/test/tmp/templates/#{name}/#{file}.html.eex"} end)

  Mix.Phoenix.copy_from(apps, source, binding(), mapping)
end
IEx.Helpers.recompile()

Logger.configure(level: :info)

{:ok, _pid} = Endpoint.start_link()
{:ok, _pid} = Repo.start_link()

Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)
