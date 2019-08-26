defmodule TwitterRetargetingWeb.TaskController do
  use TwitterRetargetingWeb, :controller

  plug :check_user_is_authorized

  def new(conn, _params) do
    render conn, "new.html"
  end

  def show(conn, _params) do
     render conn, "show.html"
  end

  def create(conn, %{"common_followers_task" =>%{"user_handlers" => handlers_string}}) do
    handlers = handlers_string |> String.split(",") |> Enum.map(&(String.trim(&1)))
    if List.length(handlers) > 1 do
      TwitterRetargeting.Task.CommonFollowers.run(self(), conn.current_user, handlers)
      conn
        |> put_flash(:info, "Task been created")
        |> redirect(to: Routes.task_path(conn, :show))
    else
      conn
        |> put_flash(:error, "Please, specify more then one handler")
        |> render("new.html")
    end
  end
end
