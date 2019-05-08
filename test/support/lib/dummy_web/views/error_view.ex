defmodule DummyWeb.ErrorView do
  def render("500.html", _changeset), do: "500.html"
  def render("400.html", _changeset), do: "400.html"
  def render("404.html", _changeset), do: "404.html"
end
