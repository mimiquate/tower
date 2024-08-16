defmodule Tower.TestPlug do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/arithmetic-error" do
    1 / 0

    send_resp(conn, 200, "OK")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
