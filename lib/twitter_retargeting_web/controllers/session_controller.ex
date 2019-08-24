defmodule TwitterRetargetingWeb.SessionController do
  use TwitterRetargetingWeb, :controller


  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"login" => %{"login" => login, "password" => password}}) do
    user = TwitterRetargeting.Auth.login_with_username_or_email_and_password(conn, login, password, repo: TwitterRetargeting.Repo)
    case user do
      {:ok, conn} -> redirect(conn, to: Routes.page_path(conn, :index))
      {:error, :unauthorized, conn} ->
          conn |> put_flash(:error, "Try again") |>  render("new.html")
    end
  end

  def delete(conn, _params) do
    conn |> TwitterRetargeting.Auth.logout! |> redirect(to: Routes.page_path(conn, :index))
  end
end
