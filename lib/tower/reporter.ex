defmodule Tower.Reporter do
  @doc """
  Reports an exception.
  """
  @callback report_exception(Exception.t(), list()) :: :ok
end
