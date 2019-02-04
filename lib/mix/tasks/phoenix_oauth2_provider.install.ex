defmodule Mix.Tasks.PhoenixOauth2Provider.Install do
  use Mix.Task

  alias PhoenixOauth2Provider.Mix.Utils
  alias Mix.Tasks.ExOauth2Provider.Install, as: ExOAuth2ProviderInstall
  alias Mix.{Phoenix, Project}
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
    * A `--uuid` option can be given to set up :uuid enabled tables in ex_oauth2_provider
  ## Disable Options
    * `--no-config` -- Don't append to your `config/config.exs` file.
    * `--no-web` -- Don't create the `phoenix_oauth2_provider_web.ex` file.
    * `--no-views` -- Don't create the `WEB_PATH/views/phoenix_oauth2_provider/` files.
    * `--no-templates` -- Don't create the `WEB_PATH/templates/phoenix_oauth2_provider` files.
    * `--no-boilerplate` -- Don't create any of the boilerplate files.
    * `--no-provider` -- Don't run ex_oauth2_provider install script.
  """

  @all_options       ~w(application authorization authorized_application token)
  @all_options_atoms Enum.map(@all_options, &(String.to_existing_atom(&1)))
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
    config_file: :string, uuid: :string
  ] ++ Enum.map(@boolean_options, &({String.to_existing_atom(&1), :boolean}))

  @switch_names Enum.map(@switches, &(elem(&1, 0)))

  @apps [".", :phoenix_oauth2_provider]

  @doc false
  @spec run(OptionParser.argv()) :: map()
  def run(args) do
    args
    |> OptionParser.parse(switches: @switches)
    |> Utils.verify_args!()
    |> parse_options()
    |> do_config()
    |> do_run()
  end

  defp do_run(%{installed_options: true} = config) do
    print_installed_options(config)
  end
  defp do_run(config) do
    config
    |> install_ex_oauth2_provider()
    |> gen_phoenix_oauth2_provider_config()
    |> gen_phoenix_oauth2_provider_web()
    |> gen_phoenix_oauth2_provider_views()
    |> gen_phoenix_oauth2_provider_templates()
    |> gen_phoenix_oauth2_provider_controllers()
    |> print_instructions()
    |> recompile_ex_oauth2_provider()
    |> touch_config() # work around for config file not getting recompiled
  end

  defp gen_phoenix_oauth2_provider_config(config) do
    config
    |> gen_phoenix_oauth2_provider_config_string()
    |> write_config(config)
    |> log_config()
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
        Enum.into([config_string: string, config_instructions?: true], config)

      {:ok, reason} ->
        Mix.shell.info(reason)
        Enum.into([config_string: string, config_instructions?: false], config)
    end
  end
  defp write_config(string, config) do
    Enum.into([config_instructions?: true, config_string: string], config)
  end

  defp do_write_config(string, config_file) do
    config_file
    |> File.exists?()
    |> maybe_check_existing(config_file)
    |> maybe_write_config(string, config_file)
  end

  defp maybe_check_existing(false, config_file) do
    {:error, "Could not find #{config_file}. Configuration was not added!"}
  end
  defp maybe_check_existing(true, config_file) do
    source = File.read!(config_file)

    case String.contains?(source, "config :phoenix_oauth2_provider,") do
      true -> {:error, "Configuration was not added because one already exists!"}
      false -> {:ok, source}
    end
  end

  defp maybe_write_config({:error, reason}, _string, _config_file), do: {:error, reason}
  defp maybe_write_config({:ok, source}, string, config_file) do
    File.write!(config_file, source <> "\n" <> string)

    {:ok, "Your #{config_file} file was updated, and deps has been recompiled."}
  end

  defp log_config(%{config_instructions?: false} = config), do: config
  defp log_config(%{config_instructions?: true, config_string: string, config_file: config_file} = config) do
    instructions = "Please add the following to your #{config_file} file." <> "\n\n" <> string

    update_in(config, [:instructions], &(&1 <> instructions))
  end

  defp touch_config(%{config_file: config_file} = config) do
    File.touch(config_file)
    config
  end

  ##################
  # ExOauth2Provider

  defp install_ex_oauth2_provider(%{provider: true, repo: _repo} = config) do
    config
    |> install_ex_oauth2_provider_task_args()
    |> ExOAuth2ProviderInstall.run()

    config
  end
  defp install_ex_oauth2_provider(config), do: config

  defp install_ex_oauth2_provider_task_args(%{repo: repo} = config) do
    ["--no-config", "--repo", repo]
    |> ex_oauth2_provider_add_resource_owner_arg(config)
    |> ex_oauth2_provider_add_uuid_arg(config)
    |> ex_oauth2_provider_add_migrations_arg(config)
  end

  defp ex_oauth2_provider_add_resource_owner_arg(args, %{resource_owner: resource_owner}) do
    Enum.concat(args, ["--resource-owner", resource_owner])
  end
  defp ex_oauth2_provider_add_resource_owner_arg(args, _config), do: args

  defp ex_oauth2_provider_add_uuid_arg(args, %{uuid: nil}), do: args
  defp ex_oauth2_provider_add_uuid_arg(args, %{uuid: uuid}), do: args ++ ["--uuid", uuid]

  defp ex_oauth2_provider_add_migrations_arg(args, %{migrations: false}), do: args ++ ["--no-migrations"]
  defp ex_oauth2_provider_add_migrations_arg(args, _config), do: args

  defp recompile_ex_oauth2_provider(%{provider: true} = config) do
    # Make sure that oauth2 uses the new config file
    Mix.Task.run("deps.compile", ~w(ex_oauth2_provider --force))

    config
  rescue
    e in Mix.Error -> Logger.warn(e.message)

    config
  end
  defp recompile_ex_oauth2_provider(config), do: config

  ################
  # Web

  defp gen_phoenix_oauth2_provider_web(%{web: true, boilerplate: true, binding: binding} = config) do
    source  = "priv/boilerplate"
    mapping = [{:eex, "phoenix_oauth2_provider_web.ex", Utils.web_path("phoenix_oauth2_provider_web.ex")}]

    Phoenix.copy_from(@apps, source, binding, mapping)

    config
  end
  defp gen_phoenix_oauth2_provider_web(config), do: config

  ################
  # Views

  @view_files [
    all:                    "phoenix_oauth2_provider_view.ex",
    all:                    "layout_view.ex",
    all:                    "phoenix_oauth2_provider_view_helpers.ex",
    application:            "application_view.ex",
    authorization:          "authorization_view.ex",
    authorized_application: "authorized_application_view.ex"
  ]

  defp gen_phoenix_oauth2_provider_views(%{views: true, boilerplate: true, binding: binding} = config) do
    source  = "priv/boilerplate/views"
    mapping = @view_files
              |> Enum.filter(&(validate_option(config, elem(&1, 0))))
              |> Enum.map(&(elem(&1, 1)))
              |> Enum.map(&({:eex, &1, Utils.web_path("views/phoenix_oauth2_provider/#{&1}")}))

    Phoenix.copy_from(@apps, source, binding, mapping)

    config
  end
  defp gen_phoenix_oauth2_provider_views(config), do: config

  @template_files [
    application:            {:application, ~w(edit new form index show)},
    authorization:          {:authorization, ~w(error new show)},
    authorized_application: {:authorized_application, ~w(index)},
    layout:                 {:all, ~w(app)}
  ]

  defp validate_option(_, :all), do: true
  defp validate_option(%{opts: opts}, opt), do: Enum.member?(opts, opt)

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
    source  = "priv/boilerplate/templates/#{name}"
    mapping = copy_templates_files(name, file_list)

    Phoenix.copy_from(@apps, source, binding, mapping)
  end

  defp copy_templates_files(name, file_list) do
    for fname <- file_list do
      fname = "#{fname}.html.eex"
      {:eex, fname, Utils.web_path("templates/phoenix_oauth2_provider/#{name}/#{fname}")}
    end
  end

  ################
  # Controllers

  @controller_files [
    application:            "application_controller.ex",
    authorization:          "authorization_controller.ex",
    token:                  "token_controller.ex",
    authorized_application: "authorized_application_controller.ex"
  ]

  defp gen_phoenix_oauth2_provider_controllers(%{controllers: true, boilerplate: true, binding: binding, base: base} = config) do
    source  = "priv/../lib/phoenix_oauth2_provider/web/controllers"
    mapping = @controller_files
              |> Enum.filter(&(validate_option(config, elem(&1, 0))))
              |> Enum.map(&(elem(&1, 1)))
              |> Enum.map(&({:text, &1, Utils.web_path("controllers/phoenix_oauth2_provider/#{&1}")}))

    Phoenix.copy_from(@apps, source, binding, mapping)
    Enum.each(mapping, &update_controller_file_with_base_module!(&1, base))

    config
  end
  defp gen_phoenix_oauth2_provider_controllers(config), do: config

  defp update_controller_file_with_base_module!({_, _, file}, base) do
    regex   = ~r/(defmodule )(PhoenixOauth2Provider\..*Controller)/
    replace = "\\1#{base}.\\2"
    content = file |> File.read!() |> String.replace(regex, replace)

    File.write!(file, content)
  end

  ################
  # Instructions

  defp router_instructions(%{base: base, controllers: true}) do
    router_instruction(", #{base}", base)
  end
  defp router_instructions(%{base: base}) do
    router_instruction("", base)
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

      scope "/"#{namespace} do
        pipe_through :browser
        oauth_routes :public
      end

      scope "/"#{namespace} do
        pipe_through [:browser, :protected]
        oauth_routes :protected
      end
      ...
    end
    """
  end

  defp migrate_instructions(%{migrations: true}) do
    """
    Don't forget to run the new migrations and seeds with:
        $ mix ecto.setup
    """
  end
  defp migrate_instructions(_config), do: ""

  defp print_instructions(%{instructions: instructions} = config) do
    Mix.shell.info(instructions)
    Mix.shell.info(router_instructions(config))
    Mix.shell.info(migrate_instructions(config))

    config
  end

  ################
  # Utilities

  defp do_default_config(config, opts) do
    @default_booleans
    |> Utils.list_to_existing_atoms()
    |> Enum.reduce(config, fn opt, acc ->
      Map.put(acc, opt, Keyword.get(opts, opt, true))
    end)
  end

  ################
  # Installer Configuration

  defp do_config({[], opts}) do
    bin_opts = Utils.list_to_existing_atoms(@default_options)

    do_config({bin_opts, opts})
  end
  defp do_config({bin_opts, opts}) do
    binding = Project.config()
              |> Keyword.fetch!(:app)
              |> Atom.to_string()
              |> Phoenix.inflect()

    base = opts[:module] || binding[:base]
    opts = Keyword.put(opts, :base, base)
    repo = opts[:repo] || "#{base}.Repo"
    resource_owner = opts[:resource_owner] || "#{base}.User"
    config_file = opts[:config_file] || @config_file

    binding = Keyword.put(binding, :base, base)
    binding = Keyword.put(binding, :web_prefix, Utils.web_path())

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
    |> Map.put(:uuid, opts[:uuid])
    |> do_default_config(opts)
  end

  defp parse_options({opts, _argv, _errors}) do
    opts
    |> reduce_options()
    |> process_reduced_options()
  end

  defp reduce_options(opts) do
    Enum.reduce(opts, {[], []}, &reduce_option/2)
  end

  defp reduce_option({:default, true}, {acc_bin, acc}),
    do: {Utils.list_to_existing_atoms(@default_options) ++ acc_bin, acc}
  defp reduce_option({:full, true}, {acc_bin, acc}),
    do: {Utils.list_to_existing_atoms(@full_options) ++ acc_bin, acc}
  defp reduce_option({name, true}, {acc_bin, acc}) when name in @all_options_atoms,
    do: {[name | acc_bin], acc}
  defp reduce_option({name, false}, {acc_bin, acc}) when name in @all_options_atoms,
    do: {acc_bin -- [name], acc}
  defp reduce_option(opt, {acc_bin, acc}), do: {acc_bin, [opt | acc]}

  defp process_reduced_options({opts_bin, opts}) do
    opts_bin = Enum.uniq(opts_bin)
    opts_names = Enum.map(opts, &(elem(&1, 0)))

    with  [] <- Enum.filter(opts_bin, &(not &1 in @switch_names)),
          [] <- Enum.filter(opts_names, &(not &1 in @switch_names)) do
            {opts_bin, opts}
    else
      list -> Utils.raise_option_errors(list)
    end
  end

  defp print_installed_options(config) do
    :phoenix_oauth2_provider
    |> Application.get_env(:opts, [])
    |> Utils.to_config_options(["mix phoenix_oauth2_provider.install"])
    |> Enum.reverse()
    |> Enum.join(" ")
    |> Mix.shell.info()

    config
  end
end
