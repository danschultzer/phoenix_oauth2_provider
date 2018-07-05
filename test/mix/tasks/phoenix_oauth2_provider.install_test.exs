Code.require_file "../../mix_helpers.exs", __DIR__

defmodule Mix.Tasks.PhoenixOauth2Provider.InstallTest do
  use ExUnit.Case
  import MixHelper

  defmodule MigrationsRepo do
    def __adapter__ do
      true
    end

    def config do
      [priv: "tmp", otp_app: :phoenix_oauth2_provider]
    end
  end

  @web_path "lib/phoenix_oauth2_provider_web"
  @all_template_dirs ~w(layout application authorization authorized_application)
  @all_views ~w(phoenix_oauth2_provider_view_helpers.ex phoenix_oauth2_provider_view.ex layout_view.ex) ++
    ~w(application_view.ex authorization_view.ex authorized_application_view.ex)
  @all_controllers Enum.map(@all_template_dirs -- ~w(layout), &("#{&1}_controller.ex"))

  test "generates files for application" do
    in_tmp "generates_files_for_application", fn ->
      ~w(--repo PhoenixOauth2Provider.Test.Repo --log-only --controllers --module PhoenixOauth2Provider.Test --no-provider)
      |> Mix.Tasks.PhoenixOauth2Provider.Install.run()

      ~w(application_view.ex authorization_view.ex authorized_application_view.ex phoenix_oauth2_provider_view.ex layout_view.ex phoenix_oauth2_provider_view_helpers.ex)
      |> assert_file_list(@all_views, web_path("views/phoenix_oauth2_provider/"))

      ~w(layout application authorization authorized_application)
      |> assert_dirs(@all_template_dirs, web_path("templates/phoenix_oauth2_provider/"))

      ~w(application_controller.ex authorization_controller.ex authorized_application_controller.ex token_controller.ex)
      |> assert_file_list(@all_controllers, web_path("controllers/phoenix_oauth2_provider/"))

      assert_file web_path("controllers/phoenix_oauth2_provider/application_controller.ex"), fn file ->
        assert file =~ "defmodule PhoenixOauth2Provider.Test.PhoenixOauth2Provider.ApplicationController do"
      end
    end
  end

  test "does not generate files for full" do
    in_tmp "does_not_generate_files_for_full", fn ->
      ~w(--repo PhoenixOauth2Provider.Test.Repo --full --log-only --no-boilerplate --no-provider)
      |> Mix.Tasks.PhoenixOauth2Provider.Install.run()

      assert_file_list([], @all_views, web_path("views/phoenix_oauth2_provider/"))

      assert_dirs([], @all_template_dirs, web_path("templates/phoenix_oauth2_provider/"))

      assert_file_list([], @all_controllers, web_path("controllers/phoenix_oauth2_provider/"))
    end
  end

  test "updates config" do
    in_tmp "installs_phoenix_oauth2_provider_config", fn ->
      file_path = "config.exs"
      File.touch! file_path
      ~w(--repo PhoenixOauth2Provider.Test.Repo --no-boilerplate --no-migrations --config-file #{File.cwd!}/#{file_path})
      |> Mix.Tasks.PhoenixOauth2Provider.Install.run()

      assert_file file_path, fn file ->
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
    in_tmp "prints_instructions", fn ->
      ~w(--repo PhoenixOauth2Provider.Test.Repo --no-boilerplate --no-migrations --no-config)
      |> Mix.Tasks.PhoenixOauth2Provider.Install.run()

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

          # Don't require CSRF protection
          pipeline :oauth_public do
            plug :put_secure_browser_headers
          end

          scope "/" do
            pipe_through :oauth_public
            oauth_routes :public
          end

          scope "/" do
            pipe_through :protected
            oauth_routes :protected
          end
          ...
        end
        """
      ]}

      ~w(--repo PhoenixOauth2Provider.Test.Repo --no-boilerplate --controllers --no-migrations --no-config)
      |> Mix.Tasks.PhoenixOauth2Provider.Install.run()

      assert_received {:mix_shell, :info, [
        """
        Configure your router.ex file the following way:

        defmodule PhoenixOauth2Provider.Router do
          use PhoenixOauth2ProviderWeb, :router
          use PhoenixOauth2Provider.Router

          pipeline :protected do
            # Require user authentication
          end

          # Don't require CSRF protection
          pipeline :oauth_public do
            plug :put_secure_browser_headers
          end

          scope "/", PhoenixOauth2Provider do
            pipe_through :oauth_public
            oauth_routes :public
          end

          scope "/", PhoenixOauth2Provider do
            pipe_through :protected
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
      ~w(--repo PhoenixOauth2Provider.Test.Repo --no-boilerplate --no-config --repo #{to_string MigrationsRepo})
      |> Mix.Tasks.PhoenixOauth2Provider.Install.run()

      assert [_] = Path.wildcard("tmp/migrations/*_create_oauth_tables.exs")
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
      ~w(--repo PhoenixOauth2Provider.Test.Repo --installed-options --no-provider)
      |>  Mix.Tasks.PhoenixOauth2Provider.Install.run()

      assert_received {:mix_shell, :info, ["mix phoenix_oauth2_provider.install --application"]}
    end
  end

  defp assert_dirs(dirs, full_dirs, path) do
    Enum.each dirs, fn dir ->
      assert File.dir?(Path.join(path, dir))
    end

    Enum.each full_dirs -- dirs, fn dir ->
      refute File.dir?(Path.join(path, dir))
    end
  end

  defp assert_file_list(files, full_files, path) do
    Enum.each files, fn file ->
      assert_file Path.join(path, file)
    end

    Enum.each full_files -- files, fn file ->
      refute_file Path.join(path, file)
    end
  end

  defp web_path(path), do: Path.join(@web_path, path)
end
