defmodule Mix.Tasks.PhoenixOauth2Provider.Gen.Templates do
  @shortdoc "Generates PhoenixOauth2Provider templates"

  @moduledoc """
  Generates views and templates.

      mix phoenix_oauth2_provider.gen.templates

  ## Arguments

    * `--context-app` - context app to use for path and module names
  """
  use Mix.Task

  alias Mix.ExOauth2Provider
  alias Mix.PhoenixOauth2Provider.Template

  @switches     [context_app: :string]
  @default_opts []
  @mix_task     "phoenix_oauth2_provider.gen.templates"

  @impl true
  def run(args) do
    ExOauth2Provider.no_umbrella!(@mix_task)

    args
    |> ExOauth2Provider.parse_options(@switches, @default_opts)
    |> parse()
    |> create_template_files()
  end

  defp parse({config, _parsed, _invalid}), do: config

  defp create_template_files(config) do
    config
    |> Map.get(:context_app)
    |> Kernel.||(ExOauth2Provider.otp_app())
    |> Template.create_view_and_template_files()
  end
end
