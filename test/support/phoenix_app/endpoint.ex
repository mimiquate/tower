defmodule Tower.PhoenixApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_app

  plug(Tower.TestPlug)
end
