defmodule Tower.PhoenixApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_app

  # So that it fetches query params
  plug(Plug.Parsers, parsers: [])
  plug(Tower.PhoenixApp.Router)
end
