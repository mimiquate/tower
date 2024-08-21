defmodule Tower.Reporter do
  @moduledoc """
  Behaviour that can be used to write Tower reporters.
  """

  @doc """
  Function that will be called with every event handled by Tower.
  """
  @callback report_event(event :: Tower.Event.t()) :: :ok
end
