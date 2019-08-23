defmodule TwitterRetargetingWeb.PageController do
  use TwitterRetargetingWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
