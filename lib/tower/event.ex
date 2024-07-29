defmodule Tower.Event do
  defstruct [:kind, :reason, :stacktrace, :log_event_meta]

  @type t :: %__MODULE__{
          kind: :error | :exit | :throw,
          reason: Exception.t() | term(),
          stacktrace: Exception.stacktrace(),
          log_event_meta: :logger.metadata()
        }

  def from_exception(exception, stacktrace, log_event_meta) do
    %__MODULE__{
      kind: :error,
      reason: exception,
      stacktrace: stacktrace,
      log_event_meta: log_event_meta
    }
  end

  def from_exit(reason, stacktrace, log_event_meta) do
    %__MODULE__{
      kind: :exit,
      reason: reason,
      stacktrace: stacktrace,
      log_event_meta: log_event_meta
    }
  end

  def from_throw(reason, stacktrace, log_event_meta) do
    %__MODULE__{
      kind: :throw,
      reason: reason,
      stacktrace: stacktrace,
      log_event_meta: log_event_meta
    }
  end
end
