defmodule Tower.Event do
  defstruct [:exception, :stacktrace, :log_event_meta]

  def from_exception(exception, stacktrace, log_event_meta) do
    %__MODULE__{
      exception: exception,
      stacktrace: stacktrace,
      log_event_meta: log_event_meta
    }
  end
end
