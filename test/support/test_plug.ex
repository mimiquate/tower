defmodule Tower.TestPlug do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/runtime-error" do
    raise "an error"

    send_resp(conn, 200, "OK")
  end

  get "/abnormal-exit" do
    exit(:abnormal)

    send_resp(conn, 200, "OK")
  end

  get "/uncaught-throw" do
    throw("something")

    send_resp(conn, 200, "OK")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
