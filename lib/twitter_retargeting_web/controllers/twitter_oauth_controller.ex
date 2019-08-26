defmodule TwitterRetargetingWeb.TwitterOauthController do
  use TwitterRetargetingWeb, :controller
  alias TwitterRetargeting.TwitterOauth
  alias TwitterRetargeting.Token
  alias TwitterRetargeting.Repo

  plug :check_user_is_authorized

  def create(conn, _params) do
    conn |> redirect(external: TwitterOauth.user_authorization_url)
  end

  def register_callback(conn, %{"oauth_token" => token, "oauth_verifier" => verifier}) do
    token = ExTwitter.access_token(verifier, token)

    case token do
      {:ok, token} ->
        store_token(conn, token)
        conn
          |> put_flash(:info, "Token for username #{token.screen_name} stored")
          |> redirect(to: Routes.page_path(conn, :index))
      {:error, _} ->
        conn
          |> put_flash(:error, "Something went wrong, please, try again")
          |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  defp store_token(%{assigns: %{current_user: user}}, token_attrs) do
    user = Repo.preload(user, :tokens)
    token = Repo.get_by(Token, user_id: user.id, screen_name: token_attrs.screen_name) |> Repo.preload(:user)
    token = token || Ecto.build_assoc(user, :tokens)
    attrs = Map.from_struct(token_attrs) |> Map.delete(:user_id)
    changeset = Token.changeset(token, attrs)
    if !token.id do
      {:ok, _} = changeset |> Repo.insert
    else
      {:ok, _} = changeset |> Repo.update
    end
  end
end
