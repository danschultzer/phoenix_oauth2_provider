defmodule PhoenixOauth2Provider.ViewHelpers do
  @moduledoc """
  Helper functions for PhoenixOauth2Provider Views.
  """
  use Phoenix.HTML
  alias Ecto.Changeset
  alias Phoenix.HTML

  @doc """
  Generates tag for inlined form input errors.
  """
  @spec error_tag(Changeset.t(), atom()) :: HTML.safe() | nil
  def error_tag(form, field) do
    if error = form.errors[field] do
      content_tag(:span, translate_error(error), class: "help-block")
    end
  end

  @doc """
  Translates an error message using gettext.
  """
  @spec translate_error({binary(), Keyword.t()}) :: binary()
  def translate_error({msg, opts}) do
    # Because error messages were defined within Ecto, we must
    # call the Gettext module passing our Gettext backend. We
    # also use the "errors" domain as translations are placed
    # in the errors.po file. On your own code and templates,
    # this could be written simply as:
    #
    #     dngettext "errors", "1 file", "%{count} files", count
    #
    Gettext.dngettext(PhoenixOauth2Provider.Web.Gettext, "errors", msg, msg, opts[:count] || 0, opts)
  end

  @spec translate_error(binary()) :: binary()
  def translate_error(msg) do
    Gettext.dgettext(PhoenixOauth2Provider.Web.Gettext, "errors", msg)
  end
end
