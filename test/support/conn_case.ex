defmodule PhoenixOauth2Provider.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """
  use ExUnit.CaseTemplate

  alias Dummy.Repo
  alias DummyWeb.{Endpoint, Router.Helpers}
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      alias Helpers, as: Routes

      @endpoint Endpoint
    end
  end

  setup tags do
    unless tags[:async] do
      :ok = Sandbox.checkout(Repo)
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
