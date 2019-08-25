defmodule TwitterRetargetingWeb.TwitterOauth do
  use TwitterRetargetingWeb, :controller
  alias TwitterRetargeting.TwitterOauth

  plug :check_user_is_authorized

  def create(conn, _params) do
    conn |> redirect(external: TwitterOauth.user_authorization_url)
  end

  def register_callback(conn, %{"oauth_token" => token, "oauth_verifier" => verifier}) do
    token = ExTwitter.access_token(verifier, token)

    case token do
      {:ok, token} ->
        store_token(token)
        conn
          |> put_flash(:info, "Token for username #{token.screen_name} stored")
          |> redirect(to: Routes.page_path(conn, :index))
      {:error, _} ->
        conn
          |> put_flash(:error, "Something went wrong, please, try again")
          |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  defp store_token(token) do
    :noop
  end
end
