defmodule TwitterRetargeting.Token do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tokens" do
    field :oauth_token, :string
    field :oauth_token_secret, :string
    field :screen_name, :string
    belongs_to :user, TwitterRetargeting.User

    timestamps()
  end

  @doc false
  def changeset(token, attrs) do
    token
    |> cast(attrs, [:oauth_token, :oauth_token_secret, :screen_name, :user_id])
    |> validate_required([:oauth_token, :oauth_token_secret, :screen_name, :user_id])
    |> unique_constraint(:screen_name)
  end
end
