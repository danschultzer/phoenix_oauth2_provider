defmodule ExOauth2Phoenix.ViewHelpers do
  @moduledoc """
  Helper functions for ExOauth2Phoenix Views.
  """
  use Phoenix.HTML

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    if error = form.errors[field] do
      content_tag :span, translate_error(error), class: "help-block"
    end
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # Because error messages were defined within Ecto, we must
    # call the Gettext module passing our Gettext backend. We
    # also use the "errors" domain as translations are placed
    # in the errors.po file. On your own code and templates,
    # this could be written simply as:
    #
    #     dngettext "errors", "1 file", "%{count} files", count
    #
    Gettext.dngettext(ExOauth2Phoenix.Web.Gettext, "errors", msg, msg, opts[:count] || 0, opts)
  end

  def translate_error(msg) do
    Gettext.dgettext(ExOauth2Phoenix.Web.Gettext, "errors", msg)
  end
end
