defmodule Mix.Tasks.PhoenixOauth2Provider.Install do
  use Mix.Task

  import PhoenixOauth2Provider.Mix.Utils
  require Logger

  @shortdoc "Configure the PhoenixOauth2Provider Package"

  @moduledoc """
  Configure PhoenixOauth2Provider for your Phoenix application.
  This installer will normally do the following unless given an option not to do so:
    * Append the :phoenix_oauth2_provider configuration to your `config/config.exs` file.
    * Generate appropriate migration files.
    * Generate appropriate view files.
    * Generate appropriate template files.
    * Generate a `WEB_PATH/phoenix_oauth2_provider_web.ex` file.
  ## Examples
      mix phoenix_oauth2_provider.install
  ## Option list
    * A PhoenixOauth2Provider configuration will be appended to your `config/config.exs` file unless
    the `--no-config` option is given.
    * A `--resource-owner MyApp.User` option can be given to override the default resource owner module in config.
    * A `--repo MyApp.Repo` option can be given to override the default Repo module.
    * A `--config-file config/config.exs` option can be given to change what config file to append to.
    * A `--controllers` option to generate controllers boilerplate (not default).
    * A `--installed-options` option to list the previous install options.
  ## Disable Options
    * `--no-config` -- Don't append to your `config/config.exs` file.
    * `--no-web` -- Don't create the `phoenix_oauth2_provider_web.ex` file.
    * `--no-views` -- Don't create the `WEB_PATH/views/phoenix_oauth2_provider/` files.
    * `--no-templates` -- Don't create the `WEB_PATH/templates/phoenix_oauth2_provider` files.
    * `--no-boilerplate` -- Don't create any of the boilerplate files.
    * `--no-provider` -- Don't run ex_oauth2_provider install script.
  """

  @all_options       ~w(application authorization authorized_application token)
  @all_options_atoms Enum.map(@all_options, &(String.to_atom(&1)))
  @default_options   ~w(application authorization authorized_application token)
  @full_options      @all_options -- ~w(application authorization authorized_application token)

  # the options that default to true, and can be disabled with --no-option
  @default_booleans  ~w(config web views templates boilerplate provider migrations)

  # all boolean_options
  @boolean_options   @default_booleans ++ ~w(default full) ++ @all_options

  @config_file "config/config.exs"

  @switches [
    resource_owner: :string, repo: :string, log_only: :boolean,
    controllers: :boolean, module: :string, installed_options: :boolean,
    config_file: :string
  ] ++ Enum.map(@boolean_options, &({String.to_atom(&1), :boolean}))

  @switch_names Enum.map(@switches, &(elem(&1, 0)))

  @doc false
  def run(args) do
    {opts, parsed, unknown} = OptionParser.parse(args, switches: @switches)

    verify_args!(parsed, unknown)

    {bin_opts, opts} = parse_options(opts)

    opts
    |> do_config(bin_opts)
    |> do_run
  end

  defp do_run(%{installed_options: true} = config),
    do: print_installed_options config

  defp do_run(config) do
    config
    |> install_ex_oauth2_provider
    |> gen_phoenix_oauth2_provider_config
    |> gen_phoenix_oauth2_provider_web
    |> gen_phoenix_oauth2_provider_views
    |> gen_phoenix_oauth2_provider_templates
    |> gen_phoenix_oauth2_provider_controllers
    |> print_instructions
    |> recompile_ex_oauth2_provider
    |> touch_config # work around for config file not getting recompiled
  end

  defp gen_phoenix_oauth2_provider_config(config) do
    config
    |> gen_phoenix_oauth2_provider_config_string
    |> write_config(config)
    |> log_config
  end
  defp gen_phoenix_oauth2_provider_config_string(config) do
    """
config :phoenix_oauth2_provider, PhoenixOauth2Provider,
  module: #{config[:base]},
  current_resource_owner: :current_user,
  repo: #{config[:repo]},
  resource_owner: #{config[:resource_owner]}\n
"""
  end

  defp write_config(string, %{config: true, config_file: config_file} = config) do
    case do_write_config(string, config_file) do
      {:error, reason} ->
        Mix.shell.info(reason)
        Enum.into [config_string: string, log_config?: true], config
      {:ok, reason} ->
        Mix.shell.info(reason)
        Enum.into [config_string: string, log_config?: false], config
    end
  end
  defp write_config(string, config), do: Enum.into([log_config?: true, config_string: string], config)

  defp do_write_config(string, config_file) do
    source = if File.exists?(config_file), do: File.read!(config_file), else: false
    cond do
      source === false ->
        {:error, "Could not find #{config_file}. Configuration was not added!"}
      String.contains? source, "config :phoenix_oauth2_provider," ->
        {:error, "Configuration was not added because one already exists!"}
      true ->
        File.write!(config_file, source <> "\n" <> string)
        {:ok, "Your #{config_file} file was updated, and deps has been recompiled."}
    end
  end

  defp log_config(%{log_config?: false} = config) do
    save_instructions config, ""
  end
  defp log_config(%{config_string: string, config_string: config_file} = config) do
    verb = if config[:log_config] === :appended, do: "has been", else: "should be"
    instructions = "The following #{verb} added to your #{config_file} file." <> string

    save_instructions config, instructions
  end

  defp touch_config(%{config_file: config_file} = config) do
    File.touch config_file
    config
  end

  ##################
  # ExOauth2Provider

  defp install_ex_oauth2_provider(%{provider: true, repo: _repo} = config) do
    install_ex_oauth2_provider_task(config, ~w(--no-config))
  end
  defp install_ex_oauth2_provider(config), do: config
  defp install_ex_oauth2_provider_task(%{config_file: _config_file, repo: _repo} = config, opts) do
    config
    |> install_ex_oauth2_provider_task_args(opts)
    |> Mix.Tasks.ExOauth2Provider.Install.run
    config
  end

  defp install_ex_oauth2_provider_task_args(config, opts) do
    ~w(--config-file #{config.config_file} --repo #{config.repo})
    |> Enum.concat(opts)
    |> add_resource_owner_arg(config)
  end

  defp add_resource_owner_arg(args, %{resource_owner: resource_owner}) do
    args
    |> Enum.concat(~w(--resource-owner=#{resource_owner}))
  end
  defp add_resource_owner_arg(args, _), do: args

  defp recompile_ex_oauth2_provider(%{provider: true} = config) do
    try do
      # Make sure that oauth2 uses the new config file
      Mix.Task.run "deps.compile", ~w(ex_oauth2_provider --force)
    rescue
      e in Mix.Error -> Logger.warn(e.message)
    end
    config
  end
  defp recompile_ex_oauth2_provider(config), do: config

  ################
  # Web

  defp gen_phoenix_oauth2_provider_web(%{web: true, boilerplate: true, binding: binding} = config) do
    Mix.Phoenix.copy_from paths(),
      "priv/boilerplate", binding, [
        {:eex, "phoenix_oauth2_provider_web.ex", web_path("phoenix_oauth2_provider_web.ex")},
      ]
    config
  end
  defp gen_phoenix_oauth2_provider_web(config), do: config

  ################
  # Views

  @view_files [
    all: "phoenix_oauth2_provider_view.ex",
    all: "layout_view.ex",
    all: "phoenix_oauth2_provider_view_helpers.ex",
    application: "application_view.ex",
    authorization: "authorization_view.ex",
    authorized_application: "authorized_application_view.ex"
  ]

  defp gen_phoenix_oauth2_provider_views(%{views: true, boilerplate: true, binding: binding} = config) do
    files = @view_files
    |> Enum.filter(&(validate_option(config, elem(&1, 0))))
    |> Enum.map(&(elem(&1, 1)))
    |> Enum.map(&({:eex, &1, web_path("views/phoenix_oauth2_provider/#{&1}")}))

    Mix.Phoenix.copy_from paths(), "priv/boilerplate/views", binding, files
    config
  end
  defp gen_phoenix_oauth2_provider_views(config), do: config

  @template_files [
    application: {:application, ~w(edit new form index show)},
    authorization: {:authorization, ~w(error new show)},
    authorized_application: {:authorized_application, ~w(index)},
    layout: {:all, ~w(app)}
  ]

  defp validate_option(_, :all), do: true
  defp validate_option(%{opts: opts}, opt) do
    if opt in opts, do: true, else: false
  end

  ################
  # Templates

  defp gen_phoenix_oauth2_provider_templates(%{templates: true, boilerplate: true, binding: binding} = config) do
    for {name, {opt, files}} <- @template_files do
      if validate_option(config, opt), do: copy_templates(binding, name, files)
    end
    config
  end
  defp gen_phoenix_oauth2_provider_templates(config), do: config

  defp copy_templates(binding, name, file_list) do
    Mix.Phoenix.copy_from paths(),
      "priv/boilerplate/templates/#{name}", binding, copy_templates_files(name, file_list)
  end
  defp copy_templates_files(name, file_list) do
    for fname <- file_list do
      fname = "#{fname}.html.eex"
      {:eex, fname, web_path("templates/phoenix_oauth2_provider/#{name}/#{fname}")}
    end
  end

  ################
  # Controllers

  @controller_files [
    application: "application_controller.ex",
    authorization: "authorization_controller.ex",
    token: "token_controller.ex",
    authorized_application: "authorized_application_controller.ex"

  ]

  defp gen_phoenix_oauth2_provider_controllers(%{controllers: true, boilerplate: true, binding: binding, base: base} = config) do
    files = @controller_files
    |> Enum.filter(&(validate_option(config, elem(&1, 0))))
    |> Enum.map(&(elem(&1, 1)))
    |> Enum.map(&({:text, &1, web_path("controllers/phoenix_oauth2_provider/#{&1}")}))

    # Mix.Phoenix.copy_from paths(), "priv/boilerplate/views", binding, files
    Mix.Phoenix.copy_from paths(),
      "priv/../lib/phoenix_oauth2_provider/web/controllers", binding, files

    files
    |> Enum.map(fn({_, _, f}) -> {f, File.read!(f)} end)
    |> Enum.each(fn({f, src}) ->
      File.write!(f, String.replace(src, ~r/(defmodule )(PhoenixOauth2Provider\..*Controller)/, "\\1#{base}.\\2"))
    end)

    config
  end
  defp gen_phoenix_oauth2_provider_controllers(config), do: config

  ################
  # Instructions

  defp router_instructions(%{base: base, controllers: controllers}) do
    namespace = if controllers, do: ", #{base}", else: ""

    router_instruction(namespace, base)
  end
  defp router_instruction(namespace, base) do
    """
    Configure your router.ex file the following way:

    defmodule #{base}.Router do
      use #{base}Web, :router
      use PhoenixOauth2Provider.Router

      pipeline :protected do
        # Require user authentication
      end

      # Don't require CSRF protection
      pipeline :oauth_public do
        plug :put_secure_browser_headers
      end

      scope "/"#{namespace} do
        pipe_through :oauth_public
        oauth_routes :public
      end

      scope "/"#{namespace} do
        pipe_through :protected
        oauth_routes :protected
      end
      ...
    end
    """
  end

  defp migrate_instructions(%{boilerplate: true, migrations: true}) do
    """
    Don't forget to run the new migrations and seeds with:
        $ mix ecto.setup
    """
  end
  defp migrate_instructions(_), do: ""

  defp print_instructions(%{instructions: instructions} = config) do
    Mix.shell.info instructions
    Mix.shell.info router_instructions(config)
    Mix.shell.info migrate_instructions(config)

    config
  end

  ################
  # Utilities

  defp do_default_config(config, opts) do
    @default_booleans
    |> list_to_atoms
    |> Enum.reduce(config, fn opt, acc ->
      Map.put acc, opt, Keyword.get(opts, opt, true)
    end)
  end

  defp list_to_atoms(list), do: Enum.map(list, &(String.to_atom(&1)))

  defp paths do
    [".", :phoenix_oauth2_provider]
  end

  defp save_instructions(config, instructions) do
    update_in config, [:instructions], &(&1 <> instructions)
  end

  ################
  # Installer Configuration

  defp do_config(opts, []) do
    do_config(opts, list_to_atoms(@default_options))
  end
  defp do_config(opts, bin_opts) do
    binding = Mix.Project.config
    |> Keyword.fetch!(:app)
    |> Atom.to_string
    |> Mix.Phoenix.inflect

    base = opts[:module] || binding[:base]
    opts = Keyword.put(opts, :base, base)
    repo = opts[:repo] || "#{base}.Repo"
    resource_owner = opts[:resource_owner] || "#{base}.User"
    config_file = opts[:config_file] || @config_file

    binding = Keyword.put binding, :base, base
    binding = Keyword.put binding, :web_prefix, web_path("")

    bin_opts
    |> Enum.map(&({&1, true}))
    |> Enum.into(%{})
    |> Map.put(:instructions, "")
    |> Map.put(:base, base)
    |> Map.put(:repo, repo)
    |> Map.put(:opts, bin_opts)
    |> Map.put(:binding, binding)
    |> Map.put(:log_only, opts[:log_only])
    |> Map.put(:controllers, opts[:controllers])
    |> Map.put(:module, opts[:module])
    |> Map.put(:installed_options, opts[:installed_options])
    |> Map.put(:config_file, config_file)
    |> Map.put(:resource_owner, resource_owner)
    |> do_default_config(opts)
  end

  defp parse_options(opts) do
    {opts_bin, opts} = reduce_options(opts)
    opts_bin = Enum.uniq(opts_bin)
    opts_names = Enum.map opts, &(elem(&1, 0))

    with  [] <- Enum.filter(opts_bin, &(not &1 in @switch_names)),
          [] <- Enum.filter(opts_names, &(not &1 in @switch_names)) do
            {opts_bin, opts}
    else
      list -> raise_option_errors(list)
    end
  end
  defp reduce_options(opts) do
    Enum.reduce opts, {[], []}, fn
      {:default, true}, {acc_bin, acc} ->
        {list_to_atoms(@default_options) ++ acc_bin, acc}
      {:full, true}, {acc_bin, acc} ->
        {list_to_atoms(@full_options) ++ acc_bin, acc}
      {name, true}, {acc_bin, acc} when name in @all_options_atoms ->
        {[name | acc_bin], acc}
      {name, false}, {acc_bin, acc} when name in @all_options_atoms ->
        {acc_bin -- [name], acc}
      opt, {acc_bin, acc} ->
        {acc_bin, [opt | acc]}
    end
  end

  defp print_installed_options(_config) do
    ["mix phoenix_oauth2_provider.install"]
    |> list_config_options(Application.get_env(:phoenix_oauth2_provider, :opts, []))
    |> Enum.reverse
    |> Enum.join(" ")
    |> Mix.shell.info
  end

  defp list_config_options(acc, opts) do
    opts
    |> Enum.reduce(acc, &config_option/2)
  end

  defp config_option(opt, acc) do
    str = opt
    |> Atom.to_string
    |> String.replace("_", "-")
    ["--" <> str | acc]
  end

  defp web_path(path), do: Path.join(get_web_prefix(), path)
  defp get_web_prefix do
    Mix.Phoenix.otp_app()
    |> Mix.Phoenix.web_path()
  end
end
