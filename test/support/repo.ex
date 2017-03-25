defmodule ExOauth2Phoenix.Test.Repo do
  use Ecto.Repo, otp_app: :ex_oauth2_phoenix

  def log(_cmd), do: nil
end
