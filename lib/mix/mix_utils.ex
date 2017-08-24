defmodule PhoenixOauth2Provider.Mix.Utils do
  @moduledoc false

  def rm_dir!(dir) do
    if File.dir? dir do
      File.rm_rf dir
    end
  end

  def rm!(file) do
    if File.exists? file do
      File.rm! file
    end
  end

  def raise_option_errors(list) do
    list
    |> Enum.map(fn option -> "--" <> Atom.to_string(option) |> String.replace("_", "-") end)
    |> Enum.join(", ")
    |> raise_unsupported
  end
  def raise_unsupported(list) do
    Mix.raise """
    The following option(s) are not supported:
        #{inspect list}
    """
  end

  def verify_args!(parsed, unknown) do
    unless Enum.empty?(parsed) do
      parsed
      |> Enum.join(", ")
      |> raise_invalid
    end

    unless Enum.empty?(unknown) do
      unknown
      |> Enum.map(&(elem(&1, 0)))
      |> Enum.join(", ")
      |> raise_invalid
    end
  end
  def raise_invalid(opts) do
    Mix.raise """
    Invalid argument(s) #{opts}
    """
  end


end
