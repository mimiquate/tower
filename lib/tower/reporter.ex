defmodule Tower.Reporter do
  @doc """
  Reports an exception.
  """
  @callback report_exception(exception :: Exception.t(), stacktrace :: list()) :: :ok
  @callback report_exception(
              exception :: Exception.t(),
              stacktrace :: list(),
              options :: Keyword.t()
            ) :: :ok
  @callback report_message(message :: String.t()) :: :ok
  @callback report_message(message :: String.t(), options :: Keyword.t()) :: :ok
end
