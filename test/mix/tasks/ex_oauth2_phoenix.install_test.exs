Code.require_file "../../mix_helpers.exs", __DIR__

defmodule Mix.Tasks.ExOauth2Phoenix.InstallTest do
  use ExUnit.Case
  import MixHelper

  defmodule MigrationsRepo do
    def __adapter__ do
      true
    end

    def config do
      [priv: "tmp", otp_app: :ex_oauth2_phoenix]
    end
  end

  setup do
    :ok
  end

  @all_template_dirs ~w(layout application)
  @all_views ~w(ex_oauth2_phoenix_view_helpers.ex ex_oauth2_phoenix_view.ex application_view.ex) ++
    ~w(layout_view.ex)
  @all_controllers Enum.map(@all_template_dirs -- ~w(layout), &("#{&1}_controller.ex"))

  test "generates files for application" do
    in_tmp "generates_views_for_application", fn ->
      ~w(--repo ExOauth2Phoenix.Test.Repo --log-only --controllers --module ExOauth2Phoenix.Test --no-provider)
      |> Mix.Tasks.ExOauth2Phoenix.Install.run

      ~w(application_view.ex ex_oauth2_phoenix_view.ex layout_view.ex ex_oauth2_phoenix_view_helpers.ex)
      |> assert_file_list(@all_views, "web/views/ex_oauth2_phoenix/")

      ~w(layout application)
      |> assert_dirs(@all_template_dirs, "web/templates/ex_oauth2_phoenix/")

      ~w(application_controller.ex)
      |> assert_file_list(@all_controllers, "web/controllers/ex_oauth2_phoenix/")

      assert_file "web/controllers/ex_oauth2_phoenix/application_controller.ex", fn file ->
        assert file =~ "defmodule ExOauth2Phoenix.Test.ExOauth2Phoenix.ApplicationController do"
      end
    end
  end

  test "does not generate files for full" do
    in_tmp "does_not_generate_files_for_full", fn ->
      ~w(--repo ExOauth2Phoenix.Test.Repo --full --log-only --no-boilerplate --no-provider)
      |> Mix.Tasks.ExOauth2Phoenix.Install.run

      ~w()
      |> assert_file_list(@all_views, "web/views/ex_oauth2_phoenix/")

      ~w()
      |> assert_dirs(@all_template_dirs, "web/templates/ex_oauth2_phoenix/")

      ~w()
      |> assert_file_list(@all_controllers, "web/controllers/ex_oauth2_phoenix/")
    end
  end

  test "updates config" do
    in_tmp "installs_ex_oauth2_phoenix_config", fn ->
      file_path = "config.exs"
      File.touch! file_path
      ~w(--repo ExOauth2Phoenix.Test.Repo --no-boilerplate --no-migrations --config-file #{File.cwd!}/#{file_path})
      |> Mix.Tasks.ExOauth2Phoenix.Install.run

      assert_file file_path, fn file ->
        assert file =~ "config :ex_oauth2_phoenix, ExOauth2Phoenix"
        assert file =~ "module: ExOauth2Phoenix"
        assert file =~ "current_resource_owner: :current_user"
      end
    end
  end

  describe "installs ex_oauth2_provider" do
    test "adds migrations" do
      ~w(--repo ExOauth2Phoenix.Test.Repo --no-boilerplate --no-config --repo #{to_string MigrationsRepo})
      |> Mix.Tasks.ExOauth2Phoenix.Install.run

      assert [_] = Path.wildcard("tmp/migrations/*_create_oauth_tables.exs")
    end

    test "updates config" do
      in_tmp "installs_ex_oauth2_provider_config", fn ->
        file_path = "config.exs"
        File.touch! file_path
        ~w(--repo ExOauth2Phoenix.Test.Repo --no-boilerplate --no-migrations --config-file #{File.cwd!}/#{file_path} --resource-owner MyApp.CustomUser)
        |> Mix.Tasks.ExOauth2Phoenix.Install.run

        assert_file file_path, fn file ->
          assert file =~ "config :ex_oauth2_provider, ExOauth2Provider"
          assert file =~ "repo: Elixir.ExOauth2Phoenix.Test.Repo"
          assert file =~ "resource_owner: MyApp.CustomUser"
        end
      end
    end
  end

  describe "installed options" do
    test "install options default" do
      Application.put_env :ex_oauth2_phoenix, :opts, [:application]
      ~w(--repo ExOauth2Phoenix.Test.Repo --installed-options --no-provider)
      |>  Mix.Tasks.ExOauth2Phoenix.Install.run

      assert_received {:mix_shell, :info, [output]}
      assert output == "mix ex_oauth2_phoenix.install --application"
    end
  end

  def assert_dirs(dirs, full_dirs, path) do
    Enum.each dirs, fn dir ->
      assert File.dir? path <> dir
    end
    Enum.each full_dirs -- dirs, fn dir ->
      refute File.dir? path <> dir
    end
  end

  def assert_file_list(files, full_files, path) do
    Enum.each files, fn file ->
      assert_file path <> file
    end
    Enum.each full_files -- files, fn file ->
      refute_file path <> file
    end
  end
end
