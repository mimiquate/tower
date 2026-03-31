defmodule Tower.PhoenixApp.HomeLive do
  use Phoenix.LiveView

  def render(%{live_action: :runtime_error}) do
    Logger.metadata(user_id: 123)

    raise "an error"
  end
end
