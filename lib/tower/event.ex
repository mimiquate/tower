defmodule Tower.Event do
  defstruct [:time, :level, :kind, :reason, :stacktrace, :metadata]

  @type metadata :: %{log_event: :logger.log_event()}
  @type error_kind :: :error | :exit | :throw
  @type non_error_kind :: :message

  @type t :: %__MODULE__{
          time: :logger.timestamp(),
          level: :logger.level(),
          kind: error_kind() | non_error_kind(),
          reason: Exception.t() | term(),
          stacktrace: Exception.stacktrace(),
          metadata: metadata()
        }

  def from_caught(kind, exception, stacktrace, options \\ [])

  def from_caught(:error, exception, stacktrace, options) when is_exception(exception) do
    from_exception(exception, stacktrace, options)
  end

  def from_caught(:error, reason, stacktrace, options) do
    Exception.normalize(:error, reason, stacktrace)
    |> from_exception(stacktrace, options)
  end

  def from_caught(:exit, reason, stacktrace, options) do
    from_exit(reason, stacktrace, options)
  end

  def from_caught(:throw, reason, stacktrace, options) do
    from_throw(reason, stacktrace, options)
  end

  def from_exception(exception, stacktrace, options \\ []) do
    log_event = Keyword.get(options, :log_event)

    %__MODULE__{
      time: log_event[:meta][:time] || now(),
      level: :error,
      kind: :error,
      reason: exception,
      stacktrace: stacktrace,
      metadata: %{
        log_event: log_event
      }
    }
  end

  def from_exit(reason, stacktrace, options \\ []) do
    log_event = Keyword.get(options, :log_event)

    %__MODULE__{
      time: log_event[:meta][:time] || now(),
      level: :error,
      kind: :exit,
      reason: reason,
      stacktrace: stacktrace,
      metadata: %{
        log_event: log_event
      }
    }
  end

  def from_throw(reason, stacktrace, options \\ []) do
    log_event = Keyword.get(options, :log_event)

    %__MODULE__{
      time: log_event[:meta][:time] || now(),
      level: :error,
      kind: :throw,
      reason: reason,
      stacktrace: stacktrace,
      metadata: %{
        log_event: log_event
      }
    }
  end

  def from_message(level, message, options \\ []) do
    log_event = Keyword.get(options, :log_event)

    %__MODULE__{
      time: log_event[:meta][:time] || now(),
      level: level,
      kind: :message,
      reason: message,
      metadata: %{
        log_event: log_event
      }
    }
  end

  defp now do
    :logger.timestamp()
  end
end
