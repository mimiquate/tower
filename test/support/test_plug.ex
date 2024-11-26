defmodule Tower.TestPlug do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/runtime-error" do
    Logger.metadata(user_id: 123, secret: "secret")

    raise "an error"

    send_resp(conn, 200, "OK")
  end

  get "/abnormal-exit" do
    Logger.metadata(user_id: 123, secret: "secret")

    exit(:abnormal)

    send_resp(conn, 200, "OK")
  end

  get "/uncaught-throw" do
    Logger.metadata(user_id: 123, secret: "secret")

    throw("something")

    send_resp(conn, 200, "OK")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
