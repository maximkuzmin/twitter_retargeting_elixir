defmodule TwitterRetargeting.Repo.Migrations.CreateTokens do
  use Ecto.Migration

  def change do
    create table(:tokens) do
      add :oauth_token, :string
      add :oauth_token_secret, :string
      add :screen_name, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end
    create index(:tokens, :screen_name, unique: true)
    create index(:tokens, [:user_id])
  end
end
