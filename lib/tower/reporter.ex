defmodule Tower.Reporter do
  @doc """
  Reports an exception.
  """
  @callback report_exception(exception :: Exception.t(), stacktrace :: list()) :: :ok
  @callback report_exception(exception :: Exception.t(), stacktrace :: list(), metadata :: map()) ::
              :ok
  @callback report_throw(reason :: term(), stacktrace :: list()) :: :ok
  @callback report_throw(reason :: term(), stacktrace :: list(), metadata :: map()) :: :ok
  @callback report_exit(reason :: term(), stacktrace :: list()) :: :ok
  @callback report_exit(reason :: term(), stacktrace :: list(), metadata :: map()) :: :ok
  @callback report_message(level :: atom(), message :: term()) :: :ok
  @callback report_message(level :: atom(), message :: term(), metadata :: map()) :: :ok
end
