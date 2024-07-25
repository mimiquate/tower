defmodule Tower.Handler do
  @doc """
  Reports an exception.
  """
  @callback handle_event(event :: Tower.Event.t()) :: :ok
end
