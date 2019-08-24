defmodule TwitterRetargetingWeb.UserController do
  use TwitterRetargetingWeb, :controller

  alias TwitterRetargeting.User
  alias TwitterRetargeting.Repo

  def new(conn, _params) do
    changeset = User.changeset(%User{}, %{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"user" => user_params}) do
    changeset = User.registration_changeset(%User{}, user_params) |> Repo.insert
    case changeset do
      { :ok, _ } ->
        conn |> put_flash(:success, "User created")
             |> redirect(to: Routes.page_path(conn, :index))
      {:error, changeset } ->
        conn |> put_flash(:error, "Please, fix errors and try again")
             |> render("new.html", changeset: changeset)
    end
  end
end
