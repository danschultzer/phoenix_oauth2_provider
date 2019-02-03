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
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:span, translate_error(error), class: "help-block")
    end)
  end

  @doc """
  Translates an error message using gettext.
  """
  @spec translate_error({binary(), Keyword.t()}) :: binary()
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(PhoenixOauth2Provider.Web.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(PhoenixOauth2Provider.Web.Gettext, "errors", msg, opts)
    end
  end
end
