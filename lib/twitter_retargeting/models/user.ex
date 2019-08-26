defmodule TwitterRetargeting.User do
  use Ecto.Schema
  import Ecto.Changeset

  @email_regexp  ~r/([A-z]|\.|\d)+\@([A-z]|\d)+\.[A-z]{2,}/
  @username_regexp  ~r/[A-z0-9]+/

  schema "users" do
    field :email,                 :string
    field :password,              :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :password_hash,         :string
    field :username,              :string
    has_many :tokens, TwitterRetargeting.Token

    timestamps()
  end

  @doc """
  Basic changeset to work with
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email])
    |> validate_required([:username, :email])
    |> validate_format(:username, @username_regexp)
    |> validate_format(:email, @email_regexp)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end

  def registration_changeset(user, attrs) do
    user
      |> changeset(attrs)
      |> cast(attrs, [:password, :password_confirmation])
      |> validate_required([:password, :password_confirmation])
      |> validate_password_confirmation
      |> validate_length(:password, min: 8)
      |> hash_password
  end

  defp hash_password(changeset) do
    change(changeset, Bcrypt.add_hash(changeset.changes.password))
  end

  defp validate_password_confirmation(%{valid?: true, changes: %{password: password, password_confirmation: password_confirmation}} = changeset) do
    changeset = change(changeset, %{password_confirmation: nil}) # get rid of password confirmation parameter anyway
    if password_confirmation == password do
      changeset
    else
      add_error(changeset, :password_confirmation, "Password confirmation is not the same as password")
    end
  end

  defp validate_password_confirmation(%{valid?: false} = changeset), do: changeset

  def find_by_username_or_email(username_or_email, repo \\ TwitterRetargeting.Repo) do
    cond do
      String.match?(username_or_email, @email_regexp) ->
        repo.get_by(__MODULE__, email: username_or_email)

      String.match?(username_or_email, @username_regexp) ->
        repo.get_by(__MODULE__, username: username_or_email)

      true -> nil
    end
  end
end
