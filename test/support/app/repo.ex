defmodule PhoenixOauth2Provider.Test.Repo do
  use Ecto.Repo, otp_app: :phoenix_oauth2_provider

  def log(_cmd), do: nil
end
