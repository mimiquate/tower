defmodule Tower.Event do
  defstruct [:time, :level, :kind, :reason, :stacktrace, :log_event_meta]

  @type t :: %__MODULE__{
          time: :logger.timestamp(),
          level: :logger.level(),
          kind: :error | :exit | :throw | :message,
          reason: Exception.t() | term(),
          stacktrace: Exception.stacktrace(),
          log_event_meta: :logger.metadata()
        }

  def from_exception(exception, stacktrace, log_event_meta) do
    %__MODULE__{
      time: Map.get(log_event_meta, :time, now()),
      level: :error,
      kind: :error,
      reason: exception,
      stacktrace: stacktrace,
      log_event_meta: log_event_meta
    }
  end

  def from_exit(reason, stacktrace, log_event_meta) do
    %__MODULE__{
      time: Map.get(log_event_meta, :time, now()),
      level: :error,
      kind: :exit,
      reason: reason,
      stacktrace: stacktrace,
      log_event_meta: log_event_meta
    }
  end

  def from_throw(reason, stacktrace, log_event_meta) do
    %__MODULE__{
      time: Map.get(log_event_meta, :time, now()),
      level: :error,
      kind: :throw,
      reason: reason,
      stacktrace: stacktrace,
      log_event_meta: log_event_meta
    }
  end

  def from_message(level, message, log_event_meta) do
    %__MODULE__{
      time: Map.get(log_event_meta, :time, now()),
      level: level,
      kind: :message,
      reason: message,
      log_event_meta: log_event_meta
    }
  end

  defp now do
    :logger.timestamp()
  end
end
