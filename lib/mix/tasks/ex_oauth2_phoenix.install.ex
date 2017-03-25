defmodule Mix.Tasks.ExOauth2Phoenix.Install do
  use Mix.Task

  import ExOauth2Phoenix.Mix.Utils

  @shortdoc "Configure the ExOauth2Phoenix Package"

  @moduledoc """
  Configure ExOauth2Phoenix for your Phoenix application.
  This installer will normally do the following unless given an option not to do so:
  * Append the :ex_oauth2_phoenix configuration to your `config/config.exs` file.
  * Append the :ex_oauth2_provider configuration to your `config/config.exs` file.
  * Generate appropriate migration files.
  * Generate appropriate view files.
  * Generate appropriate template files.
  * Generate a `web/ex_oauth2_phoenix_web.ex` file.
  ## Examples
      mix ex_oauth2_phoenix.install
  ## Option list
  A ExOauth2Phoenix configuration will be appended to your `config/config.exs` file unless
  the `--no-config` option is given.
  A `--resource_owner="SomeModule"` option can be given to override the default User module.
  A `--repo=CustomRepo` option can be given to override the default Repo module
  A `--controllers` option to generate controllers boilerplate (not default)
  A `--installed-options` option to list the previous install options
  ## Disable Options
  * `--no-config` -- Don't append to your `config/config.exs` file.
  * `--no-web` -- Don't create the `ex_oauth2_phoenix_web.ex` file.
  * `--no-views` -- Don't create the `web/views/ex_oauth2_phoenix/` files.
  * `--no-templates` -- Don't create the `web/templates/ex_oauth2_phoenix` files.
  * `--no-boilerplate` -- Don't create any of the boilerplate files.
  * `--no-provider` -- Don't run ex_oauth2_provider install script.
  """

  @all_options       ~w(application authorization)
  @all_options_atoms Enum.map(@all_options, &(String.to_atom(&1)))
  @default_options   ~w(application authorization)
  @full_options      @all_options -- ~w(application authorization)

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
    |> gen_ex_oauth2_phoenix_config
    |> gen_ex_oauth2_phoenix_web
    |> gen_ex_oauth2_phoenix_views
    |> gen_ex_oauth2_phoenix_templates
    |> gen_ex_oauth2_phoenix_controllers
    |> touch_config                # work around for config file not getting recompiled
    |> print_instructions
  end

  defp gen_ex_oauth2_phoenix_config(config) do
    """
config :ex_oauth2_phoenix,
  module: #{config[:base]},
  opts: #{inspect config[:opts]}\n
"""
    |> write_config(config)
    |> log_config
  end

  defp write_config(string, %{config: true, config_file: config_file} = config) do
    log_config? = if File.exists? config_file do
      source = File.read!(config_file)
      if String.contains? source, "config :ex_oauth2_phoenix," do
        Mix.shell.info "Configuration was not added because one already exists!"
        true
      else
        File.write!(config_file, source <> "\n" <> string)
        Mix.shell.info "Your config/config.exs file was updated."
        false
      end
    else
      Mix.shell.info "Could not find #{config_file}. Configuration was not added!"
      true
    end
    Enum.into [config_string: string, log_config?: log_config?], config
  end
  defp write_config(string, config), do: Enum.into([log_config?: true, config_string: string], config)

  defp log_config(%{log_config?: false} = config) do
    save_instructions config, ""
  end
  defp log_config(%{config_string: string, config_string: config_file} = config) do
    verb = if config[:log_config] == :appended, do: "has been", else: "should be"
    instructions = """
    The following #{verb} added to your #{config_file} file.
    """ <> string

    save_instructions config, instructions
  end

  defp touch_config(%{config_file: config_file} = config) do
    File.touch config_file
    config
  end

  ##################
  # ExOauth2Provider

  defp install_ex_oauth2_provider(%{provider: true, config: true, config_file: config_file, repo: repo} = config) do
    Mix.Tasks.ExOauth2Provider.Install.run ~w(--config-file #{config_file} --repo #{repo})
    config
  end
  defp install_ex_oauth2_provider(%{provider: true, config: false, config_file: config_file, repo: repo} = config) do
    Mix.Tasks.ExOauth2Provider.Install.run ~w(--config-file #{config_file} --repo #{repo} --no-config)
    config
  end
  defp install_ex_oauth2_provider(config), do: config


  ################
  # Web

  defp gen_ex_oauth2_phoenix_web(%{web: true, boilerplate: true, binding: binding} = config) do
    Mix.Phoenix.copy_from paths(),
      "priv/boilerplate", "", binding, [
        {:eex, "ex_oauth2_phoenix_web.ex", "web/ex_oauth2_phoenix_web.ex"},
      ]
    config
  end
  defp gen_ex_oauth2_phoenix_web(config), do: config

  ################
  # Views

  @view_files [
    all: "ex_oauth2_phoenix_view.ex",
    all: "layout_view.ex",
    all: "ex_oauth2_phoenix_view_helpers.ex",
    application: "application_view.ex",
    authorization: "authorization_view.ex"
  ]

  def view_files, do: @view_files

  def gen_ex_oauth2_phoenix_views(%{views: true, boilerplate: true, binding: binding} = config) do
    files = @view_files
    |> Enum.filter_map(&(validate_option(config, elem(&1,0))), &(elem(&1, 1)))
    |> Enum.map(&({:eex, &1, "web/views/ex_oauth2_phoenix/#{&1}"}))

    Mix.Phoenix.copy_from paths(), "priv/boilerplate/views", "", binding, files
    config
  end
  def gen_ex_oauth2_phoenix_views(config), do: config

  @template_files [
    application: {:application, ~w(edit new form index show)},
    authorization: {:authorization, ~w(error new show)},
    layout: {:all, ~w(app)}
  ]
  def template_files, do: @template_files

  defp validate_option(_, :all), do: true
  defp validate_option(%{opts: opts}, opt) do
    if opt in opts, do: true, else: false
  end

  ################
  # Templates

  def gen_ex_oauth2_phoenix_templates(%{templates: true, boilerplate: true, binding: binding} = config) do
    for {name, {opt, files}} <- @template_files do
      if validate_option(config, opt), do: copy_templates(binding, name, files)
    end
    config
  end
  def gen_ex_oauth2_phoenix_templates(config), do: config

  defp copy_templates(binding, name, file_list) do
    files = for fname <- file_list do
      fname = "#{fname}.html.eex"
      {:eex, fname, "web/templates/ex_oauth2_phoenix/#{name}/#{fname}"}
    end

    Mix.Phoenix.copy_from paths(),
      "priv/boilerplate/templates/#{name}", "", binding, files
  end

  ################
  # Controllers

  @controller_files [
    application: "application_controller.ex",
    authorization: "authorization_controller.ex"
  ]
  def controller_files, do: @controller_files

  defp gen_ex_oauth2_phoenix_controllers(%{controllers: true, boilerplate: true, binding: binding, base: base} = config) do
    files = @controller_files
    |> Enum.filter_map(&(validate_option(config, elem(&1,0))), &(elem(&1, 1)))
    |> Enum.map(&({:eex, &1, "web/controllers/ex_oauth2_phoenix/#{&1}"}))

    Mix.Phoenix.copy_from paths(),
      "priv/boilerplate/controllers", "", binding, files

    files
    |> Enum.map(fn({_, _, f}) -> {f, File.read!(f)} end)
    |> Enum.each(fn({f, src}) ->
      File.write!(f, String.replace(src, ~r/(defmodule )(ExOauth2Phoenix\..*Controller)/, "\\1#{base}.\\2"))
    end)

    config
  end
  defp gen_ex_oauth2_phoenix_controllers(config), do: config

  ################
  # Instructions

  defp router_instructions(%{base: base, controllers: controllers}) do
    namespace = if controllers, do: ", #{base}", else: ""
    """
    Add the following to your router.ex file.
    defmodule #{base}.Router do
      use #{base}.Web, :router
      use ExOauth2Phoenix.Router # Add this
      pipeline :browser do
        ...
      end
      pipeline :protected do
        ...
      end
      # Add this block
      scope "/"#{namespace} do
        pipe_through :protected
        oauth_routes
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
    [".", :ex_oauth2_phoenix]
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
    repo = (opts[:repo] || "#{base}.Repo")
    config_file = opts[:config_file] || @config_file

    binding = Keyword.put binding ,:base, base

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
    |> do_default_config(opts)
  end

  defp parse_options(opts) do
    {opts_bin, opts} = Enum.reduce opts, {[], []}, fn
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
    opts_bin = Enum.uniq(opts_bin)
    opts_names = Enum.map opts, &(elem(&1, 0))
    with  [] <- Enum.filter(opts_bin, &(not &1 in @switch_names)),
          [] <- Enum.filter(opts_names, &(not &1 in @switch_names)) do
            {opts_bin, opts}
    else
      list -> raise_option_errors(list)
    end
  end

  def all_options, do: @all_options_atoms

  def print_installed_options(_config) do
    ["mix ex_oauth2_phoenix.install"]
    |> list_config_options(Application.get_env(:ex_oauth2_phoenix, :opts, []))
    |> Enum.reverse
    |> Enum.join(" ")
    |> Mix.shell.info
  end

  def list_config_options(acc, opts) do
    opts
    |> Enum.reduce(acc, &config_option/2)
  end

  defp config_option(opt, acc) do
    str = opt
    |> Atom.to_string
    |> String.replace("_", "-")
    ["--" <> str | acc]
  end
end
