defmodule WatchexWeb.PingController do
  use WatchexWeb, :controller

  def ping(conn, params) do
    IO.puts("params => #{inspect params}")
    json(conn, %{"pong" => params["uid"]})
  end
end
