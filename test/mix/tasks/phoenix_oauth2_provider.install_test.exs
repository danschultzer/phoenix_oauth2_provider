# Get Mix output sent to the current
# process to avoid polluting tests.
Mix.shell(Mix.Shell.Process)

defmodule Mix.Tasks.PhoenixOauth2Provider.InstallTest do
  use ExUnit.Case
  alias PhoenixOauth2Provider.Test.MixHelpers
  alias Mix.Tasks.PhoenixOauth2Provider.Install

  defmodule MigrationsRepo do
    def __adapter__ do
      true
    end

    def config do
      [priv: "priv/test/tmp", otp_app: :phoenix_oauth2_provider]
    end
  end

  @web_path "lib/phoenix_oauth2_provider_web"
  @all_template_dirs ~w(layout application authorization authorized_application)
  @all_views ~w(phoenix_oauth2_provider_view_helpers.ex phoenix_oauth2_provider_view.ex layout_view.ex) ++
    ~w(application_view.ex authorization_view.ex authorized_application_view.ex)
  @all_controllers Enum.map(@all_template_dirs -- ~w(layout), &("#{&1}_controller.ex"))

  test "generates files for application" do
    MixHelpers.in_tmp "generates_files_for_application", fn ->
      Install.run(~w(--repo PhoenixOauth2Provider.Test.Repo --log-only --controllers --module PhoenixOauth2Provider.Test --no-provider))

      ~w(application_view.ex authorization_view.ex authorized_application_view.ex phoenix_oauth2_provider_view.ex layout_view.ex phoenix_oauth2_provider_view_helpers.ex)
      |> MixHelpers.assert_file_list(@all_views, web_path("views/phoenix_oauth2_provider/"))

      ~w(layout application authorization authorized_application)
      |> MixHelpers.assert_dirs(@all_template_dirs, web_path("templates/phoenix_oauth2_provider/"))

      ~w(application_controller.ex authorization_controller.ex authorized_application_controller.ex token_controller.ex)
      |> MixHelpers.assert_file_list(@all_controllers, web_path("controllers/phoenix_oauth2_provider/"))

      MixHelpers.assert_file web_path("controllers/phoenix_oauth2_provider/application_controller.ex"), fn file ->
        assert file =~ "defmodule PhoenixOauth2Provider.Test.PhoenixOauth2Provider.ApplicationController do"
      end
    end
  end

  test "does not generate files for full" do
    MixHelpers.in_tmp "does_not_generate_files_for_full", fn ->
      Install.run(~w(--repo PhoenixOauth2Provider.Test.Repo --full --log-only --no-boilerplate --no-provider))

      MixHelpers.assert_file_list([], @all_views, web_path("views/phoenix_oauth2_provider/"))

      MixHelpers.assert_dirs([], @all_template_dirs, web_path("templates/phoenix_oauth2_provider/"))

      MixHelpers.assert_file_list([], @all_controllers, web_path("controllers/phoenix_oauth2_provider/"))
    end
  end

  test "updates config" do
    MixHelpers.in_tmp "installs_phoenix_oauth2_provider_config", fn ->
      file_path = "config.exs"
      File.touch!(file_path)
      Install.run(~w(--repo PhoenixOauth2Provider.Test.Repo --no-boilerplate --no-migrations --config-file #{File.cwd!}/#{file_path}))

      MixHelpers.assert_file file_path, fn file ->
        assert file =~ "config :phoenix_oauth2_provider, PhoenixOauth2Provider"
        assert file =~ "module: PhoenixOauth2Provider"
        assert file =~ "current_resource_owner: :current_user"
        assert file =~ "repo: PhoenixOauth2Provider.Test.Repo"
        assert file =~ "resource_owner: PhoenixOauth2Provider.User"

        # Doesn't set config for provider
        refute file =~ "config :ex_oauth2_provider"
      end
    end
  end

  test "instructions" do
    MixHelpers.in_tmp "prints_instructions", fn ->
      Install.run(~w(--repo PhoenixOauth2Provider.Test.Repo --no-boilerplate --no-migrations --no-config))

      assert_received {:mix_shell, :info, [
        """
        Please add the following to your config/config.exs file.

        config :phoenix_oauth2_provider, PhoenixOauth2Provider,
          module: PhoenixOauth2Provider,
          current_resource_owner: :current_user,
          repo: PhoenixOauth2Provider.Test.Repo,
          resource_owner: PhoenixOauth2Provider.User

        """
      ]}

      assert_received {:mix_shell, :info, [
        """
        Configure your router.ex file the following way:

        defmodule PhoenixOauth2Provider.Router do
          use PhoenixOauth2ProviderWeb, :router
          use PhoenixOauth2Provider.Router

          pipeline :protected do
            # Require user authentication
          end

          scope "/" do
            pipe_through :browser
            oauth_routes :public
          end

          scope "/" do
            pipe_through [:browser, :protected]
            oauth_routes :protected
          end
          ...
        end
        """
      ]}

      Install.run(~w(--repo PhoenixOauth2Provider.Test.Repo --no-boilerplate --controllers --no-migrations --no-config))

      assert_received {:mix_shell, :info, [
        """
        Configure your router.ex file the following way:

        defmodule PhoenixOauth2Provider.Router do
          use PhoenixOauth2ProviderWeb, :router
          use PhoenixOauth2Provider.Router

          pipeline :protected do
            # Require user authentication
          end

          scope "/", PhoenixOauth2Provider do
            pipe_through :browser
            oauth_routes :public
          end

          scope "/", PhoenixOauth2Provider do
            pipe_through [:browser, :protected]
            oauth_routes :protected
          end
          ...
        end
        """
      ]}
    end
  end

  describe "installs ex_oauth2_provider" do
    test "adds migrations" do
      Install.run(~w(--repo PhoenixOauth2Provider.Test.Repo --no-boilerplate --no-config --repo #{to_string MigrationsRepo}))

      assert [_] = MixHelpers.tmp_path() |> Path.join("migrations/*_create_oauth_tables.exs") |> Path.wildcard()
      assert_received {:mix_shell, :info, [
        """
        Don't forget to run the new migrations and seeds with:
            $ mix ecto.setup
        """
      ]}
    end
  end

  describe "installed options" do
    test "install options default" do
      Application.put_env :phoenix_oauth2_provider, :opts, [:application]
      Install.run(~w(--repo PhoenixOauth2Provider.Test.Repo --installed-options --no-provider))

      assert_received {:mix_shell, :info, ["mix phoenix_oauth2_provider.install --application"]}
    end
  end

  defp web_path(path), do: Path.join(@web_path, path)
end
