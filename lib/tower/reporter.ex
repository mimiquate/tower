defmodule Tower.Reporter do
  @doc """
  Reports events.
  """
  @callback report_event(event :: Tower.Event.t()) :: :ok
  @callback report_message(level :: atom(), message :: term()) :: :ok
  @callback report_message(level :: atom(), message :: term(), metadata :: map()) :: :ok
end
