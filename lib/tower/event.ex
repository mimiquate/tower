defmodule Tower.Event do
  defstruct [:level, :kind, :reason, :stacktrace, :log_event_meta]

  @type t :: %__MODULE__{
          level: :logger.level(),
          kind: :error | :exit | :throw | :message,
          reason: Exception.t() | term(),
          stacktrace: Exception.stacktrace(),
          log_event_meta: :logger.metadata()
        }

  def from_exception(exception, stacktrace, log_event_meta) do
    %__MODULE__{
      level: :error,
      kind: :error,
      reason: exception,
      stacktrace: stacktrace,
      log_event_meta: log_event_meta
    }
  end

  def from_exit(reason, stacktrace, log_event_meta) do
    %__MODULE__{
      level: :error,
      kind: :exit,
      reason: reason,
      stacktrace: stacktrace,
      log_event_meta: log_event_meta
    }
  end

  def from_throw(reason, stacktrace, log_event_meta) do
    %__MODULE__{
      level: :error,
      kind: :throw,
      reason: reason,
      stacktrace: stacktrace,
      log_event_meta: log_event_meta
    }
  end

  def from_message(level, message, log_event_meta) do
    %__MODULE__{
      level: level,
      kind: :message,
      reason: message,
      log_event_meta: log_event_meta
    }
  end
end
