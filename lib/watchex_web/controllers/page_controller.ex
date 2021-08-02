defmodule WatchexWeb.PageController do
  use WatchexWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
