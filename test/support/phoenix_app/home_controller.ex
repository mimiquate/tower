defmodule Tower.PhoenixApp.HomeController do
  use Phoenix.Controller, formats: [:html], put_default_views: false

  def show(conn, %{"param" => "valid"}) do
    Plug.Conn.send_resp(conn, 200, "Hey!")
  end

  def runtime_error(conn, _params) do
    Logger.metadata(user_id: 123)

    raise "an error"

    Plug.Conn.send_resp(conn, 200, "OK")
  end

  def erlang_error(conn, _params) do
    Logger.metadata(user_id: 123)

    _ = 1 / 0

    Plug.Conn.send_resp(conn, 200, "OK")
  end

  def abnormal_exit(conn, _params) do
    Logger.metadata(user_id: 123)

    exit(:abnormal)

    Plug.Conn.send_resp(conn, 200, "OK")
  end

  def uncaught_throw(conn, _params) do
    Logger.metadata(user_id: 123)

    throw("something")

    Plug.Conn.send_resp(conn, 200, "OK")
  end
end
