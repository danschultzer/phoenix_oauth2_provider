defmodule DummyWeb do
  @moduledoc false

  def view do
    quote do
      use Phoenix.View,
        root: "test/support/lib/dummy_web/templates",
        namespace: DummyWeb
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
