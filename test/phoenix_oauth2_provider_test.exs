defmodule PhoenixOauth2ProviderTest do
  use PhoenixOauth2Provider.Test.ConnCase
  alias PhoenixOauth2Provider

  test "current_resource_owner/1" do
    assert PhoenixOauth2Provider.current_resource_owner(%{assigns: %{current_test_user: "user"}}) == "user"
  end

  test "current_resource_owner/1 when not loaded" do
    assert_raise RuntimeError, "Resource owner was not found with :current_test_user assigns", fn ->
      PhoenixOauth2Provider.current_resource_owner(%{assigns: %{}})
    end
  end
end
