defmodule TwitterRetargeting.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :username, :string

    timestamps()
  end

  @doc """
  Basic changeset to work with
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password, :password_hash, :email])
    |> validate_required([:username, :email])
  end

  def registration_changeset(user, attrs) do
    user
      |> changeset(attrs)
      |> validate_length(:password, min: 8)
      |> hash_password
  end

  defp hash_password(changeset) do
    change(changeset, Bcrypt.add_hash(changeset.changes.password))
  end
end
