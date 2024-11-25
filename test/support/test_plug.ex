defmodule Tower.TestPlug do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/runtime-error" do
    Tower.context(%{user_id: 123})

    raise "an error"

    send_resp(conn, 200, "OK")
  end

  get "/abnormal-exit" do
    Tower.context(%{user_id: 123})

    exit(:abnormal)

    send_resp(conn, 200, "OK")
  end

  get "/uncaught-throw" do
    Tower.context(%{user_id: 123})

    throw("something")

    send_resp(conn, 200, "OK")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
