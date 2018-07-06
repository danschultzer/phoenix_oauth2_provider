defmodule PhoenixOauth2Provider.Mix.Utils do
  @moduledoc false

  alias Mix.Phoenix

  @spec raise_option_errors([atom()]) :: no_return
  def raise_option_errors(list) do
    list
    |> Enum.map(&normalize_option/1)
    |> Enum.join(", ")
    |> raise_unsupported()
  end

  defp normalize_option(option) do
    "--"
    |> Kernel.<>(Atom.to_string(option))
    |> String.replace("_", "-")
  end

  defp raise_unsupported(list) do
    Mix.raise """
    The following option(s) are not supported:
        #{inspect list}
    """
  end

  @spec verify_args!({OptionParser.parsed(), OptionParser.argv(), OptionParser.errors()}) ::  {OptionParser.parsed(), OptionParser.argv(), OptionParser.errors()} | no_return
  def verify_args!({parsed, argv, errors}) do
    argv
    |> Enum.join(", ")
    |> maybe_raise_invalid()

    errors
    |> Enum.map(&(elem(&1, 0)))
    |> Enum.join(", ")
    |> maybe_raise_invalid()

    {parsed, argv, errors}
  end

  defp maybe_raise_invalid(""), do: nil
  defp maybe_raise_invalid(opts) do
    Mix.raise("Invalid argument(s) #{opts}")
  end

  @spec web_path() :: binary()
  def web_path(), do: web_path("")
  @spec web_path(Path.t()) :: binary()
  def web_path(path), do: Path.join(get_web_prefix(), path)

  defp get_web_prefix, do: Phoenix.web_path(Phoenix.otp_app())

  @spec list_to_existing_atoms([binary()]) :: [atom()]
  def list_to_existing_atoms(list) do
    Enum.map(list, &String.to_existing_atom/1)
  end

  @spec to_config_options([atom()], [binary()]) :: [binary()]
  def to_config_options(list, acc \\ []) do
    Enum.reduce(list, acc, &to_config_option/2)
  end

  defp to_config_option(opt, acc) do
    str = opt |> Atom.to_string() |> String.replace("_", "-")

    ["--" <> str | acc]
  end
end
