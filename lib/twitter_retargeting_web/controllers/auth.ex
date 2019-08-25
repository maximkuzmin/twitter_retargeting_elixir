defmodule TwitterRetargeting.Auth do
  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  alias TwitterRetargeting.User

  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  def call(conn, repo) do
    user_id = get_session(conn, :user_id)
    user = user_id && repo.get(User, user_id)
    assign conn, :current_user, user
  end

  def login!(conn, user) do
    conn
      |> assign(:current_user, user)
      |> put_session(:user_id, user.id)
      |> configure_session(renew: :true)
  end

  def logout!(conn) do
    configure_session(conn, drop: true)
  end

  def login_with_username_or_email_and_password(conn, username_or_email, password, opts) do
    {:ok, repo} = Keyword.fetch(opts, :repo)
    user = User.find_by_username_or_email(username_or_email, repo)

    all_good = user && Bcrypt.check_pass(user, password)
    if all_good do
      {:ok, login!(conn, user)}
    else
      Bcrypt.no_user_verify()
      {:error, :unauthorized, conn}
    end
  end

  def check_user_is_authorized(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
        |> put_flash(:error, "Login first, please")
        |> redirect(to: Router.session_path(conn, :new))
        |> halt()
    end
  end
end
