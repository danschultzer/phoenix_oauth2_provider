defmodule ExOauth2PhoenixTest do
  use ExOauth2Phoenix.Test.ConnCase

  import ExOauth2Phoenix

  test "current_resource_owner/1" do
    assert current_resource_owner(%{assigns: %{current_test_user: "user"}}) == "user"
  end

  test "current_resource_owner/1 when not loaded" do
    assert_raise RuntimeError, "Resource owner was not found with :current_test_user assigns", fn ->
      current_resource_owner(%{assigns: %{}})
    end
  end
end
