defmodule Tower.Filter do
  @moduledoc """
  Behaviour that can be implemented to write Tower filters.

  Tower comes built-in with a `Tower.NoopFilter`, that implements this behaviour and always
  reports every event, which is the default behaviour.

  ## Writing a custom filter

  # lib/my_app/error_filter.ex
  defmodule MyApp.ErrorFilter do
    @behaviour Tower.Filter

    @impl true
    def should_report?(_reporter, %Tower.Event{reason: %DBConnection.ConnectionError{}}), do: false
    def should_report?(_reporter, _event), do: true
  end

  # in some config/*.exs
  config :tower, filter: MyApp.ErrorFilter
  """

  @doc """
  Function called before reporting each event to each reporter.

  Receives the reporter module and the event, and should return `true` to report or `false` to ignore.
  """
  @callback should_report?(reporter :: module(), event :: Tower.Event.t()) :: boolean()
end
