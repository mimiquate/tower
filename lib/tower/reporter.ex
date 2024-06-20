defmodule Tower.Reporter do
  @doc """
  Reports an exception.
  """
  @callback report_exception(exception :: Exception.t(), stacktrace :: list()) :: :ok
  @callback report_exception(exception :: Exception.t(), stacktrace :: list(), metadata :: map()) ::
              :ok
  @callback report_term(reason :: term()) :: :ok
  @callback report_term(reason :: term(), metadata :: map()) :: :ok
end
