defmodule PhoenixOauth2Provider.Test.User do
  @moduledoc false

  use PhoenixOauth2Provider.Test.Schema
  alias ExOauth2Provider.OauthAccessTokens.OauthAccessToken
  alias Ecto.Changeset

  schema "users" do
    field :email, :string
    has_many :tokens, OauthAccessToken, foreign_key: :resource_owner_id

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    Changeset.cast(struct, params, [:email])
  end
end
