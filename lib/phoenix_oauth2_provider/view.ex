defmodule PhoenixOauth2Provider.View do
  @moduledoc false

  alias Phoenix.HTML.Tag

  @doc false
  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      import Phoenix.HTML.{Form, Link, Tag}

      alias PhoenixOauth2Provider.Router.Helpers, as: Routes

      Module.register_attribute(__MODULE__, :templates, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @spec templates :: [binary()]
      def templates, do: @templates
    end
  end

  defmacro template(template, content) do
    content = EEx.eval_string(content)
    quoted = EEx.compile_string(content, engine: Phoenix.HTML.Engine, line: 1, trim: true)

    quote do
      @templates unquote(template)

      def render(unquote(template), var!(assigns)) do
        _ = var!(assigns)
        unquote(quoted)
      end

      def html(unquote(template)), do: unquote(content)
    end
  end

  def error_tag(form, field) do
    form.errors
    |> Keyword.get_values(field)
    |> Enum.map(&error_tag/1)
  end

  def error_tag(error) do
    Tag.content_tag(:span, translate_error(error), class: "help-block")
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, msg ->
      token = "%{#{key}}"

      case String.contains?(msg, token) do
        true -> String.replace(msg, token, to_string(value), global: false)
        false -> msg
      end
    end)
  end
end
