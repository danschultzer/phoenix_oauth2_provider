defmodule PhoenixOauth2Provider.Test.User do
  @moduledoc false

  use PhoenixOauth2Provider.Test.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    has_many :tokens, ExOauth2Provider.OauthAccessTokens.OauthAccessToken, foreign_key: :resource_owner_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email])
  end
end
