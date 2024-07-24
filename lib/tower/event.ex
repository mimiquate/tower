defmodule Tower.Event do
  defstruct [:level, :kind, :exception, :message, :stacktrace, :log_event_meta]
end
