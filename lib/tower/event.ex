defmodule Tower.Event do
  defstruct [:id, :time, :level, :kind, :reason, :stacktrace, :metadata]

  @type metadata :: %{optional(:log_event) => :logger.log_event()}

  @type t :: %__MODULE__{
          id: Uniq.UUID.t(),
          time: :logger.timestamp(),
          level: :logger.level(),
          kind: :error | :exit | :throw | :message,
          reason: Exception.t() | term(),
          stacktrace: Exception.stacktrace() | nil,
          metadata: metadata()
        }

  @spec from_exception(Exception.t(), Exception.stacktrace()) :: t()
  @spec from_exception(Exception.t(), Exception.stacktrace(), Keyword.t()) :: t()
  def from_exception(exception, stacktrace, options \\ []) do
    log_event = Keyword.get(options, :log_event)

    %__MODULE__{
      id: new_id(),
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

  @spec from_exit(term(), Exception.stacktrace()) :: t()
  @spec from_exit(term(), Exception.stacktrace(), Keyword.t()) :: t()
  def from_exit(reason, stacktrace, options \\ []) do
    log_event = Keyword.get(options, :log_event)

    %__MODULE__{
      id: new_id(),
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

  @spec from_throw(term(), Exception.stacktrace()) :: t()
  @spec from_throw(term(), Exception.stacktrace(), Keyword.t()) :: t()
  def from_throw(reason, stacktrace, options \\ []) do
    log_event = Keyword.get(options, :log_event)

    %__MODULE__{
      id: new_id(),
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

  @spec from_message(:logger.level(), term()) :: t()
  @spec from_message(:logger.level(), term(), Keyword.t()) :: t()
  def from_message(level, message, options \\ []) do
    log_event = Keyword.get(options, :log_event)

    %__MODULE__{
      id: new_id(),
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

  def new_id do
    Uniq.UUID.uuid7()
  end
end
