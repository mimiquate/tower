defmodule Tower.Reporter do
  @doc """
  Reports events.
  """
  @callback report_event(event :: Tower.Event.t()) :: :ok
end
