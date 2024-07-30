defmodule Tower.Event do
  defstruct [:time, :level, :kind, :reason, :stacktrace, :metadata]

  @type metadata :: %{log_event: :logger.log_event()}

  @type t :: %__MODULE__{
          time: :logger.timestamp(),
          level: :logger.level(),
          kind: :error | :exit | :throw | :message,
          reason: Exception.t() | term(),
          stacktrace: Exception.stacktrace(),
          metadata: metadata()
        }

  def from_exception(exception, stacktrace, log_event) do
    %__MODULE__{
      time: log_event[:meta][:time] || :logger.timestamp(),
      level: :error,
      kind: :error,
      reason: exception,
      stacktrace: stacktrace,
      metadata: %{
        log_event: log_event
      }
    }
  end

  def from_exit(reason, stacktrace, log_event) do
    %__MODULE__{
      time: log_event[:meta][:time] || :logger.timestamp(),
      level: :error,
      kind: :exit,
      reason: reason,
      stacktrace: stacktrace,
      metadata: %{
        log_event: log_event
      }
    }
  end

  def from_throw(reason, stacktrace, log_event) do
    %__MODULE__{
      time: log_event[:meta][:time] || :logger.timestamp(),
      level: :error,
      kind: :throw,
      reason: reason,
      stacktrace: stacktrace,
      metadata: %{
        log_event: log_event
      }
    }
  end

  def from_message(level, message, log_event) do
    %__MODULE__{
      time: log_event[:meta][:time] || :logger.timestamp(),
      level: level,
      kind: :message,
      reason: message,
      metadata: %{
        log_event: log_event
      }
    }
  end
end
