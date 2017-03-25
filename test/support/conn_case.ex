defmodule ExOauth2Phoenix.Test.ConnCase do
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

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import ExOauth2Phoenix.Test.ErrorView
      import ExOauth2Phoenix.Test.Router.Helpers

      @endpoint ExOauth2Phoenix.Test.Endpoint
    end
  end


  setup tags do
    unless tags[:async] do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(ExOauth2Phoenix.Test.Repo)
    end
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

end
