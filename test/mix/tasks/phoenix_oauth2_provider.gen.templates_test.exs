defmodule Mix.Tasks.PhoenixOauth2Provider.Gen.TemplatesTest do
  use PhoenixOauth2Provider.Mix.TestCase

  alias Mix.Tasks.PhoenixOauth2Provider.Gen.Templates

  @tmp_path Path.join(["tmp", inspect(Templates)])

  @expected_template_files %{
    "application" => ["edit.html.eex", "form.html.eex", "index.html.eex", "new.html.eex", "show.html.eex"],
    "authorization" => ["error.html.eex", "new.html.eex", "show.html.eex"],
    "authorized_application" => ["index.html.eex"]
  }
  @expected_views Map.keys(@expected_template_files)

  setup do
    File.rm_rf!(@tmp_path)
    File.mkdir_p!(@tmp_path)

    :ok
  end

  test "generates templates" do
    File.cd!(@tmp_path, fn ->
      Templates.run([])

      templates_path = Path.join(["lib", "phoenix_oauth2_provider_web", "templates", "phoenix_oauth2_provider"])
      expected_dirs  = Map.keys(@expected_template_files)

      assert ls(templates_path) == expected_dirs

      for {dir, expected_files} <- @expected_template_files do
        files = templates_path |> Path.join(dir) |> ls()
        assert files == expected_files
      end

      views_path          = Path.join(["lib", "phoenix_oauth2_provider_web", "views", "phoenix_oauth2_provider"])
      expected_view_files = Enum.map(@expected_views, &"#{&1}_view.ex")
      view_content        = views_path |> Path.join("application_view.ex") |> File.read!()

      assert ls(views_path) == expected_view_files
      assert view_content =~ "defmodule PhoenixOauth2ProviderWeb.PhoenixOauth2Provider.ApplicationView do"
      assert view_content =~ "use PhoenixOauth2ProviderWeb, :view"
    end)
  end

  defp ls(path), do: path |> File.ls!() |> Enum.sort()
end
