defmodule Tower.Event do
  defstruct [:kind, :exception, :message, :stacktrace, :log_event_meta]
end
