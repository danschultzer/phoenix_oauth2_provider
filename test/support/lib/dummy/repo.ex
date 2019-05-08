defmodule Dummy.Repo do
  use Ecto.Repo, otp_app: :phoenix_oauth2_provider, adapter: Ecto.Adapters.Postgres

  def log(_cmd), do: nil
end
