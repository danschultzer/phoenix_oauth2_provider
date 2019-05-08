defmodule Mix.PhoenixOauth2Provider.Template do
  @moduledoc false

  alias ExOauth2Provider.Config
  alias Mix.{Generator, Phoenix}

  @views ["application", "authorization", "authorized_application"]
  @view_template """
  defmodule <%= inspect view_module %> do
    use <%= inspect web_module %>, :view
  end
  """

  @spec create_view_and_template_files(binary()) :: map()
  def create_view_and_template_files(context_app) do
    web_module =
      context_app
      |> web_app()
      |> Macro.camelize()
      |> List.wrap()
      |> Module.concat()
    web_path = web_path(context_app)

    for name <- @views do
      create_view_file(web_module, web_path, name)
      create_template_files(web_path, name)
    end
  end

  defp create_view_file(web_module, web_path, name) do
    view_name   = "#{name}_view"
    dir         = Path.join([web_path, "views", "phoenix_oauth2_provider"])
    path        = Path.join(dir, "#{view_name}.ex")
    view_module = Module.concat([web_module, PhoenixOauth2Provider, Macro.camelize(view_name)])
    content     = EEx.eval_string(@view_template, view_module: view_module, web_module: web_module)

    Generator.create_directory(dir)
    Generator.create_file(path, content)
  end

  defp create_template_files(web_path, name) do
    view_module = Module.concat([PhoenixOauth2Provider, Macro.camelize("#{name}_view")])

    for template <- view_module.templates() do
      content = view_module.html(template)
      dir     = Path.join([web_path, "templates", "phoenix_oauth2_provider", name])
      path    = Path.join(dir, "#{template}.eex")

      Generator.create_directory(dir)
      Generator.create_file(path, content)
    end
  end

  defp web_path(context_app), do: Phoenix.web_path(context_app)

  defp web_app(ctx_app) do
    this_app = Config.otp_app()

    if ctx_app == this_app do
      "#{ctx_app}_web"
    else
      ctx_app
    end
  end
end
